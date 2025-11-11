#!/bin/sh
# Test (as user and as root):
# - bluetooth [on|off]
# - nfc [on|off] (dummy only)
# - wifi [on|off]
# - wwan [on|off]
#
# Tested parameters:
# - none yet
#
# Copyright (c) 2025 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants


# --- Functions

read_rf_state () {
    # $1: radio type: bluetooth/wifi/wwan/nfc
    if wordinlist "$1" "bluetooth nfc wifi wwan"; then
        state="$($1 | sed -r 's/'"$1"'.+= (on|off|none).*/\1/')"
        if wordinlist "$state" "on off none"; then
            printf "%s" "$state"
            return 0
        else
            printf "unknown"
            printf_msg " Error: unrecognizable %s state \"%s\".\n" "$1" "$state"
            return 1
        fi
    else
        printf_msg " Error: unknown radio type '%s'.\n" "$1"
        exit 254
    fi
}

check_radio () {
    # TEMPLATE
    # $1: radio command: wifi/bluetooth/wwan/nfc
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local rf_cmd="$1"
    local errcnt=0
    local rf_save rf_seq

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

            for SUDO in '     ' 'sudo '; do
                for next_state in $rf_seq; do
                    # shellcheck disable=SC2086
                    $SUDO $rf_cmd "$next_state" 1> /dev/null
                    printf_msg " %s%s %-3s -> " "$SUDO" "$rf_cmd" "$next_state"
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
else
    while [ $# -gt 0 ]; do
        case "$1" in
            wifi)      do_wifi="1" ;;
            bluetooth) do_bluetooth="1" ;;
            wwan)      do_wwan="1" ;;
            nfc)       do_nfc="1" ;;
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

[ "$do_wifi" = "1" ] && check_radio wifi
[ "$do_bluetooth" = "1" ] && check_radio bluetooth
[ "$do_wwan" = "1" ] && check_radio wwan
[ "$do_nfc" = "1" ] && check_radio nfc

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
