#!/bin/sh
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

start_report

if [ -d /sys/class/power_supply/BAT0/ ]; then
    if [ -d /sys/class/power_supply/BAT1/ ]; then
        printf "%s -- Error: do not run this test on hardware that has BAT0 *and* BAT1.\n\n" "${0##*/}" 1>&2
        report_test "${0##*/}"
        report_line "not run"
        print_report
        exit 1
    fi
    export bata=BAT0
    export batb=BAT1
elif [ -d /sys/class/power_supply/BAT1/ ]; then
    export bata=BAT1
    export batb=BAT0
else
    echo "Error: neither BAT0 nor BAT1 exists." 1>&2
    exit 1
fi

export xinc="X_BAT_PLUGIN_SIMULATE=cros-ec X_BAT_CROSCC_SIMULATE_ECVER=2"
sudo tlp setcharge ${bata} 35 100 > /dev/null 2>&1 # preset start threshold for simulation
./test-bc_cros-ec-v2.sh "(cros_charge-control)"

export xinc="X_BAT_PLUGIN_SIMULATE=framework"
sudo tlp setcharge ${bata} 35 100 > /dev/null 2>&1 # preset start threshold for simulation
./test-bc_cros-ec-v2.sh "(framework)"

export xinc="X_BAT_PLUGIN_SIMULATE=cros-ec"
./test-bc_cros-ec-v3.sh

sudo tlp setcharge ${bata}  > /dev/null 2>&1 # reset test machine to configured thresholds

print_report
