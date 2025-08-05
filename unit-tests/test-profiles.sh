#!/bin/sh
# Test:
# - select power profiles: performance, balance, power-saver, ac (manual mode), bat (manual mode)
# - invoke persistent mode
#
# Tested parameters:
# - TLP_DEFAULT_MODE
# - TLP_PERSISTENT_DEFAULT
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
    # select performance/balanced/power-saver profiles as well as ac/bat manual mode
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_seq
    local prof prof_save prof_xpect
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_profile_select {{{\n"

    # save initial profile
    prof_save="$(read_sysf "$LASTPWR")"
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="balanced power-saver ac bat start auto performance" ;;
        "$PP_BAL") prof_seq="power-saver ac bat start auto performance balanced" ;;
        "$PP_SAV") prof_seq="ac bat start auto performance balanced power-saver" ;;
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

            start|auto)
                if on_ac; then
                    prof_xpect="$PP_PRF"
                else
                    prof_xpect="$PP_BAL"
                fi
                mm_xpect=""
                ;;

        esac

        ${SUDO} ${TLP} "$prof" > /dev/null 2>&1

        # expect changes
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

check_persistent_mode () {

    local prof_seq
    local prof prof_save prof_xpect
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_persistent_mode {{{\n"

    # save initial profile
    prof_save="$(read_sysf "$LASTPWR")"
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="BAL SAV AC BAT PRF" ;;
        "$PP_BAL") prof_seq="SAV AC BAT PRF BAL" ;;
        "$PP_SAV") prof_seq="AC BAT PRF BAL SAV" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " %s:" "$prof"

        case "$prof" in
            PRF)
                prof_xpect="$PP_PRF"
                ;;

            AC)
                prof_xpect="$PP_PRF"
                ;;

            BAL)
                prof_xpect="$PP_BAL"
                ;;

            BAT)
                prof_xpect="$PP_BAL"
                ;;

            SAV)
                prof_xpect="$PP_SAV"
                ;;
        esac

        ${SUDO} ${TLP} auto -- TLP_PERSISTENT_DEFAULT=1 TLP_DEFAULT_MODE="$prof"  > /dev/null 2>&1

        # expect changing profiles
        compare_sysf "$prof_xpect" "$LASTPWR"; rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " last_pwr/%s=ok" "$prof_xpect"
        else
            printf_msg " last_pwr/%s=err(%s)" "$prof_xpect" "$rc"
            errcnt=$((errcnt + 1))
        fi
        # do not expect manual mode
        mm_xpect=""
        compare_sysf "$mm_xpect" "$MANUALMODE"; rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " manual_mode/%s=ok" "$mm_xpect"
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
check_persistent_mode

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
