import updates from '../data/foreverUpdates.json'
import './updates.css'

const ORDER = ['druid','hunter','mage','paladin','priest','rogue','shaman','warlock','warrior'] as const

type ClassId = (typeof ORDER)[number]
type Change = { type: string; tree?: string; title: string; detail: string }

export function UpdatesPage() {
  const params = new URLSearchParams(window.location.hash.split('?')[1] ?? '')
  const requested = params.get('class') as ClassId | null
  const classId: ClassId = requested && ORDER.includes(requested) ? requested : 'mage'
  const entry = updates.classes[classId]

  return (
    <section className="updates-page">
      <header className="updates-hero panel">
        <div>
          <div className="updates-eyebrow">FOREVER UPDATE TRACKER · V1</div>
          <h1>Current vs Upcoming class changes</h1>
          <p>
            Blizzard announcements are kept separate from the current calculator data so we can preserve old talent trees and compare them against upcoming rebalances.
          </p>
        </div>
        <div className="updates-badge">Reviewed {updates.lastReviewed}</div>
      </header>

      <div className="updates-layout">
        <aside className="panel updates-sidebar">
          <h2>Classes</h2>
          {ORDER.map((id) => (
            <a key={id} href={`#/updates?class=${id}`} className={id === classId ? 'active' : ''}>
              {updates.classes[id].name}
            </a>
          ))}
        </aside>

        <div className="updates-main">
          <section className="panel updates-summary">
            <div>
              <div className="updates-eyebrow">{entry.currentLabel}</div>
              <h2>{entry.name}</h2>
              <p>Verified calculator snapshot remains untouched until structured change data is confirmed.</p>
            </div>
            <div className="updates-toggle" aria-label="Version comparison preview">
              <button className="active">Current</button>
              <button disabled>Upcoming</button>
            </div>
          </section>

          <section className="panel">
            <div className="updates-section-head">
              <h3>Announced talent changes</h3>
              <span>{entry.changes.length} tracked</span>
            </div>
            {entry.changes.length === 0 ? (
              <div className="updates-empty">No structured changes have been promoted for this class yet.</div>
            ) : (
              <div className="updates-change-list">
                {(entry.changes as Change[]).map((change) => (
                  <article key={`${change.type}-${change.title}`} className={`updates-change ${change.type}`}>
                    <div className="updates-change-meta">
                      <span>{change.type}</span>
                      {change.tree ? <strong>{change.tree}</strong> : null}
                    </div>
                    <h4>{change.title}</h4>
                    <p>{change.detail}</p>
                  </article>
                ))}
              </div>
            )}
          </section>

          <section className="panel">
            <div className="updates-section-head">
              <h3>Official sources</h3>
              <span>{entry.sources.length} source{entry.sources.length === 1 ? '' : 's'}</span>
            </div>
            {entry.sources.length === 0 ? (
              <div className="updates-empty">No dedicated official class article has been recorded in the v1 source set.</div>
            ) : (
              <div className="updates-sources">
                {entry.sources.map((source) => (
                  <a key={source.url} href={source.url} target="_blank" rel="noreferrer">
                    <strong>{source.title}</strong>
                    <span>{source.date} · Blizzard · verified official source</span>
                  </a>
                ))}
              </div>
            )}
          </section>

          <section className="panel updates-policy">
            <h3>Source trust policy</h3>
            <p><strong>Authoritative:</strong> Blizzard class deep dives, beta/patch notes, and official WoW news.</p>
            <p><strong>Signal only:</strong> forums and third-party calculators. These can alert us to investigate, but they should not silently modify the verified talent tree.</p>
          </section>
        </div>
      </div>
    </section>
  )
}
