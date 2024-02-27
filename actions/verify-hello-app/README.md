# Verify hello app

This action is designed for [LaunchDarkly hello applications](https://github.com/launchdarkly?q=topic%3Alaunchdarkly-demo&type=all&language=&sort=name).

In contrast to the [SDK test harness](https://github.com/launchdarkly/sdk-test-harness), the hello applications are designed to validate package management. These simple applications help ensure each SDK can be installed, configured, and executed to produce a reliable output.

# Requirements

The repository must be configured with OIDC, allowing access to an AWS account. This action will make use of the launchdarkly/gh-actions/actions/release-secrets action to obtain the appropriate SDK key(s).

# Example

This example verifies a PHP-based CLI script.
```
- uses: launchdarkly/gh-actions/actions/verify-hello-app
  name: 'Verify PHP hello-app'
  with:
    use_server_key: true
    role_arn: ${{ vars.AWS_ROLE_ARN }}
    command: php -f main.php
```
