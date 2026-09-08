#!/bin/sh
# gate_debug.sh — the tracing debugger (debug_eval.la), track C.
#
# WHAT IS ACTUALLY AT RISK HERE, and therefore what this gate is about:
# DEBUG_EVAL cannot WRAP EVAL — EVAL's recursion is internal (Z(la self. …)),
# so an outer wrapper observes only the outermost node and nothing beneath it.
# The tracer must BE the self EVAL would have used, so it REPRODUCES EVAL's
# dispatch. A reproduced evaluator can DRIFT from the one it claims to trace,
# and drift is invisible: the trace still looks plausible while describing a
# reduction that never happened.
#
# So the central assertion is NOT "the trace looks right". It is that
# DEBUG_EVAL and EVAL AGREE on the result of every program. Tracing must not
# change the answer. Everything else here is secondary.
#
# SLICE 2 (breakpoints + environment inspection) extends that same assertion
# rather than adding a separate one: every breakpoint program is run through
# the agreement check WITH THE BREAKPOINT ARMED, because a breakpoint reads
# the environment and must not perturb it either. Check 3 then asks the two
# questions agreement cannot: does the breakpoint fire WHERE it should, and
# — the half that is easy to forget — does it fire NOWHERE ELSE. A predicate
# that is accidentally always-true still agrees on every answer.
# (That was "Check 4" until slice 3 inserted a check ahead of it. A stale
# cross-reference in a gate's own header is the cheapest kind of drift and
# the easiest to leave: nothing executes it, so nothing catches it.)
#
# SLICE 3 (the call stack) adds the second projection a breakpoint reports:
# env answers "what is bound here" (LEXICAL — the scope a closure was made
# in), bt answers "how did control get here" (DYNAMIC). Neither is derivable
# from the other, so check 4 asserts they DISAGREE on a program built to
# force them apart, and asserts the ABSENCE of the lexical binder from the
# chain as well as the presence of the call chain — the absence is the only
# half a backtrace secretly rendered from the environment would fail.
#
# SLICE 4 (conditional breakpoints) makes those projections DECIDE rather
# than merely display. Until it, the stack was threaded and printed and
# nothing read it, so a fault in it could only produce a wrong-looking line;
# BRK_CALLER conditions the break ON it, so a fault now changes WHICH nodes
# break. Check 5 runs the unconditioned predicate on the same program as a
# CONTROL and requires the conditional to fire strictly less often — a
# BRK_CALLER degraded to BRK_VAR still fires, still prints a plausible bt,
# and still agrees, so the count relation is the only thing separating them.
#
# SLICE 5 (stepping) adds no dispatch either: a step command is a STOP
# CONDITION, which is how a real debugger implements it — gdb's `next` sets a
# condition on the current FRAME and resumes rather than running a second,
# slower interpreter. So step/step-over/step-out are three more predicates
# over the same (d, ast, env, stk) signature, and check 6 asserts they select
# strictly NESTED stop sets. They measure the STACK, not the depth: `d` counts
# every subexpression while only a call pushes a frame, and on SRC_STEP the
# two numbers differ (7 against 8), so a step-over written on `d` is caught.
#
# SLICE 6 is the DRIVER and the first slice to change the evaluator's SHAPE:
# an ordinal counts nodes already visited, so it flows ACROSS siblings where d
# and stk flow downward, and no predicate can express it. The dispatch threads
# state and returns PAIR(value)(state), the old tracer being DEFINED from it by
# taking FST. Note the cost, which check 7 exists to cover: agreement compares
# the VALUE, so it cannot see a mis-threaded ordinal — measured, not assumed,
# by a red run in which check 1 stayed green with DEBUG_EVAL replaced by EVAL
# outright. The ordinal's oracle is the printed trace: the k-th ENTER line IS
# node k.
#
# SLICE 7 is the POST-MORTEM. Every branch that could not proceed called
# `error` and died with one line — not where, not how control got there, not
# what was bound — so the debugger was useless at exactly the moment you would
# reach for one. It now reports and THEN dies: check 8's load-bearing assertion
# is the NON-ZERO EXIT, because a post-mortem that caught the fault would turn
# a loud failure into a silent one. And "exits non-zero" is true of a harness
# that merely failed to parse, so the run must first be shown to have got far
# enough to fault — that guard is red-tested, not assumed.
set -u
cd "$(dirname "$0")" || exit 1
ok=1
EXPECT_AGREE=18
EXPECT_BREAK=11

command -v timeout >/dev/null 2>&1 || { echo "SKIP  debug: timeout(1) absent"; exit 0; }
[ -f debug_eval.la ] || { echo "FAIL  debug: debug_eval.la missing"; exit 1; }

# ── 1. the host engine ─────────────────────────────────────────────────────
H=$(timeout 300 ./tiny_host debug_eval.la 2>&1) || {
    echo "FAIL  debug: tiny_host debug_eval.la did not complete: $(printf '%s' "$H" | tail -1)"; exit 1; }
#   ★ Non-vacuity FIRST. Every count below is taken from $H, so an empty $H
#   would make "0 DIVERGED" true and the whole gate meaningless.
lines=$(printf '%s\n' "$H" | grep -c .)
if [ "$lines" -lt 20 ]; then
    echo "FAIL  debug: host produced only $lines lines — too little to have traced anything; refusing to judge counts taken from it"; exit 1
fi

agree=$(printf '%s\n' "$H" | grep -c '^AGREE')
#   A breakpoint now reports TWO projections (slice 3), so they are
#   counted separately and required to pair up — a break that printed one
#   without the other would otherwise satisfy every count below.
#   ★ COUNTED OVER THE NON-STEPPING SECTIONS ONLY, and slice 5 is why. A
#   step predicate also fires BREAK lines — 19 of them — so counting them
#   here silently folded stepping into a check about breakpoints, and every
#   stepping defect then reported as "a breakpoint case silently stopped
#   firing": the RIGHT verdict through the WRONG assertion, which is the
#   failure this gate warns about at slice 1 and which was caught here by a
#   red run, not by reading. The filter clears on any OTHER section header
#   rather than cutting to end-of-output, so a slice appended after stepping
#   is counted again instead of silently dropped.
nostep() { printf '%s\n' "$H" | awk '/^--- step: /{s=1;next} /^--- /{s=0} !s'; }
brk_env=$(nostep | grep -c '!! BREAK .* env:')
brk_bt=$(nostep | grep -c '!! BREAK .* bt:')
diverged=$(printf '%s\n' "$H" | grep -c '^DIVERGED')
if [ "$diverged" -ne 0 ]; then
    echo "FAIL  debug 1: $diverged program(s) DIVERGED — tracing changed the answer:"
    printf '%s\n' "$H" | grep '^DIVERGED' | sed 's/^/        /'
    ok=0
elif [ "$agree" -ne "$EXPECT_AGREE" ]; then
    echo "FAIL  debug 1: $agree agreements, expected $EXPECT_AGREE — a program silently stopped being tested"; ok=0
else
    echo "PASS  debug 1: DEBUG_EVAL agrees with EVAL on all $agree programs — tracing does not change the answer"
fi

# ── 2. the trace actually describes the reduction ──────────────────────────
#   Checked on the curried-builtin program, whose shape is forced: concat is
#   looked up (VAR->bi), applied once to become a PARTIAL, then applied again.
#   If the tracer ever silently degraded to "print the top node and delegate",
#   the nested lines would vanish while agreement still passed.
#   ★ EACH HELPER CLEARS ITS CHECK'S OWN FLAG, not just the global `ok`.
#   Without that, a check whose line assertion failed still fell through to
#   its trailing `else` and printed PASS underneath its own FAIL — the exit
#   status was right and the CLAIM was wrong. A gate that reports a green it
#   did not earn is worse than one that fails, because the failure is the
#   part a reader trusts.
line2_ok=1
need_line() {
    printf '%s\n' "$H" | grep -qF "$1" || { echo "FAIL  debug 2: trace is missing the line '$1'"; ok=0; line2_ok=0; }
}
#   Same shape, but reports as check 3, so a failure names the check that
#   actually caught it. Slice 1 learned this the hard way: a red path that
#   fires through the WRONG assertion is not evidence the intended one works.
brk3_ok=1
need_brk() {
    printf '%s\n' "$H" | grep -qF "$1" || { echo "FAIL  debug 3: expected breakpoint line missing: '$1'"; ok=0; brk3_ok=0; }
}
need_line "<- VAR = bi:concat"
need_line "<- APP = pa:concat"
need_line "<- APP = str:abcd"
need_line "<- LAM = clo:x"
depth2=$(printf '%s\n' "$H" | grep -c '^    -> ')
if [ "$depth2" -lt 1 ]; then
    echo "FAIL  debug 2: no depth-2 trace lines — the tracer is not recursing, only reporting the outermost node"; ok=0
elif [ "$line2_ok" -ne 1 ]; then
    :   # a required trace line was already reported missing above; do not claim PASS on top of it
else
    echo "PASS  debug 2: the trace shows real nested reduction ($depth2 lines at depth 2+, curried builtin VAR->bi->pa->str)"
fi

# ── 3. breakpoints: fire where they should, and NOWHERE ELSE ───────────────
#   The env render is the point of the slice, so it is asserted verbatim, not
#   by counting lines: a breakpoint that fired but printed the wrong binding
#   would otherwise pass.
need_brk "!! BREAK VAR env: x=str:VALUE"
#   ★ THE SHADOWING CASE — the question a trace alone cannot answer. Both
#   bindings of x are live; the trace shows only which value came back. Only
#   the environment shows WHY, and the ORDER is the answer: APP conses the
#   new frame on the front and LIST_FIND takes the first match, so "inner"
#   must precede "outer". An env rendered tail-first would still contain both
#   names and still agree on every result, and would be wrong.
need_brk "!! BREAK VAR env: x=str:inner, x=str:outer"

#   The negative half. A predicate that never says no is indistinguishable
#   from a working one by every check above — it fires on the lines we asked
#   for, and agreement still holds because breaking does not change answers.
#   ★ THE TERMINATOR MATCHES ANY SECTION HEADER, not this section's own
#   prefix. Terminating on `/^--- break: /` meant appending a section with a
#   different prefix silently EXTENDED this one — slice 4's `--- cond:`
#   sections did exactly that to check 4 and turned it red. A section
#   extractor anchored to the names that existed when it was written is a
#   gate that breaks the next time anyone appends to the program.
neg_sec=$(printf '%s\n' "$H" | awk '/^--- break: VAR nosuchvar/{f=1;next} /^--- /{f=0} f')
neg_lines=$(printf '%s\n' "$neg_sec" | grep -c .)
neg_brk=$(printf '%s\n' "$neg_sec" | grep -c '!! BREAK')
if [ "$neg_lines" -lt 5 ]; then
    #   Non-vacuity, same discipline as check 1: "0 breakpoints" is trivially
    #   true of an empty section, so the section must be shown to exist first.
    echo "FAIL  debug 3: the must-not-fire section has only $neg_lines lines — it did not run, so '0 breakpoints' proves nothing"; ok=0
elif [ "$neg_brk" -ne 0 ]; then
    echo "FAIL  debug 3: BRK_VAR(\"nosuchvar\") fired $neg_brk time(s) — the predicate matches nodes it should not"; ok=0
elif [ "$brk3_ok" -ne 1 ]; then
    :   # a required breakpoint line was already reported missing above
elif [ "$brk_env" -ne "$EXPECT_BREAK" ]; then
    echo "FAIL  debug 3: $brk_env breakpoint env lines, expected $EXPECT_BREAK — a breakpoint case silently stopped firing"; ok=0
elif [ "$brk_bt" -ne "$brk_env" ]; then
    echo "FAIL  debug 3: $brk_env env lines but $brk_bt bt lines — a breakpoint reported one projection without the other"; ok=0
else
    echo "PASS  debug 3: breakpoints fire exactly where armed ($brk_env, each reporting both env and bt: bound value, shadowed pair innermost-first, 3 at depth 1) and not at all on a name that does not occur, while all $EXPECT_AGREE programs still AGREE"
fi

# ── 4. the call stack is DYNAMIC, not the environment relabelled ───────────
#   SRC_DYN is built so the two projections MUST disagree: MK captures v
#   and returns a closure; USE applies that closure somewhere MK never
#   mentions. At `v` the environment is MK's (lexical) and the call chain
#   is USE's (dynamic). Asserting only the presence of a plausible bt line
#   would not discriminate — a "backtrace" quietly rendered from the env
#   chain prints something equally plausible — so the ABSENCE is asserted
#   too: MK bound the value that is in scope and must NOT be on the stack,
#   because it already returned.
stk4_ok=1
need_stk() {
    printf '%s\n' "$H" | grep -qF "$1" || { echo "FAIL  debug 4: expected stack line missing: '$1'"; ok=0; stk4_ok=0; }
}
need_stk "!! BREAK VAR env: q=str:arg, v=str:cap"
need_stk "!! BREAK VAR bt: q <- f <- MAIN"

dyn_sec=$(printf '%s\n' "$H" | awk '/^--- stack: lexical/{f=1;next} /^--- /{f=0} f')
dyn_lines=$(printf '%s\n' "$dyn_sec" | grep -c .)
#   ★ THE DISCRIMINATOR IS `v`, not MK. `v` is the name that IS in the
#   environment at the breakpoint, so a bt rendered from the env chain
#   prints it and a bt built from calls cannot. MK is checked too (it
#   defined the closure and had already returned), but `v` is the one an
#   env-derived backtrace actually gets wrong.
dyn_bt=$(printf '%s\n' "$dyn_sec" | grep '!! BREAK .* bt:')
dyn_mk=$(printf '%s\n' "$dyn_bt" | grep -cE '(: |<- )(v|MK)( |$)')
#   The no-invention half, the counterpart of check 3's must-not-fire: a
#   program that calls nothing must show exactly the one frame the runner
#   entered. A " <- " in that bt line means a frame was pushed by
#   something that is not a call.
top_sec=$(printf '%s\n' "$H" | awk '/^--- stack: no calls/{f=1;next} /^--- /{f=0} f')
top_bt=$(printf '%s\n' "$top_sec" | grep '!! BREAK .* bt:')
top_extra=$(printf '%s\n' "$top_bt" | grep -c ' <- ')
if [ "$dyn_lines" -lt 5 ]; then
    echo "FAIL  debug 4: the lexical-vs-dynamic section has only $dyn_lines lines — it did not run, so its absences prove nothing"; ok=0
elif [ "$dyn_mk" -ne 0 ]; then
    echo "FAIL  debug 4: the call stack names a lexical binder ($dyn_bt) — v is in the ENVIRONMENT at this breakpoint and MK had already returned, so a bt naming either is the env chain relabelled, not the call chain"; ok=0
elif [ -z "$top_bt" ]; then
    echo "FAIL  debug 4: no bt line in the no-calls section — cannot judge the frame count"; ok=0
elif [ "$top_extra" -ne 0 ]; then
    echo "FAIL  debug 4: the no-calls program shows more than one frame ($top_bt) — a frame was pushed by something that is not a call"; ok=0
elif [ "$stk4_ok" -ne 1 ]; then
    :   # a required stack line was already reported missing above
else
    echo "PASS  debug 4: env and bt genuinely disagree (v is bound lexically by MK, absent from the dynamic chain q <- f <- MAIN) and a call-free program shows exactly one frame"
fi

# ── 5. CONDITIONAL breakpoints: the stack DECIDES, it does not just display ─
#   Until slice 4 the call stack was display-only — threaded and printed,
#   with nothing deciding on it, so a wrong stack could only ever produce a
#   wrong-looking line. BRK_CALLER conditions the break ON it, which makes a
#   stack fault change WHICH nodes break. SRC_TWO reaches ONE node (`VAR x`
#   in ID's body) by TWO routes, through A and through B.
#
#   ★ THE CONTROL IS LOAD-BEARING AND IS RUN ON THE SAME PROGRAM. A
#   BRK_CALLER that had silently degraded to plain BRK_VAR would still fire,
#   still print a plausible bt, and still AGREE. The only thing that
#   separates them is that the unconditioned predicate must fire STRICTLY
#   MORE OFTEN on this program. Asserting the conditional's count alone
#   would be the inert-control mistake from slice 3 all over again.
csec() { printf '%s\n' "$H" | awk -v s="$1" 'index($0,s){f=1;next} /^--- /{f=0} f'; }
c_ctl=$(csec "BRK_VAR x, the control" | grep -c '!! BREAK .* env:')
c_via=$(csec "BRK_CALLER x via A"     | grep -c '!! BREAK .* env:')
c_nos_l=$(csec "BRK_CALLER x via NOSUCH" | grep -c .)
c_nos=$(csec "BRK_CALLER x via NOSUCH" | grep -c '!! BREAK')
c_whn=$(csec "BRK_WHEN x = from-b"    | grep -c '!! BREAK .* env:')
cond5_ok=1
need_cond() {
    printf '%s\n' "$H" | grep -qF "$1" || { echo "FAIL  debug 5: expected conditional line missing: '$1'"; ok=0; cond5_ok=0; }
}
#   The stack-conditional picks the A route; the env-conditional picks the B
#   route. Asserting BOTH pins them apart: a predicate that had degraded to
#   "fire on the first visit" would select A in both cases.
need_cond "!! BREAK VAR bt: x <- A <- MAIN"
need_cond "!! BREAK VAR env: x=str:from-a"
need_cond "!! BREAK VAR bt: x <- B <- MAIN"
need_cond "!! BREAK VAR env: x=str:from-b"
#   ★ EVALUATED UNCONDITIONALLY, not as an `elif`, and the red path shows
#   that placement is load-bearing rather than merely defensive. Injection A
#   — STK_HAS negated, so an ABSENT frame matches and a PRESENT one does not
#   — drives c_via to 0 rather than over-firing. `c_via >= c_ctl` is
#   therefore FALSE, so inside the chain this would have fallen through to
#   the exact-count branch and reported an off-by-count, never saying that a
#   frame which is not on the stack had matched. Unconditional, it reports
#   the real defect: NOSUCH fired 4 times.
#   (This corrects an earlier claim here that every such defect also makes
#   the present frame over-fire, leaving the branch "reachable in principle,
#   shadowed in practice". Injection A is the counterexample that claim said
#   could not be constructed — it was an argument, not a red run, and the
#   red run disagreed with it.)
if [ "$c_nos_l" -lt 3 ]; then
    echo "FAIL  debug 5: the must-not-fire section has only $c_nos_l lines — it did not run, so '0 breakpoints' proves nothing"; ok=0; cond5_ok=0
elif [ "$c_nos" -ne 0 ]; then
    echo "FAIL  debug 5: BRK_CALLER(\"x\")(\"NOSUCH\") fired $c_nos time(s) — a frame that is never on the stack matched it"; ok=0; cond5_ok=0
fi

if [ "$c_ctl" -ne 2 ]; then
    echo "FAIL  debug 5: the control BRK_VAR(\"x\") fired $c_ctl times, expected 2 — SRC_TWO is supposed to reach the SAME node by two routes, so the premise of the whole check is gone"; ok=0
#   ★ THE RELATIONAL CHECK COMES FIRST BECAUSE IT IS THE LOAD-BEARING ONE.
#   Written after the two exact-count tests it was UNREACHABLE — c_ctl is
#   already pinned to 2 and c_via to 1, so `c_via >= c_ctl` could never be
#   true, and the branch that states the actual claim of this check would
#   have been dead code that reads as rigour. Ordered first, a BRK_CALLER
#   that degrades to BRK_VAR fires it and gets the RIGHT diagnosis
#   ("not filtering") rather than an off-by-count one.
elif [ "$c_via" -ge "$c_ctl" ]; then
    echo "FAIL  debug 5: the stack-conditional fired $c_via times and the unconditioned control $c_ctl — the conditional is not filtering, so it is indistinguishable from BRK_VAR and the stack is not deciding anything"; ok=0
elif [ "$c_via" -ne 1 ]; then
    echo "FAIL  debug 5: BRK_CALLER(\"x\")(\"A\") fired $c_via times, expected 1"; ok=0
elif [ "$c_whn" -ne 1 ]; then
    echo "FAIL  debug 5: BRK_WHEN(\"x\")(\"from-b\") fired $c_whn times, expected 1"; ok=0
elif [ "$cond5_ok" -ne 1 ]; then
    :   # a required conditional line was already reported missing above
else
    echo "PASS  debug 5: conditionals filter — same node reached twice, control fires $c_ctl, stack-conditional $c_via (route A), env-conditional $c_whn (route B), unmatched frame 0, all $EXPECT_AGREE programs still AGREE"
fi

# ── 6. STEPPING: the three commands select strictly NESTED stop sets ───────
#   SRC_STEP puts nodes at THREE frame depths (MAIN's own, F's, and G's
#   nested inside F) because a one-call program makes step-out EMPTY, and an
#   empty set satisfies "strictly fewer" while asserting nothing — the
#   vacuity this gate has had to guard against at every slice.
#
#   ★ THE FRAME DEPTH IS READ OFF THE bt LINE, NOT OFF THE PREDICATE. SHOW_STK
#   renders one frame per name joined by " <- ", so a stop inside a nested call
#   is exactly a bt line carrying two separators. Asserting on the OUTPUT means
#   the predicate and the renderer would both have to be wrong, in agreement,
#   to pass — where asserting on a recomputed depth would just be asking the
#   suspect to confirm its own story.
s_into=$(csec "step: INTO" | grep -c '!! BREAK .* env:')
s_over=$(csec "step: OVER" | grep -c '!! BREAK .* env:')
s_out=$(csec  "step: OUT"  | grep -c '!! BREAK .* env:')
s_out_l=$(csec "step: OUT" | grep -c .)
over_deep=$(csec "step: OVER" | grep '!! BREAK .* bt:' | grep -c ' <- .* <- ')
out_deep=$(csec  "step: OUT"  | grep '!! BREAK .* bt:' | grep -c ' <- ')
#   Containment, as an identity between counts rather than a set diff: OVER
#   must be exactly INTO restricted to frame depth <= 2, and OUT exactly the
#   frame-depth-1 stops. That IS the specification of the three predicates,
#   and it needs only grep — `comm` would want temp files and `diff <(…)` is
#   the process-substitution bashism this #!/bin/sh gate cannot use.
into_le2=$(csec "step: INTO" | grep '!! BREAK .* bt:' | grep -vc ' <- .* <- ')
over_shallow=$(csec "step: OVER" | grep '!! BREAK .* bt:' | grep -vc ' <- ')
#   ★ ORDERED SEMANTIC-FIRST, EXACT-COUNTS-LAST, for the reason slice 4 found
#   the hard way: written after the exact counts, every check below would be
#   unreachable, because 9/7/3 already pins each number. A stepper that had
#   stopped descending entirely (all three selecting the same 3 nodes) passes
#   both absences and is caught ONLY by the strict ordering — so that branch
#   has to be able to run.
if [ "$s_out_l" -lt 3 ] || [ "$s_out" -eq 0 ]; then
    echo "FAIL  debug 6: the step-out section has $s_out_l lines and $s_out stops — an empty set satisfies every 'fewer than' test below, so it proves nothing"; ok=0
elif [ "$over_deep" -ne 0 ]; then
    echo "FAIL  debug 6: step-over stopped $over_deep time(s) inside a nested call (a bt line with two frames above it) — it is descending into calls, which is the one thing step-over means not to do"; ok=0
elif [ "$out_deep" -ne 0 ]; then
    echo "FAIL  debug 6: step-out stopped $out_deep time(s) while still inside the frame it was leaving — it is using <= where it must use <"; ok=0
elif [ "$s_into" -le "$s_over" ] || [ "$s_over" -le "$s_out" ]; then
    echo "FAIL  debug 6: stops are into=$s_into over=$s_over out=$s_out — not strictly nested, so at least two of the three commands are the same command"; ok=0
elif [ "$into_le2" -ne "$s_over" ]; then
    echo "FAIL  debug 6: step-over selected $s_over stops but INTO has $into_le2 at frame depth <= 2 — over is not INTO restricted to this frame"; ok=0
elif [ "$over_shallow" -ne "$s_out" ]; then
    echo "FAIL  debug 6: step-out selected $s_out stops but OVER has $over_shallow at frame depth 1 — out is not OVER restricted to the caller"; ok=0
elif [ "$s_into" -ne 9 ] || [ "$s_over" -ne 7 ] || [ "$s_out" -ne 3 ]; then
    echo "FAIL  debug 6: stops are into=$s_into over=$s_over out=$s_out, expected 9/7/3 — the traced shape of SRC_STEP changed"; ok=0
else
    echo "PASS  debug 6: stepping selects strictly nested stop sets (into $s_into, over $s_over, out $s_out) — step-over never enters a call, step-out never stops inside the frame it leaves, and each is the previous one restricted by FRAME depth (7 here, where node depth would give 8)"
fi

# ── 7. THE DRIVER: resume, and a session where the COMMAND decides ─────────
#   Slice 5 gave stop CONDITIONS; a condition cannot say "resume from where
#   I am". Slice 6 threads an ordinal so it can, and a session is a fold
#   carrying (after, frame-depth). The two middle sessions are the assertion:
#   IDENTICAL first command, ONE differing second command. If the driver
#   ignored the command, or restarted from the beginning each time, both
#   would report the same thing.
ords()   { printf '%s\n' "$1" | sed -n 's/^  stop #\([0-9]*\) .*/\1/p'   | tr '\n' ' ' | sed 's/ $//'; }
kinds()  { printf '%s\n' "$1" | sed -n 's/^  stop #[0-9]* \([A-Z]*\) .*/\1/p' | tr '\n' ' ' | sed 's/ $//'; }
frames() { printf '%s\n' "$1" | sed -n 's/^  stop #[0-9]* [A-Z]* frame\([0-9]*\) .*/\1/p' | tr '\n' ' ' | sed 's/ $//'; }
d_or=$(csec "drive: INTO x4")
d_in=$(csec "drive: run to G, then INTO")
d_ov=$(csec "drive: run to G, then OVER")
d_en=$(csec "drive: run to z")
o_or=$(ords "$d_or"); k_or=$(kinds "$d_or"); f_or=$(frames "$d_or")
o_in=$(ords "$d_in"); f_in=$(frames "$d_in")
o_ov=$(ords "$d_ov"); f_ov=$(frames "$d_ov")
#   ★ THE ORDINAL'S ORACLE IS THE TRACE, NOT THE DRIVER'S OWN ARITHMETIC.
#   Agreement compares the VALUE (FST), so a mis-threaded counter leaves it
#   green — measured, not assumed: a red run showed check 1 stays green even
#   when DEBUG_EVAL is replaced by EVAL outright. ENTER emits one line per
#   node in visit order, so the k-th ENTER line IS node k. Taking the kinds
#   from the traced run and requiring the session's first four stops to match
#   checks the counter against something that did not compute it.
trace_k=$(csec "step: INTO" | sed -n 's/^ *-> \([A-Z]*\)$/\1/p' | head -4 | tr '\n' ' ' | sed 's/ $//')
in2=$(printf '%s\n' "$o_in" | awk '{print $2}')
ov2=$(printf '%s\n' "$o_ov" | awk '{print $2}')
mono=1; prev=-1
for x in $o_in; do [ "$x" -gt "$prev" ] || mono=0; prev=$x; done
if [ -z "$o_or" ] || [ -z "$o_in" ] || [ -z "$o_ov" ]; then
    echo "FAIL  debug 7: a session reported no stops at all (oracle='$o_or' into='$o_in' over='$o_ov') — nothing below can mean anything"; ok=0
#   ★ MONOTONIC FIRST, THEN DIVERGENCE, THEN THE EXHAUSTED PATH — and this
#   order was established by red runs, not by taste. With the exhausted-path
#   check first, BOTH the restart defect and the ignored-command defect
#   reported "the exhausted path is not being exercised": true, but a
#   consequence rather than the cause, and it named neither bug. A restart
#   makes ordinals repeat, so monotonic catches it and says so; an ignored
#   command makes the two sessions agree, so divergence catches that.
elif [ "$mono" -ne 1 ]; then
    echo "FAIL  debug 7: session ordinals '$o_in' are not strictly increasing — the driver is not resuming from the last stop, it is restarting"; ok=0
elif [ "$in2" = "$ov2" ]; then
    echo "FAIL  debug 7: after the SAME first command, step-into and step-over both stopped at #$in2 — the command is not deciding anything, so this is not a driver"; ok=0
elif ! printf '%s\n' "$d_en" | grep -q 'no further stop'; then
    echo "FAIL  debug 7: the run-off-the-end session never reported 'no further stop' — the exhausted path is not being exercised"; ok=0
elif [ "$k_or" != "$trace_k" ]; then
    echo "FAIL  debug 7: session kinds '$k_or' but the traced visit order begins '$trace_k' — the threaded ordinal disagrees with the trace, so the state is mis-threaded"; ok=0
elif [ "$o_or" != "0 1 2 3" ]; then
    echo "FAIL  debug 7: four step-intos from the start gave ordinals '$o_or', expected '0 1 2 3'"; ok=0
#   ★ THE ORACLE SESSION IS WHERE FRAME DEPTH AND NODE DEPTH DIVERGE, so its
#   frames are asserted and the other sessions' are not enough. Reporting `d`
#   in place of STK_LEN was INERT against every other assertion here: at #5/#6/#7
#   the two numbers coincide (2/3/2), so the substitution changed nothing. Across
#   these four stops they do not — frames are 1 1 2 1 where depths are 0 1 2 1.
elif [ "$f_or" != "1 1 2 1" ]; then
    echo "FAIL  debug 7: the oracle session reported frames '$f_or', expected '1 1 2 1' — a stop is reporting NODE depth where it must report FRAME depth, which is the number the next step command is relative to"; ok=0
elif [ "$o_in" != "5 6 7" ] || [ "$f_in" != "2 3 2" ]; then
    echo "FAIL  debug 7: run-to-G/into/out gave ordinals '$o_in' frames '$f_in', expected '5 6 7' / '2 3 2'"; ok=0
elif [ "$o_ov" != "5 7" ] || [ "$f_ov" != "2 2" ]; then
    echo "FAIL  debug 7: run-to-G/over gave ordinals '$o_ov' frames '$f_ov', expected '5 7' / '2 2' — over must SKIP #6 inside G"; ok=0
else
    echo "PASS  debug 7: the driver resumes and the command decides — from the same stop #5, into descends to #6 (frame 3, inside G) and over skips it to #7 (frame 2); ordinals strictly increase, match the traced visit order, and the exhausted run reports no further stop"
fi

# ── 8. THE FAULT REPORT: a post-mortem, and STILL a loud failure ───────────
#   ★ THE HARNESS IS BUILT FROM debug_eval.la ITSELF — everything before its
#   MAIN, plus a MAIN that runs a program which cannot complete. That is the
#   idiom build.sh already uses for its RUN_SM harness, and it is chosen over
#   a second .la file for one reason: there is no copy of the machinery, so
#   the harness cannot drift from the thing it is testing. A faulting program
#   cannot live in debug_eval.la's own MAIN, because halting there would take
#   the other seven checks down with it.
F_LA=./debug_fault_gen.la
FMAIN=$(grep -n '^glyph MAIN = ' debug_eval.la | tail -1 | cut -d: -f1)
head -$((FMAIN-1)) debug_eval.la > "$F_LA"
printf 'glyph MAIN = DEBUG_RUN(PARSE_PROGRAM("glyph H = la w. nosuchname\\nglyph G = la z. H(z)\\nglyph F = la y. G(y)\\nglyph MAIN = F(\\"in\\")"))\n' >> "$F_LA"
FOUT=$(timeout 300 ./tiny_host "$F_LA" 2>&1); FRC=$?
rm -f "$F_LA"
f_trace=$(printf '%s\n' "$FOUT" | grep -c '^ *-> ')
#   ★ NON-VACUITY IS NOT OPTIONAL HERE, IT IS THE WHOLE TRAP. "Exits
#   non-zero" is ALSO true of a harness that failed to parse, or that never
#   ran at all. So the run must be shown to have got somewhere first —
#   otherwise the loud-failure assertion below passes for the wrong reason
#   and reports a working post-mortem where there is none.
if [ "$f_trace" -lt 5 ]; then
    echo "FAIL  debug 8: the fault harness produced only $f_trace trace lines — it did not get far enough to fault, so a non-zero exit proves nothing"; ok=0
#   ★ THE LOUD FAILURE IS THE LOAD-BEARING ASSERTION. A debugger that
#   REPORTED the fault and then exited 0 would be strictly worse than no
#   debugger: it converts a loud failure into a silent one, which is the one
#   discipline this whole project is built on. Reporting must not catch.
elif [ "$FRC" -eq 0 ]; then
    echo "FAIL  debug 8: the fault harness exited 0 — the post-mortem SWALLOWED the error instead of reporting and dying, turning a loud failure into a silent one"; ok=0
elif ! printf '%s\n' "$FOUT" | grep -qF '!! FAULT debug_eval: unbound variable: nosuchname'; then
    echo "FAIL  debug 8: the fault produced no report line — it died with only the message, which is the state slice 7 exists to end"; ok=0
#   The location line is asserted VERBATIM because it pins four separate
#   things at once: slice 6's ordinal, the node kind, the FRAME depth, and
#   slice 3's dynamic chain. It is rendered by STOP_REC, the same renderer
#   the driver uses for a stop, so a fault reads in a breakpoint's
#   coordinates and there is no second formatter to drift from it.
elif ! printf '%s\n' "$FOUT" | grep -qF '!! FAULT at #12 VAR frame4 bt: w <- z <- y <- MAIN'; then
    echo "FAIL  debug 8: the fault location line is wrong or missing — expected '#12 VAR frame4 bt: w <- z <- y <- MAIN', got: $(printf '%s\n' "$FOUT" | grep '!! FAULT at' | head -1)"; ok=0
#   ★ AND THE TWO PROJECTIONS MUST STILL DISAGREE AT THE FAULT. `w` is the
#   only binding in scope, while control arrived through four frames. A
#   report that printed the environment wearing a backtrace label would show
#   the same thing twice — the slice 3 discriminator, applied where it
#   matters most.
elif ! printf '%s\n' "$FOUT" | grep -qF '!! FAULT env: w=str:in'; then
    echo "FAIL  debug 8: the fault report did not show the environment in force ('w=str:in') — a post-mortem without the bindings is half a report"; ok=0
else
    echo "PASS  debug 8: a fault reports before it dies — #12 VAR frame4, dynamic chain w <- z <- y <- MAIN, env w=str:in — and still exits $FRC, so the post-mortem reports without catching"
fi

# ── 9. host == VM ──────────────────────────────────────────────────────────
#   codegen.la resolves debug_eval.la's `import("eval.la")` at COMPILE time and
#   lowers the merged table; the VM has no notion of import. Costly (~11 min:
#   secd.la build + codegen over eval.la + debug_eval.la), so it is skippable
#   for a quick loop — but skipping is ANNOUNCED, never silent.
if [ "${SKIP_VM:-0}" = 1 ]; then
    echo "SKIP  debug 9: host==VM skipped by SKIP_VM=1 (the expensive half — do not read a green here as engine agreement)"
else
    rm -f logos_secd logos_program.bin logos_source.la
    timeout 900 ./tiny_host secd.la >/dev/null 2>&1
    if [ ! -x logos_secd ]; then
        echo "SKIP  debug 9: could not build logos_secd from secd.la — no VM to compare against"
    else
        cp debug_eval.la logos_source.la
        timeout 1800 ./tiny_host codegen.la >/dev/null 2>&1
        if [ ! -s logos_program.bin ]; then
            echo "FAIL  debug 9: codegen produced no program from debug_eval.la"; ok=0
        else
            V=$(timeout 600 ./logos_secd 2>&1)
            if [ "$V" = "$H" ]; then
                echo "PASS  debug 9: host == VM — byte-identical output from tiny_host and the native SECD VM"
            else
                echo "FAIL  debug 9: host and VM disagree"
                echo "        host $(printf '%s\n' "$H" | grep -c .) lines, VM $(printf '%s\n' "$V" | grep -c .) lines"
                #   ★ NOT `diff <(…) <(…)`: process substitution is a BASHISM and
                #   this gate is #!/bin/sh (dash), where it is a syntax error that
                #   kills the script mid-run — after two checks had already printed
                #   PASS. Caught by `sh -n` plus an actual run; a gate whose failure
                #   BRANCH does not parse looks perfect until the day it must fire.
                printf '%s\n' "$H" > .dbg_host.txt
                printf '%s\n' "$V" > .dbg_vm.txt
                diff .dbg_host.txt .dbg_vm.txt 2>/dev/null | head -6 | sed 's/^/        /'
                rm -f .dbg_host.txt .dbg_vm.txt
                ok=0
            fi
        fi
    fi
    rm -f logos_secd logos_program.bin logos_source.la
fi

[ "$ok" = 1 ] && echo "debug gate GREEN" || { echo "debug gate RED"; exit 1; }
