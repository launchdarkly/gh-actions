# Sign DLLs

Use this action for signing DLLs. 

When building dotnet assemblies, each targeted framework will have a different assembly. This action will iterate a build configuration, for instance "Release", and sign DLLs for each target framework.

```bash
./src/LaunchDarkly.Thing/bin/Release/net462/LaunchDarkly.Things.dll
./src/LaunchDarkly.Thing/bin/Release/netstandard2.0/LaunchDarkly.Things.dll
```

In the above example, the `build_configuration_path`` would be "./src/LaunchDarkly.Thing/bin/Release".
The `dll_name` would be "LaunchDarkly.Things.dll".

# Requirements

The repository must be configured with OIDC, allowing access to an AWS account.

# Example

This example uses the sign-dlls action to sign the dotnet client DLLs.
```
- uses: launchdarkly/gh-actions/actions/release-secrets@release-secrets-v1.2.0
  name: Get secrets
  with:
    aws_assume_role: ${{ vars.AWS_ROLE_ARN }}
    ssm_parameter_pairs: '/production/common/releasing/digicert/host = DIGICERT_HOST,/production/common/releasing/digicert/api_key = DIGICERT_API_KEY,/production/common/releasing/digicert/client_cert_file_b64 = DIGICERT_CLIENT_CERT_FILE_B64,/production/common/releasing/digicert/client_cert_password = DIGICERT_CLIENT_CERT_PASSWORD,/production/common/releasing/digicert/code_signing_cert_sha1_hash = DIGICERT_CODE_SIGNING_CERT_SHA1_HASH'

- uses: launchdarkly/gh-actions/actions/sign-dlls@sign-dlls-v1.0.0
  name: 'Sign DLLs'
  with:
    build_configuration_path: './src/LaunchDarkly.ClientSdk/bin/Release'
    dll_name: 'LaunchDarkly.ClientSdk.dll'
```
