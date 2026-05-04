# sync-snippets

A composite action that pulls the canonical SDK code snippets from the latest
[`launchdarkly/sdk-meta`](https://github.com/launchdarkly/sdk-meta) release and
opens a sync PR against the calling repository. Used by gonfalon (and future
consumers like `ld-docs-private`) to stay current with snippet changes without
hand-editing.

## Usage

```yaml
name: Sync SDK snippets
on:
  schedule:
    - cron: '0 12 * * *'      # daily at 12:00 UTC
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

jobs:
  sync-tsx:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: launchdarkly/gh-actions/actions/sync-snippets@main
        with:
          target: ld-application
          entrypoints: |
            static/ld/components/getStarted
          github-token: ${{ secrets.GITHUB_TOKEN }}

  sync-raw:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: launchdarkly/gh-actions/actions/sync-snippets@main
        with:
          target: raw-files
          manifest: packages/sdk-info/extract.yaml
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## What it does

1. Resolves the latest `snippets/vX.Y.Z` GitHub Release on `launchdarkly/sdk-meta` (override with `version:` if you need to pin or roll back).
2. Downloads the platform-specific binary archive from the release.
3. Verifies the SLSA build-provenance attestation issued by `launchdarkly/sdk-meta`'s `release-please` workflow via `gh attestation verify`.
4. Runs `snippets render` against the consumer checkout. Two modes:
   - **Marker-driven** (`target=ld-application` or `target=ld-docs`) — passes one `--entrypoint=<dir>` flag per non-empty line of `entrypoints:`. The renderer walks each directory recursively, picks up files with extensions it understands (`.tsx`/`.jsx`/`.ts`/`.js`/`.mdx`) that contain the `SDK_SNIPPET:RENDER:` sentinel, and rewrites the marked region.
   - **Manifest-driven** (`target=raw-files`) — passes `--manifest=<path>` pointing at a YAML the consumer commits. Each `{id, path}` entry extracts a snippet body and writes it to `<manifest.out>/<path>`. Used by consumers that import snippet text via Vite `?raw` (e.g. gonfalon's `packages/sdk-info/`).
5. Opens (or updates) a pull request with the rewritten files. If `render` produced no diff, the action exits 0 without opening a PR.

## Inputs

| Name | Default | Description |
|---|---|---|
| `target` | `ld-application` | Adapter target: `ld-application` (gonfalon TSX markers), `ld-docs` (ld-docs-private MDX markers), or `raw-files` (manifest-driven flat-file output). |
| `entrypoints` | `''` | (Required for `target=ld-application` and `target=ld-docs`.) Newline-separated list of consumer-checkout directories the renderer should walk for snippet markers. Paths resolve against `$GITHUB_WORKSPACE`. Ignored for `target=raw-files`. |
| `manifest` | `''` | (Required for `target=raw-files`.) Path to a raw-files manifest YAML, relative to `$GITHUB_WORKSPACE`. Ignored for marker-driven targets. |
| `version` | `latest` | Release tag to install (e.g. `snippets/v0.3.0`). `latest` resolves to the most recent published `snippets/*` release. |
| `branch` | `chore/sync-sdk-snippets` | Branch the action commits the rendered diff to. |
| `pr-title` | `chore: sync SDK snippets` | Pull-request title. |
| `pr-body` | (auto-generated) | Pull-request body. Defaults to a one-liner pointing at the upstream release notes. |
| `pr-labels` | `sdk-snippets,automated-pr` | Comma-separated labels applied to the sync PR. |
| `github-token` | (required) | Token used to download release assets and open the PR. The repo's default `GITHUB_TOKEN` is sufficient when the workflow has `contents: write` and `pull-requests: write`. |

## Outputs

| Name | Description |
|---|---|
| `version` | The release tag that was installed. |
| `changes` | `true` if `render` produced any diff. |
| `pr-number` | Pull-request number when one was opened or updated; empty otherwise. |

## How the supply chain is locked down

- **Signing identity is pinned to a specific workflow path.** `gh attestation verify --signer-workflow launchdarkly/sdk-meta/.github/workflows/release-please.yml` checks the SLSA build-provenance subject against that exact workflow file. A token leaked from any other workflow in any other repo cannot produce a matching OIDC claim.
- **No long-lived signing keys.** Each release attests itself using GitHub's OIDC token, so there is nothing to rotate, store, or accidentally check in. The attestation is published to `launchdarkly/sdk-meta`'s repo-level attestation store, not as a release asset.
- **Snippet sources travel with the binary.** The CLI's `--sdks=` flag is optional; when omitted (the default for this action) it reads from `embed.FS`. Pinning a release version pins both the engine and the snippet content atomically.
