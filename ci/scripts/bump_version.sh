#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Auto-bumps the semantic version (the "X.Y.Z" version name) in pubspec.yaml
# based on the Conventional Commits / branch names landed since the last
# release tag. Falls back to a PATCH bump when no convention is detected.
#
#   major (X+1.0.0) : a commit "<type>!:" or a "BREAKING CHANGE" footer,
#                     or a branch named  breaking/*  or  major/*
#   minor (X.Y+1.0) : a "feat:"/"feat(scope):" commit,
#                     or a branch named  feat/*  or  feature/*
#   patch (X.Y.Z+1) : anything else (fix, chore, docs, refactor, …) and the
#                     fallback when no convention is present at all
#
# The "+build" metadata is preserved as-is — CI sets the real, monotonic build
# number at build time (github.run_number + offset), so pubspec's build value
# is only a placeholder.
#
# Outputs (when $GITHUB_OUTPUT is set, i.e. on CI):
#   version_name=<new X.Y.Z>   level=<major|minor|patch>   version=<X.Y.Z+build>
# ---------------------------------------------------------------------------
set -euo pipefail

PUBSPEC="${PUBSPEC_PATH:-pubspec.yaml}"

# --- current version -------------------------------------------------------
current_line="$(grep -E '^version:' "$PUBSPEC" | head -n1)"
current="${current_line#version:}"
current="${current// /}"                       # strip spaces -> "X.Y.Z+build"
name="${current%%+*}"                           # "X.Y.Z"
build=""
[ "$current" != "$name" ] && build="${current#*+}"   # "build" (empty if no +)

IFS='.' read -r major minor patch <<<"$name"
: "${major:=0}" "${minor:=0}" "${patch:=0}"

# --- commit range to inspect (since the last release tag) ------------------
last_tag="$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true)"
if [ -n "$last_tag" ]; then
  range="${last_tag}..HEAD"
else
  range="HEAD"                                   # no tags yet: inspect all history
fi

subjects="$(git log --format='%s' "$range" 2>/dev/null || true)"
bodies="$(git log --format='%b' "$range" 2>/dev/null || true)"
# Branch name behind each merge commit, e.g. "Merge pull request #1 from org/feat/x" -> "feat/x"
branches="$(git log --merges --format='%s' "$range" 2>/dev/null | sed -nE 's/.*from [^/]+\/(.+)$/\1/p' || true)"

# --- decide the bump level (highest wins) ----------------------------------
level="patch"

if printf '%s\n' "$subjects" | grep -qiE '^[[:space:]]*(feat|feature)(\([^)]+\))?!?:' \
   || printf '%s\n' "$branches" | grep -qiE '^(feat|feature)/'; then
  level="minor"
fi

if printf '%s\n' "$subjects" | grep -qiE '^[[:space:]]*[a-z]+(\([^)]+\))?!:' \
   || printf '%s\n' "$bodies"   | grep -qiE 'BREAKING[ -]CHANGE' \
   || printf '%s\n' "$branches" | grep -qiE '^(breaking|major)/'; then
  level="major"
fi

case "$level" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

new_name="${major}.${minor}.${patch}"
new_version="$new_name"
[ -n "$build" ] && new_version="${new_name}+${build}"

# --- rewrite the top-level version line in pubspec.yaml --------------------
NEW_VERSION="$new_version" perl -i -pe 'if (!$done && /^version:/) { $_ = "version: $ENV{NEW_VERSION}\n"; $done = 1 }' "$PUBSPEC"

echo "Last release tag : ${last_tag:-<none>}"
echo "Bump level       : $level"
echo "Old version      : $current"
echo "New version      : $new_version"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "version_name=$new_name"
    echo "version=$new_version"
    echo "level=$level"
  } >>"$GITHUB_OUTPUT"
fi
