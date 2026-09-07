#!/bin/sh
# Test manual switching as user and root (without parameters):
# - bluetooth [on|off]
# - nfc [on|off] (dummy only)
# - wifi [on|off]
# - wwan [on|off]
#
# Test automated switching when changing profiles with parameters:
# - DEVICES_TO_ENABLE_ON_PRF
# - DEVICES_TO_DISABLE_ON_PRF
# - DEVICES_TO_ENABLE_ON_BAL
# - DEVICES_TO_DISABLE_ON_BAL
# - DEVICES_TO_ENABLE_ON_SAV
# - DEVICES_TO_DISABLE_ON_SAV
#
# REQUIRES: a machine with bluetooth, wifi; without nfc, wwan
#
# Copyright (c) 2026 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
ALL_RADIOS="bluetooth nfc wifi wwan"

# --- Functions

read_rf_state () {
    # $1: radio type: bluetooth/wifi/wwan/nfc
    # $2: 1=quiet

    if wordinlist "$1" "$ALL_RADIOS"; then
        state="$($1 | sed -r 's/'"$1"'.+= (on|off|none).*/\1/')"
        if wordinlist "$state" "on off none"; then
            printf "%s" "$state"
            return 0
        else
            printf "unknown"
            [ "$2" = "1" ] || printf_msg " Error: unrecognizable %s state \"%s\".\n" "$1" "$state"
            return 1
        fi
    else
        [ "$2" = "1" ] || printf_msg " Error: unknown radio type '%s'.\n" "$1"
        exit 254
    fi
}

print_rf_on_list () {
    # print list of enabled radios (limited to bluetooth, wifi)
    local rfdev rfstate
    local rfonlist=""

    for rfdev in bluetooth wifi; do
        rfstate="$(read_rf_state "$rfdev" 1)"
        if [ "$rfstate" = "on" ]; then
            rfonlist="${rfonlist}${rfonlist:+ }${rfdev}"
        fi
    done

    printf "%s" "$rfonlist"
}

restore_rf_states () {
    # enable radios on target list, disable all else (limited to bluetooth, wifi)
    # $1: target list
    local rfdev

    for rfdev in bluetooth wifi; do
        if wordinlist "$rfdev" "$1"; then
            if [ "$rfdev" = "wifi" ]; then
                nmcli
            sudo rfkill unblock "$rfdev"
        else
            sudo rfkill block "$rfdev"
        fi
    done
}

compare_rf_states () {
    # compare list of enabled radios with target list (limited to bluetooth, wifi)
    # $1: target list of radios expected to be enabled
    # rc: 0=matching, 1=differing
    local xpect="$1"
    # shellcheck disable=SC2155
    local on="$(print_rf_on_list)"

    if [ "$xpect" = "$on" ]; then
        printf_msg " --> ok"
        return 0
    else
        printf_msg " *** Deviation: %s (act) != %s (exp)" "$on" "$xpect"
        return 1
    fi
}

run_rf_profile () {
    # apply profile with radio enable/disable lists
    # $1: profile
    # $2: radios to enable
    # $3: radios to disable
    # $4: radios expected to be on after run
    # --- negative test
    # input for DEVICES_TO_ENABLE/DISABLE_ON_STARTUP
    # expectation is that it has no effect because the profile-specific parameters take precedence
    # $5: radios to enable on startup
    # $6: radios to disable on startup


    local prof="$1"
    local rf_on="$2"
    local rf_off="$3"
    local rf_xpect="$4"
    local rf_on_st="$5"
    local rf_off_st="$6"

    printf_msg " %-11s: enable=%-32s disable=%-18s expect=%-14s" "$prof" "[$rf_on]" "[$rf_off]" "[$rf_xpect]"
    case "$prof" in
        performance) sudo tlp "$prof" -- DEVICES_TO_ENABLE_ON_PRF="$rf_on" DEVICES_TO_DISABLE_ON_PRF="$rf_off" \
            DEVICES_TO_ENABLE_ON_STARTUP="$rf_on_st" DEVICES_TO_DISABLE_ON_STARTUP="$rf_off_st" > /dev/null 2>&1 ;;
        balanced)    sudo tlp "$prof" -- DEVICES_TO_ENABLE_ON_BAL="$rf_on" DEVICES_TO_DISABLE_ON_BAL="$rf_off" \
            DEVICES_TO_ENABLE_ON_STARTUP="$rf_on_st" DEVICES_TO_DISABLE_ON_STARTUP="$rf_off_st" > /dev/null 2>&1 ;;
        power-saver) sudo tlp "$prof" -- DEVICES_TO_ENABLE_ON_SAV="$rf_on" DEVICES_TO_DISABLE_ON_SAV="$rf_off" \
            DEVICES_TO_ENABLE_ON_STARTUP="$rf_on_st" DEVICES_TO_DISABLE_ON_STARTUP="$rf_off_st" > /dev/null 2>&1 ;;
        startup)     sudo tlp init start -- DEVICES_TO_ENABLE_ON_STARTUP="$rf_on" DEVICES_TO_DISABLE_ON_STARTUP="$rf_off" > /dev/null 2>&1 ;;
    esac

    return 0
}

# --- Tests
check_radio () {
    # switch all radios on and off with their respective tlp-rf command;
    # without and with sudo
    # $1: radio command: wifi/bluetooth/wwan/nfc
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local rf_cmd="$1"
    local errcnt=0
    local rf_save rf_seq
    local sdo

    printf_msg "check_radio (%s) {{{\n" "$rf_cmd"

    if rf_save="$(read_rf_state "$rf_cmd")"; then
        case "$rf_save" in
            off)  rf_seq="on off" ;;
            on)   rf_seq="off on" ;;
            none)
                rf_seq=""
                if wordinlist "$rf_cmd" "bluetooth wifi"; then
                    printf_msg " no device - REALLY?\n"
                    errcnt=1
                else
                    printf_msg " no device.\n"
                fi
                ;;
            *)
                rf_seq=""
                errcnt=1
                ;;
        esac

        if [ -n "$rf_seq" ]; then
            printf_msg " initial: %s\n" "$rf_save"

            for sdo in "" "sudo"; do
                for next_state in $rf_seq; do
                    # shellcheck disable=SC2086
                    $sdo $rf_cmd "$next_state" 1> /dev/null
                    printf_msg " %-4s %s %-3s -> " "$sdo" "$rf_cmd" "$next_state"
                    new_state="$(read_rf_state "$rf_cmd")"

                    if [ "$new_state" = "$next_state" ]; then
                        printf_msg "%-3s (ok)\n" "$new_state"
                    else
                        printf_msg "Deviation: %-3s (act) != %-3s (exp)\n" "$new_state" "$next_state"
                        errcnt=$((errcnt + 1))
                    fi
                done
            done

            printf_msg " result: %s\n" "$(read_rf_state "$rf_cmd")"
        fi
    fi

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_rf_profiles () {
    # switch radios by selecting performance/balanced/power-saver profiles
    # REQUIRES: a machine with bluetooth, wifi; without nfc, wwan
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_seq
    local prof prof_save ps
    local rfdev rf_on rf_off rf_on_st rf_off_st rf_xpect rf_on_save
    local errcnt=0

    printf_msg "check_rf_profiles {{{\n"

    # save initial profile and radio states
    read_saved_profile
    # shellcheck disable=SC2154
    prof_save="$_prof"
    # shellcheck disable=SC2154
    ps="$_ps"
    rf_on_save="$(print_rf_on_list)"

    # shellcheck disable=SC2154
    printf_msg " intial/saved: last_pwr/%s %s\n" "$prof_save $ps" "[$rf_on_save]"

    # take tlp-rdw out of the game
    sudo tlp-rdw disable > /dev/null 2>&1
    # Establish defined initial state: all radios off
    for rfdev in $ALL_RADIOS; do
        sudo rfkill block "$rfdev"
    done

    # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="startup balanced power-saver performance" ;;
        "$PP_BAL") prof_seq="startup power-saver performance balanced" ;;
        "$PP_SAV") prof_seq="startup performance balanced power-saver" ;;
    esac

    for prof in $prof_seq; do
        rf_on="bluetooth wifi nfc wwan void"
        rf_off="bluetooth"
        rf_on_st="bluetooth" # negative test, expectation is that it has no effect
        rf_off_st="wifi"     # negative test, expectation is that it has no effect
        rf_xpect="wifi"
        run_rf_profile "$prof" "$rf_on" "$rf_off" "$rf_xpect" "$rf_on_st" "$rf_off_st"
        # check expected results
        if ! compare_rf_states "$rf_xpect"; then
            errcnt=$((errcnt + 1))
        fi
        printf_msg "\n"

        rf_on="bluetooth nfc wwan void"
        rf_off="wifi"
        ### rf_on=""
        ### rf_off=""
        ### rf_on_st="bluetooth nfc wwan void"
        ### rf_off_st="wifi"
        rf_xpect="bluetooth"
        run_rf_profile "$prof" "$rf_on" "$rf_off" "$rf_xpect"
        # check expected results
        if ! compare_rf_states "$rf_xpect"; then
            errcnt=$((errcnt + 1))
        fi
        printf_msg "\n"

        rf_on="nfc wwan xyzzy"
        rf_off="bluetooth wifi"
        rf_xpect=""
        run_rf_profile "$prof" "$rf_on" "$rf_off" "$rf_xpect"
        # check expected results
        if ! compare_rf_states "$rf_xpect"; then
            errcnt=$((errcnt + 1))
        fi
        printf_msg "\n"

    done # prof

    restore_rf_states "$rf_on_save"

    read_saved_profile
    printf_msg " final/restored: last_pwr/%s %s\n" "$_prof $_ps" "[$(print_rf_on_list)]"

    # bring tlp-rdw back into the game
    sudo tlp-rdw enable > /dev/null 2>&1

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
    do_wifi="1"
    do_bluetooth="1"
    do_wwan="1"
    do_nfc="1"
    do_profiles="1"
else
    while [ $# -gt 0 ]; do
        case "$1" in
            wifi)      do_wifi="1" ;;
            bluetooth) do_bluetooth="1" ;;
            wwan)      do_wwan="1" ;;
            nfc)       do_nfc="1" ;;
            profiles)  do_profiles="1" ;;
        esac

        shift # next argument
    done # while arguments
fi

# check prerequisites and initialize
check_tlp
cache_root_cred
start_report

_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

report_test "$_basename"
printf_msg "+++ %s\n\n" "$_basename"

[ "$do_wifi" = "1" ] && check_radio wifi
[ "$do_bluetooth" = "1" ] && check_radio bluetooth
[ "$do_wwan" = "1" ] && check_radio wwan
[ "$do_nfc" = "1" ] && check_radio nfc
[ "$do_profiles" = "1" ] && check_rf_profiles

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
