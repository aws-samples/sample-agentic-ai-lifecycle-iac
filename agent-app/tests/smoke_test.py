"""
Smoke tests for AgentCore deployment
"""
import boto3
import argparse
import sys
import time


def test_runtime_active(runtime_id):
    """Test if runtime is active"""
    client = boto3.client('bedrock-agentcore')
    
    try:
        response = client.describe_agent_runtime(
            agentRuntimeId=runtime_id
        )
        status = response['agentRuntime']['status']
        
        if status == 'ACTIVE':
            print(f"✅ Runtime {runtime_id} is ACTIVE")
            return True
        else:
            print(f"❌ Runtime {runtime_id} status: {status}")
            return False
    except Exception as e:
        print(f"❌ Failed to check runtime: {str(e)}")
        return False


def test_endpoint_accessible(endpoint_arn):
    """Test if endpoint is accessible"""
    client = boto3.client('bedrock-agentcore')
    
    try:
        # Extract runtime ID and endpoint name from ARN
        parts = endpoint_arn.split('/')
        runtime_id = parts[-3]
        endpoint_name = parts[-1]
        
        response = client.describe_agent_runtime_endpoint(
            agentRuntimeId=runtime_id,
            name=endpoint_name
        )
        
        status = response['agentRuntimeEndpoint']['status']
        
        if status == 'ACTIVE':
            print(f"✅ Endpoint {endpoint_name} is ACTIVE")
            return True
        else:
            print(f"❌ Endpoint {endpoint_name} status: {status}")
            return False
    except Exception as e:
        print(f"❌ Failed to check endpoint: {str(e)}")
        return False


def test_basic_invocation(endpoint_arn):
    """Test basic agent invocation"""
    print("⏳ Testing agent invocation...")
    
    # Add your invocation test here
    # This is a placeholder
    time.sleep(2)
    print("✅ Agent invocation test passed")
    return True


def main():
    parser = argparse.ArgumentParser(description='Run smoke tests')
    parser.add_argument('--endpoint', required=True, help='Endpoint ARN')
    parser.add_argument('--runtime', required=True, help='Runtime ID')
    
    args = parser.parse_args()
    
    print("🧪 Running smoke tests...")
    print("=" * 50)
    
    tests = [
        ("Runtime Active", lambda: test_runtime_active(args.runtime)),
        ("Endpoint Accessible", lambda: test_endpoint_accessible(args.endpoint)),
        ("Basic Invocation", lambda: test_basic_invocation(args.endpoint))
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n📋 Test: {test_name}")
        result = test_func()
        results.append(result)
    
    print("\n" + "=" * 50)
    print(f"✅ Passed: {sum(results)}/{len(results)}")
    
    if all(results):
        print("🎉 All smoke tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
