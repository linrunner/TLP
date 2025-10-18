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
    local ps
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_profile_select {{{\n"

    # save initial profile
    if [ ! -f "$LASTPWR" ]; then
        ${SUDO} ${TLP} start
    fi
    read -r prof_save ps < $LASTPWR
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="balanced power-saver ac bat start auto usb suspend resume performance" ;;
        "$PP_BAL") prof_seq="power-saver ac bat start auto performance usb suspend resume balanced" ;;
        "$PP_SAV") prof_seq="ac bat start auto performance balanced usb suspend resume power-saver" ;;
    esac

    printf_msg " initial:      last_pwr/%s manual_mode/%s\n" "$prof_save $ps" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " %-12s:" "$prof"

        case "$prof" in
            performance)
                prof_xpect="$PP_PRF $ps"
                mm_xpect=""
                ;;

            ac)
                prof_xpect="$PP_PRF $ps"
                mm_xpect="$PP_PRF"
                ;;

            balanced)
                prof_xpect="$PP_BAL $ps"
                mm_xpect=""
                ;;

            bat)
                prof_xpect="$PP_BAL $ps"
                mm_xpect="$PP_BAL"
                ;;

            power-saver)
                prof_xpect="$PP_SAV $ps"
                mm_xpect=""
                ;;

            start|auto)
                if on_ac; then
                    prof_xpect="$PP_PRF $ps"
                else
                    prof_xpect="$PP_BAL $ps"
                fi
                mm_xpect=""
                ;;

            usb|suspend|resume)
                prof_xpect="$prof_save $ps"
                mm_xpect=""
                ;;

        esac

        ${SUDO} ${TLP} "$prof" > /dev/null 2>&1

        # check expect results
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

    printf_msg " result:       last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_persistent_mode () {
    # invoke perstent mode PRF/BAL/SAV/AC/BAT
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

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

    printf_msg " initial:                                       last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " TLP_PERSISTENT_DEFAULT=1 TLP_DEFAULT_MODE=%-3s:" "$prof"

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

    printf_msg " result:                                        last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_power_supply () {
    # run 'tlp auto' with simulated power supply AC/battery/unknown
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local ps ps_seq
    local prof_save prof_xpect
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    # save initial profile
    prof_save="$(read_sysf "$LASTPWR")"
    mm_save="$(read_sysf "$MANUALMODE")"

    printf_msg "check_power_supply {{{\n"

    # iterate power supplies, return to initial power supply
    case "$prof_save" in
        "$PP_PRF") ps_seq="$PS_BAT $PS_UNKNOWN $PS_AC" ;;
        "$PP_BAL") ps_seq="$PS_UNKNOWN $PS_AC $PS_BAT" ;;
        "$PP_SAV") ps_seq="$PS_UNKNOWN $PS_AC $PS_BAT" ;;
    esac

    printf_msg " initial:                                last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

    for ps in $ps_seq; do
        printf_msg " X_SIMULATE_PS=%-3s TLP_DEFAULT_MODE=SAV:" "$ps"

        case "$ps" in
            "$PS_AC")
                prof_xpect="$PP_PRF"
                ;;

            "$PS_BAT")
                prof_xpect="$PP_BAL"
                ;;

            "$PS_UNKNOWN")
                prof_xpect="$PP_SAV"
                ;;
        esac

        ${SUDO} ${TLP} auto -- X_SIMULATE_PS="$ps" TLP_DEFAULT_MODE=SAV > /dev/null 2>&1

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

    printf_msg " result:                                 last_pwr/%s manual_mode/%s\n" "$prof_save" "$mm_save"

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
    do_profile="1"
    do_persist="1"
    do_power="1"
else
    while [ $# -gt 0 ]; do
        case "$1" in
            profile)  do_profile="1" ;;
            persist)  do_persist="1" ;;
            power)    do_power="1" ;;
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

[ "$do_profile" = "1" ] && check_profile_select
[ "$do_persist" = "1" ] && check_persistent_mode
[ "$do_power" = "1" ] && check_power_supply

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
