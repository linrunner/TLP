#!/bin/sh
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

start_report

if [ -d /sys/class/power_supply/BAT0/ ] \
    && [ -d /sys/class/power_supply/BAT1/ ]; then
    printf "%s -- Error: do not run this test on hardware that has BAT0 *and* BAT1.\n\n" "${0##*/}" 1>&2
    report_test "${0##*/}"
    report_line "not run"
    print_report
fi

run_clitest charge-thresholds_simulate1
run_clitest charge-thresholds_simulate2

./test-bc_cros-ec-all-simulate.sh
./test-bc_dell-simulate.sh

print_report
