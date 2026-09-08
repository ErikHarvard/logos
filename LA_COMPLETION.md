# Lingua Adamica — the completion list

Everything still required for the language to be complete **by Erik's own stated
criteria**, ordered so that each tier unblocks the next. Assembled from: five
Fable sweeps of the codices, the phonetic/glyphic parity audit, the
meta-programming audit, the dyad/meta-sigil audit, ROADMAP's 114 open and 14
partial items, and the defects found by building.

**Every item carries the gate that would prove it, and its white-paper
counterpart.** The paper and the language must land together: an item is not
done until the code is gated AND the paper states it at the right tag.

Status key: `[ ]` unbuilt · `[~]` partial · `[✓]` done today · `[!]` needs Erik

---

## ★★★ THE GOVERNING STANDARD — read before building anything on this list

**Complexity accrues error faster than capability unless the verification layer
compounds too.** Stated as a principle before 2026-08-27; **empirically supported
after it.** Syntropy is not automatic. It is conditional on the system's capacity
to catch itself growing at least as fast as the system.

### The standard
**Before building anything new, ask: does the check for THIS actually run?**
A module with a gate that exits 0 unconditionally is **worse than a module with
no gate**, because it reports false confidence — an unwired gate looks
uncovered; a dead one looks covered. **Every gate in the arc must be able to go
RED**, and that must be demonstrated by planting the defect it claims to catch,
not argued.

### Why this is now evidence and not exhortation
One day's findings, all in the verification layer rather than the language:

| defect | count |
|---|---|
| modules marked `[✓]` in THIS FILE with no runner at all | 8 |
| gates exiting 0 without running, reported as passing, every build | 1 |
| gate invocations where deleting the gate file keeps the build green | 6 |
| comparisons that cannot fail alone (each implied by two others) | 6 |
| provenance controls defeated by an adjacent line | 1 |
| PASS messages announcing measurements that had moved | 5 |
| this document's own entries marking built work as open | 1 |
| mutation-lever entries crediting a STATIC reader for BEHAVIOURAL coverage | 1 |
| instruments that were broken when first written (mine, this session) | 3 |

Two of those deserve their own line because they generalise:

★ **The question no audit was asking.** Every audit this project has run —
Audit II's discriminating power, Audit III's cannot-fail comparisons — asks
*"can this check fail?"* of checks that **run**. None asked *"does this check
run?"* of the whole inventory. Three hits in one day, every one a by-product of
looking for something else. (Framing: track E, Freeze III.)

★ **And one level up: did the evidence come from EXECUTION?** The mutation lever
reported `selfext2b.la` CAUGHT; the mutant was killed by a *static analyser
reading the source*, and the gate never ran the organ. A static analyser and a
behavioural gate can both go red, and only one is evidence the code works.
Marker, measured: 20 CAUGHT lines, 19 carry a `% of baseline` ratio, the 1
without is the bogus one — the ratio is computed against the gate's runtime, so
it cannot exist when the gate never ran.

### ★★ THE STANDARD DOES NOT PREVENT THE NEXT INSTANCE — measured, same day
Recorded because it is the accurate picture of how these classes propagate, and
because a governing section that omitted it would be claiming more than it earns.

The rule *reconcile against an independently obtained count before acting* was
written into this document, applied to the untracked-file scan, and caught **27
files** whose absence would have produced a checkout that cannot build. Within
the same hour the same rule was **not** applied to the staging check one step
later, and commit `a9e27e8` went out materially incomplete: `specpipe.la` — the
export fix — absent while a generated output of it was present, and the eight
newly-gated modules committed alongside a `build.sh` that gates none of them.
It committed the exact condition this section exists to remove, in the commit
whose message argues against it.

Same rule, same person, same hour, adjacent step.

★ **What caught it was not the knowledge. It was repeating the ACT** — counting
what remained uncommitted *after* committing, rather than trusting that the
staged set was complete. The taxonomy names the class; naming does not fire.
A written standard is a lookup table someone has to remember to consult, and the
moment of not consulting it is precisely the moment one believes the work is
finished.

⇒ **THE OPERATIONAL FORM.** Attach the rule to the ACT, not to the class:
* after any bulk `add`/stage — **count what REMAINS**, and read the list;
* after any scan you are about to act on — reconcile against a count obtained
  **another way**, before acting;
* after any completion — ask **what would look identical if this had failed**.

Three habits rather than one principle, because the principle was already
written down and did not fire.

### The corollary for instruments — the subjects are not the only thing that rots
An instrument's `--selftest` must calibrate **coverage**, not only detection. A
tool can pass a detection control while reading half its surface — and then a
clean report means nothing. Every absence-claim in this project must be able to
show it looked.

★ **Coverage has TWO axes, and a calibration for one will not catch the other.**
* **Idiom coverage** — right files, one notation of two. (Track E's Audit IV tool
  read 51 of 96 checks and reported clean; all three calibration fixtures used
  the idiom it handled.)
* **Surface coverage** — every notation, wrong files. (`preflight_artifacts.py`
  v1 scanned `build.sh` and not the `gate_*.sh` scripts, so it **could not have
  found the bug it was written for**, and its planted controls passed.)

**The reconciliation that catches both:** a self-test must compare a count taken
**independently of the tool** against what the tool actually parsed, and refuse
to report on a mismatch. Planted controls only prove a tool sees what you built
it to see; a real-world control — revert a known fix and require the tool to find
it again — is what proves it sees what you did not.

⚠ **FOUR instrument failures in one day, all mine or track E's, none in the
subjects:** a tool that could not find its own motivating bug; a detection-only
calibration certifying a third of an input; a dependency scan matching on
**basename**, so `.bootelf_fix/asm.la` matched `asm.la` and produced 45 false
positives; and the same scan then **under-reporting**, missing eight untracked
files that were only found by acting on the result and re-checking. The
instruments need this standard at least as much as the subjects do.
### ★★ THE CODEX NAMES THIS FAILURE CLASS, AND ACCEPTS IT AS UNRESOLVED (2026-09-08)

The corollary above was derived from accidents. It is also **written down in the
governing spec**, as an accepted architectural risk — `CODEX AUTOPOIETICUS.tex`
§15.15 *"Risks Internal to the Architecture"*, item (iii), verified verbatim:

> *"A system that updates itself through ontological diffs can, if the diff engine
> itself contains a defect, propagate that defect recursively… **errors in the
> modification layer corrupt the layer that would detect errors.** … But undetected
> failures in the **verification system itself** remain a genuine risk — this is the
> halting problem applied to self-modifying systems, and **no architecture fully
> resolves it.**"*

★ **On 2026-09-08 four tracks hit exactly this, independently, in four organs, in
one afternoon** — all four are failures **of the verification layer**, not of the
subjects under test:
- **E** — `SENSE`'s mapping makes AATC's C2 unable to go false for any module
  (`9d3257b`); and three separate search-surface failures in the instruments used
  to check it (`7c94bdd`, `2c43b97`).
- **B** — a guard stopping at two of three address sites.
- **C** — a check absorbing a new emitter of the same signal.
- **Hub** — `gatesweep` printing nothing for 55 of 57 gates.

**This reframes them from "four unrelated instrument bugs" to four instances of a
named, accepted, architecturally unresolved risk.** ⚠ The practical consequence is
*not* fatalism: the codex's own mitigation is **formal verification of the core
components plus rollback**, and the operational form of that here is the standard
above — **an instrument must prove it LOOKED, and a null needs the same red path as
a green.** What the codex concedes is that this can never be *complete*; it does not
concede that it can be skipped.

★ **And the requirement has a name in the spec we did not know was written.**
`§15.8.3` Meta-Security defines five recursive levels, of which **Level 4 is the
Meta-Daemon `D(D)`: *"watches the watchers — monitors the integrity of the
monitoring systems themselves."*** That is precisely the layer all four defects
lived in. *(Positive-controlled before trusting: `Metacursive Audit` 2 hits,
`Meta-Daemon` 3 hits.)*

⚠ **FILED, NOT OPENED — the 18-row target.** `Def 15.27` (the *Metacursive Audit*)
tabulates **eighteen** components each asserted to satisfy `X(X) = X`, and
`Thm 15.28` proves `LogOS(LogOS) = LogOS` as a **conjunction over all eighteen** —
so **one failing component falsifies the theorem**, and a conjunction reported as a
single verdict hides which conjunct is load-bearing. **That is the `crit:compliance`
shape — four conditions, two unexercised — scaled to eighteen.** The Meta-Note
hedges in the same breath: *"the audit confirms no such vulnerability exists **at
the architectural level**"* — so whether the **build** satisfies 18 of 18 is
**unmeasured, and the codex does not claim it is.** A large item; recorded here so
it is not re-derived.

---

---

## OBSCURANTISM — COINED 2026-08-27. `[~]` MODULE GREEN, GATE PENDING.

`obscurantism.la`. Erik: euphemisms and meta-euphemisms create semantic
obscurantism, and it is a term the language should coin. Nothing in the corpus
named it.

    OBSCURE(t) := SDEPTH(CANON(t)) > SDEPTH(NORMK(t))

A form is obscurantist when it carries **avoidable depth** — same referent as its
own canonical form, more structure to walk. Fires on `⊗(∃,∃)` (1→0) and
`↻(↻LOVE)` (2→1); **spares** `⊕(B,A)` (1→1), a reordering rather than an
obscuring.

★ **Why depth and not α<1, settled by measurement.** Every non-canonical form is
α<1, including `⊕(B,A)`. The naive α-based definition was red-pathed against this
module's own corpus and **fails the `spares` arm**. Defining obscurantism as "not
in normal form" would have made the term mean nothing.

**The result:** obscurantism is DETECTABLE AND REMOVABLE, NOT PREVENTABLE. The
lexical euphemism is already unconstructible — `REN ≡ κ∘ETYM` by construction, so
"collateral damage" is unmintable; the form would have to carry
`⊗(killing,civilians)` in its own body. What remains can only be avoidable depth,
and any hearer collapses it in one total pass. Obscuring is self-defeating rather
than forbidden.
**BOUNDS:** relative to κ's declared rewrite set, as monosemy is; and the
utterance level is outside the semantics **by ruling R-B**, so
misleading-by-implicature is not something LA can police.

⚠ **`[~]` AND NOT `[✓]`, DELIBERATELY.** The module is green with three measured
red paths, but **its `build.sh` gate is not yet wired** — it was written during
build 5 and lands in build 6. By this document's own governing standard it is
therefore an UNGATED module, and marking it done would make it the ninth entry in
exactly the class this session spent the day pulling out. It is `[~]` until a
build has run its gate.

---

## ITEM 5 / L3 — THE GRAMMAR PARSING ITSELF. `[✓]` BOUNDED, 2026-08-26.

`grammar_l3.la`, gated. **GPARSE — interpreting the L1 data productions — parses the
source file that DEFINES those productions**, and rejects a corrupted copy of the same
token stream.

* **The lexer is NOT re-implemented.** `TOKENIZE` drives `parser.la`'s own `NEXT_TOKEN`,
  keeping its token-type names. A lexer written for this test could be tuned until the
  self-parse passed, which is exactly the result this must not be. (L2's stated bound:
  GPARSE consumes token types; lexing is parser.la's job.)
* **Composition is by concatenation, and the order is load-bearing.**
  `import("parser.la")` binds nothing — parser.la has no `export` line — so this uses the
  pattern `build.sh` already uses for `monosemy_test`. The two modules have
  **incompatible list encodings** (parser: `NIL=PAIR(FALSE)("")`, tagged-pair CONS;
  grammar: Scott), and **redefinition takes the FIRST binding**, so grammar.la must
  precede parser.la. Safe because parser.la's *lexer region* uses PAIR and strings only —
  zero NIL/CONS references, verified. parser.la's own `MAIN` must be trimmed or it wins
  the first-binding race and parses `kernel.la` instead. The gate asserts both facts.
* **The reject arm is what makes the accept mean anything** — a GPARSE returning TRUE
  unconditionally would produce an identical accept column.

### ★★ THE BOUND IS MEASURED, NOT GUESSED — and it is a PERFORMANCE bound
`grammar.la` lexes to **1689 tokens**. Lexing is fast; **GPARSE is the cost** — `MATCH`
backtracks naively and `P_MODULE` is a STAR over an ALT, so work grows superlinearly.
Measured on prefixes cut at definition boundaries (so a slice never ends mid-definition,
which would confuse "rejected because truncated" with "rejected because broken"):

| defs | lines | tokens | accept | reject-corrupted | time |
|---|---|---|---|---|---|
| 4 | 47 | 84 | T | F | 2s |
| 8 | 51 | 145 | T | F | 5s |
| 12 | 58 | 209 | T | F | 7s |
| 16 | 62 | 333 | T | F | 15s |
| 20 | 78 | 538 | T | F | 37s |

| **all** | **144** | **1689** | **T** | **F** | **1637s (27 min)** |

★★ **THE WHOLE FILE SELF-PARSES — witnessed 2026-08-26 19:05.** accept=T, reject=F on the
complete 1689-token stream. An earlier draft of this entry said the full run "was not
witnessed to terminate"; that was true when written and is now **false**, and it is
corrected here rather than quietly dropped, because a stale bound reads as a real one.
★ **accept=T and reject=F at EVERY size** — the grammar was never what was in doubt; the
interpreter is slow. Cost grows about **n^3.3** (3.1× the tokens for 44× the time), the
signature of `MATCH` re-scanning from the same position on every failed arm of a
STAR-over-ALT.
★ **The gate still asserts the 333-token prefix — for BUILD TIME, not for evidence.**
27 minutes is ~15% on a 3-hour build for a fact already established out of band.
★ The prefix is a prefix **of the self**, not a different corpus.

**Reported PARTIAL, per Erik's 2026-08-18 scope ruling** ("L3 only after L2 green, and
reported PARTIAL if it lands bounded").
**Inherited and unrepaired:** L2's associativity blind spot — `app_tail` is
left-associative and a verdict-only differential cannot see associativity.
**Red path exercised:** a corrupted subject → RED; removing `P_PRIMARY`'s `ident` arm →
RED. Plus two structural guards (the lexer survived the 395-line trim; parser's MAIN did
not).

---

## TIER 0 — CLOSED. ALL SEVEN RULINGS MADE (Erik, 2026-08-23/24)

This tier is no longer a blocker. Three were ruled on 2026-08-23 and are landed
and gated; four were ruled 2026-08-24 and are recorded here as the decisions
that govern the work below. **A gate may pin a set; it may not decide it** — so
every item below cites the ruling rather than inferring one.

### DECIDED AND LANDED

- `[✓]` **The three undeclared collisions — RESOLVED, and a fourth with them.**
  The first scan ever run *across* the content lexicon and the closed class
  found 11 collisions; eight were aliases the codex declares in its own gloss
  column (monosemy WORKING). The rulings:
    * **`You` keeps ▷(SELF,RECOGNITION); `Know` → ⊗(SELF,RECOGNITION).** You is
      closed-class and deixis/pragmatics/discourse are already gated on it.
    * **`Give` keeps ▷(BECOMING,RELATION); `Because` → ⊂(BECOMING,RELATION).**
      Give's gloss matches the form it has; Because's gloss described the
      converse, which If…then already occupies.
    * **`Change` keeps ⊗(BECOMING,FORM); `Can` → ⊗(FORM,BECOMING)** — "form in
      the process of arriving", which is the codex's own gloss for Can.
  ★ Three of these need a free form on an operand pair that a **commuting ⊗
  would have denied**. They rest on the LA.tex:2837 correction.
  **ZERO undeclared collisions remain**; `opgrammar.la` asserts each ruled pair
  ABSENT by name, so a partial revert fails rather than leaving a plausible total.

- `[✓]` **C9 — RESOLVED by moving negation off ⊕.** The tables were not the
  defect. `:5166`/`:5212` make `𝔤₆⊕X` the grammatical negation prefix, and with
  ⊕ commutative (:2854) **every ¬X is identical to the co-presence X⊕Void** —
  Bad/Grief was one visible instance of a grammar-wide collision. Negation now
  takes **⊂**, chosen because `ablate.la`'s census measured ⊂ at exactly ZERO
  uses: the only operator whose adoption could not collide. *The measurement
  selected the fix.* ⊕ keeps its commutativity and the ⊕/⊗ distinction survives.
  Grief keeps ⊕(LOVE,VOID); **Bad = ⊂(LOVE,VOID) IS ¬Love**, which is what the
  ruling said it was. ⊂ is no longer unused: census now ⊗=59 ⊕=3 ▷=24 **⊂=2** ↻=2.

- `[✓]` **C10 — NOT a ruling, an ERRATUM. 𝔤₆=Void, 𝔤₈=Form.** Backed by the
  primitive table (:4598), the phonym table (:5070), the dedicated chapter
  (:4718 "𝔤₆: Void — The Absence") and ~20 lexicon derivations. Only two prose
  lines — `:1210` and `:2050` — call 𝔤₈ "the Void"; they are stale draft text.
  **Fix those two lines; do not treat this as open.**

### RULED 2026-08-24 — FINAL, AND EACH CREATES WORK

- `[!→]` **A. `⊗(A,A) ≡ A` HOLDS ONLY FOR THE ARCHĒ.** For every other A,
  `⊗(A,A)` is a **distinct compound**. This is a *principled choice and must be
  documented as one*, because the current behaviour is otherwise indistinguishable
  from a rendering accident: `⊗(A,A)` used to be byte-identical to `A` in sound —
  with identical parents any weighted blend collapses, (2g+g)/3 = g — so an
  infinite family of distinct glyphs shared one phonym, and the renderer, not the
  theory, was deciding.
  **WORK:** state the Archē exception explicitly in `canon.la`'s rewrite set and
  in the paper; gate it in BOTH registers (glyphic and phonetic); assert the
  general case stays distinct. A rule that holds by accident is not a rule.

- `[!→]` **B. IMPLICATURE IS BANNED AT THE SEMANTIC LAYER.** LA encodes literal
  compositional meaning. Implicature **arises in use but is not a property of the
  language**. Grice is not refuted; he is placed outside the semantics.
  **WORK:** add the pragmatics note saying exactly that — the Logolaconic
  Principle (:6747) is a density principle and does not currently say it; and
  `pragmatics.la` must not grow a defeasible quantity layer. The ban is a
  *positive* claim about where meaning stops, and it needs stating, not silence.

  ### `[✓]` **B — DONE 2026-08-26, and the ban is MECHANICAL.**
  * **The ruling, stated positively** in `pragmatics_spec.la`'s header (★ the spec —
    `pragmatics.la` says "generated by specpipe.la — do not edit" on line 1). It
    REPLACES the old note that said implicature "survives monosemy and needs a ruling".
  * **Paper:** `LA_PAPER_ADDITIONS_3.md` §3e rewritten from "still open" to the ruling,
    with the falsification test spelled out; `LA_PAPER_ADDITIONS_2.md`'s "one open item
    needing YOUR ruling" resolved in place. The Logolaconic Principle (:6747) is a
    DENSITY principle and does not say this, so the sentence belongs AT that tag rather
    than being read into it.
  * **The mechanical constraint** (`build.sh`, pragmatics section): no
    `IMPLICATE`/`IMPLICATURE`/`SCALAR`/`QUANTITY`/`DEFEASIBLE`/`MAXIM` glyph may be
    defined in `pragmatics.la`, with the ruling QUOTED in the failure message so the
    next author reads the decision rather than the symptom.
  * ★★ **It is an ABSENCE assertion, so it proves it looked** — this session's own
    highest-yield finding applied to new code. A bare grep-for-absence passes over a
    missing, empty, or wrong file while checking nothing. Two POSITIVE controls guard
    it: the file is non-empty, and it really is the pragmatics module (defines
    `PRAGMATICS`). Red path exercised on all four states:

    | state | verdict |
    |---|---|
    | the real module | GREEN |
    | a `SCALAR` glyph added | **RED** — ban fires |
    | `pragmatics.la` EMPTY | **RED** — emptiness control fires |
    | a different non-empty file (absence TRUE but meaningless) | **RED** — positive control fires |

  * **BOUND:** this bans implicature from the SEMANTICS. It does not claim speakers
    cannot implicate — it claims implicature is not a fact about the language. The
    falsifier is named rather than avoided: an LA utterance whose literal composition
    underdetermines what a competent reader takes from it.

- `[!→]` **C. ★★ GENERATE FROM THE ROOT — the six co-primitives are a GAP, not a
  result.** `archroot.la`'s settled finding was that only THREE of nine primitives
  derive from the root and six are co-primitive. **Erik's ruling reverses the
  status of that finding**: it is an incompleteness to be closed, not a fact to be
  reported. Either **derive the remaining six**, or **name them as honest axioms
  with the seam stated explicitly**. ★ **NO STIPULATION** — an axiom declared as
  an axiom is acceptable; an axiom smuggled in as a derivation is not.
  **WORK:** re-open `archroot.la`. Its current conclusion must be re-tagged from
  "settled" to "the gap". `dyadseed.la` stands as-is — VOID ≡ Church zero, BEING
  ≡ Church one by eta, BECOMING ≡ successor — but it grounds the arithmetic
  stratum *beneath* the primitives and may not be cited as the derivation chain
  this ruling asks for.

  ### `[✓]` **C.1 — THE RE-TAG. DONE 2026-08-26.**
  Not a comment change: `build.sh` gates archroot's PRINTED VERDICT on the literal
  `6 co-primitive`, so it was a coupled edit across five sites — the module header,
  the printed verdict (`6 UNDERIVED ... = THE GAP`), the gate's expected string,
  build.sh's section prose **and its PASS message** (which still ANNOUNCED "6 are
  co-primitive atoms" while the gate above it checked UNDERIVED), plus `dyadseed.la`
  and `LA_PAPER_ADDITIONS_3.md`. Red path exercised: a simulated revert to
  "co-primitive" turns the gate RED, so the status is mechanically enforced.
  host==VM byte-identical on the re-tagged module.

  ### `[✓]` **C.2 — THE ATTEMPT. DONE 2026-08-26 — `archderive.la`, gated.**
  ★★ **The outcome is AXIOMS WITH THE SEAM STATED, and the seam turned out to be
  exact.** The root ∃ **is the identity combinator I** (`BEING = la s. s`, and
  ∃(∃)≡∃ is I(I)≡I). `{I}` is **closed under application** — I applied to anything
  returns that thing — so the terms reachable from the root by application alone are
  exactly `{I}`. Therefore:
  * **BEING is not a gap at all**: it IS the root, under another name. Witnessed.
  * The other five are **AXIOMS**, and what each one ADDS is now named, not waved at:

    | primitive | seam — what it introduces that I cannot do |
    |---|---|
    | `VOID` | **WEAKENING** — discards an argument |
    | `DEPTH` | **CONTRACTION** — duplicates an argument |
    | `BECOMING` | **CONTRACTION** — uses `f` twice (iteration) |
    | `FORM` | **EXCHANGE** — reorders its arguments |
    | `RELATION` | **EXCHANGE + ARITY 2** — the binary `FORM` |

  ★ **I is LINEAR: it neither discards, duplicates, nor reorders. The five
  primitives it cannot reach are precisely the three STRUCTURAL RULES it lacks.**
  That is why the derivation fails, and it is a result rather than a shortfall.
  **BOUND, stated in the module's own verdict:** closure is witnessed to depth 4
  (all 8 application trees over `{BEING}`); the induction is argued in prose, not
  mechanised. Every seam is witnessed BY REDUCTION on a total probe.
  **Gate:** `build.sh` "Arch derive", host + native VM + `cmp -s`. Red path
  measured, not guessed — mutating each of the six reds it, in **two different
  modes**: FORM/RELATION/BECOMING/BEING print `? no` and exit 0, while VOID/DEPTH
  make `str_eq` receive a non-string and HALT (rc 1) with the output TRUNCATED.
  The gate therefore asserts rc, every witness line, the absence of `? no`, **and
  the VERDICT line** — without that last one every grep still passes on the
  truncated file, because the greps that ran were true and the ones that would
  have failed were never reached.
  **NOT DONE / next:** derivation from a LARGER basis than the root alone is a
  different question and is not attempted here; if the root is ever taken to
  include more than `∃`, this result must be re-run against that basis.

  ### `[✓]` **A — DONE 2026-08-26, gated in BOTH registers.**
  `⊗(A,A) ≡ A` for the Archē alone; every other `⊗(A,A)` stays a DISTINCT compound.
  * **Glyphic:** `REWRITE_SYN` added to `canon_spec.la` beside `REWRITE_MC`, in the
    same declared-equivalence set the ruling named. ★ It had to go in the **SPEC** —
    `canon.la` is GENERATED by `canon_spec.la` and a hand-edit to it is silently
    overwritten the next time any gate runs the spec. (It was, mid-session; caught
    only by hashing the file before and after a test run.)
  * **Phonetic:** `SYNNORM` added to `phonym.la` (hand-written, nothing deploys it).
    ★★ **The two registers DISAGREED until now** — `NORMK` collapsed `⊗(∃,∃)→∃` while
    `NORMP` left it as `⊗(∃,∃)`. A rule holding in one register and not the other is
    not a rule about the LANGUAGE, it is a fact about one renderer, which is precisely
    what R-A exists to prevent.
  * **Gated both directions, both registers** (`build.sh`, canon section): the TRUE arm
    alone would be satisfied by a rule collapsing EVERY `⊗(A,A)`; the FALSE arm is the
    one that was missing when the collapse shipped.
  * **RED PATH PROVEN, and stronger than asked:** mutating the spec to collapse the
    general case makes `REWRITE_SYN: FAIL` and
    `module REJECTED — verification failed; canon.la not written`. **The compiler
    refuses to emit** — `canon.la`'s hash is unchanged. That is condition (a′) of the
    audit framework, witnessed.
  * **No regression:** `canon_spec` VERIFIED · `monosemy_test` still reports
    `idempot ⊗: ⊗(B,B) vs B : DISTINCT` · `fuzz_canon` 60/60 · `archroot` green ·
    all 8 phonym-dependent modules green (`phonorm`: `⊗order-kept OK`).
  * **BOUND:** a DECLARED equivalence, not a discovered one. It extends NORMK's
    equivalence theory, so monosemy stays enforced RELATIVE to that theory — NORMK's
    existing honest bound, unchanged.
  * ★ **Found while doing this:** `fuzz_canon.py` had the WRONG MODEL of what it
    tests — it listed `SYN` as commutative ("-> SORT2 (order-independent)") when
    `canon.la` routes SYN through order-KEEPING `WRAP2`. It reported **9 false
    failures on every run**, and nothing noticed because **build.sh never invokes it**
    (it appears only in a comment at `:2448`) — Q0's hazard exactly. Model corrected;
    now 60/60, and re-verified able to go red (breaking CON's commutativity fails it).

- `[!→]` **D. ⊗ AND ▷ NEED A SECOND PHONETIC CUE.** An accent mark alone is
  insufficient for the two most-used operators. Measured by `phoncoll.la`: **all
  fifteen** stress-only pairs in the vocabulary are the same operand pair under
  ⊗ versus ▷ — census ⊗=59, ▷=24 — and thirteen of the fifteen are the codex's
  own entries, so the thinness is the phonology's.
  **WORK:** add **duration, stress pattern, or a consonant-cluster distinction**
  so the contrast **survives across rendering environments**. It must hold in the
  romanised register a person reads and writes, not only in PCM: ▷ already gained
  a rate-carried marker in the audio, and that is exactly the kind of cue the
  written form still lacks. Re-run `phoncoll.la` after: the pinned stress-only
  set should shrink toward empty, and `phonseq.la` must then DETECT the new cue
  rather than reporting ▷ as a leaf.

  ### `[✓]` **D — DONE 2026-08-26. All fifteen collisions are GONE; the set measures EMPTY.**
  **The cue: a tail DURATION mark `":"` on ▷**, in addition to the head stress it
  already had (`lexicon.la`'s `PH`, DIR branch — hand-written, nothing deploys it).
  ASCII on purpose: the ruling requires the cue to survive across rendering
  environments, and `":"` occurred **zero** times in the phonym alphabet before the
  change, so it cannot collide with an existing contrast.
  `phoncoll` now reports `homophones=[] stress-only=[]` — **nothing was traded for it.**

  ★ **HONEST QUALIFICATION ON THE RULING'S OWN RATIONALE.** It ranked duration first
  because "▷ already carries a rate marker in PCM, so the written form would be
  following the audio rather than inventing." Read against the code that premise is
  **inexact**: `DIRP`'s acoustic marker is a periodic **amplitude modulation** of the
  tail (4/8-5/8-6/8 at period 128), and its own comment records that **duration is
  preserved exactly** — deliberately, because a ▷ compound sits in the gated WAV output
  and a length change would move the file size. So the written mark is **not** a
  transcription of the acoustic parameter. What it *is*: a convention putting the
  written cue on the **same operand** the audio marks. Still a strict gain, because
  before this **the writing stressed the HEAD while the audio modulated the TAIL** —
  the two registers did not agree on which operand carries ▷ at all.

  ★★ **THE COST, WHICH IS REAL AND IS ERIK'S TO WEIGH.** The codex's printed IPA
  predates the cue, so **every ▷ entry's derived phonym now differs from it**:
  * `lexicon.la` codex concordance: `agree=55 diverge=2 [Think Gratitude]` →
    **`agree=43 diverge=14`**
  * `la_lexicon_appendix.tex` divergent rows: **4 → 24**

  Both new numbers are **DERIVED, not captured**: 14 = the LEX entries whose canonical
  form contains `>` (KAN's ▷) and 24 = all ▷ entries (14 content + 10 closed-class),
  established by an **independent census before the change** and matching `ablate.la`'s
  census of ▷=24. The four previous divergences (vowel elision: Think/Gratitude/
  Question/Past) are themselves ▷ entries and are **absorbed**, not added — which is why
  it is 24 and not 28, the arithmetic a captured number would have hidden.
  ⚠ **The codex is not wrong; it is older than the cue.** Whether its printed forms
  should be reissued to carry `":"` is Erik's call and is **NOT decided here.**

  ★ **THE PROOF-IT-LOOKED CONTROL HAD TO BE RE-FOUNDED, and deleting it would have been
  the wrong repair.** `phoncoll`'s `OK_SAW` asserted the *vocabulary* still contained a
  stress-only pair (fixture: Know/You). R-D removed the last one, so it failed for the
  **right** reason — its fixture was an accident of the vocabulary, and the accident got
  fixed. But it is the only thing separating "no collisions" from "the scan is broken",
  this codebase's highest-yield defect shape. It is now founded on **constructed** input
  that fixing the language cannot remove, exercised in both directions
  (`/m'ashi/` vs `/mashi/` must match; `/mashi/` vs `/mashu/` must not), and
  **verified red-capable**: a `STRIP` that strips nothing flips the positive arm.

  **NOT CLOSED — ruling item 4.** `phonseq.la` "must DETECT the new cue". R-D's cue is
  **romanised**; `phonseq` decodes **PCM**, so it is untouched and its pinned confusion
  matrix is unchanged (verified: `TFFF|FTFF|FTTF|FFFT|FFFT|T`, `dir` column firing).
  Whether the **acoustic** ▷ cue is sufficient is the separate open question it always
  was, and it is **not** closed by this work.


## TIER 1 — ROOT CAUSES (fixing these prevents whole defect classes)

- `[ ]` **`gate_srcdrift.py` can vanish and the build stays green** —
  `build.sh:820-831` guards the whole drift check with
  `if command -v python3 && [ -f gate_srcdrift.py ]; then … else echo "SKIP …"; fi`.
  Delete the gate file, or run on a box without `python3`, and the build prints
  a SKIP line and **continues at rc 0**, with the entire 290-SRC/live-pair check
  across all 14 spec modules silently absent. Verified by running `:820-:831`
  verbatim with the file removed: it printed the SKIP and `SECTION_RC=0`.
  ★ This is the **exact** pattern the III-1 correction was written about, and
  which `build.sh:405-411` cites in its own comment when hard-failing the
  signature gates — "`if [ -f gate ]; then … else echo SKIP; fi` kept the build
  green when the file was deleted." The signature layer was fixed; this
  invocation was not. It is Door **iii** with a SKIP line as its alibi, and
  under this project's own rule ("a SKIP must not satisfy a gate invocation") a
  missing gate here is a broken checkout, not a configuration. Gate: make the
  absence hard-fail, as the signature block does. Red path: delete
  `gate_srcdrift.py` and assert the build exits non-zero — the arm that is green
  today. *Tier 1: it is the instrument protecting every generated module, and it
  is the one that can disappear without a sound.*
- `[ ]` **A SKIP satisfies a gate invocation in FOUR places — and the
  `verified-*` checkpoint tag cannot tell.** The item above is one instance;
  this is the census, and the census is worse than the instance. Every site
  below was verified by running its block **verbatim with the file absent**,
  not by reading it — all four printed a SKIP line and returned **`BLOCK_RC=0`
  under `set -e`**:

  | site | absent file | what silently stops running |
  |---|---|---|
  | `build.sh:820` | `gate_srcdrift.py` | the 290-pair SRC/live drift check, all 14 spec modules |
  | `build.sh:2688` | `fuzz_grammar.py` | the transcribed-grammar ↔ `parser.la` differential |
  | `build.sh:4305` | `gate_selfext0.py` | the self-extension tripwire |
  | `build.sh:4527` | `mutate.py` | **the mutation lever** — the instrument that certifies other gates can go red |

  ★★ **THE KEYSTONE: THE PREMISE IS WRITTEN DOWN, AND IT IS FALSE.**
  `build.sh:7167-7188` tags the commit `verified-<date>-<sha>` with the annotation
  *"Full audit (build.sh) passed clean."*, justified by its own comment:
  *"Reached only when every check above passed (each failure exits 1 earlier), so
  the audit is clean here."* **A check that SKIPs does not exit 1.** What the code
  establishes is "no check FAILED", which is not "every check passed" — it
  includes every check that never ran. The tag's three guards are working tree,
  git-dir, and pre-existing tag; **not one of them is a gate result.** So a run on
  a box without `python3` produces a durable, human-facing certification that four
  instruments — including the one that certifies the others — never executed.
  This is Door **iii** terminating in Door **vi**: the announcement is not prose
  this time, it is a **git tag a person rolls back to.**

  ★ **THE III-1 REPAIR WAS APPLIED BY FAMILY, NOT BY SHAPE.** `build.sh` records
  six sibling repairs of exactly this defect in its own comments — `:4365 :4393
  :4420 :4448 :4468 :4497`, each reading *"This read `if [ -f gate ]; then … else
  echo SKIP; fi`, so deleting the file kept the build GREEN."* All six are `.sh`
  gates in the selfext family. **`gate_selfext0.py` sits 60 lines ABOVE its six
  repaired siblings, in the same family, and still has the defect** — it was
  passed over because it is a `.py`, not because anyone judged it exempt. The
  rule was known, written, and applied to a *family* rather than to a *shape*.

  ★ **THE PRECEDENT IS IN THE TREE, TWICE, IN ITS OWN WORDS.**
  `gate_selfext2b.sh:65` — *"this gate now FAILS rather than exiting 0, because a
  SKIP is indistinguishable from a PASS to the one bit of resolution build.sh
  reads, and this gate skipped silently in four consecutive builds"* — and
  `gate_xmssidx_core.sh:46` — *"a missing input is a broken checkout, not a reason
  to skip"*. Neither is a new rule; both are this one, already applied.

  ★ **`fuzz_grammar` HAS TWO FURTHER CHANNELS, AND THE SECOND IS NOT ABOUT SKIPS
  AT ALL.**
  (a) It SKIPs green **with the gate file present**: `fuzz_grammar.py:298` does
  `print("SKIP …"); return 0` when its inputs are missing, and `build.sh:2690`
  matches `^SKIP` and continues. Measured: `--logos <empty dir>` → `GATE_RC=0`.
  This is Rule 1 verbatim — *a gate that declines to run is indistinguishable
  from one that ran and passed.*
  (b) ★★ **IT VALIDATES ANOTHER TRACK'S TREE.** `fuzz_grammar.py:285` defaults
  `--logos` to **`~/logos`**, and `build.sh:2689` invokes it with **no `--logos`**.
  On every worktree, this gate checks `~/logos/parser.la` and `~/logos/tiny_host`
  — *not the tree being built*. Both halves red-tested: perturbing the lexer's
  `glyph` keyword in a copied tree turned it **RED, rc 1** (4 valid programs
  `model=accept parser=reject`), so the gate is live and capable; and `parser.la`
  is byte-identical between `~/logos` and `~/logos-e` today, so the defect is
  **latent, not currently producing a wrong verdict — which is exactly why it has
  survived.** ★ This is a **FIFTH** hardcoded reach into another track's tree,
  after the Tier 1 item *"Four hardcoded absolute paths"* was closed `[✓]` on
  2026-08-23. That sweep covered the `freeze_*` family; this one is in a **gate**.
  **The same meta-pattern as the paragraph above: an item closed by family rather
  than by shape.** ★ It also falsifies a live operational assumption — a session
  running gates under `unshare -rm` with a private `/tmp` is *not* isolated from a
  hardcoded `~/logos`: a mount namespace gives a session its own `/tmp`, never its
  own worktree.

  ★ **THE ENVIRONMENTAL SKIPS ARE A DIFFERENT CLASS AND ARE NOT COUNTED HERE** —
  state this explicitly, because the next reader will otherwise fold them in and
  inflate the number. `nasm :1698`, `ld :2255/:2278`, DRM `:3941/:3944`, and the
  **36 `kernel/gate_*.sh`** scripts that do `command -v qemu-system-x86_64 || {
  echo SKIP; exit 0; }` (measured: `GATE_RC=0`) are absent **toolchain**, not an
  absent **checkout**. A missing gate file is a broken checkout and must hard-fail;
  a missing QEMU is a real machine. But their remedy is not "do nothing": on a
  QEMU-less box **36 kernel gates skip and the `verified-*` tag is still applied**,
  so the environmental class needs a **census assertion** — the build must refuse
  to certify a run it did not fully execute — rather than a hard-fail per site.
  ⚠ Checked and CLEARED, recorded because it looks alarming and the next reader
  will trip on it: `qemu-system-x86_64` here resolves to a **shim**
  (`~/.logos/shims/`), which is honest — it `exec`s `/usr/bin/qemu-system-x86_64`
  on every path and only adds a lock-contention warning. It never fakes success.

  **Gate:** (1) each of the four sites hard-fails on an absent file, as
  `build.sh:410-417` already does for the five signature gates; (2) `build.sh`
  passes `--logos "$PWD"` to `fuzz_grammar.py` and stops accepting `^SKIP` as
  success; (3) the build **tallies SKIPs and refuses to auto-tag** when the count
  is non-zero, so the checkpoint asserts what was run.
  **Red paths:** delete each of the four files and assert the build exits
  non-zero — *the arm that is green today, in all four*; point `--logos` at a tree
  with a perturbed `parser.la` and assert RED (**already exercised: rc 1**); and
  force one SKIP and assert **no `verified-*` tag is created** — that last one is
  the arm that matters, because a tag-suppression check that is only ever run on a
  clean box passes for a build that never suppresses anything.
  ⚠ **Filed, not fixed.** `build.sh` is shared and has changed on four branches
  since the merge-base; the repair is an integration decision for Erik, the same
  posture Track C is holding on its gate census.
  ★ **Adjacent instrument, cite together:** the hub's `~/.logos/verify/gatesweep.sh`
  asks *"does anything run this gate at all"* (result: A/B/E clean, C 25 dead,
  D 26 undocumented). This item asks *"can a gate that IS invoked be satisfied
  without running"*. Neither question implies the other, and between them they
  cover the class.
  *Tier 1: the mutation lever and the drift gate are the two instruments every
  other gate's credibility rests on, and both can be satisfied by their own
  absence.*
- `[ ]` **The Codex's own integration gate is unimplemented** — `crit:compliance`
  (`CODEX_AUTOPOIETICUS.tex` :816-:833), the **Ontosyntactic Compliance
  Criterion**: *every* component integrated into LogOS must satisfy five
  conditions — (i) `Id(C): C ≡ C`, (ii) `NC(C): ¬(C ∧ ¬C)`, (iii) `EM(C): C ∨ ¬C`,
  (iv) `TC(C): C(C) = C` (tautological closure), (v) `TTR(C): T(C) ≡ R(C)`. Each
  condition has a piece — `metalogic.la` carries (i)-(iii) as first-class glyphs,
  `canon.la`'s `AUTO_OK` is (iv), `aatc.la` is (v) — but **nothing applies the
  criterion to every component**. There is no per-module compliance sweep in
  `build.sh`, so a module can enter the tree having satisfied none of the five.
  Checked functionally, not by name: the only `compliance` in the tree is prose
  in an `aatc_spec.la:170` comment, and every `TTR` hit is the letters inside
  "a**ttr**actor" (`naming.la`) — substring artifacts, named here rather than
  discarded, because a grep that finds nothing is not evidence of absence.
  Gate: a sweep applying all five conditions to each `.la` module, failing the
  build on the first non-compliant one. Red path: feed it a module that is
  self-contradictory by construction (a glyph declared at one arity and defined
  at another — `specpipe.la`'s DEPLOY already rejects exactly this for (ii), so
  the red path is known to be reachable) and assert the sweep reports it; then
  assert the sweep FAILS if the condition list is emptied, so a sweep over zero
  conditions cannot report green. *Tier 1: this is the criterion by which every
  other item's output is admitted.*

  ★★ **THE GATE THIS ITEM SPECIFIES WOULD BE VACUOUS — FOUND BY TRYING TO BUILD
  IT (2026-09-08).** Two corrections to this item's own premise, both measured:

  **(a) The machinery is not absent; it is undriven and shallow.** `aatc.la`
  exports `SENSE_SRC`/`SENSE_FILE`/`AUDIT_FILE`/`ORGAN_OK`, and `AUDIT_FILE` **is**
  exercised — on exactly **one** file, `AUDIT_FILE("kernel.la")("MAIN")` at
  `build.sh:2487`. So "nothing applies the criterion to every component" is right,
  but the gap is a **driver over all 146 modules plus depth**, not missing
  machinery. An item that reads as "build it" when the truth is "drive it and
  deepen it" misdirects whoever picks it up.

  **(b) The criterion cannot distinguish a real module from a one-line stub.**
  `SENSE_SRC` derives its facts from **text `CONTAINS` checks** — does the source
  contain `glyph <concept>`, is it non-empty, does it contain `import(`. Measured
  with `AUDIT_FILE(path)("MAIN")` on the C host:

  | input | verdict |
  |---|---|
  | `kernel.la` (the real module) | `TTTT` |
  | `glyph MAIN = "x"` — one line | `TTTT` |
  | `glyph MAIN = "x"` + literal non-LA garbage | `TTTT` |
  | a module with no namesake glyph | `FTTT` |
  | an empty file | `FTFT` |

  It is **not inert** — positions 1 and 3 discriminate (namesake present,
  non-empty). But **positions 2 and 4 (`SELF_APPLICATION`, `CLOSURE`) were `T` for
  every input tested, including the empty file**, and the top three rows are
  indistinguishable. A sweep over 146 modules built on this would print **146
  green `TTTT`s** and assert little beyond "the file is non-empty and mentions its
  own name" — **the exact vacuity this item's own red path was written against**,
  arriving not as "a sweep over zero conditions" but as four conditions two of
  which never fire.

  ⚠ **This is NOT a defect in `aatc.la`, which does not overclaim:**
  `build.sh:2506`'s PASS line says "structural facts, not full spec-verification"
  in as many words. The defect is in **this item's proposed gate**, which would
  have built a 146-module green on machinery whose own gate states it cannot carry
  that weight. ★ Found only by *attempting* the build and measuring the criterion
  against deliberately non-compliant input — reading the export list showed
  `MODULE`/`ORGAN_OK`/`AUDIT_FILE` and made the sweep look nearly free, which is
  how it would have been built. **Revised gate:** first give `SELF_APPLICATION` and
  `CLOSURE` inputs that make them go `F`, or they are two constants wearing
  conditions' names; then a predicate that separates `kernel.la` from
  `glyph MAIN = "x"`. **Red path first, sweep second** — in that order, because the
  sweep is the part that looks like progress.

  ★★★ **CORRECTION, SAME DAY, TO THE PARAGRAPH ABOVE — "two of four never fire"
  WAS WRONG, AND BEING WRONG PRODUCED THE REAL FINDING.** The five inputs above
  were all **import-free**, and `CLOSURE` keys off exactly the property none of
  them had. Measured: a module containing `import(` returns **`TTTF`** — **C4
  FIRES.** I concluded a condition was constant from a sample that could not
  exercise it, which is the same error as an absorbed perturbation, one level up:
  *the input never reached the condition.*

  **The corrected table of which conditions discriminate:**

  | | condition | fires? | on what |
  |---|---|---|---|
  | C1 | `SELF_INCLUSION` | **yes** | `F` when the source lacks `glyph <concept>` |
  | C2 | `SELF_APPLICATION` | **NO — a genuine constant** | `SENSE` sets its field to `IF(selfok)(mname)("FAIL")`, never `""`, and `C2 = NOT(str_eq(·)(""))` |
  | C3 | `SELF_VALIDATION` | **yes** | `F` on an empty file |
  | C4 | `CLOSURE` | **yes** | `F` when the source contains `import(` |

  ★ **AND `aatc.la` IS MORE FAITHFUL THAN I CREDITED.** `CLOSURE` is
  `str_eq(SLACKS(s))("")` over a `dep` field that is precisely `CONTAINS(src)("import(")`
  — a literal implementation of the Codex's C4, *"closure without external
  structure… it imports what it does not ground."* **One constant, not two.**

  ★★ **THE REAL DEFECT IS A LEVEL ERROR, AND IT INVERTS THE PREDICTION.** The
  sweep would **not** print 146 green `TTTT`s. Measured over the tree: **84 of 146
  modules contain `import(`**, so they report `TTTF` and **62** report `TTTT`. This
  item's stated gate — *"failing the build on the first non-compliant one"* —
  would therefore **fail the build on 57% of the tree, starting at `app.la`
  importing `stdlib.la`**. And that failure would be **FALSE**: a module importing
  another module *of the same system* is not importing **external** structure; it
  is composing within the framework. The Codex's C4 governs the closure of a
  **framework**; `AUDIT_FILE` applies it to a **file**. *The criterion is being
  measured one level below where it lives* — which is why it reads as damning for
  ordinary composition and permissive for a one-line stub.

  **So the revised gate is revised again, and the order still holds:** C2 needs a
  red path or must be demoted from a condition to a constant; and C4 needs a
  notion of *external* that distinguishes an in-system `import` from an ungrounded
  dependency, **before** any sweep — otherwise the sweep's first act is to fail 84
  correct modules. **Red path first, sweep second**, for a second and different
  reason than the one first recorded here.
  ★★ **C2's RED PATH, RESOLVED — AND IT IS NOT A DEMOTION.** The correction above
  called `SELF_APPLICATION` "a genuine constant". Measured across **every**
  constructor rather than the one path I had tried, that is also too narrow:

  | fixture | how built | verdict |
  |---|---|---|
  | `M_AATC` / `M_FAIL` / `M_SICK3` | `MODULE` → `SENSE` (`build.sh:2483-2485`) | `TTTT` / `TTFT` / `FTFF` |
  | `ARCHE` (`build.sh:2479`) | `STRUCT` **directly** | `TTTT` |
  | `BROKEN` (`build.sh:2480`) | `STRUCT` **directly**, field 3 = `""` | **`FFFF`** |

  **C2 fires, and it is already exercised in the build** — `BROKEN` is precisely a
  fixture with an empty self-application field, and it reads `F` in position 2. So
  C2 is live, tested code and must **not** be demoted, which is what the paragraph
  above proposed.

  ★ **The defect is in `SENSE`'s mapping, not in the condition.** `SENSE` sets the
  self-application field to `IF(selfok)(la _. mname)(la _. "FAIL")` — **both
  branches non-empty** — and `C2 = NOT(str_eq(·)(""))`. So for **any module or
  file**, which reaches the AATC only through `SENSE`/`SENSE_SRC`/`SENSE_FILE`, C2
  is **structurally incapable of being false**. `SENSE` has no way to express
  *"this module lacks self-application."* A 146-module sweep would therefore test
  **three conditions while printing a four-letter verdict that reads as four.**
  ⚠ **Give `SENSE` a false branch; do not weaken the condition** — the condition
  works, the sensor cannot drive it.

  ★ **Method note — third narrowing inside one item, second inside its own
  correction.** I concluded "constant" from the `SENSE` path, then from the
  `MODULE` fixtures; a wider sample moved the answer both times. Every step was
  measured and every step was still too narrow. **The reachable-input set is itself
  something to ENUMERATE, not assume** — an unreached condition and an absorbed
  perturbation are the same error. This one was caught only by grepping for *who
  constructs a `STRUCT`* rather than trusting that `SENSE` was the only constructor.
  ★★ **C4's "EXTERNAL", RESOLVED FROM THE SOURCE TEXT — and it confirms the
  84-module false-fail.** The operative definition is in the Codex's own C4
  self-audit (`Being & Becoming.tex:6630`, verified verbatim), where the Codex
  scores itself `✓`:

  > **C4. Closure.** *Does anything external supply what this Codex lacks? Every
  > concept is **derived internally** from ∃(∃) ≡ ∃. No external axioms are
  > imported. No external authorities are cited as grounds. No external framework
  > supplies the criterion. The Archē is its own peer.* ✓

  ★ **The distinction is DERIVED INTERNALLY vs SUPPLIED EXTERNALLY — not "contains
  no reference."** The Codex passes C4 while being saturated with internal
  cross-reference, because internal derivation is not external supply. So
  `CLOSURE = str_eq(dep)("")` over `dep = CONTAINS(src)("import(")` is **the wrong
  test**: `import("stdlib.la")` names a module *of this framework, derived from the
  same ground*. It is the LA analogue of an internal chapter reference, which the
  source text scores `✓`.

  **Operational C4 for a LogOS module**, from that definition:
  - `import("X.la")` where `X.la` is **in the tree** → **INTERNAL** (derived within
    the framework) — *not* a C4 failure. This is the 84 modules.
  - a name that **resolves nowhere in the system** (an unbound reference) →
    **EXTERNAL** — the system does not derive what it uses. *This* is C4's failure
    mode, and every engine already halts loudly on it (`secd: unbound variable`),
    so the red path exists and is reachable.
  - a **host builtin** → the boundary case, and the project already rules on it:
    *"the host is the physics"*. Substrate, not external supply — but it is the one
    that deserves an explicit ruling rather than an inference.

  **So the sweep's C4 becomes a resolvability check, not a substring check**, and
  the item's original gate — *"fail the build on the first non-compliant one"* —
  stops failing 57% of the tree for composing correctly.

  ★★★ **CORRECTION (2026-09-08, same day): *Being & Becoming* IS IN THE TREE.**
  `df94b2b`'s commit message recorded that `aatc.la` implements C1–C4 with "its
  governing source text outside the repo… only in `~/Downloads/CODICIES/`". **Wrong.**
  It is tracked, and has been since `6e3ce91` (2026-06-02, *"Publish curated
  codices"*):

      codices/published/Being___Becoming.tex     (+ _ZH, and B_B_Arabic/German, Etre_et_Devenir)

  ★ **Three mechanisms in my own searches, all producing the same confident empty:**
  (1) I grepped the file list for **`codex`**, and the directory is **`codices`** —
  which does not contain that substring (verified: `echo codices | grep -c codex` →
  `0`); (2) `ls ~/logos/*.tex` globs the **root only**, not subdirectories; (3) my
  `find` over `~/logos/codices` **did return 91 matches** — and I piped it through
  `head`, then read the visible lines as the whole result. **The same truncation
  failure as `cut -c1-180`, in the same session, on the same day I wrote the rule.**
  The filename also encodes `" & "` as **`___`**, so "Being & Becoming" and "Being
  and Becoming" both miss it.

  ✓ **`b6f8b30`'s C4 ruling STANDS, and now stands on IN-REPO text** — verified
  directly in `codices/published/Being___Becoming.tex` (positive control `AATC` = 89
  hits): the C4 self-audit is present verbatim (*"…Every concept is derived
  internally… The Archē is its own peer. ✓"*), as are `C4 is the discriminant` and
  `change changes`. The ruling is **stronger** than when filed, since it no longer
  cites a document outside the tree.

  ⚠ **BUT THE TWO COPIES DIVERGE, AND THAT IS A REAL FINDING.**
  repo `00b3e227` / **7,102 lines** vs `~/Downloads` `8f57f0b2` / **7,673 lines** —
  **571 lines apart**; the in-repo copy is the **older June curated publication**.
  CLAUDE.md's rule — *"a divergence between code and codex cannot be adjudicated
  from a document outside the repo"* — is satisfied by the in-repo copy, **which
  introduces a staleness problem in its place**: anyone auditing code-against-codex
  from the tree is auditing against a text 571 lines behind. **Which copy governs is
  Erik's ruling.** Filed, not acted on. *(The hypothesis "a second divergent copy of
  the governing spec would itself be a finding" was raised and cleared for
  `CODEX_AUTOPOIETICUS.tex`, which is byte-identical across all copies — **the clean
  result did not generalise, and I generalised it.**)*

  ★★★ **CORRECTION TO THIS ITEM'S CITATION NOTE (`b6f8b30`) — THE QUOTE IS REAL,
  AND MY SEARCH COULD NOT HAVE FOUND IT.** I recorded that *"A bug IS Pathology 4
  (Inversion) at the computational resolution"* is **not** in *Logos & Paradox*.
  **It is** — verbatim, at `Logos & Paradox English.tex:4866`, in the same
  sentence-pair as the PCP line I accepted:

  > *The type checker IS the PCP of the compiler… **A `\textbf{bug}` IS Pathology 4
  > (Inversion) at the computational resolution: the code says one thing, the
  > program does another.** Debugging IS ∂_Λ applied to source code…*

  ★ **The markup is why it hid.** The source reads `A \textbf{bug} IS Pathology 4`,
  so `grep "A bug"` **cannot** match — not *did not*: the string does not exist in
  the file although the sentence does. **My search's reachable set was "strings as
  rendered"; the file's is "strings as marked up."** That is this item's own law —
  *the reachable-input set is itself something to enumerate, not assume* — applied
  to the instrument I used to check someone else, and it is the same shape as a
  perturbation that cannot reach the arm: **a search over the wrong surface returns
  a confident empty.**
  ⚠ **And I had the line in my own results and cut it off.** My `Pathology 4` scan
  printed `:4866` and I truncated the output at 180 characters, before the
  sentence. Two independent failures, one conclusion.

  ★★ **THE ASYMMETRY RUNS BOTH WAYS, WHICH IS THE PART TO KEEP.** I wrote that a
  quote agreeing with my conclusion is the one to check hardest. I did check — and
  **the check was wrong in the other direction**: I nearly discarded a TRUE quote
  supporting a CORRECT mapping, on the strength of a search that could not have
  found it. Agreement makes you under-check; suspicion makes you **trust a
  disconfirming null**. ★ **A null result needs the same red path as a green one** —
  the grep should have been validated against a string known to be on that line,
  and `\textbf{type error}` would have failed identically.

  **Substantively the mapping stands and is usable:** a bug **is** Inversion at the
  computational resolution, whose prescribed cure is **Exposure — name the
  divergence — not repair of the gate**. That is the disposition already chosen for
  `SENSE` above (*give it a false branch; do not weaken the condition*), reached
  independently and before the text was in hand.
- `[ ]` **∂ is asserted universally and measured nowhere — FILED, NOT OPENED
  (2026-09-08).** *Being & Becoming* Ch. 11 claims **∂ = 1** universally: every
  autological structure reaches full self-transparency in **one** pass. Ch. 6
  defines ∂ as a **three-band** scale (`= 1` single pass · `> 1` multiple passes,
  **unstable** · `= ∞` never stabilises). **Nothing in the build measures ∂ as a
  DEPTH.** Everything metacursive tests the *self-application* form — `X(X) = X`,
  `IS_TYPE(IS_TYPE)` (`metadebug.la:321`/`:364`, asserted at `build.sh:740-741`
  as `T5_self: T`), `META_DEBUG`, `AUTO_OK`, `C(C) = C` — and **by construction
  cannot distinguish "stabilises at pass 1" from "stabilises at pass 2"**, because
  applying an operator to itself *once* produces one verdict. `IS_TYPE(IS_TYPE)`
  also returns a **boolean**, so it measures *satisfaction*, not the identity.

  ★★ **WHY THIS IS NOW A GATE AND NOT A SEARCH — the control the corpus supplies.**
  A search that finds nothing is the weakest possible evidence, which is why this
  item was declined when first raised. The corpus names its own **sole** exception,
  so the search has a **pass/fail criterion fixed in advance**. `Logos & Paradox
  English.tex:5523` (verified verbatim, positive-controlled before trusting):

  > *"**Negation IS the sole linguistic operator that fails metacursion.** Every
  > other concept X satisfies X(X) = X… Define ¬_F(X)(P) = ¬(X(P))… Then
  > ¬_F(¬_F)(P) = ¬(¬P) = P = id(P). Therefore **¬_F(¬_F) = id**. At the operator
  > level, **id IS ∃**… it IS the sole operator that fails (X(X) ≠ X)."*

  Against Ch. 11's stated falsification form — *exhibit X where X(X) ≠ X but
  X(X)(X(X)) = X(X)* — with `X = ¬_F`: `X(X) = id ≠ ¬_F` (asserted outright), and
  `X(X)(X(X)) = id(id) = id = X(X)` (∃(∃) ≡ ∃ **is** that idempotence). Exact fit,
  stable at the second pass.

  **Gate:** a ∂-sweep over the tree's operators must find **exactly one** failure of
  `X(X) = X`, and it must be **negation**. **Red paths, both directions:** *zero*
  found ⟹ **the search is broken**, not the corpus vindicated — the instrument
  cannot see the one case the text marks; *two or more* ⟹ either a real second case
  or a false positive, and **either outcome is informative**. That is a red path
  *for a search*, which is precisely what this item lacked.

  ⚠ **Honest caveat, stated up front.** The Codex frames negation as **failing
  autology**, not as "∂ = 2". Whether *fails at pass one, closes at pass two* counts
  as ∂ = 2 or simply as **not-autological** is a typing question the corpus does not
  settle. As a **control** it is ideal either way — the instrument must find the one
  case the text marks. As a **falsification of ∂ = 1** it is **not**, since ∂ = 1 is
  claimed *for autological structures* and negation is the named non-autological
  one. ⚠ Two earlier candidates were **withdrawn** and are recorded so they are not
  re-proposed: **CTMU ∂ > 1** (`B&B:4045`) is a *closure failure* and `B&B:3708`
  calls that band **unstable** — it shares a symbol with a stable second-pass fixed
  point, not a meaning; and **ρ-composition** (`L&P:1709`) is the Codex
  *reconciling itself* — two typed readings of one glyph-form, output-level ∂ = 1
  and act-level ∂ = 2, where **nothing fails**. A control needs something that
  actually breaks.

  *Filed, not opened: `crit:compliance` and the KEM are further along, and this is
  better opened whole. Same shape as `crit:compliance` one level up — the criterion
  is stated; the discriminating measurement is absent.*

- `[✓]` **The spec pipeline emits no `export`.** — **LANDED in 9112c18
  (2026-08-27); confirmed by the Codex audit 2026-09-08.** Both halves of this
  item's own stated gate now hold, checked by running them rather than by reading
  the commit: all ten generated modules (`canon`, `aatc`, `metalogic`, `swc`,
  `glyphdag`, `pragmatics`, `deixis`, `psc`, `topoembed`, `primitives`) carry an
  `export` line, and an importer resolves the name — `import("canon.la")` then
  `CANON(SYN(PRIM("BEING"))(PRIM("FORM")))` prints `⊗(BEING,FORM)`, where this
  item recorded `unbound variable`. The drift half is `gate_srcdrift.py` (290
  SRC/live pairs across 14 spec modules, red path exercised). ★ It stayed `[ ]`
  for twelve days after it was fixed. An item marked open that the build says is
  closed misdirects work exactly as an item marked closed that is open — the
  queue was derived from the paragraph, not resolved against the artifact.
  Was: Every generated module —
  `canon`, `aatc`, `metalogic`, `swc`, `glyphdag`, `pragmatics`, `deixis`, `psc`,
  `topoembed` — is **unreachable by `import`**. Verified: `import("canon.la")`
  then `CANON(...)` gives `unbound variable`. This is why ⊗ was sorted in FIVE
  places instead of one, why `denote.la` and `metaglyph.la` re-declare, and why
  `entropy.la` had to re-implement κ. **The single highest-leverage fix in this
  document.** Gate: a module importing `canon.la` resolves `CANON`; and a
  drift gate asserting every re-implementation agrees with its source.
  *Paper: §Limitations, [B].*
- `[ ]` **Nine modules built but never gated** — `sglyph`, `sglyph_gate`,
  `phonseq`, `tactile`, `crossmodal`, `modality`, `explain`, `depthreport`,
  `sglyph_probe`. Zero occurrences in `build.sh`. **`sglyph_gate.la` is a gate
  nothing runs.** Under the project's own "a claim without a gate is not
  counted", these must be wired before they are claimed.
  *Paper: they are cited in ADDITIONS_2 §C/D — must be gated first or tagged [B].*
- `[ ]` **Three gates that cannot go RED.** (a) phonetic α=1 is a `grep` for a
  sentence the module prints unconditionally; (b) the 8/8 phonetic injectivity
  gate's concept list contains no two entries sharing a leaf-set, so the
  property is untestable by construction; (c) `seal_test.la:36`
  `COMPLEXITY = la g. 1` is a constant function. Each must be given a real red
  path or demoted to a REPORT. *Paper: §Falsification, the vacuity bet.*
- `[✓]` **Four hardcoded absolute paths** — **DONE 2026-08-23**: all four now derive from `Path(__file__).resolve().parent`; the `~/logos-d` positive control is derived + `LOGOS_CONTROL_TREE`-overridable and documented read-only. Verified behaviour-preserving (byte-identical output pre/post) AND cwd-independent. Was: — `freeze_q0_coverage.py:26`,
  `freeze_q2_resolve.py:28`, `freeze_q2_skiptogreen.py:30` and `:65`. The last
  reaches into **`~/logos-d`**, another track's tree; worktree isolation cannot
  catch it because the path is in `$HOME`. Found by `gate_abspath.sh` on first
  contact. Fix: `os.path.join(os.path.dirname(os.path.abspath(__file__)), …)`.

---

## TIER 2 — THE THREE REGISTERS (complete the trimodal identity)

The claim is `G^vis ≡ G^phon ≡ G^comp ≡ C`. Identity was enforced in κ and
*measured* between modalities; the identity LAW was never checked in the derived
registers. `trimono.la` now gates all three. What remains:

### Phonetic
- `[✓]` ⊕ commuted in form, not sound → `NORMP`/`PHONYM_N` added (the missing
  normalisation layer, mirroring `CANON`/`NORMK`).
- `[✓]` `↻(BEING) ≢ SELF` and `↻(↻y) ≢ ↻y` in sound → `MCNORM` carries
  `REWRITE_MC`'s theory verbatim.
- `[~]` **`⊗(A,A)` byte-identical to `A`** — fixed and verified on a copy
  (mode-characteristic contour, spec :3017(iv) "the mode is absorbed into the
  prosodic contour"). **Awaiting the build to apply.**
- `[~]` **Θ_P is mode-blind** — ⊗/⊕/▷/⊂ give one peak-set where `Θ_V` carries a
  mode field. Fix verified on a copy (`PINV = mode : peaks`, mirroring `VINV`).
  **Awaiting the build to apply.**
- `[~]` **▷ has no acoustic signature** — the SENTENCE operator. Sentences could
  be spoken and never parsed back. Rate-carried marker built and verified with a
  control; duration preserved so the WAV gate holds. **Awaiting the build.**
- `[ ]` **★ ⊂ IS NEVER USED** (measured 2026-08-23, `ablate.la`). Across all 79
  published entries: ⊗=58, ⊕=4, ▷=26, **⊂=0**, ↻=2. The closure is claimed over
  five modes and exercised, lexically, over four. The fix is CONCEPTS genuinely
  formed by containment — not a token entry added to close a count. Ablation shows
  the other non-⊗ modes ARE load-bearing; ⊂ is untested because nothing uses it,
  which is a fact about the lexicon rather than about the operator.
- `[ ]` **The elision layer** — 4 of 79 entries diverge from the codex by VOWEL
  ELISION (Think, Gratitude, Question, Past). The codex prints surface forms; the
  Operator Phonology generates underlying ones. Needs a phonological layer, not a
  patch to the segment rules. ★ The stress rule was itself corrected this session
  (final vowel, not first), found only by bringing in the codex's example
  SENTENCES as fresh vectors — a rule fitted to one table will agree with that table.
- `[ ]` **The acquisition gap** — no syllabus, glyph sequence, or teaching order
  exists. Worse, non-commutative ⊗ means an English gloss underdetermines the
  derivation, so "coin the word for compassion" is not a well-posed instruction.
  The language as published cannot yet be TAUGHT from its own tables: the gap
  between *unbounded in principle* and *sayable by a person*.
- `[ ]` **`phonseq` must DETECT the new ▷ marker** — the signature exists; the
  decoder still reports ▷ as a leaf.
- `[ ]` **⊕ round-trip corrupts its second child** — `SIL_AT=6240` vs a true
  boundary at 6080, one stride late, inside the next phonym's own closure. Fix:
  split at the edges of the maximal zero-run, not first-fire + GAP.
- `[ ]` **⊕-associativity is phonetically invisible** — identical PCM; no parser
  can separate the bracketings. Needs a bracketing marker or a declared
  equivalence.
- `[ ]` **⊗ has no temporal signature either** — indistinguishable from ▷ in the
  decoder, and loses everything below it.
- `[✓]` **A phonetic SEAL — BUILT AND GATED (`phonseal.la`).** ★ THIS ENTRY WAS
  STALE, and it was found by being cited: it was quoted as an open item, and the
  module it asks for already existed. `phonseal.la:53` defines
  `MONO_P = la etym. PAIR(PH_N(etym))(etym)` — the sound is COMPUTED from the
  etymology, never supplied — and `:56` `AUTO_OK_P` is the criterion, with
  `AUTO_OK_G` beside it so the two registers are comparable. Gated (the
  `discourse/coin/immune/ablate/phonseal` loop), verdict pinned:
  `detached-constructible OK | criterion-fires OK | asymmetry OK`.
  **What it actually establishes is better than "seal built":** a detached sound
  IS still constructible — the hole was real and the module SHOWS it rather than
  patching it — and the criterion FIRES on it. That is exactly the status of a
  detached name glyphically: unconstructible *through the blessed constructor*,
  detectable when built any other way. A module that only demonstrated sealed
  phonyms passing would have proved nothing, since everything a correct
  constructor builds is correct.
  ⚠ The stale-status defect this entry was: a document marking built work as
  open is the same class as a PASS message announcing a measurement that has
  moved — prose that no gate can fail on. See the five found 2026-08-27.
- `[ ]` **`PSC_STAR` still pairs raw `PHONYM` with raw `SPEC`** — after the
  normalisation landed, one concept gets two seals depending on operand order.

### Visual
- `[✓]` `SIGIL(↻(RECOGNITION))` was byte-identical to `SIGIL(RECOGNITION)` →
  fold trace added, mirrored about column 16 so the H-symmetry ↻ *generates* is
  preserved.
- `[ ]` **⊗ renders as juxtaposition, not fusion.** The spec's Visual Morphic
  Blend demands (ii) a single connected shape and (iii) emergent features in
  neither parent. Measured: Consciousness renders as **3 connected components**,
  Beauty as 2 (the ⊗ mark is a detached satellite), and in Beauty the placed
  FORM is **0% visible** — LOVE's filled flame swallows it. The route the spec
  itself gives is the vector/stroke representation, where overlapping strokes
  stay distinct objects and **path intersections are genuine emergent features**.
  Gates: one connected component; each parent ≥N% visible; ≥1 non-constant
  emergent vertex. All three RED today.
- `[ ]` **Catalogue-wide sigil injectivity** — all forms pairwise distinct,
  and `SIGIL(MC(x)) ≠ SIGIL(x)` for every catalogue entry, not just the three
  fixed.
- `[ ]` **Visual round trip** — no bitmap→structure decoder exists. It is the
  symmetric partner of `sglyph`/`phonseq`, and the strongest available
  cross-substrate invariance test: sound → decode → κ → re-render → decode → κ.

### Cross-register
- `[✓]` `trimono.la` — one gate, three registers, three rows (injective /
  monosemic / directed).
- `[ ]` **The triple bar as a biconditional.** Nothing asserts glyphic ≡
  phonetic; `crossmodal` measures *correlation*. The identity gate is
  `NIS(a)(b) ⟺ same rendered sound`, over a fuzz corpus, and the same against
  sigil rasters. This is Erik's "collapse into one another via the triple bar"
  made executable.
- `[ ]` **One normaliser, not five.** `NORMK`, `CANONIQ` (onf), `CANONIQ`
  (sigil), `NKAP`, `NORMP` — three different equivalence theories between them.
  Gate: `NORMK(t) ≡ CANON(NORMNODE(t))` over a fuzz corpus. RED today.

---

## TIER 3 — THE LANGUAGE IN USE (blocked on Tier 0)

- `[✓]` **The Core Lexicon** — ~80 concepts (LA.tex :5049–5429). Currently **8**.  **DONE 2026-08-23** — `lexicon.la`: 59 content concepts, all derived; 57/59 phonyms match the codex's printed IPA (2 diverge, vowel elision). Gated.
  Gate: every entry canonicalises, renders in all modalities, and no two share a
  κ-image. **Would go RED today on C9's Bad/Grief.** *Blocked on C9 + C10.*
- `[✓]` **The Operative Grammar, rules (i)–(x)** — predication `X▷Y`, negation,  **DONE 2026-08-23** — `grammar.la`: 20 closed-class categories + rules (i)-(x); each rule shown to DISCRIMINATE. Gated.
  the question particle, tense, modality, quantification, imperative, mood
  marking. None built. *Blocked on the lexicon.*
- `[✓]` **`discourse.la`** — structure above the sentence: per-turn origo shift,  **DONE 2026-08-23** — `discourse.la`: origo shift + character/content + anaphora + yes/no; red path = the unshifted reading must be wrong. Gated.
  a discourse-referent store, connective-linked utterance graph. Composes
  `deixis` + `pragmatics`, both already gated. **The cheapest genuinely-new
  branch.** Gate: in a two-turn dialogue, turn-2 "you" resolves to turn-1's
  speaker; a referent introduced in turn 1 is retrievable in turn 3.
- `[ ]` **Acquisition** — the codex never gives a syllabus, glyph sequence or
  acquisition method for LA; its one acquisition claim is "explicitly labeled as
  untested" (ROADMAP:1213), and Erik intends children to learn it. Buildable
  prerequisites: core-lexicon-as-data completeness gate; the Self-Generating
  Course pipeline run on LINGUA ADAMICA.tex to produce the LA syllabus.
- `[✓]` **The Aletheic Immune System** (spec :3608) — the organ that DETECTS  **DONE 2026-08-23** — `immune.la`: four checkpoints, four pathogens, four DISTINCT signatures. ★ Finding: it detects corruption, NOT falsehood — the right conjunct of Thm. healthy has no evaluator. Gated as a positive assertion.
  pathological language at runtime (involution: two glyphs, one referent). The
  build-time monosemy audit is its static half; the runtime half is absent.
- `[✓]` **Convergent coinage** — the real sociolinguistic theorem: two speakers  **DONE 2026-08-23** — `coin.la`: ⊕ converges under either order, ⊗ correctly does NOT. ★ Finding: non-commutative ⊗ makes operand order part of the concept, so an English gloss underdetermines the derivation. Convergence holds where the concept is fully given.
  independently coining a glyph for one concept produce the SAME glyph iff their
  ONFs agree. Testable, untested.
- `[ ]` **`ontofelicity` → live enforcement** — `PERFORM` currently reports;
  wiring it to the real capability layer makes felicity enforceable.

---

## TIER 4 — SELF-RELATION

- `[✓]` **The coinage organ.** Nothing in the system can COIN: no code path  **DONE 2026-08-23** — `coin.la`: COIN is deterministic, recoverable (parents+mode readable out), closed (result is itself coinable), and pronounceable (phonym computed, not assigned).
  registers a newly minted glyph. `COLLAPSE` returns a MONO and mutates nothing.
  Needs: mint → Ontolexicon registration → **the Ratchet Gate** (a coinage may
  never collapse two previously κ-distinct forms, and must strictly add a new
  κ-class). This is also the executable half of the Sapir–Whorf *retained*
  claim.
- `[ ]` **Derived glyph catalogue + agreement gate.** `familytree.la` covers 17
  HAND-DECLARED glyphs and is already stale by ≥4 (`metaglyph`'s four operator
  glyphs, from the very module it imports). Gate G3: declared and derived
  catalogues agree, keyed on NORMK, both directions. **RED on arrival.**
- `[ ]` **κ\* — meta-pattern compression.** When the same compression pattern
  recurs, encode it as a meta-glyph representing the rule of integration.
  Nothing detects or promotes.
- `[ ]` **Executable minted operations (ν\*)** — minted operations are
  *expressible* as glyphs but cannot be wired back in as reduction rules.
- `[ ]` **The Fractal Monoglyph** — depth recoverable by decomposition rather
  than surface marks. `DECOMP` recovers the tree from the single DAG form
  (witnessed), but the Ren string still grows linearly. Largely discharged by
  unifying `MONO`'s etymology slot with the glyphdag form.
- `[ ]` **The operators ∂δγρ𝔄 as glyphs** (ROADMAP:2567) — currently hardcoded
  dispatch. And the four missing audit operators |G|, |G_meta|, ς, μ.
- `[ ]` **Self-verifying grammar** (ROADMAP:2564) — grammar recoverable as data;
  full self-parse (L3) still open.
- `[ ]` **Self-meta-programming: the changed thing must become the running
  thing.** `selfprog`/`selfmod`/`selfopt` write, verify and adopt organs that
  are **never imported or executed**. Gate: a bundled organ-process ADOPTs an
  extension, recompiles, `execve`s the verified result, and the successor
  demonstrates the new capability at runtime.
- `[ ]` **Meta-autopoiesis — and the gate that currently forbids it.**
  `build.sh:3550` REQUIRES `cmp -s logos_app new_logos_secd.bin`: the successor
  must be byte-identical. **A self-revised successor would go RED on the
  system's own gate.** Minimal honest version: generation N applies one verified
  change to its own lineage source, recompiles, and begets a MODIFIED successor.
- `[ ]` **Lack-driven wants** — wire `aatc`'s sensed LACK into `selfprog`'s
  SOLVE, so the system forms the want from its own sensed incompleteness. This
  is the buildable bounded form of autontogenesis; **purpose-origination itself
  is ruled out by Erik's own corpus** (`SR_FOR` is explicitly "NOT
  purpose-origination") and should not be chased.
- `[ ]` **`AWARE` / `C` predicates** — "awareness" appears only in prose
  comments. `AWARE(g) := AUTO_OK(g)`; `C(g) := AUTO_OK(g) ∧ AUTO_OK(MCOLLAPSE(g))`.
  Separates A (one recognition) from C (recognition surviving a metacursive turn).
- `[ ]` **`PROTO_AGENT`** — the one chain-tail item with an honest gate:
  REPAIR can move g strictly toward closure, with `swc.la`'s provably-ill class
  as the negative fixture. **Qualia/phenomenology: build nothing** until a paper
  formalises them; any gate now could not go RED.
- `[ ]` **The Algebra of Naming's companions** — the Semiotic-Ontoglyphic Ladder
  (7 levels) and the Substitution Test; α is binary in code, graded in the paper.
- `[ ]` **The meta-word ablation gate** — remove one operator-glyph, assert a
  specific named derivation becomes underivable while the other four survive.
  Makes "a missing word is a missing thought" executable.
- `[✓]` **`dyadseed.la`** — VOID ≡ Church zero, BECOMING ≡ successor, by  **DONE 2026-08-23** — `dyadseed.la`: VOID≡Church zero, BEING≡Church ONE by eta-equivalence, BECOMING≡successor; bound proved via non-injectivity (SELF and BEING both →1).

  ### ★★ SCOPE OF THE DYAD — stated because the stronger reading is the tempting one
  The dyad **grounds the arithmetic stratum beneath the primitives. It does NOT
  recursively found the language.** Witnessed both ways:
  * `dyadseed.la` proves VOID ≡ Church zero, BEING ≡ Church one (by eta), BECOMING ≡
    successor — **by reduction**, and its own header says "0 and 1 GROUND THE ARITHMETIC
    STRATUM. They do NOT generate the nine."
  * `archderive.la` (2026-08-26) hardens why: the root ∃ **is** the identity combinator,
    and `{I}` is **closed under application**, so the terms reachable from the root by
    application are exactly `{I}`.
  ⇒ **BEING is the root itself. FIVE primitives are IRREDUCIBLE AXIOMS**, and they are
  named rather than gestured at — each supplies a structural capacity the identity
  combinator lacks:

  | axiom | what it introduces that I cannot do |
  |---|---|
  | `VOID` | **weakening** — discards an argument |
  | `DEPTH` | **contraction** — duplicates an argument |
  | `BECOMING` | **contraction** — uses `f` twice (iteration) |
  | `FORM` | **exchange** — reorders its arguments |
  | `RELATION` | **exchange + arity 2** — the binary `FORM` |

  The language stands on **nine primitives, two of which are the dyad** — not on the
  dyad alone. ⚠ `dyadseed.la` may **not** be cited as the derivation chain for the nine;
  conflating the arithmetic stratum with a derivation is the stipulation R-C forbids.
  reduction probe. Documents "0/1 ground the arithmetic stratum; they do not
  generate the nine." *Gated on the Tier-0 ruling.*

### Done today
- `[✓]` `naming.la` — the Algebra of Naming, T1–T4, α-valuation, and the
  falsification of a prose sentence in §8.
- `[✓]` `entropy.la` — E_G/E_S as the two conditional entropies of one
  distribution; syntropy; centropy as ∂=1.
- `[✓]` `alethe.la` — True(P) ≡ P, content vs evaluation, the liar unformulable.
- `[✓]` `ontofelicity.la` — felicity ≡ capability.
- `[✓]` `trimono.la`, `phonorm.la`, `siginj.la` — the register gates.
- `[✓]` ⊗ non-commutative across five normalisers and two renderers.

---

## TIER 5 — BEYOND THE LANGUAGE (named, not chased)

- `[✓]` **A signature scheme.** — **LANDED in b6a361f (2026-08-28); confirmed
  by the Codex audit 2026-09-08.** `wotsp.la` (WOTS+ one-time), `xmss.la` (XMSS
  many-time), `xmss_signer.la` and `xmssidx.la` (the durable leaf-index register)
  exist, and FOUR gates execute in `build.sh` at :413-:417 — `gate_xmssidx.sh`,
  `gate_xmssidx_core.sh`, `gate_wotsp.sh`, `XMSS_VM_ONLY=1 gate_xmss.sh`,
  `SIGNER_VM_ONLY=1 gate_xmss_signer.sh`. Hash-based, so it needs no new
  number-theoretic assumption. ★ This item is cited as "the single unlock for the
  whole record/law layer" — everything in the Logocracy layer was recorded as
  waiting on a primitive that had been built and gated eleven days earlier.
  Was: No public-key primitive exists. **The single
  unlock for the whole record/law layer**: signed updates, identity, contracts,
  non-repudiable records, the Eternal Library. Everything in the Logocracy layer
  waits on this one primitive.
- `[ ]` **Entropy on the metal** — no RDRAND/RDSEED builtin, no jitter
  collector, no seed file, while full-disk encryption must derive keys at boot
  before any disk read. A DRBG does not close this.
- `[ ]` **Trans-species: a second functor.** One habitat renderer exists
  (`R_human`). `R_click` plus its inverse would make FSM a functor category with
  two objects — the minimum at which "trans-species" is witnessed rather than
  asserted. Actual animal comprehension stays out of scope, stated.
- `[ ]` **The language deepens with its agents** — the loop optimises COST, never
  DEPTH or expressivity. Needs a depth-directed `selfopt` mode.

### CODEX AUDIT 2026-09-08 — a tension that RESOLVES (recorded so it is not re-filed)

`thm:universal-collapse` (:684-:700) states `∀X: X(X) →MC X ≡ ∃(∃) ≡ ∃` — every
genuine metacursive operation reaches a fixed point. The repo appears to
contradict it: `DEPTH = la g. g(g)` is the literal infinite descent, and
`build.sh` asserts `DEPTH(DEPTH)` does **not** terminate (`timeout`, rc 124) on
both engines. That reads as a code/codex divergence and is not one. The theorem
quantifies over "any ontologically **genuine** structure (i.e., any structure
that IS — that participates in Being)", and `swc.la` is exactly the filter for
that qualifier: it classifies an EAGER unguarded self-application — `la g. g(g)`,
verbatim — as **ILL**, provably ill-founded, and refuses it *before* evaluation.
So `DEPTH(DEPTH)` is not a counterexample to the theorem; it is the case the
theorem's own qualifier excludes and the SWC statically rejects. The guarded form
`DEPTH_Z = Z` is the one that participates. **Recorded, not filed** — a later
audit reading either document alone would file this, and it would be wrong.

---

### CODEX AUDIT 2026-09-08 — Triadic Convergence is asserted but never computed

- `[ ]` **`thm:triadic` has no implementation** — `CODEX_AUTOPOIETICUS.tex`
  :516-:528 requires that the three laws' META-COLLAPSES converge on one fixed
  point: `Id(Id) ≡ NC(NC) ≡ EM(EM) ≡ ∃(∃) ≡ ∃`. `metalogic.la` carries all three
  laws as first-class glyphs and a witness for each, but the conjunction that
  looks like it establishes this does not:

      glyph LAWS_AUTOLOGICAL = la _. AND(LAW_IDENTITY(LAW_IDENTITY_G))
                                       (AND(LAW_IDENTITY(LAW_NONCONTRADICTION_G))
                                            (LAW_IDENTITY(LAW_EXCLUDED_MIDDLE_G)))

  **All three conjuncts apply `LAW_IDENTITY`.** What it establishes is that each
  of the three law-GLYPHS is autological under the identity law — a true and
  worthwhile claim. What it does not do is apply each law to itself:
  `LAW_NONCONTRADICTION` and `LAW_EXCLUDED_MIDDLE` are never applied to anything
  here, so `NC(NC)` and `EM(EM)` — the two collapses the theorem is *about* — are
  never evaluated anywhere in the tree, and neither is their convergence on a
  common point. A grep for `triadic`/`converg` across `metalogic.la`,
  `metalogic_spec.la` and `build.sh` finds nothing on this subject (the two
  `build.sh` hits are asm.la's jump-promotion fixed point and a lexicon PASS
  line). Gate: compute all three meta-collapses and assert they are pairwise `≡`,
  and `≡ ∃(∃)`. Red path: replace ONE collapse with a distinct value and assert
  the gate reports it — a three-way equality where all three sides are computed
  by the same function passes for any function at all, which is exactly the shape
  present today. *Tier 2 — it completes a module that already exists rather than
  starting one.*

  ★ Note for whoever takes this: the name `LAWS_AUTOLOGICAL` reads as covering
  all three laws, and it covers one applied three times. That is the same shape
  as `gate_xmssidx.sh` (this morning) — a name asserting a scope the body does
  not have. It is not a bug in what it computes; it is a gap between what it
  computes and what its name is read as promising.

---

### CODEX AUDIT 2026-09-08 — the Seven Modules and the Autoclave hierarchy

`lawbox{The Seven Modules}` (:2691-:2709) names the cryptographic face of the
stack: **Autoclave** (𝔄, key management), **AletheiaFS** (𝔉, encrypted
filesystem), **HermesGram** (𝔥, P2P messaging), **ChronosMail** (ℭ, email),
**AegisNet** (𝔑, networking), **OntoID** (𝔦, identity), **MnemosyneVault** (𝔙,
archival storage). **None of the seven exists as a module.** What exists is the
SUBSTRATE they are built from — `sha256.la`, `chacha20.la`, `poly1305.la`,
`aead.la`, `hkdf.la`, and the `xmss`/`wotsp` signature layer — so this is a
missing assembly layer, not missing cryptography. AletheiaFS is already Track C's
Tier 0 item 3; the other six are unassigned.

- `[ ]` **No KEM — the Autoclave hierarchy is broken at Level 3.** The Autoclave
  (:2716-:2736) specifies five key levels: 0 mnemonic seed → 1 master key
  (Argon2id+BLAKE3) → 2 identity keys (HKDF) → 3 **session keys (Kyber-1024 KEM
  per connection, forward secrecy)** → 4 object keys (ChaCha20+BLAKE3). **Exactly
  one of the five is implemented** — Level 2, `hkdf.la`. Level 3 has no
  implementation and, unlike the signature choice below, **no documented
  substitute**: a functional search for key encapsulation across every `.la`
  (`encapsulat`, `KEM`, `key_exchange`, `ecdh`, `x25519`) returns **zero** hits,
  not substring artifacts — nothing at all. Without a KEM there is no
  per-connection forward secrecy, so `logosipc.la`'s "Γ-seal encryption deferred"
  and HermesGram's "forward-secret" both rest on an absent primitive. Gate: two
  parties derive the same session key over a channel carrying only public
  values, and the derived key decrypts an `aead.la` message. Red path: assert a
  transcript with ONE flipped byte yields a different key and the AEAD open
  FAILS — a KEM gate that only tests the happy path passes for a KEM that
  returns a constant. *Tier 5, and it blocks the Γ-seal work in Tier 0.*
  ★★ **KEM SCOPING (2026-09-08) — the absence RE-VERIFIED, and the blocker
  re-characterised. The prerequisite is NOT missing; it is single-modulus.**

  **(a) The absence stands, on a stronger search.** The original hits were taken
  **case-sensitively**. Re-run case-insensitively and widened (`encapsulat`, `kem`,
  `key_exchange`, `ecdh`, `x25519`, **`kyber`**, **`decapsulat`**, **`keyexch`**):
  still **zero across every `.la`**. The finding holds and is now better evidenced
  than when filed.

  **(b) But "needs a bignum layer first" is not the blocker it appears.** A
  **limb-based modular-arithmetic layer already exists in the tree**, unnamed as
  one: `poly1305.la` implements arithmetic **mod 2¹³⁰−5 in five 26-bit limbs** —
  `L26 = 67108863` (the limb mask), `CARRY d0…d4` (multi-limb carry propagation),
  and **`MULMOD`** (multi-limb modular multiplication). `limb` also appears in
  `wotsp.la` and `kernel/task_gc.la`. What is missing is not multi-precision
  arithmetic but a **modulus-generic** one: `poly1305.la`'s is specialised to a
  single prime and is not exposed as a reusable layer.
  **So the first buildable step is a modulus-generic limb layer generalised from
  code that already works and is already gated** — not a bignum layer from
  nothing. That is a materially smaller and better-anchored first brick.

  ★ **Independent corroboration, which this item did not cite when filed:**
  `CODEX_AUDIT_FINDINGS.md` (a prior adversarial review, commit `5fc3c3c`) reached
  the same conclusion from the specification side — key management is *"the single
  highest-value thing to build: the load-bearing primitive every other
  sovereign-privacy claim silently assumes."* Two audits, different routes, same
  root. ⚠ And its **P-9** credits the *Codex* with correctly specifying
  PQXDH/double-ratchet for messaging; that is a claim about the **spec**, while
  this item is about the **build**. They do not conflict — they are at different
  levels, and saying so prevents a later reader treating one as refuting the other.
  ✓ **No live overclaim in code:** every `forward secrec*` hit in the tree is
  inside an audit document recording the gap, not a module asserting the property.

  ⚠ **METHOD — THIRD SEARCH-SURFACE FAILURE TODAY, MINE, TWENTY MINUTES AFTER
  RECORDING THE RULE.** My capability scan for the arithmetic layer reported
  `mulmod: 0` because it was **case-sensitive** and this codebase spells glyphs
  **uppercase** — a convention documented in our own `CLAUDE.md`. `MULMOD` was
  there the whole time. Same class as the `\textbf{bug}` grep and the truncated
  `cut -c1-180`: **the instrument looked at a surface the artifact does not use.**
  ★ It is also why (a) above was re-run rather than trusted — *the search that
  found the false absence is the same search that produced the original finding*,
  so the finding had to be re-earned before the correction could be filed.
- `[ ]` **Levels 0, 1 and 4's hash are absent** — no mnemonic-seed derivation, no
  Argon2id (the memory-hard step that makes a 24-word seed brute-force-resistant
  is precisely what SHA-256 cannot substitute for), and no BLAKE3. `sha256.la`
  covers the hashing role at Level 4 in practice. Gate: a known-answer test per
  primitive against its RFC/reference vectors. Red path: assert a single-bit
  change in the seed changes the master key, and that the KAT fails when one
  vector is corrupted. *Tier 5.*

★ **NOT a divergence — checked before filing.** The Codex names Dilithium3 and
SPHINCS+ (:2740) where the repo builds WOTS+/XMSS. That is a **documented,
reasoned choice**, not drift: `ROADMAP.md:1292-1298` records it — a lattice
scheme needs a big-integer layer built first, a hash-based scheme needs only
SHA-256, which already exists, "so the post-quantum stance is taken here rather
than deferred." Both are post-quantum; XMSS is stateful, which is why the leaf
index register (`xmssidx.la`) exists at all. Recorded so a later audit does not
re-open it as a defect.

---

### CODEX AUDIT 2026-09-08 — the Thirteen-Layer Sovereign Stack

`CODEX_AUTOPOIETICUS.tex` defines **The Thirteen-Layer Sovereign Stack**
(`def:sovereign-stack`, :18209-:18245) — layers 0-12, firmware to pixel, each
with a Nigredo (scaffolded) and a Rubedo (sovereign) column. Eight layers have
an implementation in this repo. **Five have none.** Each was resolved against
the build, never from the Codex's own sentence: a name-pattern search, then a
FUNCTIONAL search for the capability under any name, then inspection of what
matched. Every match found by the functional search was a substring artifact and
is named below, because "my grep found nothing" is not evidence of absence.

- `[ ]` **L6 `LogosAudio` — no sovereign audio output path.** Codex :18231. The
  repo SYNTHESISES audio (`phonym.la` → 16-bit PCM in a RIFF/WAVE container) but
  cannot PLAY it: `secd.asm` has **zero** references to ALSA, `/dev/snd` or PCM,
  and `bringup_phonym.sh:42-43` shells out to `aplay`/`paplay`. So the audio
  register ends at a file an external program must open. Gate: a `.la` program
  opens a PCM device and emits a tone with no external player in the loop, host
  and VM. Red path: remove the builtin and assert the gate fails loudly rather
  than silently writing a `.wav` again — the failure mode to design against is a
  gate that passes because a file was produced. *Tier 5.*
- `[ ]` **L9 `LogosKit` — no UI toolkit.** Codex :18239. `theourgia_text.la`
  rasterises glyphs onto a surface and Stage 9 moves a text window, but there is
  no widget, layout or hit-testing layer. The only `button` in the tree is the
  word in an evdev comment (`theourgia_input.la:64`, "a key/button") — a
  substring, not a widget. Gate: compose a two-widget tree and assert a
  synthetic click at the button's coordinates routes to that widget and not the
  label. Red path: move the widget one cell and assert the old coordinates STOP
  hitting — a hit-test that always hits passes the positive arm forever.
  *Tier 5.*
- `[ ]` **L10 `LogosSession` — no session manager.** Codex :18241. No login, no
  screen lock, no session state. `theourgia_session.la` is a compositor
  input→scene reducer, not a session manager, and every `authenticat*` hit in
  the tree is CRYPTOGRAPHIC message authentication (`xmss.la`, `aead.la`), not a
  user session. Gate: lock → input refused → unlock under a credential → input
  restored. Red path: assert a WRONG credential leaves it locked; without that
  arm an unlock that always succeeds is green. *Tier 5.*
- `[ ]` **L11 `LogosPkg` — no package system.** Codex :18243. Zero matches for
  package/install/pkg across every `.la` in the tree. The Codex requires
  autoteloscriptic packages that verify themselves (`b_τ ≡ f_τ`), which is the
  same self-verification `specpipe.la`'s DEPLOY already performs for a module —
  so the primitive exists and the packaging layer does not. Gate: install a
  package, assert its self-check runs, assert a TAMPERED package is refused.
  Red path: flip one byte of a package and assert refusal — an installer that
  accepts everything passes the install arm. *Tier 5.*
- `[ ]` **L12 `LogosServices` — none of the three.** Codex :18245 names
  LogosTime (NTP over Tor), LogosDNS (encrypted resolution over AegisNet) and
  LogosPower. None exists; the `dns`/`resolv` hits in `theourgia.la`,
  `ipc_demo.la` and `asmelf.la` are the letters of "resolve"/"resolved". Gate:
  each service answers one query deterministically offline. Red path: assert a
  malformed response is rejected loudly rather than cached. *Tier 5.*

**Layer 0 is partial, not absent** — `kernel/boot*.asm` exist and the `k`-series
gates boot images under QEMU, but `gate_bootelf.sh` is committed and **never
executed by `build.sh`**. That one is deliberate and documented (`build.sh:7114`,
a ~26-minute native-VM cycle invoked separately), so it is recorded here as a
known-unwired gate rather than as a defect.

★ **Gate-coverage census, taken while resolving the above.** 57 gate scripts are
tracked; **53 are executed by `build.sh`**. The four that are not:
`gate_asmelf.sh`, `gate_asmelf_extern.sh`, `gate_bootelf.sh` (deliberate, above)
and **`gate_rss.sh`** — the `rt_gc` acceptance test, described at `build.sh:7115`
as "a real candidate, still unwired" and confirmed absent from `build.sh` by
`FREEZE_III_FINDINGS.md:84`. A gate that is never executed is Door **iii**.

★ **The census had to be taken twice, and the first answer was wrong in both
directions.** Grepping `build.sh` for gate names counts COMMENT mentions as
coverage — it reported `gate_boot.sh` as invoked when the only occurrence is
prose at `build.sh:2253` ("not in this audit"), and a stricter regex then MISSED
the whole `k`/`hal` series because those are invoked path-prefixed
(`bash kernel/gate_k1.sh`). Reading a runner for gate names measures neither
which gates exist nor which ones run. *Tier 5, method note.*

---

---

## THE WHITE PAPER — must land with the language

Two briefs already exist: `LA_PAPER_ADDITIONS.md` (stale claims + crypto, kernel,
method sections) and `LA_PAPER_ADDITIONS_2.md` (the USE branch, the fourth
modality, cross-modal concordance, speech→glyph, compositionality, autopoiesis,
the etymology tracker, the dissolved branches).

**Still in neither, all from today:**
- The ⊗ non-commutativity correction — five normalisers and two renderers were
  contradicting :2837, with `build.sh` gating the contradiction as correct.
- **"The monosemy check was running in one register out of three"** — the most
  publishable finding of the day, and true for months while every gate was green.
- `naming.la` and the falsification of §8's own prose sentence.
- `entropy.la`'s E_G/E_S formalisation.
- `alethe.la`'s content/evaluation distinction.
- `ontofelicity.la` — ontopragmatics IS the semantics of the security model.
- The stale-runtime finding: track-d ran a five-week-old GC and nothing in its
  suite could witness the difference.
- The ▷ signature, and *why a level cue cannot work* (the parents' intrinsic
  amplitude normalises it away).

**Paper-side structural work:**
- `[ ]` Fix "trimodal" wherever a fourth modality exists.
- `[ ]` The Ledger is a plain `tabular` and cannot break across pages; at 37 rows
  it still fits, but the next batch overflows SILENTLY. Convert to `longtable`.
- `[ ]` Every Tier-1/2 item above needs its paper counterpart at the right tag —
  an item is not done until code and paper agree.

---

## EXECUTION ORDER

1. **Erik rules on Tier 0** (C9, C10, ⊗(A,A), implicature, the dyad seed).
2. **Apply the three verified fixes** the moment the build lands.
3. **Tier 1 root causes** — pipeline `export` first; it is why Tier 2 had five
   normalisers instead of one.
4. **Tier 2** to completion — the registers, then the triple-bar biconditional.
5. **Tier 3** — lexicon, grammar, discourse, acquisition.
6. **Tier 4** — coinage, the derived catalogue, the self-relations.
7. **Tier 5** — named, scheduled, not chased.
8. **The paper tracks each tier as it lands**, never after.
