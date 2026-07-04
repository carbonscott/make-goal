# make-goal

A [Claude Code](https://claude.com/claude-code) skill that turns a rough goal into a **condition-driven contract** for Claude Code's native `/goal` loop.

`/goal` is a while-loop: keep working until a completion condition is demonstrably true. The hard part is writing a condition that actually *terminates* — one whose "done" state resolves to text the running agent prints, because the `/goal` evaluator reads conversation text only (it cannot run tools or read files). `make-goal` interviews you, then writes that contract for you.

## What it produces

From a rough goal, the skill writes two files into `.goal/` in your working directory:

- **`.goal/<slug>.json`** — the contract. Describes *what ends the loop*, never a task list. Key parts:
  - `done_when` — checkable end states, each carrying its own proof phrase (e.g. *"proven by printing the final line of `npm test` showing exit 0"*).
  - `operating_mode` — the running agent acts as an orchestrator, delegating each iteration to 2–5 subagents and maintaining an iteration ledger.
  - `bound` — an OR-termination clause so the loop is guaranteed to stop.
- **`.goal/<slug>.ledger.json`** — a bootstrapped ledger the running agent appends to, one entry per iteration.

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

Rough is fine — the skill runs a short interview to fill any missing pieces (goal type, measurable end state, proof, guardrails), applies sensible defaults (2–5 subagents per iteration, at least 3 iterations, stop after 9 turns), does an evaluator dry-run to confirm the condition is judgeable from text, and asks for your approval before writing anything.

You can also hand it a fully pre-written condition — it still wraps it in the contract schema, validates it, and runs the dry-run.

## Example contract (excerpt)

```json
{
  "goal": "Refactor src/auth into modules each under 200 lines",
  "type": "deterministic",
  "done_when": [
    "Every file in src/auth is under 200 lines, proven by printing the output of `wc -l src/auth/*`.",
    "The test suite passes, proven by printing the final line of `npm test` showing exit 0.",
    "The full ledger JSON is printed in this turn's output and shows at least 3 completed iterations, each with a non-empty 'new' field."
  ],
  "guardrails": ["Do not modify any file outside src/auth/."],
  "bound": "OR: the printed ledger shows 9 completed iterations. In that case print the ledger plus a gap report listing every unmet done_when item, and stop."
}
```

## License

[MIT](LICENSE)
