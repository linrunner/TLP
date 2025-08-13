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

export xinc="X_BAT_PLUGIN_SIMULATE=dell"
echo "        # xinc=${xinc}" 1>&2
run_clitest "$spath/charge-thresholds_dell" "" "$1"
sudo tlp setcharge BAT0  > /dev/null 2>&1 # reset test machine to configured thresholds

print_report
