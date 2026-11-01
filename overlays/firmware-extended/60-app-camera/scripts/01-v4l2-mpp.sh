#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12

CUR_DIR="$(realpath "$(dirname "$0")")"

GIT_URL=https://github.com/paxx12/v4l2-mpp.git
GIT_SHA=87bda8efbb7b32d8d57fc6a8d76dfae9418a2190

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

TARGET_DIR="$CACHE_DIR/v4l2-mpp"
cache_git.sh "$TARGET_DIR" "$GIT_URL" "$GIT_SHA"

# cache_git.sh reuses an existing checkout as-is on a local (non-CI) rebuild,
# so reset tracked files to the pinned commit before patching - otherwise
# re-running this script would try to re-apply the patches.
git -C "$TARGET_DIR" checkout -f "$GIT_SHA"

for patchfile in "$CUR_DIR/../v4l2-mpp-patches/"*.patch; do
  echo ">> Applying $(basename "$patchfile")..."
  patch -F 0 --no-backup-if-mismatch -d "$TARGET_DIR" -p1 < "$patchfile"
done

echo ">> Setting up cross-compilation environment..."
export CROSS_COMPILE=aarch64-linux-gnu-
export CC="${CROSS_COMPILE}gcc"
export CXX="${CROSS_COMPILE}g++"
export AR="${CROSS_COMPILE}ar"
export RANLIB="${CROSS_COMPILE}ranlib"
export STRIP="${CROSS_COMPILE}strip"

echo ">> Compiling dependencies..."
make -C "$TARGET_DIR" deps

echo ">> Compiling v4l2-mpp applications..."
make -C "$TARGET_DIR" install DESTDIR="$1"

echo ">> Validate binaries..."
stat "$1/usr/local/bin/capture-v4l2-jpeg-mpp" >/dev/null
stat "$1/usr/local/bin/capture-v4l2-raw-mpp" >/dev/null
stat "$1/usr/local/bin/stream-rtsp" >/dev/null
stat "$1/usr/local/bin/stream-webrtc" >/dev/null
stat "$1/usr/local/bin/stream-http.py" >/dev/null
stat "$1/usr/local/bin/control-v4l2.py" >/dev/null
grep -q -- "--readonly-controls" "$1/usr/local/bin/control-v4l2.py"
echo ">> v4l2-mpp installation completed successfully."
