import * as core from '@actions/core'
import { run } from './index'

// Bundle entrypoint: ncc builds this file to dist/index.js, which the
// release-secrets composite action runs via `node dist/index.js`. It is invoked
// only as a standalone process, so it runs unconditionally — the library lives
// in ./index, which the tests import without triggering execution.
//
// Do NOT gate this on `require.main === module`: ncc bundles the ESM entry with
// a webpack module wrapper for which that identity check is always false, so the
// guard would silently no-op the entire action.
run(process.env.SSM_PARAMETER_PAIRS ?? '').catch((err) => {
  core.setFailed(err instanceof Error ? err.message : String(err))
})
