# make-goal

A [Claude Code](https://claude.com/claude-code) skill that turns a rough goal into a **condition-driven contract** for Claude Code's native `/goal` loop.

`/goal` is a while-loop: keep working until a completion condition is demonstrably true. The hard part is writing a condition that actually *terminates* — one whose "done" state resolves to text the running agent prints, because the `/goal` evaluator reads conversation text only (it cannot run tools or read files). `make-goal` interviews you, then writes that contract for you.

## What it produces

From a rough goal, the skill writes three files into `.goal/` in your working directory (two if you decline the claims file):

- **`.goal/<slug>.json`** — the contract. Describes *what ends the loop*, never a task list. Key parts:
  - `done_when` — checkable end states, each carrying its own proof phrase (e.g. *"proven by printing the final line of `npm test` showing exit 0"*).
  - `operating_mode` — the running agent acts as an orchestrator, delegating each iteration to 2–5 subagents and maintaining an iteration ledger plus a claims file.
  - `bound` — an OR-termination clause so the loop is guaranteed to stop.
- **`.goal/<slug>.ledger.json`** — a bootstrapped ledger the running agent appends to, one entry per iteration.
- **`.goal/<slug>.claims.json`** — the campaign's key claims (typically 5–15), maintained every iteration. Each claim carries a provenance of `verified` (evidence cites a checkable artifact surfaced in the conversation), `inherited` (an external source named — including a subagent report you did not re-verify), or `inferred` (reasoning only) — lookups against the campaign record, not confidence scores. A `review_first` queue names up to 3 claims to check first (at least one by the end), weakest support foremost, and `next_verification` names the most valuable check not yet performed. The file exists to route a reviewer's attention.

Then it prints the exact command to start the loop:

```
/goal @.goal/<slug>.json
```

## Install

Copy `SKILL.md` into a `make-goal` directory under your Claude Code skills folder:

```bash
mkdir -p ~/.claude/skills/make-goal
cp SKILL.md ~/.claude/skills/make-goal/SKILL.md
```

## Usage

Inside Claude Code:

```
/make-goal <rough goal description>
```

Rough is fine — the skill runs a short interview to fill any missing pieces (goal type, measurable end state, proof, guardrails), applies sensible defaults (2–5 subagents per iteration, at least 3 iterations, stop after 9 turns, plus a running claims file), does an evaluator dry-run to confirm the condition is judgeable from text, and asks for your approval before writing anything.

You can also hand it a fully pre-written condition — it still wraps it in the contract schema, validates it, and runs the dry-run.

## Example contract (excerpt)

```json
{
  "goal": "Refactor src/auth into modules each under 200 lines",
  "type": "deterministic",
  "done_when": [
    "Every file in src/auth is under 200 lines, proven by printing the output of `wc -l src/auth/*`.",
    "The test suite passes, proven by printing the final line of `npm test` showing exit 0.",
    "The final turn prints the complete contents of .goal/auth-refactor.claims.json via cat, showing: non-empty goal and slug; at least 1 entry in claims; every entry's provenance one of verified/inherited/inferred; every verified or inherited entry with non-empty evidence, each verified entry's evidence citing an identifier that appeared earlier in this conversation; review_first naming 1–3 existing claim ids; next_verification naming one concrete check.",
    "This turn prints the LEDGER digest — a header line reading iterations N/3 with N ≥ 3, one roster line per completed iteration each naming a non-empty 'new', and the current iteration's full JSON entry — showing at least 3 completed iterations."
  ],
  "guardrails": ["Do not modify any file outside src/auth/."],
  "bound": "OR: the printed digest's header shows 9 completed iterations. In that case print the digest, the complete claims file via cat, and a gap report listing every unmet done_when item, then stop — this counts as bounded termination."
}
```

## License

[MIT](LICENSE)
