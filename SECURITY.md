# Security

## Reporting Security Issues

Please do **not** open a public GitHub issue for security vulnerabilities. Instead, report them via email to the maintainers listed in the README.

---

## Security Considerations

### IAM Least Privilege

All IAM policies in this project are scoped to the minimum required permissions:

- **Secrets Manager**: Access is restricted to specific secret paths (`agentcore/config-*`, `agentcore/db-credentials-*`, `agentcore/api-keys-*`) rather than a broad wildcard.
- **KMS**: Key usage is limited to `kms:Decrypt`, `kms:GenerateDataKey`, and `kms:DescribeKey` on the specific AgentCore KMS key.
- **ECR**: Image pull permissions are scoped to `agentcore-*` repositories. See note below on `ecr:GetAuthorizationToken`.
- **AgentCore Runtime**: Permissions follow least privilege with resource-level scoping where supported.

### AWS Service Requirements

#### ECR Authentication (`ecr:GetAuthorizationToken`)

The `ecr:GetAuthorizationToken` action **requires `Resource: "*"`** by AWS design. This is not a misconfiguration — it is a documented AWS requirement because the authorization token is not tied to a specific repository. See [AWS ECR IAM documentation](https://docs.aws.amazon.com/AmazonECR/latest/userguide/security_iam_id-based-policy-examples.html) for details.

This finding is suppressed with a `# nosemgrep` comment and accepted as security debt for this demo/blog context.

---

## Accepted Security Debt (Demo/Blog Context)

The following items are acceptable for a blog/demo but should be addressed before production use:

| Item | Reason | Production Recommendation |
|------|--------|--------------------------|
| `ecr:GetAuthorizationToken` with `Resource: "*"` | AWS service requirement | No change needed — this is correct |
| Security group with unrestricted egress | Simplifies demo setup | Use VPC endpoints and restrict egress per service |
| No Secrets Manager rotation | Adds complexity/cost for demo | Implement Lambda-based rotation on a 30-day schedule |

---

## Encryption

- All sensitive data is encrypted at rest using AWS KMS with customer-managed keys.
- KMS key rotation is enabled.
- Key policies use principal and condition-based access control.

---

## CI/CD Security

- GitHub Actions uses OIDC federation — no long-lived AWS credentials stored in GitHub.
- Secrets are stored in GitHub Secrets, never hardcoded.
- All workflow inputs are passed via environment variables to prevent shell injection.

---

## Dependency Security

- Python dependencies are pinned in `agent-app/requirements.txt`.
- Container images are built from a pinned base image.
- Run `pip audit` or `safety check` regularly to catch vulnerable dependencies.

---

## Scanner Suppressions

This project uses the following scanner suppressions, each with documented justification:

- **Checkov** (8 suppressions): Lambda VPC, code signing, log retention — see inline `checkov:skip` comments in Terraform files for per-resource justifications.
- **Semgrep** (1 suppression): `ecr:GetAuthorizationToken` — AWS service requirement, cannot be scoped.
- **Detect-Secrets** (4 suppressions in `.secrets.baseline`): All are false positives — the word "secret" appearing in documentation, variable names, and the baseline file itself.
