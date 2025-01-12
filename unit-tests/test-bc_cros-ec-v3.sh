#!/bin/sh
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

# shellcheck disable=SC2154
echo "        # bata=${bata} batb=${batb} xinc=${xinc}"
run_clitest charge-thresholds_cros-ec-v3

print_report
