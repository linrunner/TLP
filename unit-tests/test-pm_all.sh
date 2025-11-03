#!/bin/sh
readonly TESTLIB="test-func"
spath="${0%/*}"
# shellcheck disable=SC1090
. "$spath/$TESTLIB" || {
    printf "Error: missing library %s\n" "$spath/$TESTLIB" 1>&2
    exit 70
}

cache_root_cred
start_report

"$spath/test-profiles.sh"
"$spath/test-cpufreq.sh"
"$spath/test-gpufreq.sh"
"$spath/test-rf-switch.sh"

print_report
