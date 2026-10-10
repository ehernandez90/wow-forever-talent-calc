import { useState } from 'react'
import classesIndex from '../data/classes-index.json'
import facts from '../data/facts.json'
import { includeExamples } from '../data/load'
import { changesHash, classHash, racesHash, spellsHash } from '../url/route'
import { ClassIcon } from './ClassIcon'
import { REPO_URL } from './site'
import { continueLabel, forgetLastBuild, readLastBuild } from './storage'
import { SITE_TITLE, useTitle } from './title'
import { checkedLine, RANKS_LINE, SOURCE_LINE } from './trust'

export { REPO_URL } from './site'

interface IndexEntry {
  id: string
  origin: string
  className: string
  dataSource: string
  maxPoints: number
  talents: number
  reviewed: number
  needsReview: number
  trees: { id: string; name: string; talents: number }[]
}

const classes: IndexEntry[] = (classesIndex as IndexEntry[]).filter((c) => includeExamples || c.origin === 'talents')

export function ClassPicker() {
  useTitle(SITE_TITLE)
  const [last, setLast] = useState(() => readLastBuild())

  return (
    <div>
      {last && (
        <div className="continue-card" data-testid="continue-card">
          <a className="serif text-base" href={classHash(last.classId, last.v, last.t)} data-testid="continue-link">
            {continueLabel(last)}
          </a>
          <span className="text-xs text-[var(--text-dim)]">your last build on this browser, not shared anywhere</span>
          <button
            type="button"
            className="continue-forget ml-auto"
            data-testid="continue-forget"
            onClick={() => {
              forgetLastBuild()
              setLast(undefined)
            }}
          >
            forget
          </button>
        </div>
      )}

      <div className="landing-panel panel">
        <div className="landing-hero">
          <div className="landing-kicker">WoW Forever · Talent Calculator</div>
          <h1 className="landing-title serif">Build your class</h1>
          <p className="landing-subtitle">
            Pick a class, spend points across all three talent trees, share your build, and compare Forever changes
            against Classic Era.
          </p>
        </div>

        <div className="landing-links">
          <a className="landing-link" href={changesHash()} data-testid="landing-changes-link">
            What changed against Classic Era
          </a>
          <a className="landing-link" href={racesHash()} data-testid="landing-races-link">
            Races & class matrix
          </a>
          <a className="landing-link" href={spellsHash()} data-testid="landing-spells-link">
            Spells seen on stream
          </a>
        </div>

        {classes.length === 0 ? (
          <p className="text-center text-[var(--text-dim)]">
            No class data yet. Real classes appear here as they pass review; run the dev server to see the example
            class.
          </p>
        ) : (
          <ul className="class-list-modern grid" data-testid="class-list">
            {classes.map((c) => (
              <ClassCard key={c.id} entry={c} />
            ))}
          </ul>
        )}

        <div className="mt-7 border-t border-[#292c30] pt-4 text-center text-xs text-[var(--text-dim)]">
          <p className="mb-2" data-testid="landing-caveat">
            {SOURCE_LINE} {checkedLine(facts.talents, 'talents')} Expect wrong names and numbers. {RANKS_LINE}
          </p>
          <p className="mb-0">
            {facts.racialTraits.total} racial traits · {facts.spellEntries.total} spellbook entries ·{' '}
            {facts.spellTooltips.total} spell tooltips ·{' '}
            <a href={REPO_URL} target="_blank" rel="noreferrer">
              source on GitHub
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}

function ClassCard({ entry }: { entry: IndexEntry }) {
  const treeNames = entry.trees.map((tree) => tree.name).join(' · ')
  return (
    <li className="class-card">
      <a
        href={`#/${entry.id}`}
        className="class-card-link block no-underline"
        data-testid={`class-${entry.id}`}
      >
        <ClassIcon classId={entry.id} className={entry.className} size={56} />
        <span className="class-card-name serif">{entry.className}</span>
        <span className="class-card-meta">{treeNames}</span>
        {entry.origin !== 'talents' && <span className="text-xs text-[var(--text-dim)]">example</span>}
      </a>
    </li>
  )
}
