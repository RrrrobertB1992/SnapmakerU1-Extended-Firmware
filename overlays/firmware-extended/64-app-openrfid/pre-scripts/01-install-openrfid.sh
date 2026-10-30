#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12

GIT_URL=https://github.com/suchmememanyskill/OpenRFID.git
GIT_SHA=a13bc9e181374e182f61db4e69abf9fa1786cc29

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

TARGET_DIR="$CACHE_DIR/OpenRFID"
cache_git.sh "$TARGET_DIR" "$GIT_URL" "$GIT_SHA"

# LOCAL BUILD ONLY: apply unmerged OpenRFID PRs on top of the pinned commit.
# Reset to a clean checkout first so this works the same for every profile
# built in one run (the cached checkout keeps files a previous patch added).
PATCH_DIR="$(realpath "$(dirname "$0")/../openrfid-patches")"
git -C "$TARGET_DIR" reset -q --hard "$GIT_SHA"
git -C "$TARGET_DIR" clean -fdq
for patch in "$PATCH_DIR"/*.patch; do
  [[ -e "$patch" ]] || continue
  echo ">> Applying OpenRFID patch: $(basename "$patch")"
  git -C "$TARGET_DIR" apply "$patch"
done

echo ">> Installing OpenRFID..."
cd "$TARGET_DIR"
make install DESTDIR="$ROOTFS_DIR/usr/local/share/openrfid"
echo ">> OpenRFID installation completed successfully."
