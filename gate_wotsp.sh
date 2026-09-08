#!/usr/bin/env bash
# WOTS+ — the first PUBLIC-KEY primitive LogOS has. ROADMAP G1 carried "**No
# signature scheme yet** — still the blocker for signed updates and identity"
# as the open half of KDF/MAC/signature; G2 names the choice: "PQ or hash-based
# signatures for updates." This gate is the witness for that half.
#
# ── THE HONEST PROVENANCE OF THE VECTORS ────────────────────────────────────
# gate_sha256.sh can say "a digest is a known answer or it is nothing" because
# NIST published the answer. THIS GATE CANNOT SAY THAT. There is no published
# third-party vector for this construction (RFC 8391 §3.1 WOTS+ with the
# SPHINCS+ "simple" tweakable hash), so PK and sig[0] are cross-checked against
# `wotsp_model.py` — an independent Python implementation written BEFORE the LA
# one. Two implementations by one author agreeing is WEAKER than a known
# answer, and this comment exists so that nobody reads the PASS line as though
# it were the same thing. What is closed by a published KAT is stated where it
# would go: a full RFC 8391 XMSS known-answer test, once a Merkle layer exists.
#
# ── WHY FOUR OF THE SIX CHECKS ARE NEGATIVE ─────────────────────────────────
# A gate whose only case is "a valid signature verifies" CANNOT FAIL in the way
# that matters. This project already shipped the exact defect once: chacha20's
# BLOCK took its key as an argument and then fed forward hardcoded constants
# that happened to equal that vector's key — correct for one input, silently
# wrong for every other, and invisible to a known-answer test. The signature
# form of that bug is a signer that ignores the message. So:
#     sig(m1) != sig(m2)          -- the signer READS the message
#     verify(m2, sig(m1)) rejects -- the verifier READS the message
#     one flipped bit in sig      -- the verifier READS the signature
#     one flipped bit in PK       -- the verifier READS the public key
# Each of those goes WRONG, loudly, if the corresponding input is ignored.
#
# ── WHICH ENGINES, AND WHY THE TWO PARAMETER SETS ARE ON DIFFERENT ONES ─────
# Measured on this machine 2026-08-23: one SHA-256 call costs 6.5 s on the C
# host and 0.31 s on the native SECD VM — 21x. So:
#     wotsp.la      n=2  w=4   -- C host AND native VM, byte-identical
#     wotsp_prod.la n=32 w=16  -- native VM only
# The n=2 leg is a CODE-PATH witness at a toy security level (16 bits of hash,
# breakable by hand) and is not a security claim; the n=32 leg is the real
# parameter set on one engine. The code is IDENTICAL between them — the only
# difference is WOTS_MKP(2)(4) vs WOTS_MKP(32)(16) — which is what makes the
# split meaningful rather than a dodge. Both facts are stated rather than one
# of them being quietly dropped.
#
# ── WHAT THIS GATE ACTUALLY COSTS — MEASURED, NOT ESTIMATED ─────────────────
# Every leg below was run 2026-08-23 with exactly the command sequence in this
# script, and timed:
#     host  n=2  w=4   1861 s  (31 min)
#     VM    n=2  w=4    209 s codegen + ~1 min run
#     VM    n=32 w=16  1340 s codegen (22 min) + 4549 s run (76 min)
#     TOTAL             ~2 h 15 min
# ★ An extrapolation from the per-hash bench said the n=32 leg would take
# ~13 min. It took 76. The bench hashed a 4-byte input (ONE SHA-256 block); at
# n=32 the chain input is 1+18+4+4+32 = 59 bytes, which pads to TWO blocks, and
# sha256.la's byte access is quadratic within a block. The estimate was wrong by
# 6x and is recorded here rather than quietly replaced, because the same
# extrapolation would mislead the same way again. If this cost needs to come
# down, the lever is the two-block chain input, not the hash count.
#
# THE WIRING DECISION WAS MADE, AND THIS SCRIPT ENCODES IT. build.sh is ~3 h;
# running all three legs would add ~75% for a leg that adds PARAMETERS rather
# than a new property, while the leg carrying host==VM carries the claim. So the
# n=32 arm is OFF by default and runs only under WOTSP_FULL=1:
#
#     bash gate_wotsp.sh                 # n=2 host+VM  (~36 min)  <- build.sh
#     WOTSP_FULL=1 bash gate_wotsp.sh    # + n=32 VM    (~2 h 15)  <- out of band
#
# ★ A SKIP THAT IS NOT ANNOUNCED READS AS COVERAGE. When the n=32 arm is off
# this script SAYS SO, on stdout, in the PASS line itself — so a green build can
# never be mistaken for one that exercised production parameters.
set -uo pipefail
cd "$(dirname "$0")"
ok=1

# ── THE ORACLE IS RE-RUN, NOT REMEMBERED ────────────────────────────────────
# ★ The header above is explicit that PK and sig[0] are "cross-checked against
# wotsp_model.py, an independent Python implementation written BEFORE the LA
# one" -- and until now that cross-check was a HAND TRANSCRIPTION nothing re-ran.
# wotsp.la:212-213 and wotsp_prod.la:52-53 embed EXP_PK/EXP_SIG0 as CONSTANTS,
# and each module checks its own computed values against them. So THE CONSTANT
# IS THE ORACLE.
#
# The failure mode is not drift. If a transcription were ever wrong, the LA is
# checked against a wrong authority, and the natural repair -- "make the
# implementation agree with the expectation" -- BENDS THE LA TO THE ERROR while
# every arm of this gate stays green. A wrong oracle does not announce itself;
# it recruits the implementation.
#
# Both sides are EXTRACTED FROM THEIR SOURCES: the model by running it, the
# constants by reading the two .la files. Neither is retyped here -- a third
# copy in this gate would move the transcription problem, not close it. The
# model emits BOTH parameter sets in one sub-second run, so this covers all
# four constants (toy n=2 w=4 AND production n=32 w=16), including the prod
# vectors the LA legs themselves only reach on the VM.
#
# ★ HARD-FAILS when python3 or the model is absent rather than skipping: a SKIP
# would satisfy this check while asserting nothing, which is the defect class
# the 2026-09-08 census documents (LA_COMPLETION.md, Tier 1).
if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL  wotsp oracle: python3 absent — the model cannot be re-run, so the"
    echo "      hand-transcribed EXP_PK/EXP_SIG0 constants are unverified. This"
    echo "      FAILS rather than SKIPs: a skip would satisfy the check while"
    echo "      asserting nothing."
    exit 1
fi
for f in wotsp_model.py wotsp.la wotsp_prod.la; do
    [ -f "$f" ] || { echo "FAIL  wotsp oracle: $f absent — a missing input is a broken checkout, not a reason to skip"; exit 1; }
done

WMODEL="$(python3 wotsp_model.py 2>&1)" || { echo "FAIL  wotsp oracle: wotsp_model.py did not run cleanly"; printf '%s\n' "$WMODEL"; exit 1; }
wsec () {   # $1 = section marker, $2 = key -> that section's value
    printf '%s\n' "$WMODEL" | awk -v want="$1" -v key="$2" '
        /^=== WOTS\+/ { insec = ($0 ~ want) ? 1 : 0; next }
        insec && $1 == key && $2 == "=" { print $3; exit }'
}
wla ()  { sed -n "s/^glyph $2  *= *\"\([0-9a-f]*\)\".*/\1/p" "$1"; }

M_PK_T="$(wsec 'n=2 w=4'   PK)";            M_S0_T="$(wsec 'n=2 w=4'   'sig(m1)[0]')"
M_PK_P="$(wsec 'n=32 w=16' PK)";            M_S0_P="$(wsec 'n=32 w=16' 'sig(m1)[0]')"
L_PK_T="$(wla wotsp.la      EXP_PK)";       L_S0_T="$(wla wotsp.la      EXP_SIG0)"
L_PK_P="$(wla wotsp_prod.la EXP_PK)";       L_S0_P="$(wla wotsp_prod.la EXP_SIG0)"

# ★ An empty value on either side is a BROKEN EXTRACTION, not agreement: if a
#   sed or the awk section-match stops matching, both sides go blank and
#   "" = "" PASSES, reporting a verified oracle from two failures.
for v in "$M_PK_T" "$M_S0_T" "$M_PK_P" "$M_S0_P" "$L_PK_T" "$L_S0_T" "$L_PK_P" "$L_S0_P"; do
    [ -n "$v" ] || { echo "FAIL  wotsp oracle: an extraction came back EMPTY (model toy=[$M_PK_T/$M_S0_T] prod=[$M_PK_P/$M_S0_P]; la toy=[$L_PK_T/$L_S0_T] prod=[$L_PK_P/$L_S0_P]) — an empty comparison is not agreement"; exit 1; }
done
[ "$M_PK_T" = "$L_PK_T" ] || { echo "FAIL  wotsp oracle: n=2 w=4 model PK [$M_PK_T] != wotsp.la EXP_PK [$L_PK_T] — the transcribed constant does not match the independent implementation that produced it"; ok=0; }
[ "$M_S0_T" = "$L_S0_T" ] || { echo "FAIL  wotsp oracle: n=2 w=4 model sig[0] [$M_S0_T] != wotsp.la EXP_SIG0 [$L_S0_T]"; ok=0; }
[ "$M_PK_P" = "$L_PK_P" ] || { echo "FAIL  wotsp oracle: n=32 w=16 model PK [$M_PK_P] != wotsp_prod.la EXP_PK [$L_PK_P]"; ok=0; }
[ "$M_S0_P" = "$L_S0_P" ] || { echo "FAIL  wotsp oracle: n=32 w=16 model sig[0] [$M_S0_P] != wotsp_prod.la EXP_SIG0 [$L_S0_P]"; ok=0; }
[ "$ok" -eq 1 ] && echo "PASS  wotsp oracle: wotsp_model.py RE-RUN and all FOUR constants match their .la sources — n=2 w=4 PK=$M_PK_T sig0=$M_S0_T, n=32 w=16 PK=${M_PK_P:0:16}… sig0=${M_S0_P:0:16}… — derived from the independent model on every run, not remembered from a hand copy"

E_SMALL="wotsp n=2 w=4: PK OK | sig OK | sig(m1)!=sig(m2) OK | genuine verifies OK | wrong-msg rejected OK | tampered-sig rejected OK | wrong-PK rejected OK"
E_PROD="wotsp n=32 w=16: PK OK | sig OK | sig(m1)!=sig(m2) OK | genuine verifies OK | wrong-msg rejected OK | tampered-sig rejected OK | wrong-PK rejected OK"

run_vm () {   # name -> stdout of the native SECD VM
    rm -f logos_secd logos_program.bin logos_source.la
    ./tiny_host secd.la >/dev/null 2>&1
    cp "$1.la" logos_source.la
    ./tiny_host codegen.la >/dev/null 2>&1
    timeout 3600 ./logos_secd 2>&1 | head -1
    rm -f logos_secd logos_program.bin logos_source.la
}

HOSTOUT="$(timeout 3600 ./tiny_host wotsp.la 2>&1 | head -1)"
[ "$HOSTOUT" = "$E_SMALL" ] || { echo "FAIL  wotsp C host: [$HOSTOUT]"; ok=0; }

VMOUT="$(run_vm wotsp)"
[ "$VMOUT" = "$E_SMALL" ] || { echo "FAIL  wotsp native VM: [$VMOUT]"; ok=0; }

# The byte-identity check is separate from the two value checks on purpose: two
# engines can each be wrong in the same way, and each can be wrong in its own
# way. Only this line catches the second case.
[ "$HOSTOUT" = "$VMOUT" ] || { echo "FAIL  wotsp: host != VM"; ok=0; }

if [ "${WOTSP_FULL:-0}" = "1" ]; then
    PRODOUT="$(run_vm wotsp_prod)"
    [ "$PRODOUT" = "$E_PROD" ] || { echo "FAIL  wotsp_prod native VM: [$PRODOUT]"; ok=0; }
    PRODNOTE="n=32 w=16 verified on the native VM."
else
    # Named, not silent. The whole point of the flag is defeated if a reader of
    # the PASS line cannot tell which parameter set actually ran.
    PRODNOTE="n=32 w=16 NOT RUN in this invocation (set WOTSP_FULL=1; ~2 h). Only the n=2 w=4 code-path witness ran here."
fi

[ "$ok" -eq 1 ] && echo "PASS  wotsp: WOTS+ hash-based one-time signature in Lingua Adamica — the first public-key primitive (ROADMAP G1's open half, G2's stated hash-based choice). n=2 w=4 byte-identical on the C host AND the native VM. $PRODNOTE Public key and signature match an independent Python model, and THREE DISCRIMINATING negative controls reject: a different message signs differently, a signature verified against the wrong message fails, and one flipped bit in the signature fails. (A fourth control, a flipped bit in the PUBLIC KEY, is NOT discriminating — Audit IV, 2026-08-27: it reduces to pk != FLIPS(pk), true by construction, and is retained pending this gate's first baseline run.) NOT a published third-party KAT — that awaits an RFC 8391 XMSS vector once a Merkle layer exists — and ONE-TIME: two signatures under one key leak it."
[ "$ok" -eq 1 ]
