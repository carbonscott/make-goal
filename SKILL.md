---
description: "Interview the user and turn a rough goal into a condition-driven contract for Claude Code's native /goal loop — writes .goal/<slug>.json plus a bootstrapped ledger and claims file and prints the /goal command to run. Use when the user types /make-goal, says 'make a goal', 'write a goal contract', 'turn this into a /goal condition', or wants an orchestrated goal loop set up."
argument-hint: "[rough goal description]"
---

# Make-Goal — Condition-Driven Goal Contracts

Turn a rough goal into a contract for `/goal`, Claude Code's while-loop: keep working until a condition is demonstrably true. The contract describes *what ends the loop* — never a task list; discovering the decomposition is the job of the agent running the loop, which operates as an orchestrator delegating to subagents. The constraint shaping everything below: the /goal evaluator reads conversation text ONLY — it cannot run tools or read files — so every checkable state must resolve to text the running agent prints.

## Scope — author, never execute

This skill's entire deliverable is three files — `.goal/<slug>.json`, its ledger, and its claims file — plus the `/goal @…` command for the **user** to run. **You never do the work the goal describes, regardless of how the args are phrased.** The goal text will often contain action verbs ("implement", "refactor", "merge it", "review with X", "work until it's done") and may read like a task list or a direct order. In this skill it is none of those: it is raw material for the contract's `done_when`. Treat it the way `/no-eager` treats a prompt — material to shape, not a request to act on this turn.

So while running this skill, do **not**: create branches or worktrees, edit code, run builds or tests to "make progress", open or review PRs, spawn agents to perform the goal, or otherwise advance the goal itself. Read-only inspection to author a sharper contract is fine (Read, Grep, Glob, read-only Bash). **If the goal is about *this* repo or skill, that is not an exception** — still only author the contract; the work happens later, when the user runs `/goal`.

One hard gate follows: **never write the `.goal/` files without the user's explicit approval of the drafted contract** (see Output). Draft, show, stop, wait.

## Inputs

`$ARGUMENTS` is a rough goal description — possibly partial, possibly a complete pre-written condition.
- Parse it once against the interview slots below; mark each slot filled or missing. Ask only for missing slots.
- Empty `$ARGUMENTS` → all slots missing → full guided interview, opening with: *"What's the goal? Rough is fine — tell me in whatever shape it comes out."*
- A complete pre-written condition (slots 1–4 all detectable) → skip the questions, state the defaults veto line, wrap it in the contract schema. Never skip validation, the evaluator dry-run, or the approval gate before writing files.

## Defaults

| Setting | Default |
|---|---|
| Subagents per iteration | min 2, max 5 |
| Iteration floor | 3 |
| Turn ceiling | 3 × floor (9) |

Apply automatically and state once for veto — "Defaults: 2–5 subagents per iteration, at least 3 iterations, stop after 9 turns, plus a closure claims file — say the word for different numbers or to drop the claims file." Never ask about them as a question. If the user changes the floor without naming a ceiling, recompute ceiling = 3 × floor.

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
    "ledger": "Maintain .goal/auth-refactor.ledger.json on disk, appending one FULL entry per iteration: {n, thought, delegated: [{agent, task, model}], integrated, new, remaining} — the file keeps every field. 'new' must name a decision or artifact that did not exist before this iteration. At the end of EVERY turn print a LEDGER digest (NOT the whole file): a header line `LEDGER auth-refactor — iterations N/3, full at .goal/auth-refactor.ledger.json` (N = completed-iteration count); then one roster line per completed iteration `n · delegated:k · new: <that iteration's non-empty new>` (k = subagents delegated that iteration); then the current iteration's full JSON entry in a fenced block. Only the printed report shrinks; the file loses nothing. The evaluator reads conversation text only: what this turn's digest does not show does not exist, even if the file does.",
    "claims": "Maintain .goal/auth-refactor.claims.json on disk — the campaign's key claims (typically 5–15), updated every iteration as claims land or change. Shape: {claims: [{id, provenance, evidence, claim}], review_first: [up to 3 claim ids, weakest support first — the reviewer's priority queue], next_verification: the single most valuable check not yet performed}. provenance is one of: verified — evidence cites a checkable artifact surfaced in this conversation (job id, PR#, SHA, printed output); inherited — evidence names the external source being trusted; inferred — reasoning only (evidence may describe partial support). Tags are lookups against the campaign record, never confidence scores. The final turn prints the complete file via cat."
  },
  "done_when": [
    "Every file in src/auth is under 200 lines, proven by printing the output of `wc -l src/auth/*`.",
    "The test suite passes, proven by printing the final line of `npm test` showing exit 0.",
    "The final turn prints the complete contents of .goal/auth-refactor.claims.json via cat, showing: at least 1 entry in claims; every entry's provenance one of verified/inherited/inferred; every verified or inherited entry with non-empty evidence, each verified entry's evidence citing an identifier that appeared earlier in this conversation; review_first naming only existing claim ids (up to 3); next_verification naming one concrete check.",
    "This turn prints the LEDGER digest — a header line reading iterations N/3 with N ≥ 3, one roster line per completed iteration each naming a non-empty 'new', and the current iteration's full JSON entry — showing at least 3 completed iterations."
  ],
  "guardrails": ["Do not modify any file outside src/auth/."],
  "bound": "OR: the printed digest's header shows 9 completed iterations. In that case print the digest, the complete claims file via cat, and a gap report listing every unmet done_when item, then stop — this counts as bounded termination."
}
```

Field notes — substitute the user's real slug and numbers everywhere:
- `type` — the only enum: `deterministic` | `exploratory`. Drives interview branching; harmless to the evaluator.
- `run` — the portable preamble, verbatim from the example. It makes the file self-contained in harnesses without `/goal`.
- `operating_mode` — five prose strings: role, budget, iterations, ledger, claims. Numbers appear here as prose only; their machine-readable copy lives in the ledger's `limits`, and both are written from the same slot values in the same Output step so they never drift.
- `claims` — the durable review artifact: key claims tagged by provenance (verified/inherited/inferred — operational lookups against the campaign record, never introspective confidence), ranked for the human reviewer. Default-on for both goal types; omit the clause, its done_when item, and the third file only if the user vetoes it.
- `done_when` — checkable end states only, each carrying its own proof phrase ("proven by printing …"). The claims item is always SECOND-TO-LAST and the ledger-digest item LAST — they are how the claims file, the floor, and the budget become evaluator-enforceable; a clause alone is optional prose.
- `bound` — an OR-termination clause tied to the printed digest's header iteration count (the ceiling), so termination is also judgeable from text.

**Delegation — effort needs the Workflow tool.** By default the contract delegates via the Agent tool (model override only), as the schema example's `role` shows — leave it. Reasoning **effort** (medium/max/…) is settable *only* via the Workflow tool, not the Agent tool. So only when the user's prompt asks for effort control (e.g. "medium scouts, one max-effort thinker") weave that into the `role` prose and add one sentence — *"The user's approval of this contract authorizes the Workflow tool for delegation"* — otherwise the orchestrator can't vary effort or even call Workflow (the harness requires explicit opt-in). Never ask about this in the interview; add no JSON/ledger/`done_when` fields — effort, if used, is just noted in the free-text `delegated` rows.

If the drafted contract is ≥ 4,000 characters, do not trim automatically — ask the user whether they want it trimmed under 4,000. The `/goal @file` form inlines the file and isn't hard-capped, so staying under 4,000 is a conciseness choice, not a requirement; if the user declines, keep the contract as drafted. If they agree, trim in this order: (1) guardrail prose, (2) shorten `run` to its minimal three sentences, (3) compress `role`, (4) tighten done_when and claims-clause wording. Never delete a checkable state, the ledger or claims clause, or the ledger-digest or claims done_when item. Still over after trimming → ask which done_when items to merge.

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

Entries the running agent appends per iteration — the file retains every field even though each turn prints only a digest of it (the shape lives in the contract's ledger clause; shown here for reference):

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

### Claims bootstrap — `.goal/<slug>.claims.json`

Bootstrap exactly this shape (the running agent fills it per the contract's claims clause):

```json
{ "claims": [], "review_first": [], "next_verification": "" }
```

## Evaluator dry-run

After the user approves the draft, before writing files:
1. Compose two short hypothetical end-of-turn outputs (invented, a few lines each, no tools run): **MET** — the proof text for every done_when item, a printed LEDGER digest whose header shows ≥ floor iterations with each roster line naming a non-empty `new`, plus a cat of the complete claims file with every entry tagged and every verified/inherited entry carrying evidence; **UNMET near-miss** — e.g. proofs present but the digest's header shows one iteration too few, or a roster line's `new` is empty, or one proof missing, or a `verified` claim entry with empty evidence.
2. Role-play the /goal evaluator: judge each hypothetical using only its text against the drafted condition. Output met/not-met plus a one-line reason each.
3. Pass = MET judged met AND UNMET judged not met, with reasons citing the intended items.
4. Fail → name the ambiguous done_when item, revise its wording (typical fixes: add "proven by printing …", quantify a vague term), re-run. After two failed revisions, tell the user plainly that this proof is not judgeable from conversation text and needs a different observable.
5. Show both verdicts to the user in one short block alongside the final draft.

Worked example to calibrate the two hypotheticals (auth-refactor, floor 3) — both exercise the digest form:

**MET** — header shows 3/3, every roster `new` non-empty, both proofs present, claims file printed:
```
LEDGER auth-refactor — iterations 3/3, full at .goal/auth-refactor.ledger.json
1 · delegated:2 · new: split login/session/token helpers out of auth.py
2 · delegated:2 · new: extracted password hashing into auth/hashing.py
3 · delegated:2 · new: moved middleware into auth/guards.py; every file now <200 lines
```
```json
{ "n": 3, "thought": "carve out the final module and re-verify", "delegated": [ { "agent": "general-purpose", "task": "move middleware + decorators into auth/guards.py", "model": "sonnet" }, { "agent": "general-purpose", "task": "re-run wc -l and npm test to confirm", "model": "sonnet" } ], "integrated": "all src/auth files <200 lines; npm test exit 0", "new": "moved middleware into auth/guards.py; every file now <200 lines", "remaining": "none" }
```
```json
{
  "claims": [
    { "id": "C1", "provenance": "verified", "evidence": "wc -l and npm test outputs printed this turn", "claim": "all src/auth files <200 lines, tests passing" },
    { "id": "C2", "provenance": "inferred", "evidence": "grep found no callers outside src/auth", "claim": "the split changed no public API" }
  ],
  "review_first": ["C2"],
  "next_verification": "run the integration suite, not just unit tests"
}
```
`wc -l src/auth/*` → every file <200; `npm test` → exit 0. Verdict: **MET** — floor 3/3, each roster `new` non-empty, both proofs present, claims file complete with every entry tagged and evidenced.

**UNMET near-miss (claims)** — same outputs, but C1's evidence is empty while still tagged `verified`:
```json
{ "id": "C1", "provenance": "verified", "evidence": "", "claim": "all src/auth files <200 lines, tests passing" }
```
Verdict: **not met** — a verified entry must carry non-empty evidence citing an identifier from this conversation; the tag without the lookup fails the claims item even though every proof passes.

**UNMET near-miss (ledger)** — same proofs, but iteration 3's roster `new` is empty (a padded iteration that did nothing):
```
LEDGER auth-refactor — iterations 3/3, full at .goal/auth-refactor.ledger.json
1 · delegated:2 · new: split login/session/token helpers out of auth.py
2 · delegated:2 · new: extracted password hashing into auth/hashing.py
3 · delegated:0 · new:
```
Verdict: **not met** — header reads 3/3 but iteration 3 names no `new`; the per-iteration non-empty-`new` rule fails even though both proofs pass. (A header of 2/3 would fail the floor the same way.)

## Validation checklist

Run silently before showing the final draft; fix what you can, surface unresolved gaps to the user:
- No work toward the goal itself was performed — only the contract was authored (see Scope).
- done_when contains only checkable end states — no process verbs, no task steps.
- Every done_when item names a proof that is printable conversation text.
- Guardrails were considered: present, or the user explicitly said none.
- `bound` is present and tied to the printed digest's header iteration count.
- The ledger clause is in operating_mode AND mirrored as the last done_when item.
- The claims clause is in operating_mode AND mirrored as the second-to-last done_when item (unless the user vetoed the claims file).
- The ledger `limits` numbers equal the prose numbers in the contract.
- Contract size checked mechanically with `wc -c` (do not estimate) — if ≥ 4,000 characters, the user is asked whether to trim (not a hard limit; `/goal @file` isn't capped).

Edge cases: no git repo is fine — `mkdir -p .goal` in the cwd, no repo check at all; a full pre-written condition in args still gets wrapped, the veto line, validation, and the dry-run; over 4,000 chars → ask the user whether to trim (never auto-trim).

## Output

1. Show the drafted contract, the bootstrapped ledger, the bootstrapped claims file, and the dry-run verdicts in the conversation, then **STOP and wait for the user's explicit approval** before writing anything. Explicit means a clear go-ahead ("yes", "go", "write it"); a question, silence, a partial reaction, or "looks good but…" is not approval — refine and ask again. Do not run `mkdir` or write any file until you have it.
2. **Only after that explicit approval:** `mkdir -p .goal`. If `.goal/<slug>.json` OR `.goal/<slug>.ledger.json` OR `.goal/<slug>.claims.json` already exists, never overwrite silently (an existing ledger may hold a run in progress) — ask: *"`.goal/<slug>.json` already exists — overwrite it, or write `<slug>-2` alongside?"* Version with the first free numeric suffix; all three files always share the suffix.
3. Write all three files from the same slot values in one step.
4. `wc -c` the contract; if ≥ 4,000, tell the user the count and ask whether they want it trimmed under 4,000 — optional, since `/goal @file` isn't hard-capped. Only if they agree, trim per the priority above and rewrite; otherwise leave it as written.
5. Finish by printing the exact command for the user to run — you cannot set the goal yourself:
   `/goal @.goal/<slug>.json`

$ARGUMENTS
