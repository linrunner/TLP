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

export xinc="X_BAT_PLUGIN_SIMULATE=lenovo"
export bctoff="X_THRESH_SIMULATE_BCT=""[Standard] Long_Life"""
export bcton="X_THRESH_SIMULATE_BCT=""Standard [Long_Life]"""
echo "        # xinc=${xinc} bcton=${bcton} bctoff=${bctoff}" 1>&2
run_clitest "$spath/charge-thresholds_lenovo" "" "$1"

print_report
