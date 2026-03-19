import json
import re
import logging
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Security constants
MAX_POLICY_ID_LENGTH = 20
VALID_POLICY_ID_PATTERN = r'^POL-\d{3}$'
ALLOWED_INPUT_KEYS = ['policyId', 'policy_id', 'policy-id']


class ValidationError(Exception):
    """Custom exception for validation errors"""
    pass


def validate_policy_id(policy_id: Any) -> str:
    """
    Validate policy ID format with comprehensive security checks.
    
    Args:
        policy_id: Input to validate
        
    Returns:
        Validated and normalized policy ID
        
    Raises:
        ValidationError: If validation fails
    """
    # Type validation
    if not isinstance(policy_id, str):
        raise ValidationError(
            f"Policy ID must be a string, got {type(policy_id).__name__}"
        )
    
    # Empty/None check
    if not policy_id or not policy_id.strip():
        raise ValidationError("Policy ID cannot be empty")
    
    # Length validation (prevent DoS)
    if len(policy_id) > MAX_POLICY_ID_LENGTH:
        raise ValidationError(
            f"Policy ID exceeds maximum length of {MAX_POLICY_ID_LENGTH} characters"
        )
    
    # Normalize to uppercase
    normalized_id = policy_id.strip().upper()
    
    # Format validation (whitelist pattern)
    # This regex prevents ALL injection attacks by only allowing POL-XXX format
    if not re.match(VALID_POLICY_ID_PATTERN, normalized_id):
        raise ValidationError(
            f"Invalid policy ID format. Expected format: POL-XXX (e.g., POL-001)"
        )
    
    return normalized_id


def extract_policy_id(event: Dict[str, Any]) -> str:
    """
    Safely extract policy ID from event with validation.
    
    Args:
        event: Lambda event object
        
    Returns:
        Validated policy ID
        
    Raises:
        ValidationError: If extraction or validation fails
    """
    # Check for unexpected event structure
    if not isinstance(event, dict):
        raise ValidationError("Invalid event structure")
    
    # Extract policy ID from allowed keys only
    policy_id = None
    for key in ALLOWED_INPUT_KEYS:
        if key in event:
            policy_id = event[key]
            break
    
    if policy_id is None:
        raise ValidationError(
            f"Missing required parameter. Expected one of: {', '.join(ALLOWED_INPUT_KEYS)}"
        )
    
    # Validate the extracted policy ID
    return validate_policy_id(policy_id)


def create_response(status_code: int, body: Dict[str, Any], request_id: str = None) -> Dict[str, Any]:
    """
    Create standardized response with security headers.
    
    Args:
        status_code: HTTP status code
        body: Response body dictionary
        request_id: Optional request ID for tracking
        
    Returns:
        Lambda response dictionary
    """
    if request_id and status_code >= 500:
        body['request_id'] = request_id
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'X-Content-Type-Options': 'nosniff',
            'X-Frame-Options': 'DENY',
            'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
            'Cache-Control': 'no-store, no-cache, must-revalidate'
        },
        'body': json.dumps(body)
    }


def lambda_handler(event, context):
    """
    Lambda handler with comprehensive input validation and error handling.
    
    Security features:
    - Input validation with regex whitelist
    - Type checking
    - Length limits
    - Structured error handling
    - Security headers
    - Audit logging
    """
    request_id = context.aws_request_id if context else 'unknown'
    
    try:
        # Log incoming request (sanitized)
        logger.info(f"Processing request - RequestID: {request_id}")
        
        # Extract and validate policy ID
        policy_id = extract_policy_id(event)
        logger.info(f"Validated policy ID: {policy_id} - RequestID: {request_id}")
        
        # Mock policy database
        policies = {
            "POL-001": {
                "policy_id": "POL-001",
                "policy_name": "Data Retention Policy",
                "version": "2.1",
                "effective_date": "2024-01-01",
                "owner": "Security Team",
                "description": "Defines data retention requirements for customer data",
                "requirements": [
                    "Customer data must be retained for minimum 7 years",
                    "Backup data must be encrypted at rest",
                    "Data deletion requests must be processed within 30 days"
                ],
                "compliance_frameworks": ["SOC2", "GDPR", "HIPAA"]
            },
            "POL-002": {
                "policy_id": "POL-002",
                "policy_name": "Access Control Policy",
                "version": "1.5",
                "effective_date": "2024-03-15",
                "owner": "IT Security",
                "description": "Defines access control requirements for systems",
                "requirements": [
                    "Multi-factor authentication required for all users",
                    "Access reviews must be conducted quarterly",
                    "Privileged access requires approval"
                ],
                "compliance_frameworks": ["SOC2", "ISO27001"]
            },
            "POL-003": {
                "policy_id": "POL-003",
                "policy_name": "Incident Response Policy",
                "version": "3.0",
                "effective_date": "2024-06-01",
                "owner": "Security Operations",
                "description": "Defines incident response procedures",
                "requirements": [
                    "Security incidents must be reported within 1 hour",
                    "Critical incidents require executive notification",
                    "Post-incident reviews required within 48 hours"
                ],
                "compliance_frameworks": ["SOC2", "PCI-DSS"]
            }
        }
        
        # Retrieve policy
        policy = policies.get(policy_id)
        
        if not policy:
            logger.warning(f"Policy not found: {policy_id} - RequestID: {request_id}")
            return create_response(404, {
                'error': 'Policy not found',
                'policy_id': policy_id,
                'available_policies': list(policies.keys())
            })
        
        # Success response
        logger.info(f"Policy retrieved successfully: {policy_id} - RequestID: {request_id}")
        return create_response(200, policy)
        
    except ValidationError as e:
        # Client error (400) - invalid input
        logger.warning(f"Validation error: {str(e)} - RequestID: {request_id}")
        return create_response(400, {
            'error': 'Invalid input',
            'message': str(e),
            'expected_format': 'POL-XXX (e.g., POL-001, POL-002, POL-003)',
            'allowed_parameters': ALLOWED_INPUT_KEYS
        })
        
    except Exception as e:
        # Server error (500) - unexpected error
        logger.error(f"Unexpected error: {str(e)} - RequestID: {request_id}", exc_info=True)
        return create_response(500, {
            'error': 'Internal server error',
            'message': 'An unexpected error occurred. Please contact support.'
        }, request_id)
