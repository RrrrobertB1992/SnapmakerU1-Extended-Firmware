#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12 @RrrrobertB1992

# Restarts the internal camera after a camera setting changed: lmd (and with
# it unisrv, which owns the camera), then the paxx12 camera services.
# lmd must have fully exited before it starts again, so the lmd hook can
# switch the camera setup while nothing is streaming.

/etc/init.d/S90lmd stop
i=0
while pidof unisrv lmd >/dev/null; do
    i=$((i + 1))
    if [ "$i" -gt 90 ]; then
        echo "lmd did not stop within 90 seconds"
        exit 1
    fi
    sleep 1
done
/etc/init.d/S90lmd start
/etc/init.d/S99v4l2-mpp-mipi restart
