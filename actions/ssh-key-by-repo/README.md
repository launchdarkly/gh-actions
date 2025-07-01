<!-- action-docs-description source="action.yml" -->
## Description

Configure SSH keys for accessing different repositories.
<!-- action-docs-description source="action.yml" -->

<!-- action-docs-inputs source="action.yml" -->
## Inputs

| name | description | required | default |
| --- | --- | --- | --- |
| `repo_keys_map` | <p>A map of repo names to the SSH key to use for that repo.</p> | `true` | `""` |
| `include_git_ssh_command` | <p>Whether to export the GIT<em>SSH</em>COMMAND variable.</p> | `true` | `true` |
| `include_git_instead_of` | <p>Whether to configure git's insteadOf options.</p> | `true` | `true` |
<!-- action-docs-inputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-outputs source="action.yml" -->

<!-- action-docs-runs source="action.yml" -->
## Runs

This action is a `composite` action.
<!-- action-docs-runs source="action.yml" -->
