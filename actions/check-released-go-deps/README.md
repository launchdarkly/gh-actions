# Check Released Go Dependencies

Fails when a Go repository's `go.mod` files depend on an unreleased version of a chosen set of
modules. Run it on pull requests to release branches, so that a branch which still pins a
commit of another component cannot merge until that component is released.

By default it enforces every module under `github.com/launchdarkly/`. Third-party modules are
not checked: they legitimately use pseudo-versions and `+incompatible` versions.

# Rules

For each module whose path starts with one of `module_prefixes`, the action reports:

- A pseudo-version, such as `v7.19.2-0.20261019182248-5b041ff834f5`. It names a commit, not a
  release.
- A pre-release version, such as `v7.20.0-rc.1`, including on `// indirect` requirements.
- Any `replace` of the module, single-line or in a `replace ( ... )` block, versioned or not,
  whatever the replacement is.
- A `replace` whose target is the module at a version that is not a final release.

A final release is `vX.Y.Z`, optionally with `+incompatible`. The `module`, `go`, `toolchain`,
`godebug`, `retract`, `exclude`, `tool`, and `ignore` directives are not dependencies, and are
not checked. Comments are ignored.

Each violation is reported as an error annotation on the `go.mod` line, and in the step
summary. The step fails if there is at least one.

The action reads `go.mod` files as text. It needs no Go toolchain, network access, or token,
and runs on Linux and macOS runners.

# Inputs

All inputs are optional. List inputs take one entry per line. Blank lines and `#` comments are
ignored.

| Name              | Required | Default                    | Description                                                                                         |
|-------------------|----------|----------------------------|-----------------------------------------------------------------------------------------------------|
| `module_prefixes` | No       | `github.com/launchdarkly/` | Module path prefixes to enforce. Each is a plain string prefix, so keep the trailing `/` to match an organization. |
| `go_mod_files`    | No       | every tracked `go.mod`     | The `go.mod` files to check, relative to the repository root.                                        |
| `exclude`         | No       |                            | `go.mod` files or directories to skip, such as `testservice/`. `testservice` matches `testservice/go.mod`, but not `testservice2/go.mod`. |
| `allowed`         | No       |                            | Exact `module@version` pins to allow, such as `github.com/launchdarkly/api-client-go/v13@v13.0.1-0.20230420175109-f5469391a13e`. |

The default file list is `git ls-files -- go.mod '*/go.mod'`, so the job must run
`actions/checkout` first.

An `allowed` entry exempts only that exact version of that module. A different version of the
same module still fails. A `replace` of the module still fails, even at the allowed version.
The log prints each exemption that it applies, and warns about an entry that matched nothing,
so stale exemptions are visible. Document the reason for each entry in a comment beside it.

# Outputs

| Name         | Description                                           |
|--------------|-------------------------------------------------------|
| `violations` | The number of unreleased dependency references found. |

# Examples

Run the check on pushes and pull requests to release branches only. Feature branches can pin
unreleased components during development; the check gates the merge into a release branch.

```yaml
name: Check Released Dependencies

on:
  push:
    branches: ['v7']
  pull_request:
    branches: ['v7']

permissions:
  contents: read

jobs:
  check-released-dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: launchdarkly/gh-actions/actions/check-released-go-deps@check-released-go-deps-v0.1.0
        with:
          # testservice/ is unpublished, and replaces the SDK with ../ on purpose.
          exclude: testservice/
```

With an exemption, as in `ld-relay`:

```yaml
      - uses: launchdarkly/gh-actions/actions/check-released-go-deps@check-released-go-deps-v0.1.0
        with:
          exclude: cmd/fdv2-integration/
          allowed: |
            # The REST API client. Only tests behind the integrationtests build tag import it,
            # and no release contains this commit.
            github.com/launchdarkly/api-client-go/v13@v13.0.1-0.20230420175109-f5469391a13e
```

For another organization, or for several:

```yaml
      - uses: launchdarkly/gh-actions/actions/check-released-go-deps@check-released-go-deps-v0.1.0
        with:
          module_prefixes: |
            github.com/launchdarkly/
            example.com/acme/
```

If the check is a required status check, do not add a `paths` filter to the workflow. A
skipped workflow leaves a required check pending.

# Versioning

This action is tracked by release-please and starts at `0.1.0`. While it is below `1.0.0`,
breaking changes bump the minor version, so pin the exact version, as the examples do, rather
than the floating `check-released-go-deps-v0` tag.
