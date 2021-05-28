#!/bin/sh
set -e

#
# Runs the openapi-diff tool from https://github.com/quen2404/openapi-diff to detect changes against the base branch of the PR
#
# Used in CI pipelines to report possible breaking changes
#

if [ -z "$1" ]; then
  echo "🛑You need to provide the original spec file path"
  exit 1
fi

if [ -z "$2" ]; then
  echo "🛑You need to provide the new spec file path"
  exit 1
fi

BASE_SPEC_PATH="$1"
HEAD_SPEC_PATH="$2"
OUTPUT_DIR="$(mktemp -d -t openapi-diff-result-XXXXXXXXXX)"

# Run diff
RESULT=$(docker run --rm -v "$BASE_SPEC_PATH:/base.yaml:ro" -v "$HEAD_SPEC_PATH:/head.yaml:ro" -v "$OUTPUT_DIR:/output" quen2404/openapi-diff /base.yaml /head.yaml --markdown /output/out.md --state)

# result is `no_changes` or `incompatible` or `compatible`

echo "## _API Diff Report_"

echo
if [ "$RESULT" = "incompatible" ]; then
  echo "### :x: **BREAKING CHANGES** :bangbang:"
elif [ "$RESULT" = "compatible" ]; then
  echo "### :white_check_mark: **CHANGES - non breaking** :ok_hand:"
elif [ "$RESULT" = "no_changes" ]; then
  echo "### :white_circle: **NO API changes** :ghost:"
else
  echo "### :warning: Unexpected result from diff \`$RESULT\`"
fi

echo
echo ":information_source: This is not preventing you from merging, you are an adult."
echo

cat "$OUTPUT_DIR/out.md"

echo "---"
echo "comparing \`$BASE_SPEC_PATH\` with \`$HEAD_SPEC_PATH\`."