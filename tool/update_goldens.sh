#!/usr/bin/env bash
# Regenerates the golden masters (`test/goldens/**/*.png`) in the pinned Linux
# container that CI's `goldens` job compares them in (specs/15-writing-tests.md
# §7; CQ-64d). Masters rendered on macOS or Windows differ from Linux ones
# (font rasterization), so never commit those.
#
#   tool/update_goldens.sh                 # every package with test/goldens
#   tool/update_goldens.sh wonky_drive     # one package (a workspace path)
#
# Needs Docker. The repository (tracked and untracked, not ignored files) is
# copied into the container, so the host's .dart_tool and build folders are
# never touched; only the regenerated PNGs are copied back.
#
# Without Docker: run the `Goldens` workflow from the Actions tab with
# `update` checked and commit the PNGs from its `golden-masters` artifact.
set -euo pipefail

# Keep in step with FLUTTER_VERSION in .github/workflows/*.yml.
FLUTTER_VERSION=3.47.5
IMAGE="ghcr.io/cirruslabs/flutter:$FLUTTER_VERSION"

root=$(git rev-parse --show-toplevel)
cd "$root"

if [ $# -gt 0 ]; then
  packages="$*"
else
  packages=$(tool/golden_packages.sh)
fi
if [ -z "$packages" ]; then
  echo "No package has test/goldens."
  exit 0
fi
echo "Updating goldens in: $packages"

git ls-files -z --cached --others --exclude-standard |
  tar --null -T - -cf - |
  docker run --rm -i "$IMAGE" bash -c "
    set -euo pipefail
    mkdir -p /work && cd /work && tar -xf - >&2
    flutter pub get >&2
    for p in $packages; do
      echo \"== \$p\" >&2
      (cd \"\$p\" && flutter test --update-goldens -t golden test/goldens) >&2
    done
    find $packages -path '*/test/goldens/*' -name '*.png' -print0 |
      tar --null -T - -cf -
  " |
  tar -xvf -

echo "Done. Review the new masters with git status before committing."
