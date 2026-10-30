# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-PackageHomePage: https://github.com/paxx12-snapmaker-u1/SnapmakerU1-Extended-Firmware
# SPDX-FileCopyrightText: Copyright (c) 2026 @paxx12

if [ "$1" = start ]; then
    EXTENDED_CFG="/home/lava/printer_data/config/extended/extended2.cfg"
    CAMERA_INTERNAL=$(/usr/local/bin/extended-config.py get "$EXTENDED_CFG" camera internal snapmaker)
    if [ "$CAMERA_INTERNAL" = paxx12 ]; then
        # Stock 2.1.0 unisrv captures through librockit and opens
        # /dev/video11 and /dev/video12 directly instead of through libv4l2,
        # so the imposter can't redirect it. If unisrv starts first it holds
        # the ISP and capture-v4l2-raw-mpp fails with "queue busy". Start the
        # MIPI capture before lmd (without lmd's preloads) and wait until it
        # holds the device.
        (unset LD_PRELOAD; /etc/init.d/S99v4l2-mpp-mipi start)
        _camera_wait=0
        while [ "$_camera_wait" -lt 10 ]; do
            for _camera_pid in $(pidof capture-v4l2-raw-mpp); do
                if ls -l "/proc/$_camera_pid/fd" 2>/dev/null | grep -q /dev/video11; then
                    _camera_wait=done
                    break
                fi
            done
            [ "$_camera_wait" = done ] && break
            sleep 1
            _camera_wait=$((_camera_wait + 1))
        done
        [ "$_camera_wait" = done ] || echo "MIPI capture did not open /dev/video11 in time, starting lmd anyway."
        unset _camera_wait _camera_pid

        echo "Starting lmd in v4l2-imposter mode!"
        export LD_PRELOAD="/usr/local/lib/libv4l2-imposter.so${LD_PRELOAD:+:$LD_PRELOAD}"
        export V4L2_IMPOSTER_SOCKET_PATH=/tmp/capture-mipi-raw.sock
        export V4L2_IMPOSTER_DEVICE=/dev/video11
        export V4L2_IMPOSTER_WIDTH=1920
        export V4L2_IMPOSTER_HEIGHT=1080
        export V4L2_IMPOSTER_FORMAT=nv12
    elif [ "$CAMERA_INTERNAL" != snapmaker ]; then
        echo "Internal camera is not set to 'snapmaker', not starting lmd."
        exit 0
    fi
fi
