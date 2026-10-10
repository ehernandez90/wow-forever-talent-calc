#!/usr/bin/env node

import fs from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const registry = JSON.parse(await fs.readFile(path.join(root, 'data/companion/sources.json'), 'utf8'))
const errors = []
const ids = new Set()
const allowedTrust = new Set(['authoritative', 'verified-secondary', 'signal-only'])
const allowedIngest = new Set(['reviewed', 'discovery-only', 'manual-review', 'disabled'])

if (registry.schemaVersion !== 1) errors.push('schemaVersion must be 1')
if (!Array.isArray(registry.sources) || registry.sources.length === 0) errors.push('sources must be a non-empty array')

for (const source of registry.sources || []) {
  if (!source.id) errors.push('source missing id')
  else if (ids.has(source.id)) errors.push(`duplicate source id: ${source.id}`)
  else ids.add(source.id)
  if (!source.name) errors.push(`${source.id || '?'} missing name`)
  if (!allowedTrust.has(source.trust)) errors.push(`${source.id || '?'} invalid trust: ${source.trust}`)
  if (!allowedIngest.has(source.automatedIngest)) errors.push(`${source.id || '?'} invalid automatedIngest: ${source.automatedIngest}`)
  if (!source.reusePolicy) errors.push(`${source.id || '?'} missing reusePolicy`)
  if (source.url && !String(source.url).startsWith('https://')) errors.push(`${source.id} URL must use https`)
}

const wiki = (registry.sources || []).find((s) => s.id === 'warcraft-wiki')
if (!wiki || !String(wiki.license || '').includes('CC BY-SA 4.0')) {
  errors.push('warcraft-wiki must preserve its CC BY-SA 4.0 licensing warning')
}

for (const id of ['blizzard-client', 'blizzard-news', 'warcraft-wiki', 'wowhead', 'community']) {
  if (!ids.has(id)) errors.push(`required source policy entry missing: ${id}`)
}

if (errors.length) {
  console.error(`Source registry validation failed with ${errors.length} error(s):`)
  for (const error of errors) console.error(`- ${error}`)
  process.exit(1)
}

console.log(`Source registry OK: ${registry.sources.length} governed source(s).`)
