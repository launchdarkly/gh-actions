# Release Secrets

This action can be used for getting release secrets from SSM.

# Requirements

The repository must be configured with OIDC allowing access to an AWS account.

# Example

This example uses the release-secrets action to get an NPM token.
```
- uses: launchdarkly/gh-actions/actions/release-secrets
  name: 'Get NPM token'
  with:
    aws_assume_role: ${{ vars.AWS_ROLE_ARN }}
    ssm_parameter_pairs: '/my/ssm/path/node_token = NODE_AUTH_TOKEN'
```
