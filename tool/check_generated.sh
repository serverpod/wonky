#!/usr/bin/env bash
# Regenerates every committed generated file and fails when the result differs
# from the checkout (CQ-64b, findings R-3). Run by the `generated` job in
# .github/workflows/analyze.yml; locally (on a clean tree, from the repository
# root, after `flutter pub get`, with the Serverpod CLI on the PATH):
#
#   bash tool/check_generated.sh
#
# Covers:
# - Serverpod: wonky_server/lib/src/generated, wonky_client, the sync models'
#   generated code and test/integration/test_tools (`serverpod generate`);
# - gen-l10n of every package with an l10n.yaml, and the en_XA pseudo-locale
#   ARBs (tool/pseudo_locale.dart);
# - the board's spec index (tool/spec_index.dart);
# - the RevLog table schemas (tool/gen_rev_schema.dart);
# - the Sheets script API index (wonky_sheets_script/tool/gen_api_index.dart).
#
# Generators that don't format their output are followed by `dart format`
# (the committed files are formatted: format.yml checks them).
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

step() { echo "::group::$*" 2>/dev/null || true; }
end() { echo "::endgroup::" 2>/dev/null || true; }

step "serverpod generate"
(cd wonky_server && serverpod generate)
end

step "pseudo-locales"
for en_xa in $(git ls-files '*_en_XA.arb'); do
  dart run tool/pseudo_locale.dart "${en_xa%_en_XA.arb}_en.arb" "$en_xa"
done
end

step "gen-l10n"
for cfg in $(git ls-files '*l10n.yaml'); do
  pkg=$(dirname "$cfg")
  out=$(awk -F': *' '/^output-dir:/{print $2}' "$cfg" | tr -d '\r')
  (cd "$pkg" && flutter gen-l10n && dart format "$out" > /dev/null)
done
end

step "spec index"
dart run tool/spec_index.dart
end

step "RevLog schemas"
dart run tool/gen_rev_schema.dart
dart format packages/wonky_sheets_core/lib/src/revlog \
  packages/wonky_slides_core/lib/src/revlog > /dev/null
end

step "Sheets script API index"
(cd packages/wonky_sheets_script && dart run tool/gen_api_index.dart &&
  dart format lib/src/api/api_index_data.dart > /dev/null)
end

changes=$(git status --porcelain --untracked-files=all)
if [ -n "$changes" ]; then
  echo "Generated files are out of date. Regenerate them and commit the result:"
  echo "$changes"
  git --no-pager diff --stat
  exit 1
fi
echo "Generated files are up to date."
