#!/bin/sh
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

start_report

if cat /sys/class/power_supply/BAT1/charge_control_end_threshold > /dev/null 2>&1; then
    run_clitest charge-thresholds_thinkpad-BAT1
elif cat /sys/class/power_supply/BAT0/charge_control_end_threshold > /dev/null 2>&1; then
    run_clitest charge-thresholds_thinkpad
elif cat /sys/devices/platform/smapi/BAT0/stop_charge_thresh > /dev/null 2>&1; then
    run_clitest charge-thresholds_thinkpad-legacy
fi

print_report
