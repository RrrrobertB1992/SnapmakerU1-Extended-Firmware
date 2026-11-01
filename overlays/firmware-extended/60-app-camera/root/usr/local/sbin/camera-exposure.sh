#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12 @RrrrobertB1992

# Selects Snapmaker's auto exposure or manual exposure for the internal camera.
#
# With unisrv owning the ISP, rkaiq_3A_server applies auto exposure according
# to the sensor's tuning file in /etc/iqfiles. For manual exposure, a copy of
# the tuning file with "AecOpType": "RK_AIQ_OP_MODE_MANUAL" is bind-mounted
# over the original; everything else (white balance, noise reduction, ...)
# keeps working. rkaiq only reads the file when it starts, and it must not be
# restarted while the camera is streaming, so this runs from the lmd hook
# before unisrv starts.
#
# Usage: camera-exposure.sh apply <internal camera mode>

EXTENDED_CFG="/home/lava/printer_data/config/extended/extended2.cfg"
IQ_DIR=/etc/iqfiles
MANUAL_DIR=/tmp/camera-iq-manual

log() {
    echo "camera-exposure: $*"
    logger -t camera-exposure "$*" 2>/dev/null
}

current_mode() {
    if grep -q " $IQ_DIR/" /proc/mounts; then echo manual; else echo auto; fi
}

stop_rkaiq() {
    /etc/init.d/S40rkaiq_3A stop >/dev/null 2>&1
    i=0
    while pidof rkaiq_3A_server >/dev/null; do
        i=$((i + 1))
        if [ "$i" -gt 10 ]; then
            log "rkaiq_3A_server did not stop"
            return 1
        fi
        sleep 1
    done
}

start_rkaiq() {
    rm -f /tmp/.rkaiq_3A
    /etc/init.d/S40rkaiq_3A start >/dev/null 2>&1
}

apply() {
    want=auto
    if [ "$1" = paxx12 ] && [ "$(/usr/local/bin/extended-config.py get "$EXTENDED_CFG" camera internal_exposure auto)" = manual ]; then
        want=manual
    fi
    have=$(current_mode)
    [ "$want" = "$have" ] && return 0

    log "switching internal camera exposure from $have to $want"
    stop_rkaiq || return 1
    if [ "$want" = manual ]; then
        mkdir -p "$MANUAL_DIR"
        for f in "$IQ_DIR"/*.json; do
            grep -q '"AecOpType":[[:space:]]*"RK_AIQ_OP_MODE_AUTO"' "$f" || continue
            sed 's/"AecOpType":\([[:space:]]*\)"RK_AIQ_OP_MODE_AUTO"/"AecOpType":\1"RK_AIQ_OP_MODE_MANUAL"/' "$f" > "$MANUAL_DIR/${f##*/}"
            mount --bind "$MANUAL_DIR/${f##*/}" "$f"
        done
    else
        grep " $IQ_DIR/" /proc/mounts | while read -r _ target _; do
            umount "$target"
        done
    fi
    start_rkaiq
}

case "$1" in
apply)
    apply "$2"
    ;;
*)
    echo "Usage: $0 apply <internal camera mode>"
    exit 1
    ;;
esac
