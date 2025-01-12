#!/bin/sh
readonly TESTLIB="./test-func"
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

cache_root_cred
start_report

./test-cpufreq.sh
./test-gpufreq.sh
./test-bc_all.sh

print_report
