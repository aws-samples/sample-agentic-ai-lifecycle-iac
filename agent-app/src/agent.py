"""
StreamableHTTP Client Transport with AWS SigV4 Signing

This module extends the MCP StreamableHTTPTransport to add AWS SigV4 request signing
for authentication with MCP servers that authenticate using AWS IAM.
"""

from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from datetime import timedelta
from typing import Generator

import httpx
from anyio.streams.memory import MemoryObjectReceiveStream, MemoryObjectSendStream
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import Credentials
from mcp.client.streamable_http import (
    GetSessionIdCallback,
    StreamableHTTPTransport,
    streamablehttp_client,
)
from mcp.shared._httpx_utils import McpHttpClientFactory, create_mcp_http_client
from mcp.shared.message import SessionMessage


class SigV4HTTPXAuth(httpx.Auth):
    """HTTPX Auth class that signs requests with AWS SigV4."""

    def __init__(
        self,
        credentials: Credentials,
        service: str,
        region: str,
    ):
        self.credentials = credentials
        self.service = service
        self.region = region
        self.signer = SigV4Auth(credentials, service, region)

    def auth_flow(
        self, request: httpx.Request
    ) -> Generator[httpx.Request, httpx.Response, None]:
        """Signs the request with SigV4 and adds the signature to the request headers."""

        # Create an AWS request
        headers = dict(request.headers)
        # Header 'connection' = 'keep-alive' is not used in calculating the request
        # signature on the server-side, and results in a signature mismatch if included
        headers.pop("connection", None)  # Remove if present, ignore if not

        aws_request = AWSRequest(
            method=request.method,
            url=str(request.url),
            data=request.content,
            headers=headers,
        )

        # Sign the request with SigV4
        self.signer.add_auth(aws_request)

        # Add the signature header to the original request
        request.headers.update(dict(aws_request.headers))

        yield request


class StreamableHTTPTransportWithSigV4(StreamableHTTPTransport):
    """
    Streamable HTTP client transport with AWS SigV4 signing support.

    This transport enables communication with MCP servers that authenticate using AWS IAM,
    such as servers behind a Lambda function URL or API Gateway.
    """

    def __init__(
        self,
        url: str,
        credentials: Credentials,
        service: str,
        region: str,
        headers: dict[str, str] | None = None,
        timeout: float | timedelta = 30,
        sse_read_timeout: float | timedelta = 60 * 5,
    ) -> None:
        """Initialize the StreamableHTTP transport with SigV4 signing.

        Args:
            url: The endpoint URL.
            credentials: AWS credentials for signing.
            service: AWS service name (e.g., 'lambda').
            region: AWS region (e.g., 'us-east-1').
            headers: Optional headers to include in requests.
            timeout: HTTP timeout for regular operations.
            sse_read_timeout: Timeout for SSE read operations.
        """
        # Initialize parent class with SigV4 auth handler
        super().__init__(
            url=url,
            headers=headers,
            timeout=timeout,
            sse_read_timeout=sse_read_timeout,
            auth=SigV4HTTPXAuth(credentials, service, region),
        )

        self.credentials = credentials
        self.service = service
        self.region = region


@asynccontextmanager
async def streamablehttp_client_with_sigv4(
    url: str,
    credentials: Credentials,
    service: str,
    region: str,
    headers: dict[str, str] | None = None,
    timeout: float | timedelta = 30,
    sse_read_timeout: float | timedelta = 60 * 5,
    terminate_on_close: bool = True,
    httpx_client_factory: McpHttpClientFactory = create_mcp_http_client,
) -> AsyncGenerator[
    tuple[
        MemoryObjectReceiveStream[SessionMessage | Exception],
        MemoryObjectSendStream[SessionMessage],
        GetSessionIdCallback,
    ],
    None,
]:
    """
    Client transport for Streamable HTTP with SigV4 auth.

    This transport enables communication with MCP servers that authenticate using AWS IAM,
    such as servers behind a Lambda function URL or API Gateway.

    Yields:
        Tuple containing:
            - read_stream: Stream for reading messages from the server
            - write_stream: Stream for sending messages to the server
            - get_session_id_callback: Function to retrieve the current session ID
    """

    async with streamablehttp_client(
        url=url,
        headers=headers,
        timeout=timeout,
        sse_read_timeout=sse_read_timeout,
        terminate_on_close=terminate_on_close,
        httpx_client_factory=httpx_client_factory,
        auth=SigV4HTTPXAuth(credentials, service, region),
    ) as result:
        yield result
from strands import Agent, tool
from strands.models import BedrockModel
from strands.tools.mcp.mcp_client import MCPClient
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.tools.code_interpreter_client import CodeInterpreter
from bedrock_agentcore.tools.browser_client import BrowserClient
from bedrock_agentcore.memory import MemoryClient
from bedrock_agentcore.services.identity import IdentityClient
from browser_use import Agent as BrowserAgent
from browser_use.browser.session import BrowserSession
from browser_use.browser import BrowserProfile
from langchain_aws import ChatBedrockConverse, ChatBedrock
from contextlib import suppress
from datetime import datetime
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.credentials import Credentials
import boto3
import httpx
import os
import json
import asyncio
import re
import traceback

app = BedrockAgentCoreApp()

# Environment variables
GATEWAY_URL = os.getenv('GATEWAY_URL')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
CODE_INTERPRETER_ID = os.getenv('CODE_INTERPRETER_ID')
BROWSER_ID = os.getenv('BROWSER_ID')
MEMORY_ID = os.getenv('MEMORY_ID')
WORKLOAD_IDENTITY_NAME = os.getenv('WORKLOAD_IDENTITY_NAME', 'agentcore-weather-identity')
API_KEY_PROVIDER_ARN = os.getenv('API_KEY_PROVIDER_ARN')
GUARDRAIL_ID = os.getenv('GUARDRAIL_ID', '')
GUARDRAIL_VERSION = os.getenv('GUARDRAIL_VERSION', '1')

# Helper functions for browser
async def run_browser_task(browser_session, bedrock_chat, task: str) -> str:
    """Run a browser automation task"""
    agent = BrowserAgent(task=task, llm=bedrock_chat, browser=browser_session)
    result = await agent.run()
    
    if 'done' in result.last_action() and 'text' in result.last_action()['done']:
        return result.last_action()['done']['text']
    else:
        raise ValueError("No data returned")

async def initialize_browser_session():
    """Initialize Browser session"""
    client = BrowserClient(AWS_REGION)
    client.start(identifier=BROWSER_ID)
    
    ws_url, headers = client.generate_ws_headers()
    browser_profile = BrowserProfile(headers=headers, timeout=150000)
    browser_session = BrowserSession(cdp_url=ws_url, browser_profile=browser_profile, keep_alive=True)
    
    await browser_session.start()
    
    # Use ChatBedrock instead of ChatBedrockConverse for async support
    bedrock_chat = ChatBedrock(
        model_id="us.anthropic.claude-3-7-sonnet-20250219-v1:0",
        region_name=AWS_REGION
    )
    
    return browser_session, bedrock_chat, client

# Tools
@tool
def execute_python_code(code: str) -> dict:
    """Execute Python code using Code Interpreter"""
    try:
        code_client = CodeInterpreter(AWS_REGION)
        code_client.start(identifier=CODE_INTERPRETER_ID)

        response = code_client.invoke("executeCode", {
            "code": code,
            "language": "python",
            "clearContext": True
        })

        result = None
        for event in response["stream"]:
            result = json.dumps(event["result"])
        
        return {"status": "success", "content": [{"text": str(result)}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}"}]}

@tool
async def get_weather_data(city: str) -> dict:
    """Get weather forecast for a city using Browser"""
    browser_session = None
    try:
        browser_session, bedrock_chat, browser_client = await initialize_browser_session()
        
        task = f"""Get 8-day weather forecast for {city} from weather.gov:
1. Go to https://weather.gov
2. Search for "{city}"
3. Click "Printable Forecast"
4. Extract: date, high, low, conditions, wind, precip
5. Return as JSON array"""
        
        result = await run_browser_task(browser_session, bedrock_chat, task)
        
        if browser_client:
            browser_client.stop()

        return {"status": "success", "content": [{"text": result}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}"}]}
    finally:
        if browser_session:
            with suppress(Exception):
                await browser_session.close()

@tool
def save_to_memory(user_id: str, session_id: str, content: str) -> dict:
    """Save information to Memory"""
    try:
        client = MemoryClient(region_name=AWS_REGION)
        
        result = client.create_event(
            memory_id=MEMORY_ID,
            actor_id=user_id,
            session_id=session_id,
            messages=[(content, "USER")]
        )
        
        return {"status": "success", "content": [{"text": f"Saved to memory successfully"}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}\nTraceback: {traceback.format_exc()}"}]}

@tool
def get_from_memory(user_id: str, session_id: str) -> dict:
    """Retrieve information from Memory"""
    try:
        client = MemoryClient(region_name=AWS_REGION)
        
        events = client.list_events(
            memory_id=MEMORY_ID,
            actor_id=user_id,
            session_id=session_id,
            max_results=10
        )
        
        if events and isinstance(events, list) and len(events) > 0:
            memories = []
            for event in events:
                payload = event.get('payload', [])
                if payload and len(payload) > 0:
                    first_payload = payload[0]
                    if 'conversational' in first_payload:
                        conv = first_payload['conversational']
                        memories.append({
                            "role": conv.get('role'),
                            "text": conv.get('content', {}).get('text', '')
                        })
            if memories:
                return {"status": "success", "content": [{"text": json.dumps(memories, indent=2)}]}
        return {"status": "success", "content": [{"text": "No memories found"}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}\nTraceback: {traceback.format_exc()}"}]}

@tool
def get_workload_token(user_id: str) -> dict:
    """Get workload identity token"""
    try:
        identity_client = IdentityClient(AWS_REGION)
        token_response = identity_client.get_workload_access_token(
            workload_name=WORKLOAD_IDENTITY_NAME,
            user_id=user_id
        )
        
        return {
            "status": "success",
            "content": [{
                "text": json.dumps({
                    "user_id": user_id,
                    "workload_identity": WORKLOAD_IDENTITY_NAME,
                    "token_obtained": True,
                    "message": f"Workload token obtained for {user_id}"
                })
            }]
        }
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}"}]}

@tool
def get_policy_with_identity(policy_id: str, user_id: str) -> dict:
    """Get policy using workload identity authentication - demonstrates identity capability"""
    try:
        # Get workload token
        identity_client = IdentityClient(AWS_REGION)
        token_response = identity_client.get_workload_access_token(
            workload_name=WORKLOAD_IDENTITY_NAME,
            user_id=user_id
        )
        
        # Use token to call Gateway
        token = token_response.get('workloadAccessToken')
        
        response = httpx.get(
            f"{GATEWAY_URL}/policies/{policy_id}",
            headers={'Authorization': f'Bearer {token}'},
            timeout=30.0
        )
        
        if response.status_code == 200:
            return {
                "status": "success",
                "content": [{
                    "text": f"✓ Authenticated with workload identity for {user_id}\n\nPolicy {policy_id}:\n{response.text}"
                }]
            }
        else:
            return {"status": "error", "content": [{"text": f"Gateway returned {response.status_code}"}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}"}]}

@tool
def get_gateway_policy(policy_id: str) -> dict:
    """Get policy from Gateway using IAM authentication"""
    try:
        import requests
        from botocore.auth import SigV4Auth
        from botocore.awsrequest import AWSRequest
        import boto3
        import json
        
        session = boto3.Session(region_name=AWS_REGION)
        credentials = session.get_credentials()
        
        # Call Gateway MCP endpoint
        payload = json.dumps({
            "jsonrpc": "2.0",
            "method": "tools/call",
            "params": {
                "name": "policy-lookup-target___get_policy",
                "arguments": {"policyId": policy_id}
            },
            "id": 1
        })
        
        headers = {"Content-Type": "application/json"}
        request = AWSRequest(method='POST', url=GATEWAY_URL, data=payload, headers=headers)
        SigV4Auth(credentials, 'bedrock-agentcore', AWS_REGION).add_auth(request)
        
        response = requests.post(GATEWAY_URL, data=payload, headers=dict(request.headers), timeout=30)
        result = response.json()
        
        if 'result' in result and 'content' in result['result']:
            content = result['result']['content'][0]['text']
            return {"status": "success", "content": [{"text": content}]}
        else:
            return {"status": "error", "content": [{"text": f"Error: {result}"}]}
    except Exception as e:
        return {"status": "error", "content": [{"text": f"Error: {str(e)}"}]}

def create_agent():
    """Create agent with all AgentCore capabilities"""
    
    # No need for MCP client - use direct Gateway tool instead
    
    # Create agent
    model = BedrockModel(
        model_id="us.anthropic.claude-sonnet-4-20250514-v1:0",
        region_name=AWS_REGION,
        temperature=0.1,
        guardrail_id=GUARDRAIL_ID,
        guardrail_version=GUARDRAIL_VERSION
    )
    
    system_prompt = """You are a comprehensive assistant with full AgentCore capabilities.

Available tools:
- Gateway: get_gateway_policy(policy_id) - Get policy documents (POL-001, POL-002, POL-003)
- Code Interpreter: execute_python_code(code) - Execute Python code
- Browser: get_weather_data(city) - Get weather forecast from weather.gov
- Memory: save_to_memory(user_id, session_id, content) - Save information
- Memory: get_from_memory(user_id, session_id) - Retrieve saved information
- Identity: get_workload_token(user_id) - Get workload identity token
- Identity Demo: get_policy_with_identity(policy_id, user_id) - Get policy using identity auth

You can:
1. Look up organizational policies via Gateway
2. Get weather forecasts via Browser automation
3. Execute Python code for calculations/analysis
4. Remember user preferences via Memory
5. Manage user identity via Workload Identity

Keep responses clear and actionable."""
    
    # All tools
    all_tools = [get_gateway_policy, execute_python_code, get_weather_data, save_to_memory, get_from_memory, get_workload_token, get_policy_with_identity]
    
    return Agent(
        model=model,
        tools=all_tools,
        system_prompt=system_prompt
    )

@app.async_task
async def async_main(query=None):
    """Async main function"""
    
    agent = create_agent()
    
    query = query or "What is POL-001?"
    
    try:
        os.environ["BYPASS_TOOL_CONSENT"] = "True"
        result = agent(query)
        
        return {
            "status": "completed",
            "result": result.message['content'][0]['text']
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {"status": "error", "error": str(e)}

@app.entrypoint
async def invoke(payload=None):
    try:
        query = payload.get("prompt", "What is POL-001?")
        
        # Execute via async_task
        result = await async_main(query)
        
        return result
    except Exception as e:
        import traceback
        traceback.print_exc()
        return {"status": "error", "error": str(e)}

if __name__ == "__main__":
    app.run()
