#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12

if [[ -z "$CREATE_FIRMWARE" ]]; then
  echo "Error: This script should be run within the create_firmware.sh environment."
  exit 1
fi

set -eo pipefail

VERSION=v1.37.7
URL=https://github.com/fluidd-core/fluidd/releases/download/$VERSION/fluidd.zip
SHA256=e45889071dae4e79f22e38bfb28cad0ce0c89e134c09d174cd447c4c93bd9556
FILENAME=fluidd-$VERSION.zip

# LOCAL BUILD ONLY: use a locally built Fluidd (local/fluidd.zip, zipped the
# same way as the release: the contents of dist/) instead of the release zip.
LOCAL_ZIP="$(realpath "$(dirname "$0")/..")/local/fluidd.zip"
if [[ -f "$LOCAL_ZIP" ]]; then
  echo ">> LOCAL BUILD ONLY: installing Fluidd from $LOCAL_ZIP"
  rm -rf "$ROOTFS_DIR/home/lava/fluidd"
  mkdir -p "$ROOTFS_DIR/home/lava/fluidd"
  unzip -o -q "$LOCAL_ZIP" -d "$ROOTFS_DIR/home/lava/fluidd"
  test -f "$ROOTFS_DIR/home/lava/fluidd/index.html"
  exit 0
fi

rm -rf "$ROOTFS_DIR/home/lava/fluidd"

cache_file.sh "$CACHE_DIR/$FILENAME" "$URL" "$SHA256" "$ROOTFS_DIR/home/lava/fluidd"
