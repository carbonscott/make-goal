# make-goal

A [Claude Code](https://claude.com/claude-code) skill that turns a rough goal into a **condition-driven contract** for Claude Code's native `/goal` loop.

`/goal` is a while-loop: keep working until a completion condition is demonstrably true. The hard part is writing a condition that actually *terminates* — one whose "done" state resolves to text the running agent prints, because the `/goal` evaluator reads conversation text only (it cannot run tools or read files). `make-goal` interviews you, then writes that contract for you.

## What it produces

From a rough goal, the skill writes four files into `.goal/` in your working directory (three if you decline the claims file):

- **`.goal/<slug>.json`** — the contract. Describes *what ends the loop*, never a task list. Key parts:
  - `done_when` — checkable end states, each carrying its own proof phrase (e.g. *"proven by printing the final line of `npm test` showing exit 0"*).
  - `operating_mode` — the running agent acts as an orchestrator, delegating each iteration to 2–5 subagents as the goal-cast directs, and maintaining an iteration ledger plus a claims file.
  - `bound` — an OR-termination clause so the loop is guaranteed to stop.
- **`.goal/<slug>.ledger.json`** — a bootstrapped ledger the running agent appends to, one entry per iteration.
- **`.goal/<slug>.goal_cast.md`** — how each iteration delegates: the budget, which model and effort each launch gets, and a guard that stops looping subagents. The default `basic` cast rates each task and picks from Opus medium/high/xhigh or Sonnet medium/high, while any launch that checks work stays fixed at Opus xhigh. For campaigns that need named roles, the skill proposes one of the casts in [`references/casts/`](references/casts/) (advisor-worker, implementer-runner, reviewer-fixer, actor-judge) and fills its numbers in for you.
- **`.goal/<slug>.claims.json`** — the campaign's key claims (typically 5–15), maintained every iteration. Each claim carries a provenance of `verified` (evidence cites a checkable artifact you surfaced yourself — a SHA, a PR number, output you printed from your own run), `inherited` (the evidence you hold is a report rather than the artifact: an external source, or a subagent's account of its own work), or `inferred` (reasoning only) — lookups against the campaign record, not confidence scores. The reviewer derives their own queue from the tags — `inferred` and `inherited` claims first. The file exists to give the reviewer a provenance record to triage.

Then it prints the exact command to start the loop:

```
/goal work until all done_when conditions are met in @.goal/<slug>.json
```

Or say **launch** (or "write it and launch", or "launch auto" to pick a permission mode) and the skill starts the campaign for you with [`scripts/launch-tmux.sh`](scripts/launch-tmux.sh): a fresh Claude Code session in tmux session `goal-<slug>`, with Remote Control on and `/goal` as its first message. Attach with `tmux attach -t goal-<slug>`, or open the Remote Control session of the same name. The script never answers Claude Code's folder-trust prompt; if the folder isn't trusted yet, it tells you to attach and decide, and the campaign starts once you trust it. Without tmux, it prints the plain command instead.

## Install

Clone the repo into your Claude Code skills folder. The skill needs `references/` next to `SKILL.md`, so copy or link the whole directory:

```bash
git clone https://github.com/carbonscott/make-goal ~/.claude/skills/make-goal
```

## Usage

Inside Claude Code:

```
/make-goal <rough goal description>
```

Rough is fine — the skill runs a short interview to fill any missing pieces (goal type, measurable end state, proof, guardrails), applies sensible defaults (2–5 subagents per iteration, at least 3 iterations, stop after 9 turns, a running claims file, the `basic` goal-cast and the delegation guard), shows the delegation and model choice for you to confirm, does an evaluator dry-run to confirm the condition is judgeable from text, and asks for your approval before writing anything.

You can also hand it a fully pre-written condition — it still wraps it in the contract schema, validates it, and runs the dry-run.

## Example contract (excerpt)

```json
{
  "goal": "Refactor src/auth into modules each under 200 lines",
  "type": "deterministic",
  "done_when": [
    "Every file in src/auth is under 200 lines, proven by printing the output of `wc -l src/auth/*`.",
    "The test suite passes, proven by printing the final line of `npm test` showing exit 0.",
    "The final turn prints the complete contents of .goal/auth-refactor.claims.json via cat, showing: non-empty goal and slug; at least 1 entry in claims; every entry's provenance one of verified/inherited/inferred; every verified or inherited entry with non-empty evidence, each verified entry's evidence citing an identifier that appeared earlier in this conversation.",
    "This turn prints the LEDGER digest — a header line reading iterations N/3 with N ≥ 3, one roster line per completed iteration each naming a non-empty 'new', and the current iteration's full JSON entry — showing at least 3 completed iterations."
  ],
  "guardrails": ["Do not modify any file outside src/auth/."],
  "bound": "OR: the printed digest's header shows 9 completed iterations. In that case print the digest, the complete claims file via cat, and a gap report listing every unmet done_when item, then stop — this counts as bounded termination."
}
```

## License

[MIT](LICENSE)
