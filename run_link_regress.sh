#!/bin/bash
# Every gate that touches link.la or link_reloc.la, run sequentially so it does
# not contend with track A's build. gate_link_reloc first: it is the one that
# directly exercises the relocation resolver I changed.
cd "$HOME/logos-b" || exit 1
pass=0; fail=0
# ★ gate_link_layout.sh was MISSING from this list until 2026-09-08 — including
# in the version committed that morning. It is the only build-reachable cover for
# link_layout.la, and it had never been run by build.sh either, so the module had
# no enforcement anywhere. Listed second: it is cheap (38 s) and fails fast.
# ★ gate_seam_asm_link.sh added 2026-09-08: it was invoked by NOTHING anywhere
# and its exclusion was undocumented (my gate_link*.sh sweep glob missed it —
# it does not match that prefix). It is not in build.sh for a STATED reason
# (see there): it fails rather than skips when track A's asm.la half regresses.
# On-demand here is where it belongs, alongside gate_link_kernel.sh.
for g in gate_link_reloc.sh gate_link_layout.sh gate_link.sh gate_link_nsec.sh gate_link_script.sh gate_link_e2e.sh gate_seam_asm_link.sh gate_link_kernel.sh; do
  [ -x "$g" ] || { echo "SKIP  $g (not executable)"; continue; }
  s=$(date +%s)
  out=$(timeout 3600 ./"$g" 2>&1)
  rc=$?
  p=$(printf '%s\n' "$out" | grep -c '^PASS'); f=$(printf '%s\n' "$out" | grep -c '^FAIL')
  printf '%-24s rc=%-3s PASS=%-3s FAIL=%-3s %ss\n' "$g" "$rc" "$p" "$f" "$(( $(date +%s)-s ))"
  [ "$f" -gt 0 ] && printf '%s\n' "$out" | grep '^FAIL' | head -3 | sed 's/^/    /'
  pass=$((pass+p)); fail=$((fail+f))
done
echo "----------------------------------------"
echo "LINKER REGRESSION: $pass PASS / $fail FAIL"
