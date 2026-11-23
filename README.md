# LaunchDarkly repository for shared GitHub Actions and Workflows.

These GitHub Actions and Workflows are for LaunchDarkly repositories only. They are not supported for use outside LaunchDarkly.

## Usage
Pin each action to its own tag:

```yaml
- uses: launchdarkly/gh-actions/actions/release-secrets@release-secrets/v1
```

## Actions
| Name                                                                 | Description                                   |
|----------------------------------------------------------------------|-----------------------------------------------|
| [check-released-go-deps](./actions/check-released-go-deps/README.md) | Fail on unreleased Go module dependencies.    |
| [contract-tests](./actions/contract-tests/README.md)                 | Run SDK/SSE contract tests.                   |
| [dependency-scan](./actions/dependency-scan/README.md)               | Generate SBOM and evaluate license policy.    |
| [go-eol-versions](./actions/go-eol-versions/README.md)               | Report upstream-supported Go versions.        |
| [persistent-stores](./actions/persistent-stores/README.md)           | Start persistent stores on linux/mac/windows. |
| [publish-pages](./actions/publish-pages/README.md)                   | Publishes documentation to Github Pages.      |
| [release-secrets](./actions/release-secrets/README.md)               | Retrieve secrets from AWS Secrets Manager.    |
| [rust-eol-versions](./actions/rust-eol-versions/README.md)           | Report a Rust release to use as an MSRV.      |
| [sign-dlls](./actions/sign-dlls/README.md)                           | Sign dotnet DLL (assembly) files.             |
| [verify-hello-apps](./actions/verify-hello-app/README.md)            | Run shared quality-checks for hello-apps.     |

## Workflows
| Name                                                                   | Description                                                            |
|------------------------------------------------------------------------|------------------------------------------------------------------------|
| [dependency-scan](./.github/workflows/dependency-scan.yml)             | Generates SBOM and evaluates license policy.                           |
| [sdk-go-version-matrix](./.github/workflows/sdk-go-version-matrix.yml) | Exposes a repository's supported Go versions as a CI test matrix.      |
| [sdk-go-versions](./.github/workflows/sdk-go-versions.yml)             | Opens PRs bumping supported Go versions after an upstream release.     |
| [sdk-rust-versions](./.github/workflows/sdk-rust-versions.yml)         | Opens PRs bumping the Rust MSRV after an upstream release.             |
| [sdk-stale](./.github/workflows/sdk-stale.yml)                         | Warns about stale issues, and then closes when required.               |
| [lint-pr-title](./.github/workflows/lint-pr-title.yml)                 | Ensures PR titles follow [Conventional Commits][conventional-commits]. |


[conventional-commits]: https://www.conventionalcommits.org/en/v1.0.0/
