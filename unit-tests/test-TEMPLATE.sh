#!/bin/sh
# Test: TEMPLATE
#
# Tested parameters:
# -
# -
#
# Copyright (c) 2025 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
# TEMPLATE

# --- Functions

check_feature_one () {
    # TEMPLATE
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local errcnt=0

    printf_msg "check_feature_one {{{\n"

    printf_msg " initial: \n"

    printf_msg " result: \n"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_feature_two () {
    # TEMPLATE
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local errcnt=0

    printf_msg "check_feature_two {{{\n"

    printf_msg " initial: \n"

    printf_msg " result: \n"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_feature_three () {
    # TEMPLATE
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local errcnt=0

    printf_msg "check_feature_three {{{\n"

    printf_msg " initial: \n"

    # TEMPLATE

    printf_msg " result: \n"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}


# --- MAIN
# source library
readonly TESTLIB="test-func"
spath="${0%/*}"
# shellcheck disable=SC1090
. "$spath/$TESTLIB" || {
    printf "Error: missing library %s\n" "$spath/$TESTLIB" 1>&2
    exit 70
}

# read args
if [ $# -eq 0 ]; then
    do_feature_one="1"
    do_feature_two="1"
    do_feature_three="1"
else
    while [ $# -gt 0 ]; do
        case "$1" in
            feature_one)   do_feature_one="1" ;;
            feature_two)   do_feature_two="1" ;;
            feature_three) do_feature_three="1" ;;
        esac

        shift # next argument
    done # while arguments
fi

# check prerequisites and initialize
check_tlp
cache_root_cred
start_report

# shellcheck disable=SC2034
_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

report_test "$_basename"

# initialize TLP
${SUDO} ${TLP} start > /dev/null

[ "$do_feature_one" = "1" ] && check_feature_one
[ "$do_feature_two" = "1" ] && check_feature_two
[ "$do_feature_three" = "1" ] && check_feature_three

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
