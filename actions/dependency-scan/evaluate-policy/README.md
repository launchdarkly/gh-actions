<!-- action-docs-description source="action.yml" -->
## Description

Evaluate the OPA license policy against the BOM
<!-- action-docs-description source="action.yml" -->

<!-- action-docs-inputs source="action.yml" -->
## Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `policy-file` | <p>Filename of the license policy.</p> | `false` | `license_policy.rego` |
| `bom-file` | <p>File name for the Bill of Materials file</p> | `false` | `bom.json` |
| `opa-query` | <p>OPA query to use. If anything is returned, the build will fail.</p> | `false` | `data.launchdarkly.violation[x]` |
| `opa-version` | <p>The Open Policy Agent version to use.</p> | `false` | `latest` |
| `cyclonedx-version` | <p>The CycloneDX version to use.</p> | `false` | `latest` |
| `artifacts-pattern` | <p>Download one or more artifacts and merge them, prior to validation.</p> | `false` | `""` |
<!-- action-docs-inputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-runs source="action.yml" -->
## Runs

This action is a `composite` action.
<!-- action-docs-runs source="action.yml" -->
