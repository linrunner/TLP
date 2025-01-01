#!/bin/sh
if cat /sys/class/power_supply/BAT1/charge_control_end_threshold > /dev/null 2>&1; then
    ./charge-thresholds_thinkpad-BAT1
elif cat /sys/class/power_supply/BAT0/charge_control_end_threshold > /dev/null 2>&1; then
    ./charge-thresholds_thinkpad
elif cat /sys/devices/platform/smapi/BAT0/stop_charge_thresh > /dev/null 2>&1; then
    ./charge-thresholds_thinkpad-legacy
fi
