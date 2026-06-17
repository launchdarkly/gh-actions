import { describe, it, expect, vi, beforeEach } from 'vitest'
import * as core from '@actions/core'
import { SSMClient, GetParametersCommand } from '@aws-sdk/client-ssm'
import { mockClient } from 'aws-sdk-client-mock'
import { parsePairs, chunk, run } from './index'

vi.mock('@actions/core', () => ({
  info: vi.fn(),
  setSecret: vi.fn(),
  exportVariable: vi.fn(),
  setFailed: vi.fn(),
}))

const setSecret = vi.mocked(core.setSecret)
const exportVariable = vi.mocked(core.exportVariable)
const ssmMock = mockClient(SSMClient)

// Resolve GetParametersCommand against a path -> value fixture: present names go
// to Parameters, absent ones to InvalidParameters (mirroring the real API, which
// succeeds either way), and reject any call with >10 names like the real limit.
function withFixture(fixture: Record<string, string>) {
  ssmMock.on(GetParametersCommand).callsFake((input: { Names: string[] }) => {
    if (input.Names.length > 10) {
      throw new Error('ValidationException: Member must have length <= 10')
    }
    return {
      Parameters: input.Names.filter((n) => n in fixture).map((n) => ({ Name: n, Value: fixture[n] })),
      InvalidParameters: input.Names.filter((n) => !(n in fixture)),
    }
  })
}

beforeEach(() => {
  vi.clearAllMocks()
  ssmMock.reset()
})

describe('parsePairs', () => {
  it('parses and trims a single pair', () => {
    expect(parsePairs('  /app/db  =  DB_PASS ')).toEqual([{ ssmPath: '/app/db', envName: 'DB_PASS' }])
  })
  it('parses multiple pairs and preserves order/duplicates', () => {
    expect(parsePairs('/a = X, /a = Y')).toEqual([
      { ssmPath: '/a', envName: 'X' },
      { ssmPath: '/a', envName: 'Y' },
    ])
  })
  it('ignores empty entries', () => {
    expect(parsePairs('')).toEqual([])
    expect(parsePairs(' , ')).toEqual([])
  })
  it('throws on a missing "="', () => {
    expect(() => parsePairs('/app/orphan')).toThrow(/Malformed/)
  })
  it('throws on an empty path or env name', () => {
    expect(() => parsePairs(' = DB')).toThrow(/Malformed/)
    expect(() => parsePairs('/app/db = ')).toThrow(/Malformed/)
  })
})

describe('chunk', () => {
  it('splits into chunks of the given size', () => {
    expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]])
  })
})

describe('run', () => {
  it('masks and exports a single value', async () => {
    withFixture({ '/app/db': 'secretDB' })
    await run('/app/db = DB_PASS', new SSMClient({}))
    expect(setSecret).toHaveBeenCalledWith('secretDB')
    expect(exportVariable).toHaveBeenCalledWith('DB_PASS', 'secretDB')
  })

  it('masks a multiline value as a whole AND per line (runner masking is line-oriented)', async () => {
    const pem = '-----BEGIN-----\nLINE2\n-----END-----'
    withFixture({ '/app/key': pem })
    await run('/app/key = PRIVATE_KEY', new SSMClient({}))
    expect(setSecret).toHaveBeenCalledWith(pem)
    expect(setSecret).toHaveBeenCalledWith('-----BEGIN-----')
    expect(setSecret).toHaveBeenCalledWith('LINE2')
    expect(setSecret).toHaveBeenCalledWith('-----END-----')
    expect(exportVariable).toHaveBeenCalledWith('PRIVATE_KEY', pem)
  })

  it('propagates an SDK error as a rejection and exports nothing', async () => {
    ssmMock.on(GetParametersCommand).rejects(new Error('AccessDeniedException'))
    await expect(run('/app/db = DB_PASS', new SSMClient({}))).rejects.toThrow(/AccessDenied/)
    expect(exportVariable).not.toHaveBeenCalled()
  })

  it('throws when a requested parameter is missing', async () => {
    withFixture({ '/app/db': 'secretDB' })
    await expect(
      run('/app/db = DB_PASS, /app/missing = API_KEY', new SSMClient({})),
    ).rejects.toThrow(/\/app\/missing/)
  })

  it('does not export anything if any parameter is missing (no partial write)', async () => {
    withFixture({ '/app/db': 'secretDB' })
    await run('/app/db = DB_PASS, /app/missing = API_KEY', new SSMClient({})).catch(() => {})
    expect(exportVariable).not.toHaveBeenCalled()
  })

  it('exports a duplicate path under two env vars', async () => {
    withFixture({ '/app/shared': 'v' })
    await run('/app/shared = ENV_A, /app/shared = ENV_B', new SSMClient({}))
    expect(exportVariable).toHaveBeenCalledWith('ENV_A', 'v')
    expect(exportVariable).toHaveBeenCalledWith('ENV_B', 'v')
  })

  it('preserves values containing "=" and "&"', async () => {
    withFixture({ '/app/url': 'a=b&c=d' })
    await run('/app/url = URL', new SSMClient({}))
    expect(exportVariable).toHaveBeenCalledWith('URL', 'a=b&c=d')
  })

  it('chunks across the 10-parameter API limit', async () => {
    const fixture: Record<string, string> = {}
    let input = ''
    for (let n = 1; n <= 12; n++) {
      fixture[`/p/${n}`] = `v${n}`
      input += `${n > 1 ? ', ' : ''}/p/${n} = E_${n}`
    }
    withFixture(fixture) // throws if a single command exceeds 10 names
    await run(input, new SSMClient({}))
    expect(exportVariable).toHaveBeenCalledTimes(12)
    expect(exportVariable).toHaveBeenCalledWith('E_11', 'v11')
    // 12 unique paths -> two GetParameters calls (10 + 2).
    expect(ssmMock.commandCalls(GetParametersCommand)).toHaveLength(2)
  })

  it('requests decryption', async () => {
    withFixture({ '/app/db': 'secretDB' })
    await run('/app/db = DB_PASS', new SSMClient({}))
    const call = ssmMock.commandCalls(GetParametersCommand)[0]
    expect(call.args[0].input).toMatchObject({ WithDecryption: true, Names: ['/app/db'] })
  })

  it('is a no-op for empty input', async () => {
    withFixture({})
    await run('', new SSMClient({}))
    expect(exportVariable).not.toHaveBeenCalled()
    expect(ssmMock.commandCalls(GetParametersCommand)).toHaveLength(0)
  })
})
