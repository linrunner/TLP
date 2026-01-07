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
# Copyright (c) 2026 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TLP="tlp"
readonly SUDO="sudo"

readonly CPUD="/sys/devices/system/cpu"
readonly CPU0="${CPUD}/cpu0"
readonly INTELPSD="/sys/devices/system/cpu/intel_pstate"
readonly AMDPSD="/sys/devices/system/cpu/amd_pstate"
readonly FWACPID="/sys/firmware/acpi"

# --- Functions
print_nth_arg () {
    # Get n-th argument
    # $1: n
    # $2..$m: arguments
    local n="$1"
    [ "$1" -gt 0 ] || return

    until [ "$n" -eq 0 ] || [ $# -eq 0 ]; do
        shift
        n=$((n - 1))
    done
    printf "%s" "$1"
}


# --- Tests
check_cpu_driver_opmode () {
    # apply cpu driver operation mode

    local opm opm_save opm_seq
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_driver_opmode {{{\n"

    case "$_cpu_driver" in
        amd?pstate?epp|amd?pstate)
            # save initial opmode
            opm_save="$(read_sysf "${AMDPSD}/status")"
            printf_msg " initial(%s): %s\n" "$prof_save" "$opm_save"

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:" "$prof"

                # iterate opmodes supported by the driver, return to initial opmode
                case "$opm_save" in
                    active) opm_seq="guided passive active" ;;
                    guided) opm_seq="passive active guided" ;;
                    passive) opm_seq="active guided passive" ;;
                esac

                for opm in $opm_seq; do
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_AC="$opm"  CPU_DRIVER_OPMODE_ON_BAT="$opm_save" CPU_DRIVER_OPMODE_ON_SAV="$opm_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_SAV="$opm_save" CPU_DRIVER_OPMODE_ON_AC="$opm_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_SAV="$opm" CPU_DRIVER_OPMODE_ON_AC="$opm_save"  CPU_DRIVER_OPMODE_ON_BAT="$opm_save" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$opm" "${AMDPSD}/status"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ok" "$opm"
                    else
                        printf_msg " %s=err(%s)" "$opm" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                done # opm
                printf_msg "\n"

            done # prof

            # print resulting opmode
            printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${AMDPSD}/status")"
            ;; # amd_pstate

        intel_pstate)
            # save initial policy
            opm_save="$(read_sysf "${INTELPSD}/status")"
            printf_msg " initial(%s): %s\n" "$prof_save" "$opm_save"

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:" "$prof"

                # iterate opmodes supported by the driver, return to initial opmode
                case "$opm_save" in
                    active) opm_seq="passive active" ;;
                    passive) opm_seq="active passive" ;;
                esac

                for opm in $opm_seq; do
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_AC="$opm"  CPU_DRIVER_OPMODE_ON_BAT="$opm_save" CPU_DRIVER_OPMODE_ON_SAV="$opm_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_BAT="$opm" CPU_DRIVER_OPMODE_ON_SAV="$opm_save" CPU_DRIVER_OPMODE_ON_AC="$opm_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_DRIVER_OPMODE_ON_SAV="$opm" CPU_DRIVER_OPMODE_ON_AC="$opm_save"  CPU_DRIVER_OPMODE_ON_BAT="$opm_save" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect change
                    compare_sysf "$opm" "${INTELPSD}/status"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " %s=ok" "$opm"
                    else
                        printf_msg " %s=err(%s)" "$opm" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                done # opm
                printf_msg "\n"

            done # prof

            # print resulting opmode
            printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${AMDPSD}/status")"
            ;; # intel_pstate

        *)
            printf_msg "*** unsupported cpu\n"
            ;;

    esac # _cpu_driver

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_scaling_governor () {
    # apply cpu scaling governor

    local gov gov_save gov_seq
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_scaling_governor {{{\n"

    case "$_cpu_driver" in
        amd?pstate|amd?pstate?epp|intel_pstate)
            # save initial governor
            gov_save="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
            printf_msg " initial(%s): %s\n" "$prof_save" "$gov_save"

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:" "$prof"

                # iterate governors supported by the driver, return to initial governor
                case "$gov_save" in
                    performance) gov_seq="powersave performance" ;;
                    powersave)   gov_seq="performance powersave" ;;
                esac
                for gov in $gov_seq; do
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="$gov_save" CPU_SCALING_GOVERNOR_ON_SAV="$gov_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_SAV="$gov_save" CPU_SCALING_GOVERNOR_ON_AC="$gov_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_SAV="$gov" CPU_SCALING_GOVERNOR_ON_AC="$gov_save"  CPU_SCALING_GOVERNOR_ON_BAT="$gov_save" \
                            > /dev/null 2>&1 ;;
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

                done # gov
                printf_msg "\n"

            done # prof

            # print resulting governor
            printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
        ;; # amd/intel_pstate

        acpi-cpufreq|apple-cpufreq|intel_cpufreq)
             # save initial governor
             gov_save="$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
             printf_msg " initial(%s): %s\n" "$prof_save" "$gov_save"

             for prof in $prof_seq; do
                 # --- test profile; ensure different values from other profiles do not spill over
                 printf_msg " %s:" "$prof"

                # iterate governors supported by the driver, return to initial governor
                case "$gov_save" in
                    performance)  gov_seq="schedutil conservative ondemand powersave performance" ;;
                    schedutil)    gov_seq="performance conservative ondemand powersave performance schedutil" ;;
                    conservative) gov_seq="performance ondemand powersave performance schedutil conservative" ;;
                    ondemand)     gov_seq="performance powersave performance schedutil conservative ondemand" ;;
                    powersave)    gov_seq="performance performance schedutil conservative ondemand powersave" ;;
                esac

                for gov in $gov_seq; do
                    # apply target governor
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_AC="$gov"  CPU_SCALING_GOVERNOR_ON_BAT="$gov_save" CPU_SCALING_GOVERNOR_ON_SAV="$gov_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_BAT="$gov" CPU_SCALING_GOVERNOR_ON_SAV="$gov_save" CPU_SCALING_GOVERNOR_ON_AC="$gov_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_SCALING_GOVERNOR_ON_SAV="$gov" CPU_SCALING_GOVERNOR_ON_AC="$gov_save"  CPU_SCALING_GOVERNOR_ON_BAT="$gov_save" \
                            > /dev/null 2>&1 ;;
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

                done # gov
                printf_msg "\n"

            done # prof

            # print resulting governor
            printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${CPU0}/cpufreq/scaling_governor")"
            ;; # acpi/apple/intel-cpufreq

        *)
            printf_msg "*** unknown cpu driver\n"
            ;;

    esac # _cpu_driver

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_scaling_freq () {
    # apply cpu min/max scaling frequency

    local min min_save="" max max_save
    local favail fcnt
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_scaling_freq {{{\n"

    case "$_cpu_driver" in
        amd?pstate|amd?pstate?epp|intel_pstate|acpi-cpufreq|apple-cpufreq|intel_cpufreq)
            # save initial frequencies
            min_save="$(read_sysf "${CPU0}/cpufreq/scaling_min_freq")"
            max_save="$(read_sysf "${CPU0}/cpufreq/scaling_max_freq")"
            printf_msg " initial(%s): min/%s max/%s\n" "$prof_save" "$min_save" "$max_save"

            # target frequencies: increase min, decrease max
            if favail=$(read_sysf "${CPU0}/cpufreq/scaling_available_frequencies"); then
                fcnt="$(echo "$favail" | wc -w)"
                # shellcheck disable=SC2086
                min=$(print_nth_arg $((fcnt - 1)) $favail)
                max=$(print_nth_arg 2 $favail)
            else
                min=$((min_save + 100000))
                max=$((max_save - 100000))
            fi

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:\n" "$prof"

                # apply target frequencies
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_AC="$min"  CPU_SCALING_MIN_FREQ_ON_BAT="$min_save" CPU_SCALING_MIN_FREQ_ON_SAV="$min_save" \
                        CPU_SCALING_MAX_FREQ_ON_AC="$max"  CPU_SCALING_MAX_FREQ_ON_BAT="$max_save" CPU_SCALING_MAX_FREQ_ON_SAV="$min_save" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_BAT="$min" CPU_SCALING_MIN_FREQ_ON_SAV="$min_save" CPU_SCALING_MIN_FREQ_ON_AC="$min_save" \
                        CPU_SCALING_MAX_FREQ_ON_BAT="$max" CPU_SCALING_MAX_FREQ_ON_SAV="$max_save" CPU_SCALING_MAX_FREQ_ON_AC="$min_save" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_SAV="$min" CPU_SCALING_MIN_FREQ_ON_AC="$min_save"  CPU_SCALING_MIN_FREQ_ON_BAT="$min_save" \
                        CPU_SCALING_MAX_FREQ_ON_SAV="$max" CPU_SCALING_MAX_FREQ_ON_AC="$max_save"  CPU_SCALING_MAX_FREQ_ON_BAT="$min_save" \
                        > /dev/null 2>&1 ;;
                esac

                # expect target frequencies
                glob_compare_sysf "$min" ${CPUD}/cpu*/cpufreq/scaling_min_freq
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  min/%s=ok" "$min"
                else
                    printf_msg "  min/%s=err(%s)" "$min" "$rc"
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
                printf_msg "\n"

                # revert to initial frequencies
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_AC="$min_save"  CPU_SCALING_MIN_FREQ_ON_BAT="$min" CPU_SCALING_MIN_FREQ_ON_SAV="$min" \
                        CPU_SCALING_MAX_FREQ_ON_AC="$max_save"  CPU_SCALING_MAX_FREQ_ON_BAT="$max" CPU_SCALING_MAX_FREQ_ON_SAV="$min" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_BAT="$min_save" CPU_SCALING_MIN_FREQ_ON_SAV="$min" CPU_SCALING_MIN_FREQ_ON_AC="$min" \
                        CPU_SCALING_MAX_FREQ_ON_BAT="$max_save" CPU_SCALING_MAX_FREQ_ON_SAV="$max" CPU_SCALING_MAX_FREQ_ON_AC="$min" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_SCALING_MIN_FREQ_ON_SAV="$min_save" CPU_SCALING_MIN_FREQ_ON_AC="$min"  CPU_SCALING_MIN_FREQ_ON_BAT="$min" \
                        CPU_SCALING_MAX_FREQ_ON_SAV="$max_save" CPU_SCALING_MAX_FREQ_ON_AC="$max"  CPU_SCALING_MAX_FREQ_ON_BAT="$min" \
                        > /dev/null 2>&1 ;;
                esac
                # sleep 0.1

                # expect initial frequencies
                glob_compare_sysf "$min_save" ${CPUD}/cpu*/cpufreq/scaling_min_freq
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  min/%s=ok" "$min_save"
                else
                    printf_msg "  min/%s=err(%s)" "$min_save" "$rc"
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
                printf_msg "\n"

            done # prof

            # print resulting frequencies
            printf_msg " result(%s): min/%s max/%s\n" "$prof" "$(read_sysf "${CPU0}/cpufreq/scaling_min_freq")" "$(read_sysf "${CPU0}/cpufreq/scaling_max_freq")"
            ;; # drivers supporting freq changes

        *)
            printf_msg "*** unsupported cpu driver"
            ;;

    esac # _cpu_driver

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_epp () {
    # apply cpu energy vs. performance policy

    local pol pol_save pol_seq pol_cur
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_epp {{{\n"

    case "$_cpu_driver" in
        amd?pstate?epp|intel_pstate|intel_cpufreq)
            if [ -f "${CPU0}/cpufreq/energy_performance_preference" ]; then
                # save initial policy
                pol_save="$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
                printf_msg " initial(%s): %s\n" "$prof_save" "$pol_save"

                for prof in $prof_seq; do
                    # --- test profile; ensure different values from other profiles do not spill over
                    printf_msg " %s:" "$prof"

                    # iterate policies supported by the driver, return to initial policy
                    case "$pol_save" in
                        performance)         pol_seq="balance_performance balance_power power performance" ;;
                        balance_performance) pol_seq="performance balance_power power balance_performance" ;;
                        balance_power)       pol_seq="performance balance_performance power balance_power" ;;
                        power)               pol_seq="performance balance_performance balance_power power" ;;
                    esac

                    for pol in $pol_seq; do
                        case "$prof" in
                            performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                                CPU_ENERGY_PERF_POLICY_ON_AC="$pol"  CPU_ENERGY_PERF_POLICY_ON_BAT="$pol_save" CPU_ENERGY_PERF_POLICY_ON_SAV="$pol_save" \
                                > /dev/null 2>&1 ;;
                            balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                                CPU_ENERGY_PERF_POLICY_ON_BAT="$pol" CPU_ENERGY_PERF_POLICY_ON_SAV="$pol_save" CPU_ENERGY_PERF_POLICY_ON_AC="$pol_save" \
                                > /dev/null 2>&1 ;;
                            power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                                CPU_ENERGY_PERF_POLICY_ON_SAV="$pol" CPU_ENERGY_PERF_POLICY_ON_AC="$pol_save"  CPU_ENERGY_PERF_POLICY_ON_BAT="$pol_save" \
                                > /dev/null 2>&1 ;;
                        esac

                        # expect policy change
                        glob_compare_sysf "$pol" ${CPUD}/cpu*/cpufreq/energy_performance_preference
                        rc=$?
                        if [ "$rc" -eq 0 ]; then
                            printf_msg " %s=ok" "$pol"
                        else
                            printf_msg " %s=err(%s(" "$pol" "$rc"
                            errcnt=$((errcnt + 1))
                        fi

                    done # pol
                    printf_msg "\n"

                done # prof

                # print resulting policy
                printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${CPU0}/cpufreq/energy_performance_preference")"
            else
                printf_msg "*** unsupported cpu\n"
            fi
            ;;

        *)
            printf_msg "*** unsupported cpu\n"
            ;;

    esac # _cpu_driver

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_perf_pct () {
    # apply intel_pstate min/max performance (%)

    local min min_save max max_save
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_perf_pct {{{\n"

    case "$_cpu_driver" in
        intel_pstate|intel_cpufreq)
            # save initial performance
            min_save="$(read_sysf "$INTELPSD/min_perf_pct")"
            max_save="$(read_sysf "$INTELPSD/max_perf_pct")"
            printf_msg " initial(%s): min/%s max/%s\n" "$prof_save" "$min_save" "$max_save"

            # target performance: increase min, decrease max
            min=$((min_save + 10))
            max=$((max_save - 10))

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:\n" "$prof"

                # apply target performance
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_AC="$min"  CPU_MIN_PERF_ON_BAT="$min_save" CPU_MIN_PERF_ON_SAV="$min_save"\
                        CPU_MAX_PERF_ON_AC="$max"  CPU_MAX_PERF_ON_BAT="$min_save" CPU_MAX_PERF_ON_SAV="$min_save" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_BAT="$min" CPU_MIN_PERF_ON_SAV="$min_save" CPU_MIN_PERF_ON_AC="$min_save"\
                        CPU_MAX_PERF_ON_BAT="$max" CPU_MAX_PERF_ON_SAV="$min_save" CPU_MAX_PERF_ON_AC="$min_save" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_SAV="$min" CPU_MIN_PERF_ON_AC="$min_save"  CPU_MIN_PERF_ON_BAT="$min_save"\
                        CPU_MAX_PERF_ON_SAV="$max" CPU_MAX_PERF_ON_AC="$min_save"  CPU_MAX_PERF_ON_BAT="$min_save" \
                        > /dev/null 2>&1 ;;
                esac

                # expect performance change
                compare_sysf "$min" "$INTELPSD/min_perf_pct"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  min/%s=ok" "$min"
                else
                    printf_msg "  min/%s=err(%s)" "$min" "$rc"
                    errcnt=$((errcnt + 1))
                fi
                compare_sysf "$max" "$INTELPSD/max_perf_pct"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " max/%s=ok" "$max"
                else
                    printf_msg " max/%s=err(%s)" "$max" "$rc"
                    errcnt=$((errcnt + 1))
                fi
                printf_msg "\n"

                # revert to initial performance
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_AC="$min_save"  CPU_MIN_PERF_ON_BAT="$min" CPU_MIN_PERF_ON_SAV="$min"\
                        CPU_MAX_PERF_ON_AC="$max_save"  CPU_MAX_PERF_ON_BAT="$min" CPU_MAX_PERF_ON_SAV="$min" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_BAT="$min_save" CPU_MIN_PERF_ON_SAV="$min" CPU_MIN_PERF_ON_AC="$min"\
                        CPU_MAX_PERF_ON_BAT="$max_save" CPU_MAX_PERF_ON_SAV="$min" CPU_MAX_PERF_ON_AC="$min" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_MIN_PERF_ON_SAV="$min_save" CPU_MIN_PERF_ON_AC="$min"  CPU_MIN_PERF_ON_BAT="$min"\
                        CPU_MAX_PERF_ON_SAV="$max_save" CPU_MAX_PERF_ON_AC="$min"  CPU_MAX_PERF_ON_BAT="$min" \
                        > /dev/null 2>&1 ;;
                esac

                # expect initial performance
                compare_sysf "$min_save" "$INTELPSD/min_perf_pct"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  min/%s=ok" "$min_save"
                else
                    printf_msg "  min/%s=err(%s)" "$min_save" "$rc"
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
                printf_msg "\n"

            done # prof

            # print resulting min/max performance
            printf_msg " result(%s): min/%s max/%s\n" "$prof" "$(read_sysf "$INTELPSD/min_perf_pct")" "$(read_sysf "$INTELPSD/max_perf_pct")"
            ;; # intel_pstate/cpufreq

        *)
            printf_msg "*** unsupported cpu driver\n"
            ;;
    esac

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_cpu_boost () {
    # apply cpu boost/turbo mode and dynamic boost

    local boost boost_save no_turbo no_turbo_save dyn_boost dyn_boost_save
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_cpu_boost {{{\n"

    case "$_cpu_driver" in
        intel_pstate|intel_cpufreq)
            # save initial states
            no_turbo_save="$(read_sysf "$INTELPSD/no_turbo")"
            dyn_boost_save="$(read_sysf "$INTELPSD/hwp_dynamic_boost" "<not available>")"
            printf_msg " initial(%s): no_turbo/%s dyn_boost/%s\n" "$prof_save" "$no_turbo_save" "$dyn_boost_save"

            # target turbo state: inverted
            no_turbo="$((no_turbo_save ^ 1))"

            for prof in $prof_seq; do
                # --- test profile; ensure different values from other profiles do not spill over
                printf_msg " %s:\n" "$prof"

                # apply inverted turbo state
                # note: the CPU_BOOST_ON_AC/BAT/SAV setting must be the inverse of the new no_turbo state
                # so use $no_turbo_save as parameter value
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_AC="$no_turbo_save"  CPU_BOOST_ON_BAT="$no_turbo" CPU_BOOST_ON_SAV="$no_turbo" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_BAT="$no_turbo_save" CPU_BOOST_ON_SAV="$no_turbo" CPU_BOOST_ON_AC="$no_turbo" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_SAV="$no_turbo_save" CPU_BOOST_ON_AC="$no_turbo"  CPU_BOOST_ON_BAT="$no_turbo" \
                        > /dev/null 2>&1 ;;
                esac

                # expect turbo state change
                # note: the actual no_turbo state is the inverse of the CPU_BOOST_ON_AC/BAT/SAV parameter value,
                # so use $no_turbo for comparison
                compare_sysf "$no_turbo" "$INTELPSD/no_turbo"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  no_turbo/%s=ok" "$no_turbo"
                else
                    printf_msg "  no_turbo/%s=err(%s)" "$no_turbo" "$rc"
                    errcnt=$((errcnt + 1))
                fi

                if [ -f "$INTELPSD/hwp_dynamic_boost" ]; then
                    # invert dyn boost state
                    dyn_boost="$((dyn_boost_save ^ 1))"

                    # apply inverted dyn boost state
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost"  CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost_save" CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost" CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost_save" CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost" CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost_save"  CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost_save" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect dyn boost state change
                    compare_sysf "$dyn_boost" "$INTELPSD/hwp_dynamic_boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " dyn_boost/%s=ok" "$dyn_boost"
                    else
                        printf_msg " dyn_boost/%s=err(%s)" "$dyn_boost" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                else
                    printf_msg " dyn_boost/<not available>"
                fi
                printf_msg "\n"

                # revert to initial turbo state
                # note: the CPU_BOOST_ON_AC/BAT/SAV setting must be the inverse of the new no_turbo state
                # so use $no_turbo as parameter value
                case "$prof" in
                    performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_AC="$no_turbo"  CPU_BOOST_ON_BAT="$no_turbo_save" CPU_BOOST_ON_SAV="$no_turbo_save" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_BAT="$no_turbo" CPU_BOOST_ON_SAV="$no_turbo_save" CPU_BOOST_ON_AC="$no_turbo_save" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        CPU_BOOST_ON_SAV="$no_turbo" CPU_BOOST_ON_AC="$no_turbo_save"  CPU_BOOST_ON_BAT="$no_turbo_save" \
                        > /dev/null 2>&1 ;;
                esac

                # expect initial turbo state
                # note: the actual no_turbo state is the inverse of the CPU_BOOST_ON_AC/BAT/SAV parameter value,
                # so use $no_turbo_save for comparison
                compare_sysf "$no_turbo_save" "$INTELPSD/no_turbo"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg "  no_turbo/%s=ok" "$no_turbo_save"
                else
                    printf_msg "  no_turbo/%s=err(%s)" "$no_turbo_save" "$rc"
                    errcnt=$((errcnt + 1))
                fi

                if [ -f "$INTELPSD/hwp_dynamic_boost" ]; then
                    # revert to initial dyn boost state
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost_save"  CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost" CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost_save" CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost" CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_HWP_DYN_BOOST_ON_SAV="$dyn_boost_save" CPU_HWP_DYN_BOOST_ON_AC="$dyn_boost"  CPU_HWP_DYN_BOOST_ON_BAT="$dyn_boost" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect initial dyn boost state
                    compare_sysf "$dyn_boost_save" "$INTELPSD/hwp_dynamic_boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " dyn_boost/%s=ok" "$dyn_boost_save"
                    else
                        printf_msg " dyn_boost/%s=err(%s)" "$dyn_boost_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                else
                    printf_msg " dyn_boost/<not available>"
                fi
                printf_msg "\n"

            done # prof

            # print resulting turbo, dyn boost states
            printf_msg " result(%s): no_turbo/%s dyn_boost/%s\n" \
                "$prof_save" \
                "$(read_sysf "$INTELPSD/no_turbo")" \
                "$(read_sysf "$INTELPSD/hwp_dynamic_boost" "<not available>")"
            ;; # intel_pstate/cpufreq

        acpi-cpufreq|amd?pstate*)
            if [ -f "${CPUD}/cpufreq/boost" ]; then
                # save initial boost state
                boost_save="$(read_sysf "${CPUD}/cpufreq/boost")"
                printf_msg " initial(%s): boost/%s\n" "$prof_save" "$boost_save"

                # invert boost state
                boost="$((boost_save ^ 1))"

                 for prof in $prof_seq; do
                    # --- test profile; ensure different values from other profiles do not spill over
                    printf_msg " %s:" "$prof"
                    # apply inverted boost state
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_AC="$boost"  CPU_BOOST_ON_BAT="$boost_save" CPU_BOOST_ON_SAV="$boost_save" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_BAT="$boost" CPU_BOOST_ON_SAV="$boost_save" CPU_BOOST_ON_AC="$boost_save" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_SAV="$boost" CPU_BOOST_ON_AC="$boost_save"  CPU_BOOST_ON_BAT="$boost_save" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect boost state change
                    compare_sysf "$boost" "${CPUD}/cpufreq/boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " boost/%s=ok" "$boost"
                    else
                        printf_msg " boost/%s=err(%s)" "$boost" "$rc"
                        errcnt=$((errcnt + 1))
                    fi

                    # revert to initial boost state
                    case "$prof" in
                        performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_AC="$boost_save"  CPU_BOOST_ON_BAT="$boost" CPU_BOOST_ON_SAV="$boost" \
                            > /dev/null 2>&1 ;;
                        balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_BAT="$boost_save" CPU_BOOST_ON_SAV="$boost" CPU_BOOST_ON_AC="$boost" \
                            > /dev/null 2>&1 ;;
                        power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                            CPU_BOOST_ON_SAV="$boost_save" CPU_BOOST_ON_AC="$boost"  CPU_BOOST_ON_BAT="$boost" \
                            > /dev/null 2>&1 ;;
                    esac

                    # expect initial boost state
                    compare_sysf "$boost_save" "${CPUD}/cpufreq/boost"
                    rc=$?
                    if [ "$rc" -eq 0 ]; then
                        printf_msg " boost/%s=ok" "$boost_save"
                    else
                        printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                        errcnt=$((errcnt + 1))
                    fi
                    printf_msg "\n"

                done # prof

                # print resulting boost state
                printf_msg " result(%s): boost/%s\n" "$prof_save" "$(read_sysf "${CPUD}/cpufreq/boost")"
            else
                printf_msg "*** unsupported cpu\n"
            fi
            ;; # acpi-cpufreq/amd-pstate

        *)
            printf_msg "*** unsupported cpu driver\n"
            ;;

    esac # _cpu_driver

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_platform_profile () {
   # apply plaform profile

    local pprof pprof_save
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_platform_profile {{{\n"

    # save initial platform profile / check availability
    if pprof_save="$(read_sysf "${FWACPID}/platform_profile")"; then
        printf_msg " initial(%s): %s\n" "$prof_save" "$pprof_save"

        # iterate profiles w/ standard platform profile values (hoping all drivers support them)
        for prof in $prof_seq; do
            # --- test profile; ensure different values from other profiles do not spill over
            printf_msg " %s:" "$prof"

            case "$prof" in
                performance)
                    pprof="performance"
                    ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        PLATFORM_PROFILE_ON_AC="$pprof"  PLATFORM_PROFILE_ON_BAT="$pprof_save" PLATFORM_PROFILE_SAV="$pprof_save" \
                        > /dev/null 2>&1
                    ;;

                balanced)
                    pprof="balanced"
                    ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        PLATFORM_PROFILE_ON_BAT="$pprof" PLATFORM_PROFILE_ON_SAV="$pprof_save" PLATFORM_PROFILE_AC="$pprof_save" \
                        > /dev/null 2>&1
                    ;;

                power-saver)
                    pprof="low-power"
                    ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        PLATFORM_PROFILE_ON_SAV="$pprof" PLATFORM_PROFILE_ON_AC="$pprof_save"  PLATFORM_PROFILE_BAT="$pprof_save" \
                        > /dev/null 2>&1
                    ;;
            esac

            # expect platform profile change
            compare_sysf "$pprof" "${FWACPID}/platform_profile"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ok" "$pprof"
            else
                printf_msg " %s=err(%s)" "$pprof" "$rc"
                errcnt=$((errcnt + 1))
            fi
            printf_msg "\n"

        done # prof

        # print resulting platform profile
        printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${FWACPID}/platform_profile")"
    else
        printf_msg "*** unsupported platform\n"
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

# check prerequisites and initialize
check_tlp
_cpu_driver=$(read_sysf "${CPU0}/cpufreq/scaling_driver") || {
    printf_msg "Error: could not determine cpu scaling driver."
    exit 128
}
cache_root_cred

start_report

# shellcheck disable=SC2034
_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

report_test "$_basename"

printf_msg "+++ %s --- cpu_driver: %s\n\n" "${0##*/}" "$_cpu_driver"

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

# --- TEST
check_cpu_driver_opmode
check_cpu_scaling_governor
check_cpu_scaling_freq
check_cpu_epp
check_cpu_perf_pct
check_cpu_boost
check_platform_profile

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
