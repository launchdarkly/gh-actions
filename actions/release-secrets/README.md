# Release Secrets

This action can be used to access release secrets from SSM.

It can also be used to download files from s3.

# Requirements

The repository must be configured with OIDC, allowing access to an AWS account.

The SSM step runs a bundled Node script, so the runner must have `node` on its
`PATH` (GitHub-hosted runners do; self-hosted runners need Node installed).

`ssm_parameter_pairs` paths must be plain SSM parameter names. Version or label
selectors (`/path:2`, `/path:label`) are not supported — the value is looked up
by its bare name and a selector will fail the lookup.

# Example

This example uses the release-secrets action to get an NPM token.
```
- uses: launchdarkly/gh-actions/actions/release-secrets
  name: 'Get NPM token'
  with:
    aws_assume_role: ${{ vars.AWS_ROLE_ARN }}
    ssm_parameter_pairs: '/my/ssm/path/node_token = NODE_AUTH_TOKEN'
```

This example uses the release-secrets action to get a strong-naming key.
```
- uses: launchdarkly/gh-actions/actions/release-secrets
  name: 'Get Strong Naming Key'
  with:
    aws_assume_role: ${{ vars.AWS_ROLE_ARN }}
    s3_path_pairs: 'some/s3/path = local-path/file'
```