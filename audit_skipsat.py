#!/usr/bin/env python3
"""audit_skipsat — can a gate that IS invoked be satisfied WITHOUT RUNNING?

WHY THIS EXISTS
---------------
`audit_standalone_gates.py` asks, of the assertions inside a gate: *which of
these cannot go RED?*  The hub's `gatesweep.sh` asks, of the gate inventory:
*does anything run this gate at all?*  Neither asks the question in between,
and it is the one that was open:

    a gate that build.sh DOES invoke, which can return rc 0 having asserted
    NOTHING, because a SKIP satisfied the invocation.

`sh gate_X.sh || exit 1` has one bit of resolution.  A gate that declines to run
is indistinguishable from one that ran and passed.  That is CLAUDE.md's Rule 1,
and on 2026-09-08 a hand census found FOUR live instances in build.sh plus two
further channels in one gate.  ★ Every one was found BY HAND.  A paragraph does
not re-run; that is what this file is for.

WHAT IT REPORTS
---------------
  CHECKOUT   an invocation guarded on a file that is IN THE REPO, whose else-arm
             SKIPs.  Delete the file -> the build stays green.  A missing gate
             file is a broken checkout, not a configuration: these are defects.
  ENVIRONMENT a guard on `command -v <tool>`.  A missing nasm/ld/QEMU is a real
             machine, so these are NOT counted as defects -- but they are
             reported, because 36 of them plus an unconditional checkpoint tag
             is its own finding (see CERTIFICATION below).
  ACCEPTED   build.sh matches `^SKIP` in a gate's OUTPUT and continues at rc 0 --
             the gate file is PRESENT and still asserts nothing.
  INTERNAL   an invoked gate script that can `exit 0` on its own prerequisite
             guard, reported with which class its guard belongs to.

  CERTIFICATION  the keystone.  build.sh:7167 tags the commit `verified-*`
             ("Full audit (build.sh) passed clean.") on the premise "Reached
             only when every check above passed (each failure exits 1 earlier)".
             A check that SKIPs does not exit 1.  If a `verified-` tag is created
             and NO SKIP tally gates it, the certification cannot distinguish a
             full run from one that skipped everything skippable.

WHAT THIS IS NOT
----------------
A bash parser.  It tracks `if`/`fi` nesting and reads guard conditions with
regexes; `case`, `&&`-chained guards and functions are not modelled.  Output is
a WORKLIST.  ★ A clean report is NOT evidence that no gate is SKIP-satisfiable --
only that this tool found none.

★ AND THE TOOL MUST PROVE IT LOOKED.  `--selftest` reconciles a count taken by
`grep` (a different instrument, not this file's regexes) against what this file
parsed, and REFUSES to report on a mismatch; then it reproduces the four known
CHECKOUT sites and the one known-good NEGATIVE CONTROL (build.sh:410-417, the
signature block, which hard-fails on an absent gate and must NOT be flagged).
A reporting tool whose own harness is dead reports ABSENCE and is believed.

USAGE
    audit_skipsat.py --selftest            # calibrate FIRST
    audit_skipsat.py                       # audit ./build.sh
    audit_skipsat.py --build path/to/build.sh --quiet
"""
import argparse, os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lint_namematch import reconcile, ReconcileError   # reuse, do not re-invent

# ── the idioms, established by survey of build.sh, not assumed ───────────────
SKIP_ECHO = re.compile(r'echo\s+"SKIP')
IF_OPEN   = re.compile(r'^\s*if\b')            # NOT elif: see if_blocks()
ELIF_ARM  = re.compile(r'^\s*elif\b')
FI_CLOSE  = re.compile(r'^\s*fi\b')
ELSE_ARM  = re.compile(r'^\s*else\b')
FILETEST  = re.compile(r'\[\s+-[fex]\s+([^\]\s]+)\s+\]')
CMDTEST   = re.compile(r'\bcommand\s+-v\s+([\w.-]+)')
INVOKE    = re.compile(r'(?<!\w)(?:bash|sh|python3)\s+([A-Za-z0-9_./-]+\.(?:sh|py))')
ACCEPTS   = re.compile(r'grep\s+-q[a-zA-Z]*\s+"\^SKIP')
VERIFTAG  = re.compile(r'tag="verified-|git\s+tag\s+-a')
# a gate script's own bail-out
ANY_SKIP  = re.compile(r'echo\s+"SKIP|print\(f?"SKIP')
BAILS     = re.compile(r'\b(?:exit|return)\s+0\b')


def is_checkout_path(path, root):
    """A CHECKOUT file lives in the repo; /dev/dri/card0 does not.

    ★ An earlier draft classified any `[ -e X ]` as CHECKOUT and flagged
    build.sh:3918 `[ -e /dev/dri/card0 ]` as a defect. A device node is the
    ENVIRONMENT -- absent hardware, like absent nasm. A triage tool that cries
    wolf gets ignored, so the discriminator is where the path LIVES."""
    if path.startswith('/'):
        return False
    return os.path.exists(os.path.join(root, path))


def strip_comments(lines):
    """Drop comment-only lines; keep index alignment with None."""
    out = []
    for ln in lines:
        out.append(None if ln.lstrip().startswith('#') else ln)
    return out


def if_blocks(code):
    """(start, last_arm_idx|None, end) for each if..fi, by nesting depth.

    ★ `elif` opens an ARM, not a BLOCK. An earlier draft matched `(?:el)?if`
    and pushed a new frame for every elif, so every if/elif/else chain had its
    nesting corrupted and its else-arm attributed to the wrong block -- which
    is exactly how build.sh:2688 (fuzz_grammar) went unreported. The selftest
    caught it; that is what the known-site list is for.
    """
    stack, blocks = [], []
    for i, ln in enumerate(code):
        if ln is None:
            continue
        if IF_OPEN.match(ln):
            stack.append([i, None])
        elif (ELSE_ARM.match(ln) or ELIF_ARM.match(ln)) and stack:
            stack[-1][1] = i                      # last arm boundary wins
        elif FI_CLOSE.match(ln) and stack:
            st, arm = stack.pop()
            blocks.append((st, arm, i))
    return blocks


def audit_build(path, root=None):
    root = root or os.path.dirname(os.path.abspath(path))
    raw = open(path, encoding='utf-8', errors='replace').read().split('\n')
    code = strip_comments(raw)
    findings = []
    # EVERY non-comment SKIP echo the parser can see. Findings are a SUBSET of
    # these; the remainder is reported as UNMODELLED and never silently dropped,
    # which is what lets reconcile() run at tolerate=0.
    all_skips = [i + 1 for i, l in enumerate(code) if l and SKIP_ECHO.search(l)]
    claimed = set()

    for start, els, end in if_blocks(code):
        body = [l for l in code[start:end + 1] if l]
        then_arm = [l for l in code[start:(els if els is not None else end)] if l]
        else_arm = [l for l in code[(els if els is not None else end):end] if l]
        hit = [j for j in range(els if els is not None else end, end)
               if code[j] and SKIP_ECHO.search(code[j])]
        if not hit:
            continue
        claimed.update(j + 1 for j in hit)
        cond = code[start]
        gates = sorted({m for l in then_arm for m in INVOKE.findall(l)})
        files = FILETEST.findall(cond)
        cmds  = CMDTEST.findall(cond)
        # a guard testing a file that is IN THE REPO is the defect class: its
        # absence is a broken checkout. An absolute path is the environment.
        repo_files = [f for f in files if is_checkout_path(f, root)]
        cls = ('CHECKOUT' if repo_files else
               'ENVIRONMENT' if (cmds or files) else 'UNCLASSIFIED')
        files = repo_files or files
        findings.append(dict(kind=cls, line=start + 1, cond=cond.strip(),
                             files=files, cmds=cmds, gates=gates))

    # gate output accepted as a pass
    for i, ln in enumerate(code):
        if ln and ACCEPTS.search(ln):
            ctx = [l for l in code[max(0, i - 4):i] if l]
            gates = sorted({m for l in ctx for m in INVOKE.findall(l)})
            findings.append(dict(kind='ACCEPTED', line=i + 1, cond=ln.strip(),
                                 files=[], cmds=[], gates=gates))

    tags = any(ln and VERIFTAG.search(ln) for ln in code)
    tallies = any(ln and re.search(r'SKIP', ln) and
                  re.search(r'\b(count|tally|total|n_skip|skips)\b', ln, re.I)
                  for ln in code)
    unmodelled = [n for n in all_skips if n not in claimed]
    return findings, all_skips, unmodelled, (tags and not tallies)


def audit_gate(path, root, window=3):
    """Every SKIP path in a gate that can reach `exit 0` / `return 0`.

    ★ An earlier draft matched ONLY the one-line `|| { echo SKIP; exit 0; }`
    idiom and found 3 where an independent grep found 37. The 34 it missed use
    the multi-line `if ! command -v X; then echo SKIP; exit 0; fi` form. That is
    Rule 3's IDIOM axis, in this tool, on its second surface -- which is why the
    internal scan now reconciles too.
    """
    try:
        lines = strip_comments(open(path, encoding='utf-8',
                                    errors='replace').read().split('\n'))
    except OSError:
        return []
    out = []
    for i, ln in enumerate(lines):
        if not ln or not ANY_SKIP.search(ln):
            continue
        near = [l for l in lines[max(0, i - window):i + window + 1] if l]
        if not any(BAILS.search(l) for l in near):
            continue                      # a SKIP that does NOT exit 0
        guard = ' '.join(near)
        if CMDTEST.search(guard):
            cls = 'ENVIRONMENT'
        else:
            fs = FILETEST.findall(guard)
            cls = ('CHECKOUT' if any(is_checkout_path(f, root) for f in fs)
                   else 'ENVIRONMENT' if fs else 'CHECKOUT')
        out.append((i + 1, cls, ln.strip()[:88]))
    return out


def gates_with_skip_paths(build, root):
    """Independent count: how many invoked gates contain a SKIP path at all.
    Taken with grep -- a different instrument from this file's regexes."""
    n = 0
    for g in invoked_gates(build):
        f = os.path.join(root, g)
        if not os.path.exists(f):
            continue
        r = subprocess.run(['grep', '-qE', r'^[^#]*(echo "SKIP|print\(f?"SKIP)', f])
        if r.returncode == 0:
            n += 1
    return n


def invoked_gates(path):
    code = strip_comments(open(path, encoding='utf-8', errors='replace').read().split('\n'))
    return sorted({m for l in code if l for m in INVOKE.findall(l)})


# ── calibration ─────────────────────────────────────────────────────────────
KNOWN_CHECKOUT = {'gate_srcdrift.py', 'fuzz_grammar.py', 'gate_selfext0.py', 'mutate.py'}
NEGATIVE_CONTROL = 'gate_xmss_signer.sh'   # in the hard-fail signature block


def selftest(build):
    print("audit_skipsat --selftest")
    ok = True

    # 1. RECONCILE against a DIFFERENT instrument (grep, not this file's regexes).
    surveyed = int(subprocess.run(
        ['grep', '-c', '-E', r'^[^#]*echo "SKIP', build],
        capture_output=True, text=True).stdout.strip() or 0)
    findings, all_skips, unmodelled, _ = audit_build(build)
    # ★ tolerate=0, deliberately. An earlier draft passed
    # tolerate=surveyed-parsed, which makes `abs(d) > tolerate` false for every
    # input -- a reconcile that cannot fail, inside the tool built to find
    # checks that cannot fail. Door i, self-inflicted. The parser must ACCOUNT
    # for every SKIP echo (classified or UNMODELLED); it may not discount them.
    try:
        reconcile("SKIP echoes in build.sh", surveyed, len(all_skips), tolerate=0)
        print(f"  reconcile: grep {surveyed}, parser accounted {len(all_skips)} "
              f"({len(unmodelled)} UNMODELLED, reported not dropped)")
    except ReconcileError as e:
        print(f"  FAIL reconcile: {e}"); return False

    # 2. the four known CHECKOUT sites must reproduce
    got = {f for d in findings if d['kind'] == 'CHECKOUT' for f in d['files']}
    missing = KNOWN_CHECKOUT - got
    if missing:
        print(f"  FAIL known CHECKOUT sites not reproduced: {sorted(missing)}"); ok = False
    else:
        print(f"  known CHECKOUT sites reproduced: {sorted(KNOWN_CHECKOUT)}")

    # 3. NEGATIVE CONTROL — the signature block hard-fails; it must NOT be flagged
    flagged = {g for d in findings for g in d['gates']}
    if NEGATIVE_CONTROL in flagged:
        print(f"  FAIL negative control {NEGATIVE_CONTROL} was flagged — the "
              f"signature block hard-fails on an absent gate and is CORRECT"); ok = False
    else:
        print(f"  negative control clean: {NEGATIVE_CONTROL} not flagged")

    # 4. THE SECOND SURFACE must reconcile too — the gate-internal scan.
    root = os.path.dirname(os.path.abspath(build))
    examined = sum(1 for g in invoked_gates(build)
                   if audit_gate(os.path.join(root, g), root))
    surveyed = gates_with_skip_paths(build, root)
    # ★ reconcile(0, 0) PASSES. A surveyed count of zero means the gates were
    #   not where we looked (wrong root), and a tool that reports "reconciled"
    #   from an empty survey is asserting nothing -- the vacuity this whole
    #   file exists to detect, one level up. Caught by red-testing the negative
    #   control from a scratch directory with no gates beside it.
    if surveyed == 0:
        print(f"  FAIL gate-internal survey found 0 gates beside {root} — an "
              f"empty survey reconciles with anything; check the root"); ok = False
    else:
        try:
            reconcile("invoked gates with a SKIP path", surveyed, examined, tolerate=0)
            print(f"  reconcile (gate-internal surface): grep {surveyed}, "
                  f"tool examined {examined}")
        except ReconcileError as e:
            print(f"  FAIL reconcile (gate-internal surface): {e}"); ok = False

    # 5. the certification link must be detected
    *_, cert = audit_build(build)
    if not cert:
        print("  FAIL certification link not detected (a verified-* tag with no "
              "SKIP tally is the keystone this tool exists to report)"); ok = False
    else:
        print("  certification link detected")

    print("  SELFTEST", "PASS" if ok else "FAIL")
    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--build', default=os.path.join(HERE, 'build.sh'))
    ap.add_argument('--selftest', action='store_true')
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()

    if a.selftest:
        return 0 if selftest(a.build) else 1

    findings, all_skips, unmodelled, cert = audit_build(a.build)
    root = os.path.dirname(os.path.abspath(a.build))

    defects = [d for d in findings if d['kind'] in ('CHECKOUT', 'ACCEPTED')]
    envs    = [d for d in findings if d['kind'] == 'ENVIRONMENT']

    print(f"audit_skipsat: {os.path.relpath(a.build, root) or a.build}")
    print(f"\n  ── SKIP-SATISFIABLE INVOCATIONS (defects: a missing checkout file "
          f"or a declining gate keeps the build green) ──")
    for d in sorted(defects, key=lambda x: x['line']):
        what = ', '.join(d['files']) or ', '.join(d['gates']) or '?'
        print(f"    {d['kind']:9} build.sh:{d['line']:<5} {what}")
        if not a.quiet:
            print(f"      {d['cond'][:100]}")
    if not defects:
        print("    (none found — NOT evidence there are none)")

    print(f"\n  ── ENVIRONMENT-guarded (absent toolchain, not absent checkout — "
          f"NOT counted as defects) ──")
    for d in sorted(envs, key=lambda x: x['line']):
        what = (', '.join(f'command -v {c}' for c in d['cmds'])
                or ', '.join(d['files']) or d['cond'][:70])
        print(f"    build.sh:{d['line']:<5} {what}")

    # the invoked gate scripts' own bail-outs
    print(f"\n  ── INTERNAL bail-outs in invoked gates (exit 0 without asserting) ──")
    n_env = n_co = examined = 0
    for g in invoked_gates(a.build):
        rs = audit_gate(os.path.join(root, g), root)
        if not rs:
            continue
        examined += 1
        for ln, cls, txt in rs:
            if cls == 'ENVIRONMENT':
                n_env += 1
            else:
                n_co += 1
                print(f"    CHECKOUT  {g}:{ln}  {txt}")
    # ★ RECONCILE THE SECOND SURFACE TOO. The first version of this scan found 3
    #   where grep found 37 -- and printed the 3 as though they were the count.
    surveyed = gates_with_skip_paths(a.build, root)
    try:
        reconcile("invoked gates with a SKIP path", surveyed, examined, tolerate=0)
        print(f"    {examined} invoked gates carry a SKIP path reaching exit 0"
              f" — {n_env + n_co} sites ({n_env} ENVIRONMENT-class = absent"
              f" toolchain, {n_co} CHECKOUT-class = defect)")
    except ReconcileError as e:
        print(f"    ⚠ REFUSING TO REPORT: {e}")

    if unmodelled:
        print(f"\n  ── UNMODELLED SKIP echoes (this tool could not place these in an "
              f"if/else; they are NOT cleared, they are unexamined) ──")
        print(f"    build.sh lines: {', '.join(str(n) for n in unmodelled)}")

    print(f"\n  ── CERTIFICATION ──")
    if cert:
        print("    ★ build.sh creates a `verified-*` tag and NOTHING tallies SKIPs.")
        print("      The tag asserts 'Full audit passed clean' on the premise that")
        print("      every check passed. A check that SKIPs does not exit 1, so the")
        print("      certification cannot distinguish a full run from one that")
        print("      skipped everything skippable.")
    else:
        print("    a SKIP tally gates the checkpoint (or no checkpoint exists)")

    print(f"\n  {len(defects)} defect-class, {len(envs)} environment-class, "
          f"{n_env + n_co} internal bail-outs.")
    print("  ★ A clean report is not evidence a gate can fail. Run --selftest first.")
    return 0


if __name__ == '__main__':
    sys.exit(main())
