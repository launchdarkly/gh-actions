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
      - uses: launchdarkly/gh-actions/actions/go-eol-versions@go-eol-versions-v0.1.0
        id: go-versions
        with:
          precision: cycle
```

The job needs no `actions/checkout`; the action only makes an HTTP request.

# Versioning

This action is tracked by release-please and starts at `0.1.0`. While it is below `1.0.0`,
breaking changes bump the minor version, so **pin the exact version** as shown above rather
than the floating `go-eol-versions-v0` tag -- a `v0` pin would follow breaking changes. (Some
repositories do pin floating majors, such as `persistent-stores-v0` in `python-server-sdk`;
that is fine for an action whose 0.x line is stable, and a hazard for one whose isn't.)

Repositories outside this one should not reference the action at `@main`. The `renovate/sdk`
preset deliberately exempts `launchdarkly/gh-actions` from digest pinning, so Renovate tracks
these tags by semver and opens bump PRs after a 7-day `minimumReleaseAge` -- a `@main`
reference is invisible to it and silently adopts every change the moment it merges.

The in-repo reference from `sdk-go-versions.yml` is the deliberate exception: it uses `@main`
because release-please cannot maintain a pin there. `GITHUB_TOKEN` cannot write under
`.github/workflows/`, and that is the token release-please runs with in this repository, so a
pin on that line would have to be bumped by hand -- and forgotten, leaving `main`'s workflow
calling an old copy of an action whose current source sits in the same commit, with nothing to
surface the divergence. The same limitation removed `.github/workflows` as a release-please
package in 98896e0; it is tracked upstream as
[release-please-action#938](https://github.com/googleapis/release-please-action/issues/938) and
is still open. Consumers call the reusable workflow itself at `@main`, so its body floats
regardless and Renovate is not watching it; `@main` on the `uses:` line inside it at least
moves the workflow and the action together.
