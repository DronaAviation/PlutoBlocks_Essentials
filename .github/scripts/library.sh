#!/usr/bin/env bash
# Builds and checks Pluto_Libs_v<version>.zip, the library PlutoBlocks downloads.
#
#   library.sh check                          the tree is complete and its version files read
#   library.sh expect <version>               the .a files a release of <version> needs, one per line
#   library.sh build <version> <a-dir> <out>  the zip: the files git exports, plus the .a files
#
# The boards each library folder builds for are in families.json (the same list as the app's
# FAMILIES in src-tauri/src/cpp_sdk/channels.rs). Each board needs lib<TARGET>_<FW>.a, where FW
# is the FW_Version in that folder's version file.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

die() { echo "error: $*" >&2; exit 1; }

# "FW_Version = 3.0.0 \r\n" → 3.0.0
field() { # file key
  [[ -f "$1" ]] || die "$1 is missing"
  local v
  v=$(tr -d '\r' < "$1" | sed -n "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\([^[:space:]]*\).*/\1/p" | head -1)
  [[ -n "$v" ]] || die "$1 has no $2"
  echo "$v"
}

families() { python3 -c 'import json; [print(k) for k in json.load(open("families.json"))]'; }
targets() { python3 -c 'import json,sys; [print(t) for t in json.load(open("families.json"))[sys.argv[1]]]' "$1"; }

check() {
  [[ -f families.json ]] || die "families.json is missing"
  field version Repo_Version > /dev/null
  [[ -d ld ]] || die "ld/ is missing"
  for f in $(families); do
    for p in "$f/PlutoPilot.h" "$f/PlutoPilot.cpp" "$f/API"; do [[ -e "$p" ]] || die "$p is missing"; done
    field "$f/version" FW_Version > /dev/null
    field "$f/version" API_Version > /dev/null
  done
  if git ls-files | grep -q '\.a$'; then die ".a files belong on the release, not in git"; fi
}

expect() { # version
  local repo
  repo=$(field version Repo_Version)
  [[ "$repo" == "$1" ]] || die "the version file says Repo_Version = $repo, but the release is $1"
  for f in $(families); do
    local fw
    fw=$(field "$f/version" FW_Version)
    for t in $(targets "$f"); do echo "lib${t}_${fw}.a"; done
  done
}

build() { # version a-dir out
  local version=$1 adir=$2 out=$3
  check
  local names
  names=$(expect "$version")
  for n in $names; do [[ -s "$adir/$n" ]] || die "$n is missing from $adir"; done
  for a in "$adir"/*.a; do
    [[ -e "$a" ]] || continue
    grep -qx "$(basename "$a")" <<< "$names" || die "$(basename "$a") isn't a board of this release (expected: $(echo $names))"
  done

  local stage
  stage=$(mktemp -d)
  trap 'rm -rf "$stage"' RETURN
  git archive HEAD | tar -x -C "$stage"
  for f in $(families); do
    local fw
    fw=$(field "$f/version" FW_Version)
    mkdir -p "$stage/$f/lib"
    for t in $(targets "$f"); do cp "$adir/lib${t}_${fw}.a" "$stage/$f/lib/"; done
  done
  rm -f "$out"
  out=$(cd "$(dirname "$out")" && pwd)/$(basename "$out")
  (cd "$stage" && zip -q -r -X "$out" .)
  unzip -tq "$out" > /dev/null
  echo "built $out ($(du -h "$out" | cut -f1))"
}

case "${1:-}" in
  check) check && echo "library tree ok: $(field version Repo_Version)" ;;
  expect) [[ $# -eq 2 ]] || die "usage: library.sh expect <version>"; expect "$2" ;;
  build) [[ $# -eq 4 ]] || die "usage: library.sh build <version> <a-dir> <out.zip>"; build "$2" "$3" "$4" ;;
  *) die "usage: library.sh check | expect <version> | build <version> <a-dir> <out.zip>" ;;
esac
