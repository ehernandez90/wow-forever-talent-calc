/**
 * Hash routing for the static calculator.
 */
export type Route =
  | { kind: 'picker' }
  | { kind: 'class'; classId: string; version?: number; build?: string; sel?: string; embed?: true }
  | { kind: 'changes'; classId?: string }
  | { kind: 'updates' }
  | { kind: 'races'; raceId?: string; variant?: string }
  | { kind: 'spells'; classId?: string }
  | { kind: 'about' }
  | { kind: 'review'; classId: string }
  | { kind: 'unknown'; hash: string }

const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/

export function parseHash(hash: string): Route {
  let h = hash.startsWith('#') ? hash.slice(1) : hash
  if (h.startsWith('/')) h = h.slice(1)
  if (h === '') return { kind: 'picker' }

  const q = h.indexOf('?')
  const path = q === -1 ? h : h.slice(0, q)
  const params = new URLSearchParams(q === -1 ? '' : h.slice(q + 1))
  const segments = path.split('/').filter(Boolean)

  if (segments[0] === 'review' && segments[1] && SLUG.test(segments[1])) {
    return { kind: 'review', classId: segments[1] }
  }
  if (segments[0] === 'changes' && segments.length <= 2) {
    if (segments.length === 1) return { kind: 'changes' }
    if (segments[1] && SLUG.test(segments[1])) return { kind: 'changes', classId: segments[1] }
  }
  if (segments[0] === 'updates' && segments.length === 1) return { kind: 'updates' }
  if (segments[0] === 'races' && segments.length <= 2) {
    const variant = params.get('variant')
    const view = variant && SLUG.test(variant) ? { variant } : {}
    if (segments.length === 1) return { kind: 'races' }
    if (segments[1] && SLUG.test(segments[1])) return { kind: 'races', raceId: segments[1], ...view }
  }
  if (segments[0] === 'spells' && segments.length <= 2) {
    if (segments.length === 1) return { kind: 'spells' }
    if (segments[1] && SLUG.test(segments[1])) return { kind: 'spells', classId: segments[1] }
  }
  if (segments.length === 1 && segments[0] === 'about') return { kind: 'about' }
  if (segments.length === 1 && segments[0] && SLUG.test(segments[0])) {
    const v = params.get('v')
    const t = params.get('t')
    const sel = params.get('sel')
    const version = v === null ? undefined : Number(v)
    return {
      kind: 'class',
      classId: segments[0],
      version: version !== undefined && Number.isFinite(version) ? version : v === null ? undefined : NaN,
      build: t ?? undefined,
      sel: sel && SLUG.test(sel) ? sel : undefined,
      embed: params.get('embed') === '1' ? true : undefined,
    }
  }
  return { kind: 'unknown', hash }
}

export function buildHash(route: Route): string {
  switch (route.kind) {
    case 'picker': return '#/'
    case 'review': return `#/review/${route.classId}`
    case 'changes': return route.classId ? `#/changes/${route.classId}` : '#/changes'
    case 'updates': return '#/updates'
    case 'spells': return route.classId ? `#/spells/${route.classId}` : '#/spells'
    case 'about': return '#/about'
    case 'races': {
      if (!route.raceId) return '#/races'
      return `#/races/${route.raceId}${route.variant ? `?variant=${route.variant}` : ''}`
    }
    case 'class': {
      const params = new URLSearchParams()
      if (route.build) {
        if (route.version !== undefined) params.set('v', String(route.version))
        params.set('t', route.build)
      }
      if (route.sel) params.set('sel', route.sel)
      if (route.embed) params.set('embed', '1')
      const qs = params.toString()
      return `#/${route.classId}${qs ? `?${qs}` : ''}`
    }
    default: return route.hash
  }
}

export interface ClassView { sel?: string; embed?: boolean }

export function classHash(classId: string, version: number, build: string, view: ClassView = {}): string {
  return buildHash({ kind: 'class', classId, version, build: build || undefined, sel: view.sel, embed: view.embed ? true : undefined })
}
export function changesHash(classId?: string): string { return buildHash({ kind: 'changes', classId }) }
export function updatesHash(): string { return buildHash({ kind: 'updates' }) }
export function spellsHash(classId?: string): string { return buildHash({ kind: 'spells', classId }) }
export function aboutHash(): string { return buildHash({ kind: 'about' }) }
export function racesHash(raceId?: string, variant?: string): string { return buildHash({ kind: 'races', raceId, variant }) }
