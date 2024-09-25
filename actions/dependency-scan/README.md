# dependency-scan

This set of actions is used for license validation to prevent GPL licenses from being shipped in our product.

There are four sub-actions in this action.

## [generate-sbom](./generate-sbom)

This action generates a Software Bill of Materials (SBOM) for a project. It is uploaded as an artifact to the
GitHub Action workspace.

## [evaluate-policy](./evaluate-policy)

This action evaluates the SBOM against the policy file. A summary is posted to GitHub Actions.

# Example workflows

## Serial generation of BOMs

```yaml
name: Workflow
on: pull_request

jobs:
  dependency-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version-file: go.mod
      - name: Generate SBOM
        uses: launchdarkly/gh-actions/actions/dependency-scan/generate-sbom@main
        with:
          types: 'go,nodejs'
      - name: Evaluate SBOM Policy
        uses: launchdarkly/gh-actions/actions/dependency-scan/evaluate-policy@main
```
