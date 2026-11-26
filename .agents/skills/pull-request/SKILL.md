---
name: pull-request
description: Open a pull request for the current branch against main after running CI's checks locally. Optionally babysit it, polling for review feedback and CI failures and addressing both until the PR has been quiet for an hour.
argument-hint: "[draft] [babysit] [yolo]"
disable-model-invocation: true
# This file is synced with beam-community/common-config. Any changes will be overwritten.
---

Open a pull request for the current branch against `main`.

## Arguments

`$ARGUMENTS` is a space-separated list of flags, in any order:

- `draft`: create a draft PR. If omitted, creates a regular PR.
- `babysit`: after the PR exists, enter [Babysit mode](#babysit-mode): poll for review comments and CI failures, address both, and stop once the PR has been quiet for an hour. Combines with `draft`.
- `yolo`: skip Step 3 (pre-flight checks) entirely. Combines with `draft` and `babysit`.

If `babysit` is passed and a PR **already exists** for the current branch (`gh pr view` succeeds), skip Steps 1 to 7 and go straight to Babysit mode. That is how each polling wake-up re-enters the skill, and it also lets you babysit a PR opened earlier.

### `yolo`

`yolo` is an explicit override: the user accepts an unverified PR. Honor it without arguing or "just quickly" running a check anyway.

- Don't run any of the Step 3 commands.
- Still do Steps 1, 2, and 4 to 7. The rebase, diff analysis, PR body, and creation happen as normal. If the rebase hits conflicts, still resolve them; `yolo` skips verification, not the merge.
- Note it in your final message to the user (one line, e.g. "Opened with `yolo`, pre-flight skipped"). Don't put it in the PR body.

## Steps

1. **Refuse to open from `main`.** If the current branch is `main`, stop and ask the user to create a branch.

2. **Rebase on `origin/main`** so checks run against the current base:
   - `git fetch origin main`
   - `git rebase origin/main`
   - If `origin` is your fork rather than the BEAM Community repo, use the upstream remote (usually `upstream`) in place of `origin` for every `main` reference in this skill
   - If there are conflicts, resolve them one file at a time: read the file, apply a resolution that preserves the intent of both sides, `git add <file>`, `git rebase --continue`.
     - `mix.lock`: take `main`'s copy (during a rebase that is `git checkout --ours mix.lock`), then `mix deps.get` to re-add what this branch's `mix.exs` needs
     - `CHANGELOG.md` or the `mix.exs` version: take `main`'s. Release Please owns them

3. **Pre-flight checks.** _Skipped if `$ARGUMENTS` includes `yolo`._ Run what CI runs, in this order, and fix any failure before continuing:

   ```bash
   mix deps.get
   mix format
   mix compile --warnings-as-errors
   mix credo --strict
   mix deps.unlock --check-unused
   mix test
   mix dialyzer
   ```

   `mix format` rewrites files; commit what it changed (`style: mix format`, or fold it into the relevant commit). `mix dialyzer` is slow the first time while it builds the PLT; let it finish rather than skipping it. If the test suite needs services (see `AGENTS.md`) that aren't running, say so in the final message rather than skipping silently.

4. **Analyze the changes**
   - `git log origin/main..HEAD --oneline` for the commits
   - `git diff origin/main...HEAD` for the full diff
   - Check whether the diff changes public API (documented functions, return shapes, options, raised exceptions). If it does, the title needs `!`. See [Choosing the title](#choosing-the-title).
   - Check the diff for files it shouldn't touch: anything with the `synced with beam-community/common-config` header, `CHANGELOG.md`, or the `mix.exs` version. If present, point it out and ask before opening.
   - Find the GitHub issue this branch addresses, if any. See [Linking the issue](#linking-the-issue).

5. **Draft the PR**
   - **Title**: a conventional commit under 70 characters. See [Choosing the title](#choosing-the-title).
   - **Body**: use `.github/pull_request_template.md` if the repo has one. Otherwise use the [default body](#default-body). If an issue was found, the reference goes on the first line.
   - Don't add labels. The `PR` workflow assigns them from the title.

6. **Push and create**
   - `git push -u origin HEAD`. If the rebase in Step 2 rewrote commits already on the remote, use `git push --force-with-lease`.
   - If you don't have push access to the repository, push to a fork instead (`gh repo fork --remote --remote-name fork`, then `git push -u fork HEAD`).
   - `gh pr create --base main --title '...' --body-file <file>`, adding `--draft` if requested. Write the body to a temp file outside the repo.

7. **Return the PR URL** to the user.

8. **If `$ARGUMENTS` includes `babysit`**, continue into Babysit mode. Otherwise you're done.

## Choosing the title

PRs are squash-merged, so the title becomes the commit on `main` that Release Please reads to decide the next version and write the changelog. Pick the type by what the change means to people using the project:

| Change | Title |
| --- | --- |
| Fixes a bug users can hit | `fix: ...` (patch release) |
| Adds user-facing capability | `feat: ...` (minor release) |
| Breaks public API or behavior | `feat!: ...` / `fix!: ...` (major release) |
| Internal refactor, tests, docs, CI, tooling | `refactor:` / `test:` / `docs:` / `ci:` / `build:` / `chore:` (no release) |
| Dependency bump | `chore(deps): ...`, or `fix(deps): ...` when it fixes a user-facing problem |

Commitlint enforces the allowed types (see `.commitlintrc.yml`). The description says what changed for the user, e.g. `fix: return 400 for invalid relationship linkage`. Case doesn't matter; Release Please sentence-cases the changelog.

## Linking the issue

If the branch addresses a GitHub issue, reference it on the first line of the body so GitHub links the two. Check these in order and stop at the first that yields a number:

1. **The session context.** The user named an issue, or one was being worked on earlier in this session.
2. **The branch name** (`git rev-parse --abbrev-ref HEAD`), e.g. `123-fix-parser` or `fix/123-parser`. A digit run that is part of a version or slug (`bump-elixir-1-19`, `v2-api`) is not an issue.
3. **The commit messages**: `#123`, `Fixes #123`, `Closes #123`.

Confirm the number with `gh issue view <n> --json number,title,state` before using it. If it doesn't exist, is a PR, or has nothing to do with the diff, treat the branch as having no linked issue. Never invent one.

Use `Fixes #123` when merging fully resolves the issue, and `Ref #123` for partial or related work. When unsure, use `Ref`: a wrongly auto-closed issue is worse than one that needs a manual close.

## Default body

```markdown
Fixes #123

### Summary

What this changes and why, in a few sentences. Lead with the user-visible effect.

### Breaking changes

Only if the title has `!`: what breaks for existing users and how they migrate.

### Testing

How the change was verified: tests added or updated, and anything checked by hand.
```

Drop the issue line and the breaking-changes section when they don't apply. Keep it short; reviewers here are volunteers.

## Babysit mode

A self-paced polling loop: each iteration checks the PR for new feedback and failing CI, handles what it finds, then schedules the next wake-up with the ScheduleWakeup tool. Every ScheduleWakeup call must pass the prompt `/pull-request babysit` verbatim so the next firing re-enters this skill.

If no scheduling tool is available, run a single iteration, report what you did, and tell the user to re-run `/pull-request babysit` (or use `/loop`) to continue.

### State file

Track loop state in `$(git rev-parse --absolute-git-dir)/pr-babysit-state.json`, inside the gitdir so it can never be committed. (`.git` is a file, not a directory, in a worktree; `--absolute-git-dir` resolves the real location either way.)

```json
{
  "pr": 123,
  "startedAt": "<ISO timestamp of loop start>",
  "lastActivityAt": "<ISO timestamp of the most recent handled comment or red CI>",
  "handledCommentIds": [456, 789],
  "ciFixAttempts": { "<check name>": 2 },
  "mainMergeCount": 0
}
```

On the first iteration (file missing, or `pr` doesn't match the current PR), initialize it with `lastActivityAt = startedAt = now`. Treat any absent field as its zero value.

### Each iteration

1. **Confirm the PR is still open**: `gh pr view --json number,state,mergedAt`. If merged or closed, report the final status, delete the state file, and stop without scheduling another wake-up.
2. **Check for merge conflicts**: `gh pr view --json mergeable,mergeStateStatus`. If `CONFLICTING`, resolve it first by following the Merge conflicts section of the `incorporate-feedback` skill: merge `origin/main` in, never rebase, since babysit doesn't force-push. Then set `lastActivityAt = now` and increment `mainMergeCount`. If `mainMergeCount` reaches **3**, stop: the branch is churning against a moving `main`, so post a PR comment saying so and report to the user.
3. **Check for new feedback**
   - `gh pr view --json reviews,comments` and `gh api repos/{owner}/{repo}/pulls/{number}/comments`
   - A comment is new if its id isn't in `handledCommentIds` and it isn't your own reply to earlier feedback.
   - If there are new comments, invoke the `incorporate-feedback` skill with the context `babysit mode: incorporate clear, actionable feedback; do NOT block on questions to the user. For ambiguous or debatable feedback, reply asking the reviewer to clarify (or explaining the tradeoff) and move on`. Then add every processed id to `handledCommentIds` and set `lastActivityAt = now`.
4. **Check CI**: `gh pr checks --json name,state,link`
   - **Failing** → set `lastActivityAt = now`, then:
     - Read the logs: `gh run view <run-id> --log-failed`
     - If it looks infrastructural (network timeout, Hex or GitHub outage, runner died) and unrelated to the diff, re-run once with `gh run rerun <run-id> --failed`. That doesn't count as a fix attempt.
     - Otherwise reproduce locally with the matching command (CI's jobs are named after them: Credo, Dependencies, Dialyzer, Format, Test), fix the root cause, run that check again, commit with a conventional message, and `git push`.
     - A failure on only one Elixir version in the test matrix usually means a newer-only stdlib function or a version-dependent behavior. Check before assuming flakiness.
     - Increment `ciFixAttempts[<check name>]`. If a check is still red after **3** attempts, stop: post a PR comment summarizing what was tried and report to the user.
   - **Pending** → not activity, but keep polling on the short interval.
5. **Quiet check**: if `now - lastActivityAt >= 1 hour`, CI is green, and there are no unhandled comments, the PR has been quiet for an hour. Post a short wrap-up comment only if the loop actually did something, report a summary to the user, delete the state file, and stop.
6. **Schedule the next wake-up** (only if not stopped), always with the prompt `/pull-request babysit`:
   - CI running, or activity this iteration → `delaySeconds: 480`
   - Otherwise (quiet, waiting out the hour) → `delaySeconds: 1200`
   - Give a specific `reason`, e.g. "watching PR #123: CI running" or "PR #123 quiet 40m/60m".

### Babysit rules

- Never force-push during babysit. Rebasing is for PR creation only.
- `yolo` applies to PR creation only. A fix pushed while babysitting gets its relevant check run first.
- Commits made while babysitting use conventional commit format.
- If `git push` is rejected because the remote moved, `git pull --rebase` and retry once. If it still fails, stop and report.
- Every iteration ends in exactly one of: a scheduled wake-up, or a final report to the user. Never end an iteration silently.
