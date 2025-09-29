# Launching Persistent Store Instances 

This action is useful to simplify the process of running persistent store instances on GitHub Actions. It is particularly useful when used alongside the contract-tests action.

It is capable of running persistent store instances on Linux, Mac, and Windows.

# Requirements

The action is only useful if there is a test service running on a specific port. That is out
of scope for this action, as the building/running of a test service is specific to each SDK.

# Example

```yml
jobs:
  contract-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      # Here's the actual usage of this action!
      - uses: launchdarkly/gh-actions/actions/persistent-stores@persistent-stores-v1.0.0
        with:
          redis: true
          consul: true
          dynamodb: true

      - uses: launchdarkly/gh-actions/actions/contract-tests@contract-tests-v1.1.0
        with:
          test_service_port: ${{ env.TEST_SERVICE_PORT }}
          enable_persistence_tests: 'true'
          token: ${{ secrets.GITHUB_TOKEN }}
```

# Options

| Name       | Description                                           | Default |
|------------|-------------------------------------------------------|---------|
| `consul`   | Whether or not a consul instance should be started.   | `false` |
| `dynamodb` | Whether or not a dynamodb instance should be started. | `false` |
| `redis`    | Whether or not a redis instance should be started.    | `false` |
