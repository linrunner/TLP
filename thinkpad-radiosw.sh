#!/bin/sh
# thinkpad-radiosw.sh - handle ThinkPad hardware radio switch
#
# Copyright (c) 2015 Thomas Koch <linrunner at gmx.net>
# This software is licensed under the GPL v2 or later.

readonly LIBDIRS="/usr/lib/tlp-pm /usr/lib64/tlp-pm"
readonly LIBS="tlp-functions tlp-rf-func"

for libdir in $LIBDIRS; do [ -d $libdir ] && break; done
[ -d $libdir ] || exit 0

for lib in $LIBS; do
    [ -f $libdir/$lib ] || exit 0
    . $libdir/$lib
done

read_defaults || exit 0

[ "$TLP_ENABLE" = "1" ] || exit 0

sleep 2 # Allow some time for rfkill state to settle

for dev in bluetooth wifi wwan; do
    get_devc $dev
    get_devs $dev

    case $devs in
        2) # Hardware radio switch was turned off, do nothing
            echo_debug "rf" "thinkpad-radiosw: off"
            exit 0
            ;;

        0|1) # Hardware radio switch was turned on, exit loop
            break
            ;;

        *) ;; # No device, continue loop
    esac
done

# Disable configured radios
echo_debug "rf" "thinkpad-radiosw: on"
set_radio_devices_state radiosw

exit 0
