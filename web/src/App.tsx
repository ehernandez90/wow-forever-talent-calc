import { lazy, Suspense, useEffect, useState } from 'react'
import { aboutHash, changesHash, parseHash, racesHash, spellsHash, updatesHash, type Route } from './url/route'
import { ClassPicker, REPO_URL } from './ui/ClassPicker'
import { ShortcutsOverlay } from './ui/ShortcutsOverlay'
import facts from './data/facts.json'
import { checkedLine, SOURCE_LINE } from './ui/trust'

const ClassPage = lazy(() => import('./ui/ClassPage').then((m) => ({ default: m.ClassPage })))
const ReviewPage = lazy(() => import('./ui/ReviewPage').then((m) => ({ default: m.ReviewPage })))
const ChangesPage = lazy(() => import('./ui/ChangesPage').then((m) => ({ default: m.ChangesPage })))
const UpdatesPage = lazy(() => import('./ui/UpdatesPage').then((m) => ({ default: m.UpdatesPage })))
const RacesPage = lazy(() => import('./ui/RacesPage').then((m) => ({ default: m.RacesPage })))
const SpellsPage = lazy(() => import('./ui/SpellsPage').then((m) => ({ default: m.SpellsPage })))
const AboutPage = lazy(() => import('./ui/AboutPage').then((m) => ({ default: m.AboutPage })))

function useRoute(): Route {
  const [route, setRoute] = useState<Route>(() => parseHash(window.location.hash))
  useEffect(() => {
    const onChange = () => setRoute(parseHash(window.location.hash))
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])
  return route
}

export default function App() {
  const route = useRoute()

  if (route.kind === 'class' && route.embed) {
    return (
      <div className="app-shell embed-shell px-3 py-3" data-testid="embed-shell">
        <main id="main" tabIndex={-1}>
          <Suspense fallback={<div className="panel p-4 text-[var(--text-dim)]">Loading...</div>}>
            <ClassPage key={route.classId} classId={route.classId} version={route.version} buildString={route.build} sel={route.sel} embed />
          </Suspense>
        </main>
      </div>
    )
  }

  return (
    <div className="app-shell px-4 py-4">
      <a
        className="skip-link"
        href="#main"
        onClick={(e) => {
          e.preventDefault()
          document.getElementById('main')?.focus()
        }}
      >
        Skip to the talent trees
      </a>
      <nav className="app-nav mb-4 flex items-baseline justify-between gap-4">
        <a href="#/" className="site-wordmark serif font-semibold no-underline">
          WoW Forever
        </a>
        <span className="app-nav-right text-xs text-[var(--text-dim)]">
          <a href={changesHash()} data-testid="nav-changes">Changes</a>
          <a href={updatesHash()} data-testid="nav-updates">Updates</a>
          <a href={racesHash()} data-testid="nav-races">Races</a>
          <a href={spellsHash()} data-testid="nav-spells">Spells</a>
          <span className="site-note">Talent Calculator · Unofficial</span>
          <ShortcutsOverlay />
        </span>
      </nav>
      <main id="main" tabIndex={-1}>
        <Suspense fallback={<div className="panel p-4 text-[var(--text-dim)]">Loading...</div>}>
          <Body route={route} />
        </Suspense>
      </main>
      <footer className="app-footer mt-8 text-xs text-[var(--text-dim)]">
        Not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft, talent names, descriptions, icons
        and screenshots are property of Blizzard Entertainment. {SOURCE_LINE} {checkedLine(facts.talents, 'talents')} Code
        MIT,{' '}
        <a href={REPO_URL} target="_blank" rel="noreferrer">source on GitHub</a>.{' '}
        <a href={aboutHash()} data-testid="footer-about">About this calculator</a>.
      </footer>
    </div>
  )
}

function Body({ route }: { route: Route }) {
  switch (route.kind) {
    case 'picker':
      return <ClassPicker />
    case 'class':
      return (
        <ClassPage
          key={route.classId}
          classId={route.classId}
          version={route.version}
          buildString={route.build}
          sel={route.sel}
        />
      )
    case 'changes':
      return <ChangesPage key={route.classId ?? ''} classId={route.classId} />
    case 'updates':
      return <UpdatesPage />
    case 'races':
      return <RacesPage key={route.raceId ?? ''} raceId={route.raceId} variant={route.variant} />
    case 'spells':
      return <SpellsPage key={route.classId ?? ''} classId={route.classId} />
    case 'about':
      return <AboutPage />
    case 'review':
      return <ReviewPage classId={route.classId} />
    default:
      return (
        <div className="panel p-4">
          Unknown route <code>{route.hash}</code>. <a href="#/">Pick a class</a>.
        </div>
      )
  }
}
