#!/usr/bin/env bash
# XMSS — the MANY-TIME hash-based signature. This is the gate that actually
# unblocks ROADMAP G1's "signed updates and identity": `wotsp.la` gave the
# system a public-key primitive, but a one-time key cannot sign a stream of
# updates, so WOTS+ alone left G1 half-open. A Merkle tree over 2^h WOTS+ keys
# closes it — one small public key, 2^h signatures.
#
# ── THE ONE CHECK THAT IS THE WHOLE POINT ───────────────────────────────────
# "leaf2 verifies vs SAME root". Any single-signature test passes on a tree
# that ignores its leaf index entirely; only signing under TWO DIFFERENT leaves
# and verifying both against ONE root witnesses many-time-ness. Everything else
# here supports that claim or attacks it.
#
# ── THE NEGATIVES, AND WHAT EACH ONE FORCES THE VERIFIER TO READ ────────────
#     wrong leaf idx rejected      -- the index is authenticated, not decorative
#     corrupt auth path rejected   -- the path is authenticated
#     wrong msg rejected           -- the message is authenticated
#     wrong root rejected          -- the root is authenticated
# ★ FOUR of the nine checks are negative AND DISCRIMINATING (corrected 2026-08-27,
# Freeze-Day Audit IV). A fifth — "wrong root rejected" — asserts r0 != FLIPS(root)
# while a neighbour already asserts r0 == root, so it reduces to root != FLIPS(root),
# true by construction of FLIPS. A gate whose only case is "a signature
# verifies" cannot fail in the way this project has already been bitten by
# (chacha20's BLOCK ignoring its own key argument and passing anyway).
#
# ── EXPECTED-STRING PROVENANCE (read this before editing E_XMSS) ────────────
# ★ E_XMSS below was DERIVED from xmss.la's own concat structure and the model's
# vectors, NOT pasted from a run's stdout. That distinction is the difference
# between a gate and a rubber stamp: an expected value copied from observed
# output cannot detect a wrong observed output, because it IS the observed
# output. If this string ever needs updating, derive it again — do not capture
# it. The root (7d20) and leaf0 (cf5d) inside xmss.la come from xmss_model.py,
# an independent Python implementation written before the LA one.
#
# ── PROVENANCE OF THE VECTORS THEMSELVES — THE STANDING LIMIT ───────────────
# Cross-implementation agreement with a model by the same author is WEAKER than
# a published known answer, and this gate does not blur the two. RFC 8391
# publishes XMSS test vectors, and reaching them is now a concrete, bounded
# task rather than a wish — it requires the RFC's own tweakable hash (per-step
# bitmasks + L-trees) in place of the SPHINCS+ "simple" (i,j) construction used
# here. Until that is done this remains a construction witness, not a KAT.
#
# ── WHY n=2 w=4 h=2, STATED NOT HIDDEN ──────────────────────────────────────
# One leaf is a full WOTS+ keygen. At n=32 w=16 that is 1072 hashes, measured at
# ~1.75 s/hash on the native VM for this input size: ~31 min PER LEAF, ~2 h for
# a four-leaf tree before signing anything. So the witnessed parameters are a
# TOY security level (16 bits) chosen to exercise every code path — two tree
# levels, both sibling directions, an even leaf and an odd one — not to be safe.
# ★ Before the expensive run, the Merkle layer was verified SEPARATELY with the
# leaf function stubbed out: all four leaves walked to the same root, and the
# root and both internal nodes matched the Python model byte-for-byte. That
# isolates a tree/auth-path off-by-one from the WOTS integration, and it cost
# seconds instead of the ~100 min the full host leg costs.
# ── MEASURED COST — this gate is EXPENSIVE, know it before wiring it ────────
#     C host      7426 s  (124 min)
#     native VM   1597 s codegen (27 min) + 601 s run (10 min)
#     TOTAL       ~2 h 41 min
# ★ The host leg is ~12x the VM leg for the identical program. On a ~3 h build
# this gate roughly doubles it, so — as with gate_wotsp.sh — wiring it whole is
# a decision, not a default. The cheapest honest option is the VM leg alone
# (~37 min), at the cost of giving up host==VM, which is the project's core
# discipline; that trade is stated so it can be made deliberately.
set -uo pipefail
cd "$(dirname "$0")"
ok=1

# ── THE ORACLE IS RE-RUN, NOT REMEMBERED ────────────────────────────────────
# ★ xmss.la:178-179 embed EXP_ROOT/EXP_LEAF0 as CONSTANTS hand-transcribed from
# xmss_model.py, and the LA checks its computed root/leaf0 against them. So THE
# CONSTANT IS THE ORACLE -- and until now nothing re-ran the model that produced
# it. That is a captured expectation wearing a derived one's clothes: if the
# transcription were wrong, the LA would be checked against a wrong authority,
# and the natural repair ("make the LA agree") bends the implementation to the
# error. The provenance note above is careful about E_XMSS; this closes the same
# gap one level down, for the vectors E_XMSS is derived FROM.
#
# Both sides are EXTRACTED FROM THEIR SOURCES -- the model by running it, the
# constants by reading xmss.la. Neither is retyped here: a third copy in this
# gate would only move the transcription problem, not close it.
#
# ★ AND IT HARD-FAILS WHEN python3 IS ABSENT rather than skipping. A SKIP would
# satisfy this check while asserting nothing, which is the defect class the
# 2026-09-08 census documents (LA_COMPLETION.md, Tier 1) and which
# build.sh:405-411 already states for gate FILES: absence is a broken checkout,
# not a configuration. The model is a checkout artifact; so is this gate.
if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL  xmss oracle: python3 absent — the model cannot be re-run, so the"
    echo "      hand-transcribed EXP_ROOT/EXP_LEAF0 in xmss.la are unverified."
    echo "      This FAILS rather than SKIPs: a skip would satisfy the check"
    echo "      while asserting nothing."
    exit 1
fi
[ -f xmss_model.py ] || { echo "FAIL  xmss oracle: xmss_model.py absent — a missing model is a broken checkout, not a reason to skip"; exit 1; }

MODELOUT="$(python3 xmss_model.py 2>&1)" || { echo "FAIL  xmss oracle: xmss_model.py did not run cleanly"; printf '%s\n' "$MODELOUT"; exit 1; }
M_ROOT="$(printf '%s\n' "$MODELOUT"  | sed -n 's/^  root  *= *\([0-9a-f]*\)$/\1/p')"
M_LEAF="$(printf '%s\n' "$MODELOUT"  | sed -n 's/^  leaf0  *= *\([0-9a-f]*\)$/\1/p')"
L_ROOT="$(sed -n 's/^glyph EXP_ROOT  *= *"\([0-9a-f]*\)".*/\1/p'  xmss.la)"
L_LEAF="$(sed -n 's/^glyph EXP_LEAF0  *= *"\([0-9a-f]*\)".*/\1/p' xmss.la)"

# a blank on either side means the extraction broke, not that they agree --
# "" = "" would otherwise pass and report a verified oracle from two failures.
for v in "$M_ROOT" "$M_LEAF" "$L_ROOT" "$L_LEAF"; do
    [ -n "$v" ] || { echo "FAIL  xmss oracle: could not extract a value (model root=[$M_ROOT] leaf0=[$M_LEAF]; xmss.la root=[$L_ROOT] leaf0=[$L_LEAF]) — an empty comparison is not agreement"; exit 1; }
done
[ "$M_ROOT" = "$L_ROOT" ] || { echo "FAIL  xmss oracle: model root [$M_ROOT] != xmss.la EXP_ROOT [$L_ROOT] — the transcribed constant does not match the independent implementation that produced it"; ok=0; }
[ "$M_LEAF" = "$L_LEAF" ] || { echo "FAIL  xmss oracle: model leaf0 [$M_LEAF] != xmss.la EXP_LEAF0 [$L_LEAF]"; ok=0; }
[ "$ok" -eq 1 ] && echo "PASS  xmss oracle: xmss_model.py RE-RUN and its root=$M_ROOT leaf0=$M_LEAF match the constants in xmss.la — the expectation is derived from the independent model on every run, not remembered from a hand copy"

E_XMSS="xmss n=2 w=4 h=2: root OK | leaf0 OK | leaf0 verifies OK | leaf2 verifies vs SAME root OK | sigs differ OK | wrong leaf idx rejected OK | corrupt auth path rejected OK | wrong msg rejected OK | wrong root rejected OK"

# ★ XMSS_VM_ONLY=1 runs the VM leg alone (~37 min instead of 2 h 41 m) and GIVES
#   UP host==VM. This is the trade this gate's header names above; it is now
#   implemented rather than merely described, and the PASS line SAYS which ran.
if [ "${XMSS_VM_ONLY:-0}" = "1" ]; then
    HOSTNOTE="C host leg NOT RUN in this invocation (XMSS_VM_ONLY=1; that leg is 124 min). host==VM byte-identity is therefore NOT established here — only the native VM ran, against the derived expectation."
    HOSTOUT="$E_XMSS"   # not measured; see the note above
else
    HOSTOUT="$(timeout 10800 ./tiny_host xmss.la 2>&1 | head -1)"
    [ "$HOSTOUT" = "$E_XMSS" ] || { echo "FAIL  xmss C host: [$HOSTOUT]"; ok=0; }
    HOSTNOTE="Byte-identical on the C host AND the native VM."
fi

rm -f logos_secd logos_program.bin logos_source.la
./tiny_host secd.la >/dev/null 2>&1
cp xmss.la logos_source.la
./tiny_host codegen.la >/dev/null 2>&1
VMOUT="$(timeout 10800 ./logos_secd 2>&1 | head -1)"
rm -f logos_secd logos_program.bin logos_source.la
[ "$VMOUT" = "$E_XMSS" ] || { echo "FAIL  xmss native VM: [$VMOUT]"; ok=0; }

# Separate from the two value checks on purpose: both engines can be wrong the
# same way, and each can be wrong its own way. Only this line catches the second.
[ "$HOSTOUT" = "$VMOUT" ] || { echo "FAIL  xmss: host != VM"; ok=0; }

[ "$ok" -eq 1 ] && echo "PASS  xmss: a MANY-TIME hash-based signature in Lingua Adamica — a Merkle tree over 2^h WOTS+ one-time keys, so one small public key (the root) signs 2^h messages. This is what ROADMAP G1's 'signed updates and identity' actually needs; wotsp.la alone could sign once. Two signatures under DIFFERENT leaves verify against the SAME root, and FOUR DISCRIMINATING negative controls reject: a wrong leaf index, a one-bit-corrupted authentication path, a wrong message, and the two signatures are not equal. (A fifth control, a flipped bit in the ROOT, is NOT discriminating — Audit IV, 2026-08-27: it reduces to root != FLIPS(root), true by construction, and is retained pending a baseline run.) $HOSTNOTE Parameters n=2 w=4 h=2 are a TOY security level chosen for code-path coverage, NOT a safe parameter set — n=32 w=16 costs ~31 min per leaf on this substrate. Vectors are cross-implementation agreement with an independent Python model, NOT a published RFC 8391 KAT."
[ "$ok" -eq 1 ]
