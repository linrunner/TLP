#!/bin/sh
# Note: the simulation is intended to run on a ThinkPad, which has a superset
# of all battery care features

readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

cache_root_cred
start_report

run_clitest charge-thresholds_simulate1
run_clitest charge-thresholds_simulate2

./test-bc_cros-ec-all-simulate.sh
./test-bc_dell-simulate.sh

print_report
