#!/usr/bin/env bash
# Prints the workspace members that have image golden tests (a `test/goldens`
# folder), one per line. With `--with-masters`, only those that have committed
# masters (`test/goldens/**/*.png` in git), which CI's `goldens` job compares;
# the others are listed by the job as waiting for masters (CQ-64d).
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

members=$(awk '/^workspace:/{f=1;next} /^[^ -]/{f=0} f && /^ *- /{sub(/^ *- */,""); sub(/ *#.*/,""); sub(/\r$/,""); print}' pubspec.yaml)
for p in $members; do
  [ -d "$p/test/goldens" ] || continue
  if [ "${1:-}" = --with-masters ]; then
    [ -n "$(git ls-files "$p/test/goldens/*.png" "$p/test/goldens/**/*.png")" ] || continue
  fi
  echo "$p"
done
