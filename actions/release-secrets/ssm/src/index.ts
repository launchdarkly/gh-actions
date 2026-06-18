import * as core from '@actions/core'
import { SSMClient, GetParametersCommand } from '@aws-sdk/client-ssm'

interface Pair {
  ssmPath: string
  envName: string
}

// AWS SSM GetParameters accepts at most 10 names per call.
const CHUNK_SIZE = 10

// Region is configured by the upstream `configure-aws-credentials` step (via
// AWS_REGION/AWS_DEFAULT_REGION); the action pins it to us-east-1, so we fall
// back to that if the env var is somehow absent.
const REGION = process.env.AWS_REGION ?? process.env.AWS_DEFAULT_REGION ?? 'us-east-1'

/**
 * Parse the `ssm_parameter_pairs` input, of the form
 *   "/ssm/path = ENV_NAME, /ssm/path2 = ENV_NAME2"
 * into ordered { ssmPath, envName } pairs. Duplicate paths are allowed (the
 * same secret can be exported under more than one env var). Throws on a
 * malformed entry rather than silently skipping it.
 */
export function parsePairs(input: string): Pair[] {
  const pairs: Pair[] = []
  for (const raw of input.split(',')) {
    const entry = raw.trim()
    if (entry === '') continue
    const eq = entry.indexOf('=')
    const ssmPath = eq === -1 ? '' : entry.slice(0, eq).trim()
    const envName = eq === -1 ? '' : entry.slice(eq + 1).trim()
    if (ssmPath === '' || envName === '') {
      throw new Error(
        `Malformed ssm_parameter_pairs entry: '${entry}' (expected '/ssm/path = ENV_NAME')`,
      )
    }
    pairs.push({ ssmPath, envName })
  }
  return pairs
}

export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = []
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size))
  }
  return out
}

export function run(input: string, client: SSMClient = new SSMClient({ region: REGION })): Promise<void> {
  return runImpl(input, client)
}

async function runImpl(input: string, client: SSMClient): Promise<void> {
  const pairs = parsePairs(input)
  if (pairs.length === 0) {
    core.info('No SSM parameter pairs to process.')
    return
  }

  // Fetch every requested parameter (chunked to the 10-name API limit) and build
  // a path -> value map. setSecret is called the moment a value is read, before
  // it is stored or used anywhere else, so it is registered for masking as early
  // as possible. The response contains decrypted secrets and is never logged.
  const values = new Map<string, string>()
  const uniquePaths = [...new Set(pairs.map((p) => p.ssmPath))]
  for (const names of chunk(uniquePaths, CHUNK_SIZE)) {
    const res = await client.send(
      new GetParametersCommand({ Names: names, WithDecryption: true }),
    )
    for (const param of res.Parameters ?? []) {
      if (param.Name === undefined || param.Value === undefined) continue
      // setSecret masks multiline secrets correctly: it emits one `::add-mask::`
      // command and the runner masks both the whole value and each line — see
      // https://github.com/actions/runner/blob/main/src/Runner.Worker/ActionCommandManager.cs
      // (AddMaskCommandExtension splits the value on \r\n and masks each line).
      core.setSecret(param.Value)
      values.set(param.Name, param.Value)
    }
  }

  // Validate that every requested path resolved BEFORE exporting anything, so a
  // missing parameter (it lands in InvalidParameters and the API still succeeds)
  // never leaves a partially-populated environment for downstream steps.
  for (const { ssmPath, envName } of pairs) {
    if (!values.has(ssmPath)) {
      throw new Error(
        `SSM parameter '${ssmPath}' (-> ${envName}) was not returned by AWS ` +
          `(missing parameter or insufficient permissions).`,
      )
    }
  }

  for (const { ssmPath, envName } of pairs) {
    // exportVariable handles masking-safe, multiline-safe writes to GITHUB_ENV.
    core.exportVariable(envName, values.get(ssmPath) as string)
    core.info(`Env variable ${envName} set with value from ssm parameterName ${ssmPath}`)
  }
}

if (require.main === module) {
  run(process.env.SSM_PARAMETER_PAIRS ?? '').catch((err) => {
    core.setFailed(err instanceof Error ? err.message : String(err))
  })
}
