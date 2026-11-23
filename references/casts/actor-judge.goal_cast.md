<!-- goal-cast — actor-judge: refine a taste-shaped artifact until a
     cold judge scores it above a bar. Loop per round: act → gate → judge →
     distill. Rules only; the rationale, the family table and the
     reducibility notes are in the pre-compaction version in goal-campaign-examples (git log -p).
     Use when: quality is taste-shaped (figure, doc, prompt, UI, image);
     a cheap deterministic check can reject it (renders, builds, runs);
     a judge can score it cold against fixed references or a rubric.
     Two hard rules that never collapse: (1) the judge never shares context
     with the actor or the trajectory; (2) whoever produced the artifact
     does not score it. Everything else may fold into the orchestrator.
     Usage: /make-goal reads this file only when this cast is selected,
     fills the [slots] and writes the block to .goal/<slug>.goal_cast.md.
     A single bracketed value is the default, and
     [pick one: a|b] is chosen once for the whole campaign. The
     orchestrator picks the Workflow or Agent tool per launch. To pin a
     per-launch role, swap model="per launch" for fixed values, e.g.
     <worker name="actor" model="opus" effort="xhigh" count=...>.
     Iteration and delegation budgets live in <delegation> inside the block.
     Not campaign-specific. -->

<goal-cast>

<delegation>
[3–9] rounds, one per iteration. [2–5] delegations in an ordinary round:
actors [1-3], gate [0-1], judges [1] per gated candidate, strategist [0-1]
on a stalled round.
</delegation>

<model-choice>
Roles marked model="per launch": before every launch, rate the task's
complexity and pick from [Opus medium/high/xhigh, Sonnet medium/high] to
match it, with no default. Log the rating and choice in the ledger for
each launch.
The judge, gate and strategist check the actors' work or your steering, so
their model and effort are set up front and you never change them, up or
down: choosing a checker's strength per launch is a lever on the check.
The judge panel is fixed in bootstrap for the same reason. A fixed judge
also keeps scores comparable across rounds.
</model-choice>

<orchestrator>
You orchestrate and, by default, hold GATE, DISTILL and STEER. You never
write the artifact and never score it. Each iteration = one round: brief
the actor(s), gate their commits, judge what passes, distill, ledger,
scoreboard. Use the Workflow or Agent tool as fits, your call per launch;
a launch with a set effort goes through a tool that takes effort.

Bootstrap, iteration 1, before any actor runs:
(a) Fix the references or rubric ([path or rubric]), the bar ([bar]) and
    the plateau rule ([k] rounds without the champion improving). Never
    edit them afterwards.
(b) Name the gate command ([gate command]) and its mechanical rules:
    non-blank output, uses [required library or API], not [forbidden
    substitutes], under [size cap].
(c) Record the pre-campaign HEAD SHA. Everything lands on [campaign
    branch], nothing on main.
(d) Fix the judge panel: [1] judge per gated candidate, an N-judge noise
    panel, or one judge per rubric lens. Never change it afterwards, and
    never re-judge a candidate because its score disappointed.

Brief: each actor gets the goal (never reworded), its own block, the
champion (artifact path, gated-output path, commit SHA) with the judge's
directives, and the current lesson list. Nothing else — no drafts,
verdicts, ledger or narrative. Write COMPETE or COOPERATE, and why, in the
ledger before actors run; one actor is the default.

GATE: run it inline only when it is one command returning one PASS/FAIL
line per rule; otherwise delegate to the gate worker. A failed gate skips
the judge; the failed rule or first trace lines become that round's
lesson. Never fix the artifact yourself.

JUDGE stays cold: it gets the gated output and the references only — no
round number, previous score, directive, actor reasoning or your view.
If you suspect drift, re-judge the champion in the same round as a
control, unlabeled.

DISTILL: after each judged round REWRITE the lesson list — merge, drop
what the champion now satisfies, turn diagnoses into instructions, keep
under [12] lines; record before/after in the ledger. Drop a lesson or
rubric dimension unchanged for [2] rounds. If the list has grown three
rounds running, hand DISTILL to the strategist.

STEER: after each round choose revise, restart (same complaint recurred
[2] rounds), or stop (bar reached, or plateau rule). Never stop on a
feeling. Convene the strategist only on a stall.

Best-so-far: the scoreboard names the champion; the brief pulls from it.
A round replaces the champion only after you read its structured verdict.

Belief: you are the skeptic. Before believing a score check: gate ran on
the SHA the judge saw; the jump is plausible for the change made; the
judge scored the gated output, not source. Open raw logs only when a
score is suspect, and say so in the ledger. No round enters the
scoreboard without a SHA you can `git show`.

Bookkeeping: ledger, scoreboard rows, claims and lesson list written in
ONE tool call per round that prints only a one-line confirmation; never
re-read a file you just wrote. Keep tool output landing in your window
under [20k] tokens per round; whatever you read by hand over that is
delegated next round.
</orchestrator>

<worker name="actor" model="per launch"
        count="[1-3] per round, chosen by the orchestrator"
        cadence="every round, first; concurrent actors never share a
                 worktree, branch or commit">
The brief is your whole world: goal, champion with directives (or lessons
only, on restart), these instructions. Do not ask for history; report
what is missing instead.
COMPETING: one whole artifact under your candidate id; never blend with
siblings. COOPERATING: only the files or sections assigned to you.
Revising: address every directive, preserve the rest. Restarting: do not
rebuild the old draft from the lessons.
Before anyone runs it, state which directive you expect to move the
score and by roughly how much.
Commit on [campaign branch] (candidate branch
`<campaign-branch>-i<iter>-<candidate_id>` when several actors run)
under [artifacts/i<iter>/], message naming the round.
Return: SHA, artifact path, exact render/run command, your prediction,
directives NOT addressed and why, `git status --porcelain` clean. Do not
run the gate or score yourself.
</worker>

<worker name="gate" model="[pick one: opus|sonnet]" effort="[medium]"
        count="[0-1] per round — 0 when the orchestrator gates inline"
        cadence="after actors commit, before any judge">
Check out the SHA you were given; print `git rev-parse HEAD` and
`git status --porcelain`; run exactly: [gate command]. Apply the
mechanical rules verbatim (output exists, non-blank, uses [required
library or API] not [forbidden substitutes], under [size cap]), one
PASS/FAIL line each with evidence. No quality judgment, no fixing: on
failure report the error verbatim with the shortest repro and stop.
Commit the gated output or failing log under [results/i<iter>/gate/] on
the campaign branch. Return the SHA, output path and the PASS/FAIL lines
only — the log stays in your transcript and the commit.
</worker>

<worker name="judge" model="[opus]" effort="[xhigh]"
        count="the panel fixed in bootstrap, per gated candidate (an
               N-judge panel records median and spread); plus 1 control
               judgment of the champion on request"
        cadence="every gated round, after PASS; never on a failed round">
Score one artifact, cold. You receive the gated output, [path or rubric]
and this format — no round number, earlier score, directive or history;
do not ask for them. Score the output AS THE GATE PRODUCED IT; handed
source alone, refuse. With references judge PAIRWISE against [2] drawn
from the set; with a rubric, score each dimension before the total.
Return only:
  score: [0-10]
  pairwise: one line per reference — better / equal / worse, and why
  dimensions: one line per rubric dimension, if any
  directives: at most [3] concrete revisions naming property and
    direction; zero if nothing concrete would help
  not_assessed: what you could not see
Same input → same verdict. You do not decide what happens next.
</worker>

<advisor name="strategist" model="[opus]" effort="[xhigh]"
         count="[0-1] per round; zero is the default"
         cadence="only when the champion has not improved for [2] rounds
                  or the lesson list grew three rounds running">
You hold STEER and DISTILL for one round, cold, from a summary only:
scoreboard rows, current lesson list, last [2] verdicts' directives.
Return (1) revise / restart (name lessons to carry) / stop (directives
are filler or scores oscillate within judge noise — say which), with the
losing option's argument in one line; (2) the lesson list rewritten,
under [12] lines. Advise only; never brief the actor.
</advisor>

<discipline>
- Judge never shares context with actor or trajectory; producer never
  scores. These two never fold into anyone.
- Gate before pay: no judge on a failed gate; the row still goes on the
  scoreboard with gate FAIL and score blank.
- Best-so-far, never most-recent.
- Distill rewrites, never appends; under [12] lines after every round.
- References, bar and plateau fixed before round 1.
- Predict before you judge: the actor's expected gain is in the ledger
  before the gate runs.
- Parallel actors compete or cooperate, never both; competing candidates
  are never blended before judging.
- Git tracks everything; nothing uncommitted is gated or judged; nothing
  lands on main, nothing is force-pushed.
- One writer per scarce resource: own worktree per actor, gate writes
  only its results directory, only the orchestrator writes the lessons.
- Stop on [bar] or on [k] rounds without improvement — reported as a
  plateau, not a success.
- Final round: print every lesson that survived from first appearance to
  the end, as candidates for a future campaign's standing instructions.
</discipline>

<scoreboard>
Maintain [.goal/<slug>.scoreboard.tsv], tab-separated, append-only,
committed. Header (real tabs):
`iter\tcandidate_id\tcommit\tartifact\toutput\tgate\tpredicted\tscore\tpairwise\tcontrol\tdirectives\tlessons\tchampion\tprovenance\tnote`.
One row per candidate per round; gate FAIL rows have score blank;
`lessons` is the list's line count after distill; `champion` Y on at most
one row per round; `provenance` verified/inherited/inferred as in the
claims file. Never rewrite a past row — correct with a new row naming
the one it supersedes. Print the full table each turn while ≤[30] rows,
else header + champion row + this round's rows + `N rows total, full at
<path>`; final turn prints the whole file. Beneath it name the champion
(round, SHA, score vs bar, rounds since it moved vs [k]) and the full
lesson list.
</scoreboard>

</goal-cast>
