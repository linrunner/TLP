#!/bin/sh
# Test:
# - select power profiles: performance, balance, power-saver, ac (manual mode), bat (manual mode)
# - run persistent mode
#
# Tested parameters:
# - TLP_AUTO_SWITCH
# - TLP_DEFAULT_MODE
# - TLP_PERSISTENT_DEFAULT
#
# Copyright (c) 2026 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TLP="tlp"
readonly SUDO="sudo"
readonly UDEVADM="udevadm"

readonly MANUALMODE='/run/tlp/manual_mode'
readonly TEMPCONF='/etc/tlp.d/99-unit-test.conf'

# --- Tests
check_profile_select () {
    # select performance/balanced/power-saver profiles as well as ac/bat manual mode
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_seq
    local prof prof_save prof_xpect
    local ps_save
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_profile_select {{{\n"

    # save initial profile, power source and manual mode
    read_saved_profile
    # shellcheck disable=SC2154
    prof_save="$_prof"
    # shellcheck disable=SC2154
    ps_save="$_ps"
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="balanced power-saver ac bat start auto suspend resume0 resume usb usb0 performance" ;;
        "$PP_BAL") prof_seq="power-saver ac bat start auto performance suspend resume0 resume usb usb0 balanced" ;;
        "$PP_SAV") prof_seq="ac bat start auto performance balanced suspend resume0 resume usb usb0  power-saver" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save $ps_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " %-12s:" "$prof"

        case "$prof" in
            performance)
                prof_xpect="$PP_PRF $ps_save"
                mm_xpect=""
                prof_save="$PP_PRF"
                ;;

            ac)
                prof_xpect="$PP_PRF $ps_save"
                mm_xpect="$PP_PRF"
                prof_save="$PP_PRF"
                ;;

            balanced)
                prof_xpect="$PP_BAL $ps_save"
                mm_xpect=""
                prof_save="$PP_BAL"
                ;;

            bat)
                prof_xpect="$PP_BAL $ps_save"
                mm_xpect="$PP_BAL"
                prof_save="$PP_BAL"
                ;;

            power-saver)
                prof_xpect="$PP_SAV $ps_save"
                mm_xpect=""
                prof_save="$PP_SAV"
                remove_saved_profile
                ;;

            start|auto)
                if on_ac; then
                    prof_xpect="$PP_PRF $ps_save"
                    prof_save="$PP_PRF"
                else
                    prof_xpect="$PP_BAL $ps_save"
                    prof_save="$PP_BAL"
                fi
                mm_xpect=""
                remove_saved_profile
                ;;

            usb)
                prof_xpect="$ps_save $ps_save"
                mm_xpect=""
                ;;

            usb0)
                prof="usb"
                prof_xpect=""
                mm_xpect=""
                remove_saved_profile
                ;;

            suspend)
                prof_xpect="$prof_save $ps_save"
                mm_xpect=""
                ;;

            resume)
                prof_xpect="$ps_save $ps_save"
                mm_xpect=""
                ;;

            resume0)
                prof="resume"
                prof_xpect="$ps_save $ps_save"
                mm_xpect=""
                remove_saved_profile
                ;;

        esac

        ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" > /dev/null 2>&1

        # check expect results
        compare_sysf "$prof_xpect" "$LASTPWR"; rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " last_pwr/%s=ok" "$prof_xpect"
        else
            printf_msg " last_pwr/%s=err(%s)" "$prof_xpect" "$rc"
            errcnt=$((errcnt + 1))
        fi
        compare_sysf "$mm_xpect" "$MANUALMODE"; rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " manual_mode/%s=ok" "$mm_xpect"
        else
            printf_msg " manual_mode/%s=err(%s)" "$mm_xpect" "$rc"
            errcnt=$((errcnt + 1))
        fi
        printf_msg "\n"

    done # prof

    read_saved_profile
    printf_msg " result: last_pwr/%s manual_mode/%s\n" "$_prof $_ps" "$(read_sysf "$MANUALMODE")"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_default_mode () {
    # run default mode PRF/BAL/SAV/AC/BAT
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_seq
    local prof prof_save prof_xpect
    local ps_save
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_default_mode {{{\n"

    # save initial profile, power source and manual mode
    read_saved_profile; prof_save="$_prof"; ps_save="$_ps"
    mm_save="$(read_sysf "$MANUALMODE")"

   # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="BAL SAV AC BAT PRF" ;;
        "$PP_BAL") prof_seq="SAV AC BAT PRF BAL" ;;
        "$PP_SAV") prof_seq="AC BAT PRF BAL SAV" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save $ps_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " TLP_AUTO_SWITCH=0 TLP_DEFAULT_MODE=%-4s" "${prof}:"

        case "$prof" in
            PRF)
                prof_xpect="$PP_PRF $ps_save"
                ;;

            AC)
                prof_xpect="$PP_PRF $ps_save"
                ;;

            BAL)
                prof_xpect="$PP_BAL $ps_save"
                ;;

            BAT)
                prof_xpect="$PP_BAL $ps_save"
                ;;

            SAV)
                prof_xpect="$PP_SAV $ps_save"
                ;;
        esac

        ${SUDO} ${TLP} start -- TLP_AUTO_SWITCH=0 TLP_DEFAULT_MODE="$prof" TLP_PERSISTENT_DEFAULT=0 > /dev/null 2>&1

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
        printf_msg "\n"

    done # prof

    read_saved_profile
    printf_msg " result: last_pwr/%s manual_mode/%s\n" "$_prof $_ps" "$(read_sysf "$MANUALMODE")"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_persistent_mode () {
    # run persistent mode PRF/BAL/SAV/AC/BAT
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_seq
    local prof prof_save prof_xpect
    local ps_save
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_persistent_mode {{{\n"

    # save initial profile, power source and manual mode
    read_saved_profile; prof_save="$_prof"; ps_save="$_ps"
    mm_save="$(read_sysf "$MANUALMODE")"

   # iterate supported profiles, return to initial profile
    case "$prof_save" in
        "$PP_PRF") prof_seq="BAL SAV AC BAT PRF" ;;
        "$PP_BAL") prof_seq="SAV AC BAT PRF BAL" ;;
        "$PP_SAV") prof_seq="AC BAT PRF BAL SAV" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save $ps_save" "$mm_save"

    for prof in $prof_seq; do
        printf_msg " TLP_PERSISTENT_DEFAULT=1 TLP_DEFAULT_MODE=%-4s" "${prof}:"

        case "$prof" in
            PRF)
                prof_xpect="$PP_PRF $ps_save"
                ;;

            AC)
                prof_xpect="$PP_PRF $ps_save"
                ;;

            BAL)
                prof_xpect="$PP_BAL $ps_save"
                ;;

            BAT)
                prof_xpect="$PP_BAL $ps_save"
                ;;

            SAV)
                prof_xpect="$PP_SAV $ps_save"
                ;;
        esac

        ${SUDO} ${TLP} auto -- TLP_PERSISTENT_DEFAULT=1 TLP_DEFAULT_MODE="$prof" > /dev/null 2>&1

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
        printf_msg "\n"

    done # prof

    read_saved_profile
    printf_msg " result: last_pwr/%s manual_mode/%s\n" "$_prof $_ps" "$(read_sysf "$MANUALMODE")"

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
    local ps_save
    local mm_save mm_xpect
    local rc=0
    local errcnt=0

    printf_msg "check_power_supply {{{\n"

    # save initial profile, power source and manual mode
    read_saved_profile; prof_save="$_prof"; ps_save="$_ps"
    mm_save="$(read_sysf "$MANUALMODE")"

    # iterate power supplies, return to initial power supply
    case "$prof_save" in
        "$PP_PRF") ps_seq="$PS_BAT $PS_UNKNOWN $PS_AC" ;;
        "$PP_BAL") ps_seq="$PS_UNKNOWN $PS_AC $PS_BAT" ;;
        "$PP_SAV") ps_seq="$PS_UNKNOWN $PS_AC $PS_BAT" ;;
    esac

    printf_msg " initial: last_pwr/%s manual_mode/%s\n" "$prof_save $ps_save" "$mm_save"

    for ps in $ps_seq; do
        printf_msg " X_SIMULATE_PS=%-3s TLP_DEFAULT_MODE=SAV:" "$ps"

        case "$ps" in
            "$PS_AC")
                prof_xpect="$PP_PRF $ps"
                ;;

            "$PS_BAT")
                prof_xpect="$PP_BAL $ps"
                ;;

            "$PS_UNKNOWN")
                prof_xpect="$PP_SAV $ps"
                ;;
        esac

        ${SUDO} ${TLP} start -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE=SAV TLP_PERSISTENT_DEFAULT=0 \
            X_SIMULATE_PS="$ps" > /dev/null 2>&1

        # expect changing profiles
        compare_sysf "$prof_xpect" "$LASTPWR"; rc=$?
        if [ "$rc" -eq 0 ]; then
            printf_msg " last_pwr/%s=ok" "$prof_xpect $ps_save"
        else
            printf_msg " last_pwr/%s=err(%s)" "$prof_xpect $ps_save" "$rc"
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
        printf_msg "\n"

    done # prof

    read_saved_profile
    printf_msg " result: last_pwr/%s manual_mode/%s\n" "$_prof $_ps" "$(read_sysf "$MANUALMODE")"

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}


check_auto_switch () {
    # test TLP_AUTO_SWITCH=0/1/2
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof prof_save prof_xpect
    local ps_now ps_next
    local as
    local mm_xpect mm_save
    local rc=0
    local errcnt=0

    printf_msg "check_auto_switch {{{\n"

    # save initial manual mode
    mm_save="$(read_sysf "$MANUALMODE")"

    for as in 0 1 2; do
        # iterate auto switch modes

        # reset profile
        ${SUDO} ${TLP} start -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" TLP_PERSISTENT_DEFAULT=0 > /dev/null

        # save current profile and power source
        read_saved_profile; prof_save="$_prof"
        printf_msg " TLP_AUTO_SWITCH=%s: last_pwr/%s manual_mode/%s\n" "$as" "$_prof $_ps" "$mm_save"

        case "$as" in
            0|1) # auto switch: disabled|enabled
                for ps_now in 0 1; do
                    for mode in auto resume; do
                        printf_msg "  %-6s X_SIMULATE_PS=%s:" "$mode" "$ps_now"
                        ${SUDO} ${TLP} "$mode" -- TLP_AUTO_SWITCH="$as" TLP_DEFAULT_MODE="" TLP_PERSISTENT_DEFAULT=0 \
                            X_SIMULATE_PS="$ps_now" > /dev/null 2>&1
                        # do not expect profile change
                        case "$as" in
                            0) prof_xpect="$prof_save $ps_now" ;;
                            1) prof_xpect="$ps_now $ps_now" ;;
                        esac
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
                        printf_msg "\n"
                    done # auto/resume
                done # ps_now
                ;; # disabled|enabled

            2) # auto switch: smart
                for mode in auto resume; do
                    for ps_now in 0 1; do
                        # calc opposite pweor source
                        ps_next="$((! ps_now))"

                        for prof in performance balanced power-saver; do
                            # prepare simulated active profile and power source
                            printf_msg "  %-6s (prof=%-11s ps_now=%s) --> ps_next=%s:" "$mode" "$prof" "$ps_now" "$ps_next"
                            ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_PERSISTENT_DEFAULT=0 \
                                X_SIMULATE_PS="$ps_now" > /dev/null 2>&1

                            # determine expected profile
                            case "$ps_now" in
                                0) # simulated active power source: AC
                                    case "$prof" in
                                        performance) prof_xpect="$PP_BAL $ps_next" ;;
                                        balanced)    prof_xpect="$PP_BAL $ps_next" ;;
                                        power-saver) prof_xpect="$PP_SAV $ps_next" ;;
                                    esac
                                    ;;

                                1) # simulated active pwoer source: battery
                                    case "$prof" in
                                        performance) prof_xpect="$PP_PRF $ps_next" ;;
                                        balanced)    prof_xpect="$PP_PRF $ps_next" ;;
                                        power-saver) prof_xpect="$PP_SAV $ps_next" ;;
                                    esac
                                    ;;
                            esac

                            # check auto/resume on opposite power source
                            ${SUDO} ${TLP} "$mode" -- TLP_AUTO_SWITCH="$as" TLP_PERSISTENT_DEFAULT=0 \
                                X_SIMULATE_PS="$ps_next" > /dev/null 2>&1

                            # check against expectations
                            compare_sysf "$prof_xpect" "$LASTPWR"; rc=$?
                            if [ "$rc" -eq 0 ]; then
                                printf_msg " last_pwr/%s=ok" "$prof_xpect"
                            else
                                printf_msg " last_pwr/%s=err(%s)" "$prof_xpect" "$rc"
                                errcnt=$((errcnt + 1))
                            fi
                            mm_xpect=""
                            compare_sysf "$mm_xpect" "$MANUALMODE"; rc=$?
                            if [ "$rc" -eq 0 ]; then
                                printf_msg " manual_mode/%s=ok" "$mm_xpect"
                            else
                                printf_msg " manual_mode/%s=err(%s)" "$mm_xpect" "$rc"
                                errcnt=$((errcnt + 1))
                            fi
                            printf_msg "\n"
                        done # prof
                        printf_msg "\n"
                    done # ps_now
                done # auto/resume
                ;; # smart
        esac # as

        read_saved_profile
        printf_msg " result: last_pwr/%s manual_mode/%s\n\n" "$_prof $_ps" "$(read_sysf "$MANUALMODE")"
   done # as

   # print summary
   printf_msg "}}} errcnt=%s\n\n" "$errcnt"
   _testcnt=$((_testcnt + 1))
   [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
   return $errcnt

}

check_ps_udev_no_switch () {
    # cover special case of USB-C disk unplug:
    # 1. configure TLP_AUTO_SWITCH=1
    # 2. apply power-saver profile
    # 3. simulate udev power_supply change event
    # 4. check if logic works properly and power-saver profile doesn't change
    # Refer to:
    # - https://thinkpad-forum.de/threads/tlp-1-9-alpha-testergebnisse.244864/page-3#post-2451309
    # - 7eec753, 61ac2ea
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local prof_save prof_xpect
    local ps ppi
    local rc=0
    local errcnt=0

    printf_msg "check_ps_udev_no_switch {{{\n"

    # reset profile
    ${SUDO} ${TLP} start -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" TLP_PERSISTENT_DEFAULT=0 > /dev/null

    # save initial profile
    read_saved_profile; prof_save="$_prof"; ps="$_ps"
    printf_msg " initial: last_pwr/%s\n" "$prof_save $ps"

    # 1. create temp config
    echo "TLP_AUTO_SWITCH=1" | ${SUDO} tee $TEMPCONF > /dev/null

    # 2. apply power-saver profile
    printf_msg " Apply power-saver:"
    ${SUDO} ${TLP} power-saver -- TLP_PERSISTENT_DEFAULT=0 > /dev/null 2>&1
    # expect power-saver
    prof_xpect="2"
    compare_sysf "$prof_xpect $ps" "$LASTPWR"; rc=$?
    if [ "$rc" -eq 0 ]; then
        printf_msg " last_pwr/%s=ok" "$prof_xpect $ps"
    else
        printf_msg " last_pwr/%s=err(%s)" "$prof_xpect $ps" "$rc"
        errcnt=$((errcnt + 1))
    fi
    printf_msg "\n"

    # 3. simulate udev power_supply change event
    printf_msg " Simulate PS udev event w/TLP_AUTO_SWITCH=1:"
    ${SUDO} ${UDEVADM} trigger --type=all --action=change --subsystem-match=power_supply --sysname-match=AC
    # wait for tlp processing
    sleep 2

    # 4. check if logic works properly and power-saver profile didnt't change
    compare_sysf "$prof_xpect $ps" "$LASTPWR"; rc=$?
    if [ "$rc" -eq 0 ]; then
        printf_msg " last_pwr/%s=ok" "$prof_xpect $ps"
    else
        printf_msg " last_pwr/%s=err(%s)" "$prof_xpect $ps" "$rc"
        errcnt=$((errcnt + 1))
    fi
    printf_msg "\n"

    # restore initial profile
    case "$prof_save" in
        "$PP_PRF") ppi="performance" ;;
        "$PP_BAL") ppi="balanced" ;;
        "$PP_SAV") ppi="power-saver" ;;
    esac
    ${SUDO} ${TLP} ${ppi} -- TLP_PERSISTENT_DEFAULT=0 > /dev/null 2>&1

    read_saved_profile
    printf_msg " result: last_pwr/%s\n" "$_prof $_ps"

    # remove temp config
    ${SUDO} rm -f $TEMPCONF

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
    do_psudev="1"
    do_default="1"
    do_switch="1"
else
    while [ $# -gt 0 ]; do
        case "$1" in
            profile)  do_profile="1" ;;
            default)  do_default="1" ;;
            persist)  do_persist="1" ;;
            power)    do_power="1" ;;
            psudev)   do_psudev="1" ;;
            switch)   do_switch="1" ;;
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

# --- TEST
[ "$do_profile" = "1" ] && check_profile_select
[ "$do_default" = "1" ] && check_default_mode
[ "$do_persist" = "1" ] && check_persistent_mode
[ "$do_power" = "1" ] && check_power_supply
[ "$do_switch" = "1" ] && check_auto_switch
[ "$do_psudev" = "1" ] && check_ps_udev_no_switch

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
