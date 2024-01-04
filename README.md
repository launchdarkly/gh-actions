# LaunchDarkly repository for shared GitHub Actions and Workflows.

This repository contains LaunchDarkly shared GitHub Actions and Workflows for other LaunchDarkly Repos to use.


## Actions
| Name                                                   | Description                                |
|--------------------------------------------------------|--------------------------------------------|
| [publish-pages](./actions/publish-pages/README.md)     | Publishes documentation to Github Pages.   |
| [release-secrets](./actions/release-secrets/README.md) | Retrieve secrets from AWS Secrets Manager. |


## Workflows
| Name                                                   | Description                                                            |
|--------------------------------------------------------|------------------------------------------------------------------------|
| [sdk-stale](./.github/workflows/sdk-stale.yml)         | Warns about stale issues, and then closes when required.               |
| [lint-pr-title](./.github/workflows/lint-pr-title.yml) | Ensures PR titles follow [Conventional Commits][conventional-commits]. |


[conventional-commits]: https://www.conventionalcommits.org/en/v1.0.0/
