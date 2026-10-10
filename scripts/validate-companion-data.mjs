#!/usr/bin/env node

import fs from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const manifest = JSON.parse(await fs.readFile(path.join(root, 'data/companion/manifest.json'), 'utf8'))
const expectedClasses = ['druid','hunter','mage','paladin','priest','rogue','shaman','warlock','warrior']
const errors = []

function fail(message) { errors.push(message) }
function unique(values, label) {
  const seen = new Set()
  for (const value of values) {
    if (seen.has(value)) fail(`${label} duplicate: ${value}`)
    seen.add(value)
  }
}
async function exists(rel) {
  try { await fs.access(path.join(root, rel)); return true } catch { return false }
}
function rejectNulls(value, label) {
  if (value === null || value === undefined) {
    fail(`${label} contains null/undefined (Lua pack compiler cannot represent it safely)`)
    return
  }
  if (Array.isArray(value)) {
    value.forEach((item, i) => rejectNulls(item, `${label}[${i}]`))
  } else if (typeof value === 'object') {
    for (const [key, item] of Object.entries(value)) rejectNulls(item, `${label}.${key}`)
  }
}

if (manifest.schemaVersion !== 1) fail('manifest.schemaVersion must be 1')
if (manifest.gameFlavor !== 'forever') fail('manifest.gameFlavor must be forever')
if (manifest.interface !== 16001) fail(`manifest.interface must be 16001 for current Forever 1.60.1 target (got ${manifest.interface})`)
if (!manifest.dataRevision) fail('manifest.dataRevision is required')

unique((manifest.modules || []).map((m) => m.id), 'module id')
unique((manifest.modules || []).map((m) => m.order), 'module order')
unique((manifest.datasets || []).map((d) => d.id), 'dataset id')

const datasetIds = new Set((manifest.datasets || []).map((d) => d.id))
for (const module of manifest.modules || []) {
  for (const dataset of module.datasets || []) {
    if (!datasetIds.has(dataset)) fail(`module ${module.id} references unknown dataset ${dataset}`)
  }
}
for (const dataset of manifest.datasets || []) {
  if (!['live','planned','partial','backbone'].includes(dataset.status)) fail(`dataset ${dataset.id} has invalid status ${dataset.status}`)
  if (!dataset.canonicalPath) fail(`dataset ${dataset.id} missing canonicalPath`)
  if (!dataset.pack) fail(`dataset ${dataset.id} missing pack`)
  if (dataset.status === 'live' && !(await exists(dataset.canonicalPath))) fail(`live dataset ${dataset.id} path missing: ${dataset.canonicalPath}`)
}

const talentFiles = (await fs.readdir(path.join(root, 'data/talents'))).filter((name) => name.endsWith('.json')).sort()
const foundClasses = []
let talentCount = 0
for (const filename of talentFiles) {
  const data = JSON.parse(await fs.readFile(path.join(root, 'data/talents', filename), 'utf8'))
  foundClasses.push(data.class)
  if (filename !== `${data.class}.json`) fail(`${filename}: class field does not match filename`)
  if (!expectedClasses.includes(data.class)) fail(`${filename}: unexpected class ${data.class}`)
  if (!Array.isArray(data.trees) || data.trees.length === 0) fail(`${filename}: no trees`)
  const ids = []
  for (const tree of data.trees || []) {
    for (const talent of tree.talents || []) {
      talentCount += 1
      ids.push(talent.id)
      if (!talent.source || !talent.source.kind) fail(`${filename}:${talent.id} missing provenance source.kind`)
      if (!talent.name || !talent.description) fail(`${filename}:${talent.id} missing name/description`)
      rejectNulls(talent, `${filename}:${talent.id}`)
    }
  }
  unique(ids, `${filename} talent id`)
}
for (const classId of expectedClasses) {
  if (!foundClasses.includes(classId)) fail(`missing talent class file: ${classId}.json`)
}
unique(foundClasses, 'talent class')

const updates = JSON.parse(await fs.readFile(path.join(root, 'web/src/data/foreverUpdates.json'), 'utf8'))
for (const classId of expectedClasses) {
  if (!updates.classes?.[classId]) fail(`updates missing class ${classId}`)
}
for (const [classId, cls] of Object.entries(updates.classes || {})) {
  for (const source of cls.sources || []) {
    if (!source.title || !source.url || !source.date) fail(`update source incomplete for ${classId}`)
    if (source.verified !== true) fail(`promoted update source for ${classId} must be verified=true`)
    if (!String(source.url).startsWith('https://')) fail(`update source URL must be https for ${classId}`)
  }
}
rejectNulls(updates, 'foreverUpdates')

for (const toc of [
  'addon/WoWForeverCompanion/WoWForeverCompanion.toc',
  'addon/WoWForeverCompanion_Data_Core/WoWForeverCompanion_Data_Core.toc',
  'addon/WoWForeverCompanion_Data_Talents/WoWForeverCompanion_Data_Talents.toc',
]) {
  const text = await fs.readFile(path.join(root, toc), 'utf8')
  if (!/^## Interface: 16001$/m.test(text)) fail(`${toc}: expected ## Interface: 16001`)
}

if (errors.length) {
  console.error(`Companion validation failed with ${errors.length} error(s):`)
  errors.forEach((error) => console.error(`- ${error}`))
  process.exit(1)
}

console.log(`Companion validation OK: ${foundClasses.length} classes, ${talentCount} talents, ${manifest.modules.length} modules, ${manifest.datasets.length} datasets declared.`)
