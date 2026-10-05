#!/usr/bin/env bash
# Print every kit directory at the repo root, one per line, sorted.
#
# A kit is any directory holding a descriptor named after itself —
# `<dir>/<dir>.yaml`. No registration list, so adding a kit needs no change
# here or in any of this script's callers.
#
# Why the name has to match the directory: a v3 kit is a single OCI image
# published as <registry>/<namespace>/<dir>, and the directory name is
# the only thing that reference is derived from. A descriptor free to be called
# anything would let a kit build under one name and publish under another. It
# is also how the companion recipe is found — the frontend pairs `<dir>.yaml`
# with `<dir>.dockerfile` by filename stem — so the stem is already load-bearing
# before publishing ever sees it.
#
# The stem rule is also what keeps non-kit directories out without an ignore
# list: `spec/`, `tck/`, `scripts/` and `skills/` hold no file named after
# themselves, so they are not kits by construction rather than by exception.
#
# RESERVED SUFFIXES. A kit may not be named `*-kit` or `*-image`. Those are the
# v2 publishing scheme's two names for one kit (`claude-kit` carried the spec,
# `claude-image` the base), and they are still published from the frozen v2
# branch into the same `sbx` namespace this one publishes to. A kit directory
# named `foo-kit` would resolve to `sbx/foo-kit` and land on the v2 artifact for
# a kit called `foo` — a silent overwrite across two generations, in the one
# place nothing downstream would notice. Refused here rather than in a workflow
# because this script is what every caller agrees "a kit" means.
#
# Checked in a FIRST PASS, before a single name is printed, so the refusal
# cannot be read as a short list. Callers consume this through process
# substitution (`done < <(./scripts/discover-kits.sh)`), which discards the
# exit status entirely — emitting as we validate would hand tck.yml a truncated
# kit list and a green run. Nothing is printed unless every name is legal.
#
# Used by every workflow that needs the full kit list — build-and-publish-kits.yml's
# own discovery, hub-overview.yml's docs-triggered sync, and tck.yml's kit
# detection — so what counts as a kit is defined in exactly one place.
set -euo pipefail

# Anchor to the repo root so this works regardless of the caller's cwd —
# run from a kit subdirectory otherwise, the glob below matches nothing and
# the script silently prints an empty list instead of erroring.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR/.."

# `*/` rather than `*` so only directories are considered: a stray top-level
# file would otherwise be probed as though it were a kit directory.
#
# sort -u de-dupes a kit carrying both `.yaml` and `.yml` (mid-rename, say),
# which would otherwise list it twice and spawn two matrix legs racing to push
# the same tags.
kits=()
for dir in */; do
  kit=${dir%/}
  if [ -f "$kit/$kit.yaml" ] || [ -f "$kit/$kit.yml" ]; then
    kits+=("$kit")
  fi
done

for kit in ${kits[@]+"${kits[@]}"}; do
  case "$kit" in
    *-kit | *-image)
      echo "error: kit directory '${kit}' uses a reserved suffix" >&2
      echo "       '-kit' and '-image' name v2 artifacts in the same Hub" >&2
      echo "       namespace; publishing this kit would overwrite one." >&2
      exit 1
      ;;
  esac
done

printf '%s\n' ${kits[@]+"${kits[@]}"} | sort -u
