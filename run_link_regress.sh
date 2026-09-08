#!/bin/bash
# Every gate that touches link.la or link_reloc.la, run sequentially so it does
# not contend with track A's build. gate_link_reloc first: it is the one that
# directly exercises the relocation resolver I changed.
cd "$HOME/logos-b" || exit 1
pass=0; fail=0
for g in gate_link_reloc.sh gate_link.sh gate_link_nsec.sh gate_link_script.sh gate_link_e2e.sh gate_link_kernel.sh; do
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
