# Rust EOL Versions

Reports a recent Rust release cycle from [endoflife.date](https://endoflife.date/rust), for
use as a minimum supported Rust version (MSRV). Rust ships a release every six weeks. The
LaunchDarkly Rust repositories set their MSRV to the third newest release, which is the
default.

Most repositories will not use this action directly -- the
[sdk-rust-versions](../../.github/workflows/sdk-rust-versions.yml) reusable workflow wraps it
and opens the MSRV bump pull request.

# Why this is an action

The endoflife.date response is data from a third party. This action reads it with `jq` and
requires the extracted cycle to match `^[0-9]+\.[0-9]+$` before emitting it, so callers can
safely use the output in a `run:` block.

The Rust repositories previously pasted the raw `cycle` field into `run:` scripts with
`${{ }}`, in a job that had `contents: write`. A change to the feed could run commands with
that job's token.

# Inputs

| Name      | Required | Default                                | Description                                                       |
|-----------|----------|----------------------------------------|-------------------------------------------------------------------|
| `offset`  | No       | `2`                                    | How many releases back from the newest to report. `0` is the newest. |
| `api_url` | No       | `https://endoflife.date/api/rust.json` | The endpoint to query. Override only for testing.                 |

# Outputs

| Name     | Description                                              |
|----------|----------------------------------------------------------|
| `target` | The Rust release cycle at the requested offset, e.g. `1.98`. |

# Example

```yaml
jobs:
  check-rust-eol:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      target: ${{ steps.rust-versions.outputs.target }}
    steps:
      - uses: launchdarkly/gh-actions/actions/rust-eol-versions@rust-eol-versions-v0.1.0
        id: rust-versions
```

The job needs no `actions/checkout`; the action only makes an HTTP request.

# Reusable workflow

```yaml
name: Check Supported Rust Versions
on:
  schedule:
    - cron: "0 17 * * *"
  workflow_dispatch:

permissions: {}

jobs:
  check-rust-versions:
    permissions:
      contents: write
      pull-requests: write
    uses: launchdarkly/gh-actions/.github/workflows/sdk-rust-versions.yml@main
    with:
      cargo_tomls: |
        launchdarkly-server-sdk/Cargo.toml
        contract-tests/Cargo.toml
```

The workflow reads `target=` from `.github/variables/rust-versions.env`. When the target
release changes, it rewrites that line and the `rust-version` field in each listed
`Cargo.toml`, and opens a pull request titled `fix: Bump MSRV from <old> to <new>`. Set
`pr_title_prefix: chore` in a repository that does not release, such as a hello app.

# Versioning

This action is tracked by release-please and starts at `0.1.0`. While it is below `1.0.0`,
breaking changes bump the minor version, so pin the exact version rather than the floating
`rust-eol-versions-v0` tag. The in-repo reference from `sdk-rust-versions.yml` uses `@main`,
for the reason given in the [go-eol-versions README](../go-eol-versions/README.md#versioning).
