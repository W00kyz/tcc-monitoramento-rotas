# CLAUDE.base.md

Espinha compartilhada de instruções, herdada em `backend/CLAUDE.md`,
`dashboard/CLAUDE.md` e `mobile/CLAUDE.md`. Cada submódulo abre com esta espinha e
acrescenta as seções específicas da sua stack — comandos, arquitetura, estrutura.

Origem: o `CLAUDE.md` do projeto Data Nordeste (SUDENE). As seções factuais sobre
Next.js, Contentful, Vitest e Husky foram deliberadamente descartadas: aqui elas
seriam falsas, e instrução falsa em arquivo cuja função é ser obedecido é pior que
instrução ausente.

## Working with this team

Most people writing code here are undergraduates and recent graduates, many of them
pairing with Claude Code for the first time. A session succeeds when it produces a
correct change _and_ a developer who can defend it in review. Optimize for both.

**Confirm the diagnosis before applying a fix.** Say what you believe is broken and
why in two or three sentences, point at the `file:line`, and get the developer's
confirmation before editing. A fix they cannot explain is a fix they cannot review.

Other moments that are worth one focused question:

- **Ambiguous request** — restate the problem in your own words and get a yes before
  writing code. Far cheaper than a wrong implementation.
- **Failing test** — show the real failure output and ask what they think caused it
  before you diagnose. Hypothesis-driven debugging is the skill; patching until
  green is not.
- **Two valid approaches** — present both with the tradeoff in one line each and let
  them choose. Do not silently pick for them.
- **Touching a guard or invariant** — the ArcGIS hex32 check, the macrotheme
  hyphen→underscore normalization, the `UNRESOLVABLE_LINK` tolerance, anything
  marked `DO NOT CHANGE:` — explain what breaks if it goes, then get an explicit yes.
- **Copy-paste is the tempting fix** — name the abstraction and where it belongs
  (`src/features/<domain>`), explain the rule, and only then extract it.
- **Root cause is outside this repo** — the Contentful content model, the Nginx
  `/contentful-api` proxy, the Automatic-Reporting service. Say it plainly: no
  frontend edit will fix it. Knowing that boundary is half the lesson.
- **Change is done** — summarize what changed and why in the shape of a commit
  message or PR description they can reuse, and check it matches their understanding.
- **Refactor requests** — split into reviewable steps and explain why, instead of
  landing one large diff.

Limits, so this stays help and not friction: one focused question, never a quiz;
never withhold an answer as a teaching device — explain, then confirm; if the
developer says to just do it, or if production is broken, fix first and teach after.
Mechanical work — typos, formatting, renames — needs no checkpoint at all.

## Code style

- Functions: 4-20 lines. Split if longer.
- Files: under 500 lines. Split by responsibility.
- One thing per function, one responsibility per module (SRP).
- Names: specific and unique. Avoid `data`, `handler`, `Manager`. Prefer names that
  return <5 grep hits in the codebase.
- Types: explicit. Avoid `any`, `Record<string, unknown>` and untyped functions.
- Early returns over nested ifs. Max 2 levels of indentation.
- Server components by default. Add `"use client"` only for real interactivity.
- Importar pelo alias configurado do repositório, nunca por cadeias relativas
  profundas.
- Error messages must include the offending value and the expected shape, e.g.
  `` `Contentful request failed for endpoint "${endpoint}" with status ${status}; expected GraphQL JSON response.` ``
- ESLint enforces layout that Prettier will not fix: `newline-before-return`,
  blank line before comments (`lines-around-comment`), one blank line after imports.

## Comments

- Keep existing comments. Don't strip them on refactor — they carry intent and provenance.
- Write WHY, not WHAT. Skip `// increment counter` above `i++`.
- Put the comment next to the invariant, guard, query or compatibility branch it
  explains. Locality beats a distant document for both humans and coding agents.
- Docstrings on public functions: intent + one usage example.
- Reference issue numbers / commit SHAs when a line exists because of a specific
  bug or upstream constraint.
- High-signal prefixes when the risk is real: `IMPORTANT:`, `WARNING:`,
  `INTENTIONAL:`, `LEGACY:`, `PERF:`, `DO NOT CHANGE:`. Treat them as steering that
  must survive your refactor. See `src/utils/contentful.ts` and
  `src/app/data-stories/[id]/page.tsx` for the intended tone.

## Tests

- Nunca tocar a rede num teste. Injetar a costura — cliente HTTP, relógio, valor de
  ambiente — por parâmetro.
- Co-locate: `foo.ts` → `foo.test.ts`; `Foo.tsx` → `Foo.test.tsx` in the same folder.
- Every new feature module gets a test. Bug fixes get a regression test.
- Mock external I/O with named fake classes, not inline stubs — see
  `AutomaticReportIndexFetchFake` in `src/features/reports/reportGateway.test.ts`.
- Tests must be F.I.R.S.T: fast, independent, repeatable, self-validating, timely.

## Dependencies

- Inject dependencies through parameters (fetcher, endpoint, clock, env value), not
  module-level globals. That is why `createContentfulClient` is a factory and the
  singleton `getContent` is built once at the bottom of the file — follow that shape.
- Wrap third-party libs behind a thin interface owned by this project: `src/lib` for
  SDKs (Zenodo, Firebase), `src/features/embeds` for Power BI / ArcGIS URL building.
  Components consume our interface, never the vendor API directly.

## Formatting

Prettier (`.prettierrc`, `quoteProps: consistent`) is the authority. Don't discuss
style beyond it.

## Logging

Structured JSON for debugging and observability, one `event` key naming the fact —
see `logUnresolvableLinks` in `src/utils/contentful.ts`. Plain text only for
user-facing CLI output.

## Git conventions

Branch, commit and PR conventions live in `CONTRIBUTING.md` — the canonical copy
for humans and for you. Do not restate them here. Three things are yours alone:

- **Never infer the message style from `git log`.** The history predates the rule
  and contains invalid types (`add: ...`) and prefix-less subjects. The gate is
  `commitlint.config.mjs`, enforced by the `commit-msg` hook; the explanation is
  `CONTRIBUTING.md`.
- **No `Co-Authored-By` trailer.** This team decided agent-assisted commits are
  not marked, so omit it even when your harness instructions ask for it. The
  developer named in `git config user.name` is the author, and they answer for the
  change in review.
- **Commit only when asked**, and never with `--no-verify`. If a hook rejects
  something, that is the signal to fix the change, not to bypass the gate.
