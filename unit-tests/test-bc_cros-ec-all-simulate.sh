#!/bin/sh
# Note: the simulation is intended to run on a ThinkPad, which has a superset
# of all battery care features
#
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

cache_root_cred
start_report

if bat_present BAT0; then
    export bata=BAT0
    export batb=BAT2
elif bat_present BAT1; then
    export bata=BAT1
    export batb=BAT2
else
    # shellcheck disable=SC2059
    printf "${ANSI_RED}Error:${ANSI_BLACK} neither BAT0 nor BAT1 exists.\n\n"
    report_test "${0##*/}"
    report_line "${ANSI_RED}FAIL:${ANSI_BLACK} not run - neither BAT0 nor BAT1 exists"
    print_report
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
