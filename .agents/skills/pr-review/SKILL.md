---
name: pr-review
description: Review a pull request in this repository the way a senior BEAM Community maintainer would. Use when reviewing a pull request, re-reviewing after the author pushes changes, or commenting on changed code. Reads beyond the diff into the code it calls, verifies every finding against the actual codebase before posting it, weighs public API and compatibility impact for Hex packages, challenges the approach when the evidence supports it, and writes short, casual, non-patronizing comments.
argument-hint: "[PR number or URL]"
# This file is synced with beam-community/common-config. Any changes will be overwritten.
---

# Code Review

Review pull requests the way a good senior maintainer would: read beyond the diff, verify every claim before making it, and keep comments short and casual.

## Getting the PR

- `$ARGUMENTS` is a PR number or URL. With no argument, review the current branch's PR (`gh pr view`).
- `gh pr view <n> --json title,body,author,baseRefName,headRefName,files,commits` for context, `gh pr diff <n>` for the change.
- Check the PR out (`gh pr checkout <n>`) when you need to read surrounding code, run tests, or reproduce something. Return to the original branch when you're done.
- `gh pr checks <n>` first. Don't review formatting, Credo, or compile warnings by hand: CI already enforces them. If CI is red, say which job and why in one line.

## What these repositories are

BEAM Community projects are mostly open-source libraries published to Hex and maintained by volunteers. Other people's applications depend on them, so the defects that hurt most are **breaking changes nobody flagged** and **behavior that silently differs across supported Elixir/OTP versions or optional dependencies**. Many contributors are first-timers from the community. Weight the review accordingly, and read `AGENTS.md` and `.agents/PROJECT.md` (if present) for this repo's conventions.

## Investigate beyond the diff

This is what separates a real review from diff-skimming, and it is the step to skip last, not first. Before writing any finding:

- **Read the code the diff calls into.** If the PR adds callers of existing functions, open those functions. Check what they return in the error case, what they raise, and what they assume about their inputs.
- **Check the blast radius of shared-code changes.** If the PR touches a widely used module, behaviour, protocol, or macro, find its other callers and implementations (`grep -rn` across `lib/` and `test/`). A macro change affects every module that `use`s it.
- **Verify factual claims in the PR description and in code comments.** If a comment says "this is the only caller" or "this can't be nil", grep and confirm. A verified claim is worth a short note of praise; a falsified one is a finding.
- **Think about existing users.** For a library, the callers that matter are not in this repo. Ask what an app on the previous release experiences after upgrading: changed return shapes, new exceptions, renamed options, changed defaults, new required config.
- **Run it when in doubt.** `mix test path/to/test.exs` or a quick `mix run -e '...'` settles a question faster than reasoning about it. Say when you ran something, and paste the command.

## Repository-wide checks

Run these against any diff that touches the relevant surface. Each is a real defect class in Elixir libraries, not a style preference.

**Public API changes.** Anything documented (no `@doc false` / `@moduledoc false`) is public. A changed name, arity, argument order, return shape (`{:ok, x}` vs `x`), raised exception, or option key is breaking. Breaking changes need a `!` in the PR title (the squash commit drives the release) and, where feasible, a deprecation path first. An unflagged breaking change is blocking.

**Version compatibility.** For Hex packages, CI tests the Elixir/OTP matrix in `.github/workflows/ci.yaml`. A standard-library function newer than the matrix floor breaks users on older versions. Check the function's `@doc since:` when unsure.

**Optional dependencies.** Code using a dependency marked `optional: true` must compile and behave when it is absent, typically behind `Code.ensure_loaded?/1` at compile time. A new hard reference to an optional dep is a compile failure for some users.

**New dependencies.** A new runtime dependency becomes every user's dependency. Ask whether it is needed, and check its version constraint isn't so tight it will conflict with common apps.

**Configuration.** Libraries read config at runtime, not compile time: `Application.get_env/3` in a module attribute (Credo flags it) or `Application.compile_env/3` for something users expect to change at runtime. Prefer options passed by the caller over global application env for new settings.

**Atoms from input.** `String.to_atom/1`, `List.to_atom/1`, or `:erlang.binary_to_atom/2` on external input leaks atoms until the VM crashes. Use `String.to_existing_atom/1` or an explicit mapping.

**Processes and concurrency.** `Task.async` over an unbounded collection is the Elixir version of an unbounded `Promise.all`: use `Task.async_stream/3` with `max_concurrency` and a `timeout`. Watch for a GenServer `call` that can block on slow I/O (it serializes every caller), processes started without supervision, and `:infinity` timeouts.

**Errors.** Prefer tagged tuples for expected failures and exceptions for programmer errors, matching what the module already does. A function that used to return `{:error, reason}` and now raises (or the reverse) is a breaking change. A `rescue` that swallows everything hides bugs; check what it actually catches.

**Docs and specs.** New public functions need `@doc` and a `@spec`, and the docs should match what the code does. A doctest that doesn't run (missing `doctest` line in the test module) is decoration.

**Release-owned and synced files.** `CHANGELOG.md`, the `mix.exs` version, and README version strings are owned by Release Please. Files with the `synced with beam-community/common-config` header are overwritten on every sync. Hand edits to either are a finding: point the author to the right place.

**Tests.** A bug fix needs a test that fails without the fix. `async: false` without an obvious reason (global state) slows the suite; `Process.sleep` in a test is usually a race waiting to happen.

## The bar for posting a finding

Post a finding only if you can name a concrete failure: specific input or state, and the wrong output, crash, or broken upgrade that results. If you cannot construct that scenario, you do not understand the code well enough to comment yet. Read more, or leave it out. That bar governs defects in the code as written. A challenge to the approach clears a different bar, described below.

Do not post:

- Findings that the diff's own surrounding lines already handle. Read the full function, not the hunk.
- Speculation hedged into a question ("could this be a problem if...?") where you have not checked whether it is.
- Restatements of what the code does, with no defect or cost attached.
- Anything the formatter, Credo, Dialyzer, or the compiler already catches in CI.
- Style preferences that no project convention supports.

Priority order, roughly: correctness bugs, unflagged breaking changes, compatibility breaks (Elixir/OTP versions, optional deps), approach problems that will be expensive to reverse, behavior changes outside the PR's stated scope, error handling that hides failures, missing tests, docs that disagree with the code, then nits. An approach problem outranks its own symptoms: if the shape is wrong, say that once instead of filing each consequence separately.

An empty review is a legitimate and useful outcome. If the PR is clean, say so plainly and do not pad it with invented findings. Clean means the approach holds up too, not just that nothing on a changed line broke.

## Challenging the approach

A review that only audits the code as written will approve a well-implemented bad idea. The other half of the job is the approach: the right API shape, the right place for the logic, whether this belongs in the library at all. Every review says something about it, even if only that the approach holds.

Questions worth asking on a library:

- Does this belong in the library, or is it one user's use case that could live in their app (or behind a behaviour or callback the library already exposes)?
- Is the new API consistent with the rest of the library's API, and with how the Elixir ecosystem usually does this (options keyword lists, `{:ok, _}` / `{:error, _}` tuples, bang variants)?
- Will this be hard to change later? New public functions and options are forever, or until a major version.
- Is there an existing function or module that already does most of this?

"The codebase already does it this way" is a strong argument when getting it wrong would fail loudly (a crash, a failing test). It is a weak one when the wrong version fails silently: a value quietly wrong, an error swallowed into `nil`, a config option ignored. In that case correct it even if this file becomes the odd one out, as long as the correct form is simple to reach for.

File the challenge at the tier its evidence supports, not the tier your conviction supports:

- **Nit.** A named convention, or nothing at all. One per review at most.
- **Worth discussing.** A mechanism, and the line in this diff where it applies. Say plainly what you have not verified.
- **Change before merge.** A reproduction (a failing test or `mix run` command you ran, pasted), a linked issue where this exact failure happened, or a concrete upgrade scenario traced through the code.
- **Blocking.** The tier above, plus an unflagged breaking change, a compatibility break, or data loss. Write the blocker in the review body and label it one.

If you did not run it, you do not cite it. Say what would unblock the PR, and name an alternative reachable from this diff. A block survives one round of pushback only if you can add evidence; if your only reply restates the concern, downgrade it. If the design predates the diff, mark it non-blocking unless this PR makes it more expensive to reverse. Expect zero approach challenges on a normal PR, and don't go hunting for one.

## Writing the comments

Tone matters as much as the findings. A correct comment that reads as generated gets skimmed and ignored, and a harsh one on a first-time contributor's PR may be the last PR they send.

- **Casual and easy to understand, never patronizing.** "Heads up, this changes the return shape for callers on 2.x" not "It should be noted that". No lecture, no filler.
- **Short.** Each comment: what's wrong, one concrete failure scenario, and a suggested direction. A few sentences, not paragraphs. A GitHub suggestion block is often the clearest way to propose a small fix.
- **Triage explicitly.** Distinguish pre-merge asks from "minor, take it or leave it" from "Nit:". Say "Not blocking" or "fine to punt on this" when it's true, and mean it.
- **Acknowledge intent before redirecting.** "Nice catch on the nil case, but..." Critique the tradeoff, not the author. Thank first-time contributors.
- **Anchor to the line the defect is on**, not the nearest line you're confident about. An approach challenge usually has no such line: put it in the review body, once.

Avoid the tells that make a review read as machine-written:

- No em-dashes. Use a comma, a period, or parentheses.
- No stock throat-clearing: "It's worth noting", "It should be mentioned", "Additionally", "Furthermore", "That said".
- No tidy rule-of-three constructions, no "not only X but Y".
- No buzzwords: "robust", "leverage", "seamless", "crucial", "delve".
- No emoji, no bolded lead-in labels inside comments ("**Issue:**"), no sign-offs.
- Vary sentence openers and comment length. Five identically shaped comments in a row read as generated even when each one is right.

## Posting

Unless the user asked you to post, present the review to them first: the summary and each finding with its `file:line`. When posting, use one review with inline comments rather than a string of separate comments:

```bash
gh api repos/OWNER/REPO/pulls/<n>/reviews --input review.json
```

where `review.json` has `commit_id` (the PR head SHA), `event` (`COMMENT`, or `APPROVE` when the user asks), a `body`, and `comments` entries of `{ "path", "line", "side": "RIGHT", "body" }`. Write the JSON to a temp file outside the repo. Don't use `REQUEST_CHANGES` unless the user asks; write blockers into the body instead.

## Re-reviewing after the author pushes

Diff only between the two review points (`git diff <last-reviewed-sha>..<new-head> -- <files the PR touches>`), so merged-in `main` noise stays out of the review.

Walk the prior comments one at a time and sort them into fully fixed, half-fixed, and unaddressed. An approach challenge the author answered with a rationale is a fourth outcome: say it is settled and drop it. Re-raising a point the author already answered, with no new evidence, is noise. Verify fixes rather than taking them on faith, then review the new code the fixes introduced with the same rigor as the first pass, since fix commits get less scrutiny than they earn.

Credit what actually landed, and briefly re-raise anything still open. If everything is addressed, say so and stop.
