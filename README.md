# LaunchDarkly repository for shared GitHub Actions and Workflows.

This repository contains LaunchDarkly shared GitHub Actions and Workflows for other LaunchDarkly Repos to use.


## Actions
| Name                                                          | Description                                   |
|---------------------------------------------------------------|-----------------------------------------------|
| [contract-tests](./actions/contract-tests/README.md)          | Run SDK/SSE contract tests.                   |
| [persistent-stores](./actions/persistent-stores/README.md)    | Start persistent stores on linux/mac/windows. |
| [publish-pages](./actions/publish-pages/README.md)            | Publishes documentation to Github Pages.      |
| [release-secrets](./actions/release-secrets/README.md)        | Retrieve secrets from AWS Secrets Manager.    |
| [sign-dlls](./actions/sign-dlls/README.md)                    | Sign dotnet DLL (assembly) files.             |
| [verify-hello-apps](./actions/verify-hello-app/README.md)     | Run shared quality-checks for hello-apps.     |

## Workflows
| Name                                                   | Description                                                            |
|--------------------------------------------------------|------------------------------------------------------------------------|
| [sdk-stale](./.github/workflows/sdk-stale.yml)         | Warns about stale issues, and then closes when required.               |
| [lint-pr-title](./.github/workflows/lint-pr-title.yml) | Ensures PR titles follow [Conventional Commits][conventional-commits]. |

### Workflow Versioning

Reusable workflows must live in `.github/workflows/`, but release-please [cannot write changelogs there][rp-issue].
To work around this, each workflow has a tracking directory under `workflows/` (e.g. `workflows/lint-pr-title/`)
that release-please uses for version management. Tags are created with the workflow name as the component
(e.g. `lint-pr-title-v1.0.0`).

When making changes to a reusable workflow, also touch a file in the corresponding `workflows/<name>/` directory
so that release-please detects the change and creates a release PR.

[conventional-commits]: https://www.conventionalcommits.org/en/v1.0.0/
[rp-issue]: https://github.com/googleapis/release-please-action/issues/938
