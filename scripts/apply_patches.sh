#!/usr/bin/env bash
set -euo pipefail

# Idempotent patch applier for DumbOS (lineage-22.2) + Nexus 5X (bullhead)
# Usage: ./scripts/apply_patches.sh /path/to/dumbos-15

ROM_DIR="${1:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_ROOT="$(cd "$SCRIPT_DIR/../patches" && pwd)"

declare -A TARGET_MAP=(
  ["art"]="art"
  ["build_make"]="build/make"
  ["build_soong"]="build/soong"
  ["frameworks_av"]="frameworks/av"
  ["frameworks_base"]="frameworks/base"
  ["frameworks_native"]="frameworks/native"
  ["frameworks_opt_telephony"]="frameworks/opt/telephony"
  ["hardware_interfaces"]="hardware/interfaces"
  ["packages_apps_Settings"]="packages/apps/Settings"
  ["packages_modules_Connectivity"]="packages/modules/Connectivity"
  ["packages_modules_DnsResolver"]="packages/modules/DnsResolver"
  ["packages_services_Iwlan"]="packages/services/Iwlan"
  ["system_core"]="system/core"
  ["system_memory_lmkd"]="system/memory/lmkd"
  ["system_netd"]="system/netd"
  ["vendor_partner_gms"]="vendor/partner_gms"
)

FAILED=0

for key in "${!TARGET_MAP[@]}"; do
  rel_path="${TARGET_MAP[$key]}"
  repo_dir="$ROM_DIR/$rel_path"
  patch_dir="$PATCH_ROOT/$key"

  if [[ ! -d "$patch_dir" ]]; then
    continue
  fi
  if [[ ! -d "$repo_dir/.git" ]]; then
    echo "[ERROR] Missing git repo at $repo_dir"
    FAILED=1
    continue
  fi

  echo "=== Checking $rel_path ==="
  for p in "$patch_dir"/*.patch; do
    [[ -e "$p" ]] || continue
    pname="$(basename "$p")"
    if [[ "$key" == "hardware_interfaces" && "$pname" == "0001-03d829a9.patch" ]]; then
      if git -C "$repo_dir" log -n 5 --oneline | grep -q "avoid reconfiguring Binder thread pools"; then
        echo "  [SKIP] Equivalent fix already present in hardware/interfaces"
        continue
      fi
    fi
    if git -C "$repo_dir" apply --reverse --check "$p" >/dev/null 2>&1; then
      echo "  [SKIP] Already applied: $pname"
    elif git -C "$repo_dir" apply --check "$p" >/dev/null 2>&1; then
      if git -C "$repo_dir" am --3way "$p" >/dev/null 2>&1; then
        echo "  [OK] Applied (git am): $pname"
      else
        git -C "$repo_dir" am --abort >/dev/null 2>&1 || true
        git -C "$repo_dir" apply --index "$p" && git -C "$repo_dir" commit -m "bullhead: $pname" || {
          echo "  [ERROR] Failed to apply $pname"
          FAILED=1
        }
        echo "  [OK] Applied (git apply): $pname"
      fi
    else
      echo "  [CONFLICT] Cannot apply cleanly: $pname (needs manual rebase against DumbOS)"
      FAILED=1
    fi
  done
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "One or more patches had conflicts or errors."
  exit 1
fi

echo "All bullhead patches verified/applied cleanly."
