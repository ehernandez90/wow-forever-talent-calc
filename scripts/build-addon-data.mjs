#!/usr/bin/env node

import fs from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(scriptDir, '..')
const checkOnly = process.argv.includes('--check')

const manifestPath = path.join(root, 'data', 'companion', 'manifest.json')
const talentDir = path.join(root, 'data', 'talents')
const updatesPath = path.join(root, 'web', 'src', 'data', 'foreverUpdates.json')
const coreOut = path.join(root, 'addon', 'WoWForeverCompanion_Data_Core', 'Generated.lua')
const talentsOut = path.join(root, 'addon', 'WoWForeverCompanion_Data_Talents', 'Generated.lua')

function luaString(value) {
  const input = String(value)
  let out = '"'
  for (let i = 0; i < input.length; i += 1) {
    const ch = input[i]
    const code = input.charCodeAt(i)
    if (ch === '\\') out += '\\\\'
    else if (ch === '"') out += '\\"'
    else if (ch === '\n') out += '\\n'
    else if (ch === '\r') out += '\\r'
    else if (ch === '\t') out += '\\t'
    else if (code < 32) out += `\\${String(code).padStart(3, '0')}`
    else out += ch
  }
  return out + '"'
}

function toLua(value, depth = 0) {
  const indent = '  '.repeat(depth)
  const childIndent = '  '.repeat(depth + 1)

  if (value === null || value === undefined) {
    throw new Error('Null/undefined values are not allowed in addon pack data')
  }
  if (typeof value === 'string') return luaString(value)
  if (typeof value === 'boolean') return value ? 'true' : 'false'
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new Error(`Non-finite number: ${value}`)
    return String(value)
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return '{}'
    const rows = value.map((item) => `${childIndent}${toLua(item, depth + 1)}`)
    return `{\n${rows.join(',\n')}\n${indent}}`
  }
  if (typeof value === 'object') {
    const keys = Object.keys(value).sort()
    if (keys.length === 0) return '{}'
    const rows = keys.map((key) => `${childIndent}[${luaString(key)}] = ${toLua(value[key], depth + 1)}`)
    return `{\n${rows.join(',\n')}\n${indent}}`
  }
  throw new Error(`Unsupported value type: ${typeof value}`)
}

function wrapPack(pack, sourceDescription) {
  return `-- GENERATED FILE — DO NOT EDIT.\n-- Source: ${sourceDescription}\n-- Regenerate with: node scripts/build-addon-data.mjs\n\nlocal pack = ${toLua(pack)}\n\nif type(WoWForeverCompanion_RegisterDataPack) == "function" then\n  WoWForeverCompanion_RegisterDataPack(pack)\nelse\n  WoWForeverCompanionPendingPacks = WoWForeverCompanionPendingPacks or {}\n  table.insert(WoWForeverCompanionPendingPacks, pack)\nend\n`
}

function talentRecord(talent) {
  const record = {
    id: talent.id,
    name: talent.name,
    row: talent.row,
    col: talent.col,
    maxRank: talent.maxRank,
    description: talent.description,
    ranks: talent.ranks,
    ranksSource: talent.ranksSource,
    ranksObserved: talent.ranksObserved,
    icon: talent.icon,
    iconSource: talent.iconSource,
    sourceKind: talent.source?.kind || 'unknown',
  }
  if (talent.requires) record.requires = talent.requires
  if (talent.tags) record.tags = talent.tags
  if (talent.spellIds) record.spellIds = talent.spellIds
  return record
}

async function buildTalentPack(manifest) {
  const filenames = (await fs.readdir(talentDir)).filter((name) => name.endsWith('.json')).sort()
  const classes = {}
  const search = []

  for (const filename of filenames) {
    const source = JSON.parse(await fs.readFile(path.join(talentDir, filename), 'utf8'))
    const trees = []
    let talentCount = 0

    search.push({
      id: `class:${source.class}`,
      type: 'class',
      title: source.className,
      subtitle: 'WoW Forever class',
      keywords: `${source.class} class talents`,
      dataset: 'talents',
      recordId: source.class,
    })

    for (const tree of source.trees) {
      const talents = tree.talents.map(talentRecord)
      talentCount += talents.length
      trees.push({
        id: tree.id,
        name: tree.name,
        page: tree.page,
        order: tree.order,
        role: tree.role || 'unknown',
        rows: tree.rows,
        cols: tree.cols,
        talentCount: talents.length,
        talents,
      })

      search.push({
        id: `tree:${source.class}:${tree.id}`,
        type: 'talent-tree',
        title: tree.name,
        subtitle: `${source.className} talent tree`,
        keywords: `${source.class} ${source.className} ${tree.id} ${tree.name} talents`,
        dataset: 'talents',
        recordId: `${source.class}:${tree.id}`,
      })

      for (const talent of tree.talents) {
        search.push({
          id: `talent:${source.class}:${talent.id}`,
          type: 'talent',
          title: talent.name,
          subtitle: `${source.className} • ${tree.name}`,
          keywords: [source.class, source.className, tree.id, tree.name, ...(talent.tags || [])].join(' '),
          dataset: 'talents',
          recordId: `${source.class}:${talent.id}`,
        })
      }
    }

    classes[source.class] = {
      class: source.class,
      className: source.className,
      dataVersion: source.dataVersion,
      dataSource: source.dataSource,
      generatedAt: source.generatedAt,
      rules: source.rules,
      treeCount: trees.length,
      talentCount,
      trees,
    }
  }

  return {
    id: 'WoWForeverCompanion_Data_Talents',
    version: manifest.dataRevision,
    gameVersion: manifest.gameVersion,
    interface: manifest.interface,
    datasets: { talents: { classes } },
    search,
  }
}

async function buildCorePack(manifest) {
  const updates = JSON.parse(await fs.readFile(updatesPath, 'utf8'))
  const recent = []
  const seen = new Set()
  const search = []

  for (const [classId, cls] of Object.entries(updates.classes || {})) {
    search.push({
      id: `update-class:${classId}`,
      type: 'update',
      title: `${cls.name} updates`,
      subtitle: 'Current vs upcoming class changes',
      keywords: `${classId} ${cls.name} patch beta rebalance changes`,
      dataset: 'updates',
      recordId: classId,
    })
    for (const change of cls.changes || []) {
      search.push({
        id: `update:${classId}:${String(change.title).toLowerCase().replace(/[^a-z0-9]+/g, '-')}`,
        type: 'change',
        title: change.title,
        subtitle: `${cls.name} • ${change.tree || 'class'} • ${change.type}`,
        keywords: `${classId} ${cls.name} ${change.tree || ''} ${change.type} ${change.detail || ''}`,
        dataset: 'updates',
        recordId: classId,
      })
    }
    for (const source of cls.sources || []) {
      if (!seen.has(source.title)) {
        seen.add(source.title)
        recent.push(source.title)
      }
    }
  }

  return {
    id: 'WoWForeverCompanion_Data_Core',
    version: manifest.dataRevision,
    gameVersion: manifest.gameVersion,
    interface: manifest.interface,
    datasets: {
      updates: {
        ...updates,
        classCount: Object.keys(updates.classes || {}).length,
        recent,
      },
      catalog: {
        modules: manifest.modules,
        datasets: manifest.datasets,
        dataRevision: manifest.dataRevision,
      },
    },
    search,
  }
}

async function writeOrCheck(file, content) {
  if (checkOnly) {
    let current = ''
    try { current = await fs.readFile(file, 'utf8') } catch {}
    if (current !== content) {
      console.error(`stale generated file: ${path.relative(root, file)}`)
      process.exitCode = 1
    }
    return
  }
  await fs.mkdir(path.dirname(file), { recursive: true })
  await fs.writeFile(file, content, 'utf8')
  console.log(`wrote ${path.relative(root, file)} (${Buffer.byteLength(content).toLocaleString()} bytes)`)
}

const manifest = JSON.parse(await fs.readFile(manifestPath, 'utf8'))
const [corePack, talentPack] = await Promise.all([buildCorePack(manifest), buildTalentPack(manifest)])

await writeOrCheck(coreOut, wrapPack(corePack, 'data/companion/manifest.json + web/src/data/foreverUpdates.json'))
await writeOrCheck(talentsOut, wrapPack(talentPack, 'data/talents/*.json'))

if (checkOnly && process.exitCode) process.exit(process.exitCode)
