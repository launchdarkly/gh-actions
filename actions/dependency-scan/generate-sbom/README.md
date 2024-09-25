<!-- action-docs-description source="action.yml" -->
## Description

Generate a Software Bill of Materials (SBOM)
<!-- action-docs-description source="action.yml" -->

<!-- action-docs-inputs source="action.yml" -->
## Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `types` | <p>Comma separated project types. Please refer to https://cyclonedx.github.io/cdxgen/#/PROJECT_TYPES for supported languages/platforms.</p> | `true` | `""` |
| `cdxgen-version` | <p>Version of cdxgen to use</p> | `false` | `10.9.2` |
| `project-directory` | <p>Relative path (from root of repo) to the root of the golang project / module</p> | `false` | `.` |
| `fetch-license` | <p>Fetch license information for dependencies</p> | `false` | `true` |
| `recurse` | <p>Recurse mode suitable for mono-repos.</p> | `false` | `true` |
<!-- action-docs-inputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-runs source="action.yml" -->
## Runs

This action is a `composite` action.
<!-- action-docs-runs source="action.yml" -->
