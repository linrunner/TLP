#!/bin/sh
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

start_report

if [ -d /sys/class/power_supply/BAT0/ ]; then
    export bata=BAT0
    export batb=BAT1
elif [ -d /sys/class/power_supply/BAT1/ ]; then
    export bata=BAT1
    export batb=BAT0
else
    echo "Error: neither BAT0 nor BAT1 exists." 1>&2
    exit 1
fi

# shellcheck disable=SC2154
echo "        # bata=${bata} batb=${batb} xinc=${xinc}"
run_clitest charge-thresholds_cros-ec-v2 "$1"

print_report
