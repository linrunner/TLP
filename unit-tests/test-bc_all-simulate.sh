#!/bin/sh
# Note: the simulation is intended to run on a ThinkPad, which has a superset
# of all battery care features
readonly TESTLIB="test-func"
spath="${0%/*}"
# shellcheck disable=SC1090
. "$spath/$TESTLIB" || {
    printf "Error: missing library %s\n" "$spath/$TESTLIB" 1>&2
    exit 70
}
cache_root_cred
set_threshold_trap
start_report

run_clitest "$spath/charge-thresholds_simulate1"
run_clitest "$spath/charge-thresholds_simulate2"

"$spath/test-bc_cros-ec-all-simulate.sh"
"$spath/test-bc_dell-simulate.sh"
"$spath/test-bc_lenovo-simulate.sh"
"$spath/test-bc_tuxedo-simulate.sh"

print_report
reset_threshold_trap
