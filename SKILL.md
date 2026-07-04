---
description: "Interview the user and turn a rough goal into a condition-driven contract for Claude Code's native /goal loop — writes .goal/<slug>.json plus a bootstrapped ledger and prints the /goal command to run. Use when the user types /make-goal, says 'make a goal', 'write a goal contract', 'turn this into a /goal condition', or wants an orchestrated goal loop set up."
argument-hint: "[rough goal description]"
---

# Make-Goal — Condition-Driven Goal Contracts

Turn a rough goal into a contract for `/goal`, Claude Code's while-loop: keep working until a condition is demonstrably true. The contract describes *what ends the loop* — never a task list; discovering the decomposition is the job of the agent running the loop, which operates as an orchestrator delegating to subagents. The constraint shaping everything below: the /goal evaluator reads conversation text ONLY — it cannot run tools or read files — so every checkable state must resolve to text the running agent prints.

## Inputs

`$ARGUMENTS` is a rough goal description — possibly partial, possibly a complete pre-written condition.
- Parse it once against the interview slots below; mark each slot filled or missing. Ask only for missing slots.
- Empty `$ARGUMENTS` → all slots missing → full guided interview, opening with: *"What's the goal? Rough is fine — tell me in whatever shape it comes out."*
- A complete pre-written condition (slots 1–4 all detectable) → skip the questions, state the defaults veto line, wrap it in the contract schema. Never skip validation or the evaluator dry-run.

## Defaults

| Setting | Default |
|---|---|
| Subagents per iteration | min 2, max 5 |
| Iteration floor | 3 |
| Turn ceiling | 3 × floor (9) |

Apply automatically and state once for veto — "Defaults: 2–5 subagents per iteration, at least 3 iterations, stop after 9 turns — say the word for different numbers." Never ask about them as a question. If the user changes the floor without naming a ceiling, recompute ceiling = 3 × floor.

## Interview flow

Progressive Q&A. Ask only for missing slots, one at a time, in this order. Do not batch questions into a form. Do not rush to JSON.

### 1. Goal type
Filled when the args imply artifact end-states (tests, builds, file counts, "all X migrated") → `deterministic`, or learning/deciding language ("figure out", "compare", "should we", "investigate") → `exploratory`. Ambiguous → ask:
*"Is 'done' a state of artifacts — tests pass, files exist — or something learned or decided, like findings or a go/no-go?"*

### 2. Measurable end state
Filled when the args contain at least one checkable state: a number, an exit code, a named file with named content.
- Deterministic: *"What observably true statement ends this? A test result, a file count, a build exit code?"*
- Exploratory — offer the three shapes: *"Question-shaped (a findings file answers N named questions with evidence), decision-shaped (a go/no-go with rationale gets recorded), or budget-shaped (at least K hypotheses tested with verdicts) — which fits?"*

### 3. Proof
Filled when the args state how the end state is shown (e.g. "npm test exits 0").
*"How will the final turn show this in plain conversation text? The evaluator can't run tools or read files — it only sees what gets printed."*

### 4. Guardrails
Filled when the args contain a "without / only / don't touch" constraint, or the user has said none.
*"Anything that must not change along the way? Fine to say none."*

### 5. Numbers and slug
Never asked. State the defaults veto line. Derive the slug: lowercase kebab-case from the 2–4 most distinctive words of the goal, `[a-z0-9-]` only, stopwords stripped, max 40 chars — propose it as part of the draft.

## Contract schema — `.goal/<slug>.json`

JSON container, prose values. Key order is deliberate: `/goal @file` inlines the file text top-to-bottom as the condition, so loop semantics come first, checkable states before guardrails and the bound.

```json
{
  "goal": "Refactor src/auth into modules each under 200 lines",
  "type": "deterministic",
  "run": "Keep working across turns toward done_when below. After each turn, check done_when against what you have surfaced in this conversation — the evaluator reads conversation text only and cannot run tools or read files. If any item is not demonstrably met in surfaced text, continue, treating the unmet item as the next turn's directive. When all items are met, stop. Do not stop early on partial progress; do not exceed the bound. (In Claude Code, /goal automates exactly this loop.)",
  "operating_mode": {
    "role": "You are an orchestrator. Each iteration (= one turn): think about the next slice of work, decompose it, delegate to subagents via the Agent tool, then integrate. Doing small steps yourself is allowed; delegating is preferred. The decomposition is part of the deliverable.",
    "budget": "Delegate to at least 2 and at most 5 subagents per iteration.",
    "iterations": "Complete at least 3 iterations before done_when may be considered met, even if it appears satisfied earlier — use surplus iterations to verify and harden.",
    "ledger": "Maintain .goal/auth-refactor.ledger.json on disk, appending one entry per iteration: {n, thought, delegated: [{agent, task, model}], integrated, new, remaining}. 'new' must name a decision or artifact that did not exist before this iteration. At the end of EVERY turn, print the complete current ledger JSON verbatim in a fenced code block headed LEDGER. The goal evaluator reads conversation text only: a ledger that is not printed this turn does not exist, even if the file does."
  },
  "done_when": [
    "Every file in src/auth is under 200 lines, proven by printing the output of `wc -l src/auth/*`.",
    "The test suite passes, proven by printing the final line of `npm test` showing exit 0.",
    "The full ledger JSON is printed in this turn's output and shows at least 3 completed iterations, each with a non-empty 'new' field."
  ],
  "guardrails": ["Do not modify any file outside src/auth/."],
  "bound": "OR: the printed ledger shows 9 completed iterations. In that case print the ledger plus a gap report listing every unmet done_when item, and stop — this counts as bounded termination."
}
```

Field notes — substitute the user's real slug and numbers everywhere:
- `type` — the only enum: `deterministic` | `exploratory`. Drives interview branching; harmless to the evaluator.
- `run` — the portable preamble, verbatim from the example. It makes the file self-contained in harnesses without `/goal`.
- `operating_mode` — four prose strings: role, budget, iterations, ledger. Numbers appear here as prose only; their machine-readable copy lives in the ledger's `limits`, and both are written from the same slot values in the same Output step so they never drift.
- `done_when` — checkable end states only, each carrying its own proof phrase ("proven by printing …"). The LAST item is always the ledger-print item — it is how the floor and budget become evaluator-enforceable.
- `bound` — an OR-termination clause tied to the printed ledger's iteration count (the ceiling), so termination is also judgeable from text.

If the drafted contract is ≥ 4,000 characters, trim in this order: (1) guardrail prose, (2) shorten `run` to its minimal three sentences, (3) compress `role`, (4) tighten done_when wording. Never delete a checkable state, the ledger clause, or the ledger-print item. Still over → ask the user which done_when items to merge.

## Ledger schema — `.goal/<slug>.ledger.json`

Bootstrap exactly this shape (real values; `created` from `date -Iseconds`):

```json
{
  "goal": "Refactor src/auth into modules each under 200 lines",
  "slug": "auth-refactor",
  "contract": ".goal/auth-refactor.json",
  "created": "2026-07-04T20:45:00-07:00",
  "limits": { "subagents_min": 2, "subagents_max": 5, "min_iterations": 3, "max_turns": 9 },
  "iterations": []
}
```

Entries the running agent appends per iteration (the shape lives in the contract's ledger clause; shown here for reference):

```json
{
  "n": 1,
  "thought": "what this iteration is for and why",
  "delegated": [ { "agent": "Explore", "task": "map current src/auth structure", "model": "haiku" } ],
  "integrated": "what came back and how it was combined",
  "new": "one decision or artifact that did not exist before this iteration",
  "remaining": "what still blocks done_when"
}
```

## Evaluator dry-run

After the user approves the draft, before writing files:
1. Compose two short hypothetical end-of-turn outputs (invented, a few lines each, no tools run): **MET** — the proof text for every done_when item plus a printed ledger with ≥ floor iterations, each with non-empty `new`; **UNMET near-miss** — e.g. proofs present but the ledger shows one iteration too few, or one proof missing.
2. Role-play the /goal evaluator: judge each hypothetical using only its text against the drafted condition. Output met/not-met plus a one-line reason each.
3. Pass = MET judged met AND UNMET judged not met, with reasons citing the intended items.
4. Fail → name the ambiguous done_when item, revise its wording (typical fixes: add "proven by printing …", quantify a vague term), re-run. After two failed revisions, tell the user plainly that this proof is not judgeable from conversation text and needs a different observable.
5. Show both verdicts to the user in one short block alongside the final draft.

## Validation checklist

Run silently before showing the final draft; fix what you can, surface unresolved gaps to the user:
- done_when contains only checkable end states — no process verbs, no task steps.
- Every done_when item names a proof that is printable conversation text.
- Guardrails were considered: present, or the user explicitly said none.
- `bound` is present and tied to the printed ledger's iteration count.
- The ledger clause is in operating_mode AND mirrored as the last done_when item.
- The ledger `limits` numbers equal the prose numbers in the contract.
- Contract file < 4,000 characters — check mechanically with `wc -c` (a hard /goal limit; do not estimate).

Edge cases: no git repo is fine — `mkdir -p .goal` in the cwd, no repo check at all; a full pre-written condition in args still gets wrapped, the veto line, validation, and the dry-run; over 4,000 chars → trim priority above.

## Output

1. Show the drafted contract and the dry-run verdicts; wait for approval.
2. `mkdir -p .goal`. If `.goal/<slug>.json` OR `.goal/<slug>.ledger.json` already exists, never overwrite silently (an existing ledger may hold a run in progress) — ask: *"`.goal/<slug>.json` already exists — overwrite it, or write `<slug>-2` alongside?"* Version with the first free numeric suffix; contract and ledger always share the suffix.
3. Write both files from the same slot values in one step.
4. `wc -c` the contract; if ≥ 4,000, trim per the priority above and rewrite.
5. Finish by printing the exact command for the user to run — you cannot set the goal yourself:
   `/goal @.goal/<slug>.json`

$ARGUMENTS
