#!/usr/bin/env bash

set -euo pipefail

version_file="${VERSION_FILE:-datasplice.yaml}"
base_sha="${BASE_SHA:?BASE_SHA is required}"
head_sha="${HEAD_SHA:?HEAD_SHA is required}"

current_version="$(awk -F'"' '/^version:/ { print $2; exit }' "$version_file")"
version_pattern='^[0-9]+\.[0-9]+\.[0-9]+$'
breaking_header_pattern='^[a-z]+(\([^)]*\))?!:'
feature_pattern='^feat(\([^)]*\))?:'
patch_pattern='^(fix|perf|revert)(\([^)]*\))?:'
breaking_footer_pattern='BREAKING[[:space:]]CHANGE(-|:)[[:space:]]'

if [[ ! "$current_version" =~ $version_pattern ]]; then
  printf 'invalid version in %s: %s\n' "$version_file" "$current_version" >&2
  exit 1
fi

if [[ "$base_sha" =~ ^0+$ ]]; then
  commit_range=("$head_sha")
else
  commit_range=("$base_sha..$head_sha")
fi

bump="none"
while IFS= read -r commit; do
  if [[ "$commit" =~ $breaking_header_pattern ]] || [[ "$commit" =~ $breaking_footer_pattern ]]; then
    bump="major"
    break
  elif [[ "$commit" =~ $feature_pattern ]] && [[ "$bump" != "major" ]]; then
    bump="minor"
  elif [[ "$commit" =~ $patch_pattern ]] && [[ "$bump" == "none" ]]; then
    bump="patch"
  fi
done < <(git log "${commit_range[@]}" --format='%s%n%b')

if [[ "$bump" == "none" ]]; then
  echo "No releasable conventional commits found."
  exit 0
fi

IFS=. read -r major minor patch <<< "$current_version"
case "$bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
esac

next_version="$major.$minor.$patch"
sed -i "0,/^version: \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"/s//version: \"$next_version\"/" "$version_file"
printf 'Updated %s from %s to %s (%s bump).\n' "$version_file" "$current_version" "$next_version" "$bump"