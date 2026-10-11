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

export xinc="X_SIMULATE_BC_PLUGIN=lenovo"
export bctoff="X_SIMULATE_THRESH_CHTYPES=""[Standard] Long_Life"""
export bctoff2="X_SIMULATE_THRESH_CHTYPES=""[Fast] Standard Long_Life"""
export bcton="X_SIMULATE_THRESH_CHTYPES=""Standard [Long_Life]"""
export bcton2="X_SIMULATE_THRESH_CHTYPES=""Fast Standard [Long_Life]"""
echo "        # xinc=${xinc} bcton=${bcton} bctoff=${bctoff} bcton2=${bcton2} bctoff2=${bctoff2}" 1>&2
run_clitest "$spath/charge-thresholds_lenovo" "" "$1"

print_report
