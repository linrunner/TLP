#!/bin/sh
# Test CPU related features
#
# Tested parameters:
# * CPU_SCALING_GOVERNOR_ON_AC/BAT
# * CPU_SCALING_MIN/MAX_FREQ_ON_AC/BAT
# * CPU_ENERGY_PERF_POLICY_ON_AC/BAT
# * CPU_MIN/MAX_PERF_ON_AC/BAT
# * CPU_BOOST_ON_AC/BAT
# * CPU_HWP_DYN_BOOST_ON_AC/BAT
# * PLATFORM_PROFIiLE_ON_AC/BAT
#
# Supported CPU scaling drivers:
# * acpi-cpufreq
# * apple-cpufreq
# * amd-pstate
# * amd-pstate-epp
# * intel_pstate
# * intel_cpufreq
#
# Copyright (c) 2023 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TESTLIB="./test-func"
readonly TLP="tlp"

readonly CPUD="/sys/devices/system/cpu"
readonly CPU0="${CPUD}/cpu0"
readonly INTELPSD="/sys/devices/system/cpu/intel_pstate"
readonly AMDPSD="/sys/devices/system/cpu/amd_pstate"
readonly FWACPID="/sys/firmware/acpi"

# --- Functions

check_cpu_driver_opmode () {
    # apply cpu driver operation mode

    local opm opm_save opm_seq opm_cur
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_driver_opmode {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            amd?pstate?epp|amd?pstate)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial policy
                    opm_save="$(read_sysf "${AMDPSD}/status")"
                    printf_msg " initial: %s\n" "$opm_save"

                    printf_msg " %s(active):" "$psfx"

                    # iterate policies supported by the driver, return to initial policy
                    case "$opm_save" in
                        active) opm_seq="guided passive active" ;;
                        guided) opm_seq="passive active guided" ;;
                        passive) opm_seq="active guided passive" ;;
                    esac

                    for opm in $opm_seq; do
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_DRIVER_OPMODE_ON_AC="$opm" CPU_DRIVER_OPMODE_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        compare_sysf "$opm" "${AMDPSD}/status"
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$opm"
                        else
                            printf_msg " %s=%s" "$opm" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    done # opm
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # save current policy
                    opm_cur="$(read_sysf "${AMDPSD}/status")"

                    # try different policy
                    case "$opm_cur" in
                        active)  opm="guided" ;;
                        guided)  opm="passive" ;;
                        passive) opm="active" ;;
                    esac
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_DRIVER_OPMODE_ON_AC="$opm" CPU_DRIVER_OPMODE_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    compare_sysf "$opm_cur" "${AMDPSD}/status"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ignored(ok)" "$opm"
                    else
                        printf_msg " %s=err(%s)" "$opm" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting policy
                    printf_msg "\n result: %s\n" "$(read_sysf "${AMDPSD}/status")"
                fi
                ;; # amd_pstate

            intel_pstate)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial policy
                    opm_save="$(read_sysf "${INTELPSD}/status")"
                    printf_msg " initial: %s\n" "$opm_save"

                    printf_msg " %s(active):" "$psfx"

                    # iterate policies supported by the driver, return to initial policy
                    case "$opm_save" in
                        active) opm_seq="passive active" ;;
                        passive) opm_seq="active passive" ;;
                    esac

                    for opm in $opm_seq; do
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_DRIVER_OPMODE_ON_AC="$opm" CPU_DRIVER_OPMODE_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        compare_sysf "$opm" "${INTELPSD}/status"
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$opm"
                        else
                            printf_msg " %s=%s" "$opm" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    done # opm
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # save current policy
                    opm_cur="$(read_sysf "${INTELPSD}/status")"

                    # try different policy
                    case "$opm_cur" in
                        active)  opm="passive" ;;
                        passive) opm="active" ;;
                    esac
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_DRIVER_OPMODE_ON_AC="$opm" CPU_DRIVER_OPMODE_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    compare_sysf "$opm_cur" "${INTELPSD}/status"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ignored(ok)" "$opm"
                    else
                        printf_msg " %s=err(%s)" "$opm" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting policy
                    printf_msg "\n result: %s\n" "$(read_sysf "${INTELPSD}/status")"
                fi
                ;; # intel_pstate

            *)
                printf_msg "*** unsupported cpu\n"
                break
                ;;

        esac # _cpu_driver
    done # psfx

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_scaling_governor () {
    # apply cpu scaling governor

    local gov gov_cur gov_save="" gov_seq
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_scaling_governor {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            amd?pstate|amd?pstate?epp|intel_pstate)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial governor
                    gov_save="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
                    printf_msg " initial: %s\n" "$gov_save"

                    printf_msg " %s(active):" "$psfx"

                    # iterate governors supported by the driver, return to initial governor
                    case "$gov_save" in
                        performance) gov_seq="powersave performance" ;;
                        powersave)   gov_seq="performance powersave" ;;
                    esac
                    for gov in $gov_seq; do
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_AC=""  > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        glob_compare_sysf "$gov" ${CPUD}/cpu*/cpufreq/scaling_governor
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$gov"
                        else
                            printf_msg " %s=err(%s)" "$gov" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    done
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # save current governor
                    gov_cur="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"

                    # try different governor
                    case "$gov_cur" in
                        powersave)   gov="performance" ;;
                        performance) gov="powersave" ;;
                    esac
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    glob_compare_sysf "$gov_cur" ${CPUD}/cpu*/cpufreq/scaling_governor
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ignored(ok)" "$gov"
                    else
                        printf_msg " %s=err(%s)" "$gov" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting governor
                    printf_msg "\n result: %s\n" "$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
                fi
                ;;

            acpi-cpufreq|apple-cpufreq|intel_cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial governor
                    gov_save="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
                    printf_msg " initial: %s\n" "$gov_save"

                    printf_msg " %s(active):" "$psfx"

                    # iterate governors supported by the driver, return to initial governor
                    case "$gov_save" in
                        performance)  gov_seq="schedutil conservative ondemand powersave performance" ;;
                        schedutil)    gov_seq="performance conservative ondemand powersave performance schedutil" ;;
                        conservative) gov_seq="performance ondemand powersave performance schedutil conservative" ;;
                        ondemand)     gov_seq="performance powersave performance schedutil conservative ondemand" ;;
                        powersave)    gov_seq="performance performance schedutil conservative ondemand powersave" ;;
                    esac
                    for gov in $gov_seq; do
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_AC=""  > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        glob_compare_sysf "$gov" ${CPUD}/cpu*/cpufreq/scaling_governor
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$gov"
                        else
                            printf_msg " %s=err(%s)" "$gov" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    done
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # save current governor
                    gov_cur="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"

                    # try different governor
                    case "$gov_cur" in
                        schedutil) gov="ondemand" ;;
                        *)         gov="schedutil" ;;
                    esac
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    glob_compare_sysf "$gov_cur" ${CPUD}/cpu*/cpufreq/scaling_governor
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ignored(ok)" "$gov"
                    else
                        printf_msg " %s=err(%s)" "$gov" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting governor
                    printf_msg "\n result: %s\n" "$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
                fi
                ;;

            *)
                printf_msg "*** unknown cpu driver\n"
                break
                ;;

        esac # _cpu_driver
    done # psfx

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_scaling_freq () {
    # apply cpu min/max scaling frequency

    local min min_save="" max max_save avail
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_scaling_freq {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            amd?pstate|amd?pstate?epp|intel_pstate|acpi-cpufreq|apple-cpufreq|intel_cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial frequencies
                    min_save="$(read_sysf "${CPU0}/cpufreq/scaling_min_freq")"
                    max_save="$(read_sysf "${CPU0}/cpufreq/scaling_max_freq")"
                    printf_msg " initial: min/%s max/%s\n" "$min_save" "$max_save"

                    printf_msg " %s(active):" "$psfx"

                    # increase min, decrease max frequency
                    min=$((min_save + 100000))
                    if avail=$(read_sysf "${CPU0}/cpufreq/scaling_available_frequencies"); then
                        # shellcheck disable=SC2086
                        max=$(print_nth_arg 3 $avail)
                    else
                        max=$((max_save - 100000))
                    fi
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_AC="$min"  CPU_SCALING_MIN_FREQ_ON_BAT="" \
                                             CPU_SCALING_MAX_FREQ_ON_AC="$max"  CPU_SCALING_MAX_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_BAT="$min" CPU_SCALING_MIN_FREQ_ON_AC=""  \
                                             CPU_SCALING_MAX_FREQ_ON_BAT="$max" CPU_SCALING_MAX_FREQ_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    glob_compare_sysf "$min" ${CPUD}/cpu*/cpufreq/scaling_min_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ok" "$min"
                    else
                        printf_msg " min/%s=err(%s)" "$min" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    glob_compare_sysf "$max" ${CPUD}/cpu*/cpufreq/scaling_max_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ok" "$max"
                    else
                        printf_msg " max/%s=err(%s)" "$max" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # revert to initial frequencies
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_AC="$min_save"  CPU_SCALING_MIN_FREQ_ON_BAT="" \
                                             CPU_SCALING_MAX_FREQ_ON_AC="$max_save"  CPU_SCALING_MAX_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_BAT="$min_save" CPU_SCALING_MIN_FREQ_ON_AC=""  \
                                             CPU_SCALING_MAX_FREQ_ON_BAT="$max_save" CPU_SCALING_MAX_FREQ_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # expect initial frequencies
                    glob_compare_sysf "$min_save" ${CPUD}/cpu*/cpufreq/scaling_min_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ok" "$min_save"
                    else
                        printf_msg " min/%s=err(%s)" "$min_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    glob_compare_sysf "$max_save" ${CPUD}/cpu*/cpufreq/scaling_max_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ok" "$max_save"
                    else
                        printf_msg " max/%s=err(%s)" "$max_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # try increased min, decreased max frequency again (from above)
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_AC="$min"  CPU_SCALING_MIN_FREQ_ON_BAT="" \
                                             CPU_SCALING_MAX_FREQ_ON_AC="$max"  CPU_SCALING_MAX_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_SCALING_MIN_FREQ_ON_BAT="$min" CPU_SCALING_MIN_FREQ_ON_AC=""  \
                                             CPU_SCALING_MAX_FREQ_ON_BAT="$max" CPU_SCALING_MAX_FREQ_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    glob_compare_sysf "$min_save" ${CPUD}/cpu*/cpufreq/scaling_min_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ignored(ok)" "$min"
                    else
                        printf_msg " min/%s=err(%s)" "$min" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    glob_compare_sysf "$max_save" ${CPUD}/cpu*/cpufreq/scaling_max_freq
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ignored(ok)" "$max"
                    else
                        printf_msg " max/%s=err(%s)" "$max" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting frequencies
                    printf_msg "\n result: min/%s max/%s\n" "$(read_sysf "${CPU0}/cpufreq/scaling_min_freq")" "$(read_sysf "${CPU0}/cpufreq/scaling_max_freq")"
                fi
                ;;

            *)
                printf_msg "*** unsupported cpu driver"
                break
                ;;

        esac # _cpu_driver
    done # psfx

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_epp () {
    # apply cpu energy vs. performance policy

    local pol pol_save pol_seq pol_cur
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_epp {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            amd?pstate?epp|intel_pstate|intel_cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial policy
                    pol_save="$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
                    printf_msg " initial: %s\n" "$pol_save"

                    printf_msg " %s(active):" "$psfx"

                    # iterate policies supported by the driver, return to initial policy
                    case "$pol_save" in
                        performance) pol_seq="balance_performance balance_power power performance" ;;
                        balance_performance) pol_seq="performance balance_power power balance_performance" ;;
                        balance_power) pol_seq="performance balance_performance power balance_power" ;;
                        power) pol_seq="performance balance_performance balance_power power" ;;
                    esac

                    for pol in $pol_seq; do
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_ENERGY_PERF_POLICY_ON_AC="$pol" CPU_ENERGY_PERF_POLICY_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_ENERGY_PERF_POLICY_ON_BAT="$pol" CPU_ENERGY_PERF_POLICY_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        glob_compare_sysf "$pol" ${CPUD}/cpu*/cpufreq/energy_performance_preference
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$pol"
                        else
                            printf_msg " %s=%s" "$pol" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    done # pol
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # save current policy
                    pol_cur="$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"

                    # try different policy
                    case "$pol_cur" in
                        performance)         pol="balance_performance" ;;
                        balance_performance) pol="balance_power" ;;
                        balance_power)       pol="power" ;;
                        power)               pol="performance" ;;
                    esac
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_ENERGY_PERF_POLICY_ON_AC="$pol" CPU_ENERGY_PERF_POLICY_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_ENERGY_PERF_POLICY_ON_BAT="$pol" CPU_ENERGY_PERF_POLICY_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    glob_compare_sysf "$pol_cur" ${CPUD}/cpu*/cpufreq/energy_performance_preference
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ignored(ok)" "$pol"
                    else
                        printf_msg " %s=err(%s)" "$pol" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting policy
                    printf_msg "\n result: %s\n" "$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
                fi
                ;;

            *)
                printf_msg "*** unsupported cpu\n"
                break
                ;;

        esac # _cpu_driver
    done # psfx

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_perf_pct () {
    # apply intel_pstate min/max performance (%)

    local min min_save max max_save
    local psfsq psfx sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_perf_pct {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            intel_pstate|intel_cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial performance
                    min_save="$(read_sysf "$INTELPSD/min_perf_pct")"
                    max_save="$(read_sysf "$INTELPSD/max_perf_pct")"
                    printf_msg " initial: min/%s max/%s\n" "$min_save" "$max_save"

                    printf_msg " %s(active):" "$psfx"

                    # increase min, decrease max performance
                    min=$((min_save + 10))
                    max=$((max_save - 10))
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_MIN_PERF_ON_AC="$min" CPU_MIN_PERF_ON_BAT="" \
                                             CPU_MAX_PERF_ON_AC="$max" CPU_MAX_PERF_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_MIN_PERF_ON_BAT="$min" CPU_MIN_PERF_ON_AC="" \
                                             CPU_MAX_PERF_ON_BAT="$max" CPU_MAX_PERF_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$min" "$INTELPSD/min_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ok" "$min"
                    else
                        printf_msg " min/%s=err(%s)" "$min" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    compare_sysf "$max" "$INTELPSD/max_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ok" "$max"
                    else
                        printf_msg " max/%s=%s" "$max" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # revert to initial min/max performance
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_MIN_PERF_ON_AC="$min_save" CPU_MIN_PERF_ON_BAT="" \
                                             CPU_MAX_PERF_ON_AC="$max_save" CPU_MAX_PERF_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_MIN_PERF_ON_BAT="$min_save" CPU_MIN_PERF_ON_AC="" \
                                             CPU_MAX_PERF_ON_BAT="$max_save" CPU_MAX_PERF_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect initial performance
                    compare_sysf "$min_save" "$INTELPSD/min_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ok" "$min_save"
                    else
                        printf_msg " min/%s=err(%s)" "$min_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    compare_sysf "$max_save" "$INTELPSD/max_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ok" "$max_save"
                    else
                        printf_msg " max/%s=err(%s)" "$max_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # try increased min, decreased max performance again (from above)
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_MIN_PERF_ON_AC="$min" CPU_MIN_PERF_ON_BAT="" \
                                             CPU_MAX_PERF_ON_AC="$max" CPU_MAX_PERF_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_MIN_PERF_ON_BAT="$min" CPU_MIN_PERF_ON_AC="" \
                                             CPU_MAX_PERF_ON_BAT="$max" CPU_MAX_PERF_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    compare_sysf "$min_save" "$INTELPSD/min_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " min/%s=ignored(ok)" "$min"
                    else
                        printf_msg " min/%s=err(%s)" "$min" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    compare_sysf "$max_save" "$INTELPSD/max_perf_pct"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " max/%s=ignored(ok)" "$max"
                    else
                        printf_msg " max/%s=%s" "$max" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resulting min/max performance
                    printf_msg "\n result: min/%s max/%s\n" "$(read_sysf "$INTELPSD/min_perf_pct")" "$(read_sysf "$INTELPSD/max_perf_pct")"
                fi
                ;;

            *)
                printf_msg "*** unsupported cpu driver\n"
                break
                ;;
        esac

    done # psfx

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_boost () {
    # apply cpu boost/turbo mode and dynamic boost

    local boost boost_save no_turbo no_turbo_save dyn_boost dyn_boost_save
    local psfsq psfx sc=0
    local rc=0 errcnt=0

    printf_msg "check_cpu_boost {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    # iterate suffixes
    for psfx in $psfsq; do
        sc=$((sc + 1))

        case "$_cpu_driver" in
            intel_pstate|intel_cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial states
                    no_turbo_save="$(read_sysf "$INTELPSD/no_turbo")"

                    if [ -f "$INTELPSD/hwp_dynamic_boost" ]; then
                        dyn_boost_save="$(read_sysf "$INTELPSD/hwp_dynamic_boost")"
                    else
                        dyn_boost_save="not-available"
                    fi
                    printf_msg " initial: no_turbo/%s dyn_boost/%s\n" "$no_turbo_save" "$dyn_boost_save"

                    printf_msg " %s(active):" "$psfx"

                    # invert turbo state
                    no_turbo="$((no_turbo_save ^ 1))"
                    # note: CPU_BOOST_ON_AC/BAT is the inverse of no_turbo
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_BOOST_ON_AC="$((no_turbo ^ 1))" CPU_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_BOOST_ON_BAT="$((no_turbo ^ 1))" CPU_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$no_turbo" "$INTELPSD/no_turbo"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " no_turbo/%s=ok" "$no_turbo"
                    else
                        printf_msg " no_turbo/%s=err(%s)" "$no_turbo" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # revert to initial turbo state
                    # note: CPU_BOOST_ON_AC/BAT is the inverse of no_turbo
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_BOOST_ON_AC="$((no_turbo_save ^ 1))" CPU_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_BOOST_ON_BAT="$((no_turbo_save ^ 1))" CPU_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$no_turbo_save" "$INTELPSD/no_turbo"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " no_turbo/%s=ok" "$no_turbo_save"
                    else
                        printf_msg " no_turbo/%s=err(%s)" "$no_turbo_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    if [ -f "$INTELPSD/hwp_dynamic_boost" ]; then
                        # invert dyn boost state
                        dyn_boost="$((dyn_boost_save ^ 1))"
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost"  CPU_HWP_DYN_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost" CPU_HWP_DYN_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        compare_sysf "$dyn_boost" "$INTELPSD/hwp_dynamic_boost"
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " dyn_boost/%s=ok" "$dyn_boost"
                        else
                            printf_msg " dyn_boost/%s=err(%s)" "$dyn_boost" "$rc"
                            errcnt=$((errcnt + 1))
                        fi

                        # revert to initial dyn boost state
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost_save"  CPU_HWP_DYN_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost_save" CPU_HWP_DYN_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # expect change
                        compare_sysf "$dyn_boost_save" "$INTELPSD/hwp_dynamic_boost"
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " dyn_boost/%s=ok" "$dyn_boost_save"
                        else
                            printf_msg " dyn_boost/%s=err(%s)" "$dyn_boost_save" "$rc"
                            errcnt=$((errcnt + 1))
                        fi
                    else
                        printf_msg " dyn_boost/not-available"
                    fi
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # try to invert turbo state
                    no_turbo="$((no_turbo_save ^ 1))"
                    # note: CPU_BOOST_ON_AC/BAT is the inverse of no_turbo
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_BOOST_ON_AC="$((no_turbo ^ 1))"  CPU_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_BOOST_ON_BAT="$((no_turbo ^ 1))" CPU_BOOST_ON_AC=""  > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    compare_sysf "$no_turbo_save" "$INTELPSD/no_turbo"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " no_turbo/%s=ignored(ok)" "$no_turbo"
                    else
                        printf_msg " no_turbo/%s=err(%s)" "$no_turbo" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    if [ -f "$INTELPSD/hwp_dynamic_boost" ]; then
                        # try to invert dyn boost state
                        dyn_boost="$((dyn_boost_save ^ 1))"
                        case "$psfx" in
                            AC)  ${TLP} start -- CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost"  CPU_HWP_DYN_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                            BAT) ${TLP} start -- CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost" CPU_HWP_DYN_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                        esac

                        # do not expect change
                        compare_sysf "$dyn_boost_save" "$INTELPSD/hwp_dynamic_boost"
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " dyn_boost/%s=ignored(ok)" "$dyn_boost"
                        else
                            printf_msg " dyn_boost/%s=err(%s)" "$dyn_boost" "$rc"
                            errcnt=$((errcnt + 1))
                        fi

                        # print resulting states
                        printf_msg "\n result: no_turbo/%s dyn_boost/%s\n" "$(read_sysf "$INTELPSD/no_turbo")" "$(read_sysf "$INTELPSD/hwp_dynamic_boost")"
                    else
                        printf_msg " dyn_boost/not-available"
                        printf_msg "\n result: no_turbo/%s dyn_boost/not-available\n" "$(read_sysf "$INTELPSD/no_turbo")"
                    fi
                fi
                ;;

            acpi-cpufreq)
                if [ $sc -eq 1 ]; then
                    # power source matches parameter suffix

                    # save initial boost state
                    boost_save="$(read_sysf "${CPUD}/cpufreq/boost")"
                    printf_msg " initial: boost/%s\n" "$boost_save"

                    printf_msg " %s(active):" "$psfx"

                    # invert boost state
                    boost="$((boost_save ^ 1))"
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_BOOST_ON_AC="$boost"  CPU_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_BOOST_ON_BAT="$boost" CPU_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$boost" "${CPUD}/cpufreq/boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " boost/%s=ok" "$boost"
                    else
                        printf_msg " boost/%s=err(%s)" "$boost" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # revert to initial boost state
                    ${TLP} start -- CPU_BOOST_ON_AC="$boost_save" CPU_BOOST_ON_BAT="$boost_save" > /dev/null 2>&1
                    compare_sysf "$boost_save" "${CPUD}/cpufreq/boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " boost/%s=ok" "$boost_save"
                    else
                        printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                else
                    # power source does not match parameter suffix
                    printf_msg "\n %s(inactive):" "$psfx"

                    # try to invert boost state
                    boost="$((boost_save ^ 1))"
                    case "$psfx" in
                        AC)  ${TLP} start -- CPU_BOOST_ON_AC="$boost"  CPU_BOOST_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- CPU_BOOST_ON_BAT="$boost" CPU_BOOST_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # do not expect change
                    compare_sysf "$boost_save" "${CPUD}/cpufreq/boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " boost/%s=ignored(ok)" "$boost_save"
                    else
                        printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # print resultign boost state
                    printf_msg "\n result: boost/%s\n" "$(read_sysf "${CPUD}/cpufreq/boost")"
                fi
                ;;

            *)
                printf_msg "*** unsupported cpu driver\n"
                break
                ;;

        esac # _cpu_driver
    done # psfx

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_platform_profile () {
   # apply plaform profile

    local prof prof_list prof_save
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_platform_profile {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    # save initial platform profile / check availability
    if prof_save="$(read_sysf "${FWACPID}/platform_profile")"; then
       printf_msg " initial: %s\n" "$prof_save"

        for psfx in $psfsq; do
            sc=$((sc + 1))

            if [ $sc -eq 1 ]; then
                # power source matches parameter suffix
                printf_msg " %s(active):" "$psfx"

                # iterate policies supported by the driver
                prof_list="$(read_sysf "${FWACPID}/platform_profile_choices")"
                prof_list="$(echo "$prof_list" | sed -r 's/'"$prof_save"'//') $prof_save"
                for prof in $prof_list; do
                    case "$psfx" in
                        AC)  ${TLP} start -- PLATFORM_PROFILE_ON_AC="$prof" PLATFORM_PROFILE_ON_BAT="" > /dev/null 2>&1 ;;
                        BAT) ${TLP} start -- PLATFORM_PROFILE_ON_BAT="$prof" PLATFORM_PROFILE_ON_AC="" > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$prof" "${FWACPID}/platform_profile"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ok" "$prof"
                    else
                        printf_msg " %s=err(%s)" "$prof" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                done # prof
            else
                # power source does not match parameter suffix
                printf_msg "\n %s(inactive):" "$psfx"

                # try different platform profile
                case "$prof_save" in
                    low-power)   prof="balanced" ;;
                    balanced)    prof="performance" ;;
                    performance) prof="low-power" ;;
                esac
                case "$psfx" in
                    AC)  ${TLP} start -- PLATFORM_PROFILE_ON_AC="$prof" PLATFORM_PROFILE_ON_BAT="" > /dev/null 2>&1 ;;
                    BAT) ${TLP} start -- PLATFORM_PROFILE_ON_BAT="$prof" PLATFORM_PROFILE_ON_AC="" > /dev/null 2>&1 ;;
                esac

                # do not expect change
                compare_sysf "$prof_save" "${FWACPID}/platform_profile"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " %s=ignored(ok)" "$prof"
                else
                    printf_msg " %s=err(%s)" "$prof" "$rc"
                    errcnt=$((errcnt + 1))
                fi

                # print resulting platform profile
                printf_msg "\n result: %s\n" "$(read_sysf "${FWACPID}/platform_profile")"
            fi
        done # psfx
    else
        printf_msg "** unsupported platform\n"
        # break
    fi

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
check_root
cmd_exists "$TLP" || {
    printf_msg "Error: %s not installed." "$TLP"
    exit 254
}
_cpu_driver=$(read_sysf "${CPU0}/cpufreq/scaling_driver") || {
    printf_msg "Error: could not determine cpu scaling driver."
    exit 128
}
# shellcheck disable=SC2034
_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

printf_msg "+++ %s --- cpu_driver: %s\n\n" "${0##*/}" "$_cpu_driver"

# --- Checks
check_cpu_driver_opmode
check_cpu_scaling_governor
check_cpu_scaling_freq
check_cpu_epp
check_cpu_perf_pct
check_cpu_boost
check_platform_profile

printf_msg "+++ Test results: %d run, %d failed.\n\n" "$_testcnt" "$_failcnt"

# --- Exit
exit $_failcnt
