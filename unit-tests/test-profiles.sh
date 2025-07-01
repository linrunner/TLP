#!/bin/sh
# Test selection of power profiles
#
# Tested parameters:
# * n/a yet
#
# Copyright (c) 2025 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TESTLIB="./test-func"
readonly TLP="tlp"
readonly SUDO="sudo"

readonly LASTPWR='/run/tlp/last_pwr'
readonly MANUALMODE='/run/tlp/manual_mode'


# --- Functions

check_profile_select () {
    # select performance/balanced/power-saver profiles
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++


    local prof_seq
    local prof prof_save prof_xpect
    local mm_save mm_xpect mm_prev
    local rc=0
    local errcnt=0

    printf_msg "check_profile_select {{{\n"

    # save initial profile
    prof_save="$(read_sysf "$LASTPWR")"
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate support profiles, return to initial profile
    case "$prof_save" in
        0) prof_seq="balanced power-saver ac bat start performance" ;;
        1) prof_seq="power-saver ac bat start performance balanced" ;;
        2) prof_seq="ac bat start performance balanced power-saver" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " %s:" "$prof"

        case "$prof" in
            performance)
                prof_xpect="$PP_PRF"
                mm_xpect=""
                ;;

            ac)
                prof_xpect="$PP_PRF"
                mm_xpect="$prof_xpect"
                ;;

            balanced)
                prof_xpect="$PP_BAL"
                mm_xpect=""
                ;;

            bat)
                prof_xpect="$PP_BAL"
                mm_xpect="$prof_xpect"
                ;;

            power-saver)
                prof_xpect="$PP_SAV"
                mm_xpect=""
                ;;

            start)
                if on_ac; then
                    prof_xpect="$PP_PRF"
                else
                    prof_xpect="$PP_BAL"
                fi
                mm_xpect=""
                ;;

        esac

        ${SUDO} ${TLP} $prof > /dev/null 2>&1

        # expect change
        compare_sysf "$prof_xpect" "$LASTPWR";  rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " last_pwr/%s=ok" "$prof_xpect"
        else
            printf_msg " last_pwr/%s=err(%s)" "$prof_xpect" "$rc"
            errcnt=$((errcnt + 1))
        fi
        compare_sysf "$mm_xpect" "$MANUALMODE";rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " manual_mode/%s=ok" "$mm_xpect"
            mm_prev="$(read_sysf "$MANUALMODE")"
        else
            printf_msg " manual_mode/%s=err(%s)" "$mm_xpect" "$rc"
            errcnt=$((errcnt + 1))
        fi
        printf "\n"

    done # prof

    prof_save="$(read_sysf "$LASTPWR")"
    mm_save="$(read_sysf "$MANUALMODE")"

    printf_msg " result: last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

# --- MAIN
# source library
# shellcheck disable=SC1090
. $TESTLIB || {
    printf "Error: missing library %s\n" "${TESTLIB}" 1>&2
    exit 70
}

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

check_profile_select

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
