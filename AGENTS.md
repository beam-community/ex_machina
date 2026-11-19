<!-- This file is synced with beam-community/common-config. Any changes will be overwritten. -->

# AGENTS.md

Guidance for AI coding agents working in this repository. It is shared across every
[BEAM Community](https://github.com/beam-community) Elixir project, so it covers the conventions they
all have in common.

**Project-specific notes live in [`.agents/PROJECT.md`](.agents/PROJECT.md).** Read it before starting
work if it exists: it covers this repo's architecture, quirks, and anything that overrides the
defaults below. That file belongs to this repository and is never synced, so put repo-specific
guidance there rather than here.

## What these projects are

This is an open-source library published to [Hex](https://hex.pm). Other people's applications depend
on it, so its public API is a contract:

- A change to a public function's name, arity, arguments, return shape, raised exceptions, or config
  keys is a breaking change. Avoid it. When it is unavoidable, deprecate first (`@deprecated` plus a
  warning) and mark the commit as breaking (`feat!:` / `fix!:`).
- "Public" means anything documented. Modules and functions with `@moduledoc false` / `@doc false`
  are internal and can change freely.
- Optional dependencies (`optional: true` in `mix.exs`) may be absent at runtime. Guard code that uses
  them with `Code.ensure_loaded?/1` and keep it compiling without them.
- Read configuration at runtime (`Application.get_env/3` inside a function), not in a module
  attribute. Credo's `ApplicationConfigInModuleAttribute` check enforces this.
- Don't add a runtime dependency without a strong reason. Every dependency becomes every user's
  dependency.

Maintainers are volunteers and most traffic is automated (Dependabot, the common-config sync,
release PRs). Keep changes small, focused, and easy to review. A tight fix with a test beats a broad
refactor.

## Files you must not hand-edit

- **Files starting with `This file is synced with beam-community/common-config`** are overwritten on
  every sync. This includes this file, `CLAUDE.md`, `.credo.exs`, `.formatter.exs`,
  `.commitlintrc.yml`, `.tool-versions`, everything under `.github/workflows/`, and the skills under
  `.claude/skills/` and `.agents/skills/`. Propose changes in
  [beam-community/common-config](https://github.com/beam-community/common-config) instead. A repo
  can stop receiving a file by listing it under `ignore-files` in `.github/common-config.yaml`.
- **`CHANGELOG.md`, the `version` in `mix.exs`, and version strings in `README.md`** are owned by
  Release Please. They update when the release PR merges. Never bump them in a feature PR.
- **`mix.lock`** changes only as a side effect of a `mix.exs` dependency change (`mix deps.get` /
  `mix deps.update <dep>`). Don't regenerate it wholesale.

## Before you call work done

CI runs each of these as a separate job and fails on any of them. Run them locally first:

```bash
mix deps.get
mix format                          # CI: mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test
mix deps.unlock --check-unused
mix dialyzer                        # slow on the first run while it builds the PLT
```

CI tests a matrix of Elixir and OTP versions (see the `Test` job in `.github/workflows/ci.yaml`).
That matrix, not the `elixir:` requirement in `mix.exs`, is what is actually verified, so don't use
a standard-library function newer than its oldest Elixir version without a fallback.

Tests need running services:
- PostgreSQL 16 on `localhost:5432` (user `postgres`, password `postgres`)

If they aren't available, say so instead of skipping or deleting the tests that need them.

## Code conventions

Formatting and most style rules are enforced by tooling. Don't fight it, and don't restate it in
review comments.

- **Formatter**: 120-character lines. Always run `mix format` rather than hand-formatting.
- **Credo strict**: the rules that most often trip up new code are
  - `StrictModuleLayout`: `@moduledoc`, `@behaviour`, `use`, `import`, `require`, `alias`, in that
    order
  - `SinglePipe`, `PipeChainStart`, `BlockPipe`, `NestedFunctionCalls`: no one-step pipes, start a
    pipe with a plain value, no piping into blocks, no `f(g(h(x)))` nesting
  - `AliasOrder` (alphabetical) and `AliasUsage` for deeply nested modules
  - `TagTODO` fails the build. Don't leave `TODO` comments; open an issue instead
  - `UnsafeToAtom`: never `String.to_atom/1` on external input; use `String.to_existing_atom/1`
  - `IoInspect` / `IExPry`: remove debugging calls before committing
- **Docs**: public modules and functions get `@moduledoc` / `@doc`, with examples (ideally doctests)
  where they help. Internal ones get `@moduledoc false` / `@doc false`.
- **Typespecs**: add `@spec` to public functions. Dialyzer runs in CI.
- **Comments**: default to none. Comment only what the code can't say: a non-obvious constraint, why
  a surprising choice was made, or a workaround with a link. Don't narrate the code or describe what
  changed in this PR; that belongs in the commit message.
- **Match the surrounding code.** These projects span a decade of Elixir. Follow the conventions of
  the file you're in over your own preferences.

## Testing

- Tests live in `test/`, mirroring `lib/`. Shared helpers go in `test/support/` (compiled in the
  test environment via `elixirc_paths`).
- Every bug fix gets a test that fails without the fix. Every feature gets tests for its documented
  behavior.
- Prefer `async: true`. Use `async: false` only for tests that touch global state (application env,
  named processes, the filesystem), and say why when it isn't obvious.
- Don't delete, skip, or loosen an existing test to make a change pass. If a test is wrong, explain
  why in the PR.

## Commits and pull requests

Commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/), enforced by
commitlint (header up to 100 characters):

```text
<type>(<optional scope>): <description>
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
`revert`. Add `!` (`feat!:`) for a breaking change.

PRs are **squash-merged**, so the PR title becomes the commit on `main` that Release Please reads.
`feat` triggers a minor release, `fix` a patch, `!` a major. Choose the type by what the change means
to users of the project, not by how much code moved:

- `fix:` for a bug users can hit; `feat:` for new user-facing capability
- `refactor:`, `test:`, `docs:`, `ci:`, `build:`, `chore:` don't release on their own
- Dependency bumps are `chore(deps):`, unless the bump fixes a user-facing problem (`fix(deps):`)

Keep commit messages short. The subject is the deliverable; a body, if any, explains *why*. Don't
inventory the diff.

## Skills

Task workflows that ship with every BEAM Community repo, in `.claude/skills/` (mirrored to
`.agents/skills/` for other agents):

- `pull-request`: run CI's checks locally, then open a PR against `main`. Optionally babysit it
  through review and CI.
- `incorporate-feedback`: address review comments on the current PR, reply, and resolve threads.
- `pr-review`: review a PR the way a senior maintainer would.
