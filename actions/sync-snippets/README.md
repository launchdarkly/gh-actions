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
  id-token: write              # required for cosign keyless verification

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: launchdarkly/gh-actions/actions/sync-snippets@main
        with:
          entrypoints: |
            static/ld/components/getStarted
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## What it does

1. Resolves the latest `snippets/vX.Y.Z` GitHub Release on `launchdarkly/sdk-meta` (override with `version:` if you need to pin or roll back).
2. Downloads the platform-specific binary archive plus the cosign signature and certificate.
3. Verifies the signature is keyless-signed by `launchdarkly/sdk-meta`'s `release-please` workflow on `main` via GitHub OIDC.
4. Runs `snippets render --target=<adapter> --entrypoint=<dir>...` with one `--entrypoint` flag per non-empty line of the `entrypoints:` input. The binary embeds the canonical `sdks/` tree at build time — no separate snippet fetch. The renderer walks each entrypoint recursively, picks up files with extensions it understands (`.tsx`/`.jsx`/`.ts`/`.js`/`.mdx`) that contain the `SDK_SNIPPET:RENDER:` sentinel, and skips junk dirs (`node_modules`, `.git`, `dist`, `build`, ...).
5. Opens (or updates) a pull request with the rewritten files. If `render` produced no diff, the action exits 0 without opening a PR.

## Inputs

| Name | Default | Description |
|---|---|---|
| `entrypoints` | (required) | Newline-separated list of consumer-checkout directories the renderer should walk for snippet markers. Paths resolve against `$GITHUB_WORKSPACE`. |
| `version` | `latest` | Release tag to install (e.g. `snippets/v0.3.0`). `latest` resolves to the most recent published `snippets/*` release. |
| `target` | `ld-application` | Adapter target. `ld-application` for gonfalon. Future targets (e.g. `ld-docs`) plug in here. |
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

- **Signing identity is pinned to a specific workflow path.** `cosign verify-blob` checks `--certificate-identity-regexp` against `https://github.com/launchdarkly/sdk-meta/.github/workflows/release-please.yml@.+`. A token leaked from any other workflow in any other repo cannot produce a matching OIDC claim.
- **No long-lived signing keys.** Each release signs itself using GitHub's OIDC token, so there is nothing to rotate, store, or accidentally check in.
- **Snippet sources travel with the binary.** The CLI's `--sdks=` flag is optional; when omitted (the default for this action) it reads from `embed.FS`. Pinning a release version pins both the engine and the snippet content atomically.
