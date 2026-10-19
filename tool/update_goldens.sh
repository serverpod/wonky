#!/usr/bin/env bash
# Regenerates the golden masters (`test/goldens/**/*.png`) in a Linux
# container matching CI's `goldens` job (Ubuntu 24.04 with the pinned Flutter;
# specs/15-writing-tests.md §7; CQ-64d). Masters rendered on macOS or Windows differ from Linux ones
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
# The `goldens` job's runner image; Flutter is installed into it at the pinned
# version (there is no prebuilt Flutter image for it).
IMAGE="ubuntu:24.04"

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
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >&2
    apt-get install -y -qq git curl unzip xz-utils ca-certificates libglu1-mesa >&2
    git clone -q --depth 1 --branch $FLUTTER_VERSION \
      https://github.com/flutter/flutter.git /opt/flutter >&2
    export PATH=/opt/flutter/bin:\$PATH
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
