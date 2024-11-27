# Contract Tests

This action is used to run contract tests against a LaunchDarkly SDK component. It is capable
of running either the SDK or SSE contract tests.

# Requirements

The action is only useful if there is a test service running on a specific port. That is out
of scope for this action, as the building/running of a test service is specific to each SDK.

# Example

```yml
jobs:
  contract-tests:
    runs-on: ubuntu-22.04
    env:
      # Port the test service (implemented in the SDK repo) should bind to.
      TEST_SERVICE_PORT: 8123
      # Path to the test service binary. 
      TEST_SERVICE_BINARY: ./some-sdk-build-folder/client-tests
    steps:
      - uses: actions/checkout@v3
      - name: Build the test service
        run: make build-the-test-service-however-you-want
      - name: Launch the test service in the background
        run: $TEST_SERVICE_BINARY $TEST_SERVICE_PORT 2>&1 &
        
        # Here's the actual usage of this action!
      - uses: launchdarkly/gh-actions/actions/contract-tests@contract-tests-v1.1.0
        with:
          # Inform the test harness of test service's port.
          test_service_port: ${{ env.TEST_SERVICE_PORT }}
          token: ${{ secrets.GITHUB_TOKEN }}
```

# Options

| Name                       | Description                                                | Default                            |
|----------------------------|------------------------------------------------------------|------------------------------------|
| `repo`                     | Which tests to run (git repo)                              | `sdk-test-harness` (see below [1]) |
| `version`                  | Version of the tests. This is the tag.                     | `v2`                               |
| `branch`                   | The downloader script is fetched from this branch.         | `v2`                               |
| `test_service_port`        | Port the test service (your SDK) is running on.            | `8123`                             |
| `test_harness_port`        | Port the test harness is running on.                       | `8111`                             |
| `enable_persistence_tests` | Enables persistent store test support.                     | `false`                            |
| `debug_logging`            | Whether the test harness should emit debug logs            | `false`                            |
| `extra_params`             | Any other params that should be passed to the test harness | None.                              |
| `token`                    | Github token, if available. Helps avoid ratelimiting.      | None.                              |

[1] For Server-Sent-Event tests, use [`sse-contract-tests`](https://github.com/launchdarkly/sse-contract-tests).
