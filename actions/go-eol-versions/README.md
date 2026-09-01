# Go EOL Versions

Reports the two most recently released Go versions that upstream still supports, per
[endoflife.date](https://endoflife.date/go). Go ships a major release roughly every six
months and supports the two most recent, so these are the versions a repository should be
building and testing against.

Most repositories will not use this action directly -- the
[sdk-go-versions](../../.github/workflows/sdk-go-versions.yml) reusable workflow wraps it
and opens the version-bump pull request. Use the action on its own when the surrounding
pull request logic needs to differ, as it does for `ld-relay`.

# Why this is an action

The endoflife.date response is data from a third party. This action reads it with `jq` and
requires each extracted version to match `^[0-9]+\.[0-9]+(\.[0-9]+)?$` before emitting it,
so callers can safely interpolate the outputs into a `run:` block.

Doing that validation once, here, is the point. The same check previously lived as inline
shell in fourteen Go repositories and was wrong in all fourteen.

# Inputs

| Name        | Required | Default                              | Description                                                                            |
|-------------|----------|--------------------------------------|----------------------------------------------------------------------------------------|
| `precision` | No       | `cycle`                              | `cycle` for the major.minor version (`1.27`); `latest` for the patch version (`1.27.0`) |
| `api_url`   | No       | `https://endoflife.date/api/go.json` | The endpoint to query. Override only for testing.                                       |

Pick `precision` to match what the repository pins. Repositories that track a Go minor
series want `cycle`; those that pin an exact toolchain, such as anything building a
container image, want `latest`.

# Outputs

| Name          | Description                              |
|---------------|------------------------------------------|
| `latest`      | The most recent supported Go version.    |
| `penultimate` | The second most recent supported version.|

# Example

```yaml
jobs:
  check-go-eol:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      latest: ${{ steps.go-versions.outputs.latest }}
      penultimate: ${{ steps.go-versions.outputs.penultimate }}
    steps:
      - uses: launchdarkly/gh-actions/actions/go-eol-versions@go-eol-versions-v1
        id: go-versions
        with:
          precision: cycle
```

The job needs no `actions/checkout`; the action only makes an HTTP request.

This action is tracked by release-please, so `go-eol-versions-v1` is a floating major tag
that follows each release. Pin the exact version instead -- `go-eol-versions-v1.0.0` -- if
you need the reference to be immutable. Neither tag exists until the first release lands.
