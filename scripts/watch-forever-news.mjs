import fs from 'node:fs/promises'
import crypto from 'node:crypto'

const SOURCE = 'https://worldofwarcraft.blizzard.com/en-us/news'
const OUT = 'data/forever-news-watch.json'

let previous = { lastChecked: null, hashes: [], discoveries: [] }
try {
  previous = JSON.parse(await fs.readFile(OUT, 'utf8'))
} catch {}

const response = await fetch(SOURCE, {
  headers: { 'user-agent': 'wow-forever-talent-calc-source-watcher/1.0' },
})
if (!response.ok) throw new Error(`Blizzard news returned ${response.status}`)

const html = (await response.text()).replace(/\s+/g, ' ')
const patterns = [
  /World of Warcraft: Forever[^<\"]{0,220}(?:Class|Talent|Deep Dive|Update|Beta|Patch)[^<\"]{0,260}/gi,
  /(?:Class|Talent|Deep Dive|Update|Beta|Patch)[^<\"]{0,180}World of Warcraft: Forever[^<\"]{0,260}/gi,
]
const snippets = [...new Set(patterns.flatMap((re) => [...html.matchAll(re)].map((m) => m[0].trim())))]
const hashes = snippets.map((text) => crypto.createHash('sha256').update(text).digest('hex').slice(0, 16))
const newItems = snippets
  .map((text, i) => ({ text, hash: hashes[i] }))
  .filter((item) => !previous.hashes.includes(item.hash))
  .map((item) => ({ ...item, source: SOURCE, detectedAt: new Date().toISOString(), status: 'candidate' }))

const next = {
  lastChecked: new Date().toISOString(),
  hashes,
  discoveries: [...newItems, ...(previous.discoveries || [])].slice(0, 100),
}
await fs.writeFile(OUT, JSON.stringify(next, null, 2) + '\n')
console.log(`Found ${newItems.length} new candidate Forever announcement(s).`)
