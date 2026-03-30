#!/bin/sh
# Test:
# - Iterate all profiles with TLP_DISABLE_DEFAULTS=1
# - Check a default-configured tunable to ensure it does not change
# - Use EPP as sample, it's available on most hardware
# Tested parameters:
# - TLP_DISABLE_DEFAULTS=1
#
# Copyright (c) 2026 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly CPUD="/sys/devices/system/cpu"
readonly CPU0="${CPUD}/cpu0"
readonly DEFAULTS="/usr/share/tlp/defaults.conf"
readonly READCONFS="/usr/share/tlp/tlp-readconfs"

# --- Functions

check_disabled_defaults () {
    # Iterate all profiles and check if EPP changes
    # global param: $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local pol pol_save
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_disabled_defaults {{{\n"

    if $READCONFS | grep -v '^defaults.conf' | grep -E -q 'CPU_ENERGY_PERF_POLICY'; then
        printf_msg "*** Error: For the test to succeed, your configuration must not include CPU_ENERGY_PERF_POLICY_ON_AC/BAT/SAV.\n"
        errcnt=1

    elif [ -f "${CPU0}/cpufreq/energy_performance_preference" ]; then
        # save initial policy
        pol_save="$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
        printf_msg " initial(%s): %s\n" "$prof_save" "$pol_save"

        for prof in $prof_seq; do
            # --- test profile
            printf_msg " %s:\n" "$prof"
            pol_save="$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
            case "$prof" in
                performance) pol="$(sed -rn 's/CPU_ENERGY_PERF_POLICY_ON_AC=(.+)/\1/p' "$DEFAULTS")" ;;
                balanced)    pol="$(sed -rn 's/CPU_ENERGY_PERF_POLICY_ON_BAT=(.+)/\1/p' "$DEFAULTS")" ;;
                power-saver) pol="$(sed -rn 's/CPU_ENERGY_PERF_POLICY_ON_SAV=(.+)/\1/p' "$DEFAULTS")" ;;
            esac

            # defaults disabled --> don't expect policy change
            printf_msg "  TLP_AUTO_SWITCH=2 TLP_DISABLE_DEFAULTS=1:"
            sudo tlp "$prof" -- TLP_AUTO_SWITCH=2 TLP_PROFILE_DEFAULT="" TLP_DISABLE_DEFAULTS=1 > /dev/null 2>&1

            compare_sysf "$pol_save" "${CPU0}/cpufreq/energy_performance_preference"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ok" "$pol_save"
            else
                printf_msg " %s=err(%s)" "$pol" "$rc"
                errcnt=$((errcnt + 1))
            fi
            printf_msg "\n"

            # defaults enabled --> expect policy change
            printf_msg "  TLP_AUTO_SWITCH=2:"
            sudo tlp "$prof" -- TLP_AUTO_SWITCH=2 TLP_PROFILE_DEFAULT="" > /dev/null 2>&1

            compare_sysf "$pol" "${CPU0}/cpufreq/energy_performance_preference"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ok" "$pol"
            else
                printf_msg " %s=err(%s)" "$pol" "$rc"
                errcnt=$((errcnt + 1))
            fi
            printf_msg "\n"

        done # prof

        # print resulting policy
        printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
    else
        printf_msg "*** unsupported cpu or driver\n"
    fi

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
    do_disabled_defaults="1"
else
    while [ $# -gt 0 ]; do
        case "$1" in
            disabled_defaults) do_disabled_defaults="1" ;;
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
printf_msg "+++ %s\n\n" "$_basename"

# save initial profile
read_saved_profile
# shellcheck disable=SC2154
prof_save="$(pp2str "$_prof")"

# iterate supported profiles, return to initial profile
case "$prof_save" in
    performance) prof_seq="balanced power-saver performance" ;;
    balanced)    prof_seq="power-saver performance balanced" ;;
    power-saver) prof_seq="performance balanced power-saver" ;;
esac

[ "$do_disabled_defaults" = "1" ] && check_disabled_defaults

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
