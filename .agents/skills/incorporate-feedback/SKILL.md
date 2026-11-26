---
name: incorporate-feedback
description: Review and incorporate valid, actionable review feedback on the current branch's pull request. Fetches top-level and inline comments, fixes the clear ones, asks about the debatable ones, replies, and resolves settled threads. Use when the user asks to address, handle, or respond to PR comments or review feedback, and when /pull-request babysit hands off a feedback round.
argument-hint: "[optional context]"
# This file is synced with beam-community/common-config. Any changes will be overwritten.
# Model invocation is allowed so /pull-request babysit can delegate feedback rounds to this skill.
---

Review and incorporate valid feedback from the current pull request.

## Steps

1. **Identify the PR**
   - Run `gh pr view --json number,url,title,headRepositoryOwner,isCrossRepository` to get the current branch's PR
   - If no PR exists, tell the user and stop

2. **Check for merge conflicts.** _Babysit mode only_ (the invocation context says it came from `/pull-request babysit`). Resolve conflicts against `main` before touching feedback, so changes land on top of the merged tree. See [Merge conflicts](#merge-conflicts). When the babysit loop already merged this iteration, this step is a no-op.

3. **Fetch all review comments**
   - `gh pr view --json reviews,comments` for top-level PR comments and review bodies
   - `gh api repos/{owner}/{repo}/pulls/{number}/comments` for inline review comments
   - Focus on unresolved comments and actionable feedback
   - Drop the noise described in [What isn't feedback](#what-isnt-feedback) before categorizing anything

4. **Categorize each comment**
   - **Clear and actionable**: an obvious improvement (a typo, a missing error clause, a correctness bug, a missing test, a straightforward refactor, a docs fix). Plan to incorporate these without asking.
   - **Ambiguous or debatable**: a style preference, an API design suggestion, a request that would change public behavior, an unclear ask, or anything with several valid responses. These need user input.

   Treat a suggestion that changes the library's public API (function signatures, return shapes, option names, defaults) as debatable even when it sounds simple. It decides the release type and whether the PR becomes a breaking change.

5. **Ask the user about ambiguous feedback.** Skip this step if the invocation context says not to block on user input (for example, `/pull-request babysit`): handle only the clear bucket, reply to ambiguous comments asking the reviewer to clarify or explaining the tradeoff, and list them in the final summary. Otherwise, for each ambiguous comment (or batch of related comments), ask the user a question that includes:
   - A brief quote or summary of the reviewer's comment
   - Concrete options for addressing it (e.g., "Rename the option as suggested and keep the old name as a deprecated alias", "Add a doc note explaining the current behavior")
   - An **"Ignore this feedback"** option, always included so the user can decline
   - Batch related comments into a single question where possible

6. **Make changes** for the feedback you're incorporating, then run the same checks CI runs and fix anything the changes broke:

   ```bash
   mix format
   mix compile --warnings-as-errors
   mix credo --strict
   mix test
   ```

   Add `mix dialyzer` when the change touches typespecs or function contracts, and `mix deps.unlock --check-unused` when it touches dependencies.

7. **Respond to every comment**
   - **Incorporated**: confirm the change (e.g., "Done, it returns `{:error, :timeout}` now")
   - **Declined by the user's choice**: a clear, respectful explanation based on the user's reasoning (e.g., "Keeping this as-is because it would be a breaking change for 2.x users")
   - **Incorporated with the user's own approach**: describe what was done and why
   - Reply to an inline comment with `gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies -f body='...'`
   - Many reviewers here are volunteers and community contributors. Keep replies short, friendly, and specific.

8. **Resolve settled threads.** After replying, resolve every inline thread the reply finishes. See [Resolving threads](#resolving-threads).

9. **Commit and push** if changes were made:
   - Use conventional commit format, scoped to what changed (e.g. `fix(parser): handle empty input`). Use `fix: incorporate PR feedback` only when the round is a grab bag.
   - Keep the body to the why, if anything. The replies on the PR already record what was addressed, so don't inventory them in the commit.
   - `git push`. If the PR comes from a fork, push to the fork's branch (the PR's head), not to `origin` in the upstream repo.

10. **Summary.** Report what was changed, what was declined, and what was left open (threads waiting on a reviewer or user answer), with reasoning.

## What isn't feedback

Some of what review bots post is scaffolding, not a request. Drop it before categorizing: don't act on it, don't reply to it, don't count it in the summary.

**Bot-suppressed comments.** Some review bots (Copilot among them) embed comments they decided _not_ to post in a collapsed block in the review body, with a summary like `Comments suppressed due to low confidence (N)` or `Suppressed comments (N)`. Match the concept, not the exact string. The bot withheld these deliberately and no thread exists for them, so there is nothing to reply to. If something in there looks like a genuine defect, mention it to the user in your summary and let them decide. Acting on suppressed comments is how a feedback round turns into an unbounded rewrite.

A bot's **posted inline comments** are real feedback. Categorize and handle those normally.

**Other boilerplate**: review overview summaries, per-file summary tables, tips and footers, and automated comments from the common-config sync or Release Please. Descriptive, not actionable.

## Resolving threads

Resolve a thread once the exchange is over: you made the change, or you replied with a final decision, and nothing is left for the reviewer or the user to weigh in on.

**Leave open:**

- Threads where you asked the reviewer to clarify (you're waiting on an answer)
- Ambiguous feedback still pending a user decision
- Work deferred to a follow-up, unless the reply links the issue or PR that carries it
- Anything you replied to but couldn't fully address

Top-level PR comments and review summaries aren't threads and can't be resolved. Skip them.

Fetch the threads. GraphQL doesn't expand `{owner}`/`{repo}` the way `gh api` does for REST, so pass them explicitly:

```bash
read -r OWNER REPO <<<"$(gh repo view --json owner,name -q '.owner.login + " " + .name')"

gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$pr){
      reviewThreads(first:100){
        nodes{
          id
          isResolved
          isOutdated
          path
          comments(first:1){ nodes{ databaseId author{login} body } }
        }
      }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F pr=<number> \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)'
```

The first comment's `databaseId` is the REST comment id you replied to. Use it to map each reply to its thread `id` (`PRRT_...`), which is what the mutation takes:

```bash
gh api graphql -f query='
mutation($threadId:ID!){
  resolveReviewThread(input:{threadId:$threadId}){ thread{ isResolved } }
}' -f threadId=PRRT_...
```

Reply first, then resolve. Resolving collapses the thread, and a resolution with no reply reads as feedback ignored. Resolving needs write access to the repository; if it fails, leave the thread open and mention it in the summary.

## Merge conflicts

Babysit mode only. A conflicting PR can't merge and every later CI run is wasted, so clear it before doing feedback work.

**Detect** with `gh pr view --json mergeable,mergeStateStatus`:

- `CONFLICTING`: resolve, below
- `UNKNOWN`: GitHub is still computing. Wait a few seconds and re-check once; if it's still unknown, leave it for the next babysit iteration
- `MERGEABLE`: nothing to do

**Resolve with a merge, not a rebase.** Babysit never force-pushes, so take `main` into the branch. PRs are squash-merged, so the merge commit never reaches `main`'s history.

- `git fetch origin main` (use the upstream remote if `origin` is a fork)
- `git merge origin/main`
- Resolve one file at a time (`git diff --name-only --diff-filter=U`): read the file, understand both sides, and apply a resolution that preserves the intent of each. Never blanket-pick `--ours`/`--theirs` on source files.
  - `mix.lock`: take `main`'s copy (`git checkout --theirs mix.lock`), then run `mix deps.get` to re-add anything this branch's `mix.exs` needs
  - `CHANGELOG.md` or the `mix.exs` version: take `main`'s copy. Release Please owns them and this branch shouldn't touch them
  - Migrations under `priv/`: keep both; they're additive and conflicts are almost always an ordering artifact. Two migrations altering the same column is a stop-and-ask.
- `git add <file>`, then commit the merge (`chore: merge origin/main`)
- Re-run `mix compile --warnings-as-errors` and `mix test`. A clean textual merge can still break when both sides changed related code
- `git push` (no `--force`)

**When to stop instead.** If the conflict needs a judgment call you can't make (both sides rewrote the same logic incompatibly, or resolving it means choosing between two intended behaviors), run `git merge --abort`, post a PR comment saying the branch conflicts with `main` and needs a human, report to the user, and end the babysit loop. Never leave the working tree mid-merge.
