#!/bin/sh
# Test GPU related features
#
# Tested parameters:
# * INTEL_GPU_MIN_FREQ_ON_AC/BAT
# * INTEL_GPU_MAX_FREQ_ON_AC/BAT
# * INTEL_GPU_BOOST_FREQ_ON_AC/BAT
# * RADEON_DPM_PERF_LEVEL_ON_AC/BAT
# * AMDGPU_ABM_LEVEL_ON_AC/BAT
#
# Supported GPU drivers:
# * i915
# * amdgpu
#
# Copyright (c) 2024 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TESTLIB="./test-func"
readonly TLP="tlp"

readonly GPUGLOB='/sys/class/drm/card[0-9]'

# --- Functions

check_intel_gpu_freq () {
    # apply Intel gpu min/max/boost frequencies
    # global param: $_gpu_base, $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local min min_save="" max max_save boost boost_save
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_intel_gpu_freq {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        if [ $sc -eq 1 ]; then
            # --- test settings profile for active power source
            # /sys/class/drm/card1/gt_min_freq_mhz         =   100 [MHz]
            # /sys/class/drm/card1/gt_max_freq_mhz         =  1300 [MHz]
            # /sys/class/drm/card1/gt_boost_freq_mhz       =  1300 [MHz]
            # /sys/class/drm/card1/gt_RPn_freq_mhz         =   100 [MHz] (GPU min)
            # /sys/class/drm/card1/gt_RP0_freq_mhz         =  1300 [MHz] (GPU max)

            # save initial frequencies
            min_save="$(read_sysf "${_gpu_base}/gt_min_freq_mhz")"
            max_save="$(read_sysf "${_gpu_base}/gt_max_freq_mhz")"
            boost_save="$(read_sysf "${_gpu_base}/gt_boost_freq_mhz")"

            printf_msg " initial: min/%s max/%s boost/%s\n" "$min_save" "$max_save" "$boost_save"

            printf_msg " %s(active):" "$psfx"

            # increase min, decrease max/boost frequency
            min=$((min_save + 100))
            max=$((max_save - 200))
            boost=$((boost_save - 100))
            case "$psfx" in
                AC)  ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_AC="$min"     INTEL_GPU_MIN_FREQ_ON_BAT="" \
                                     INTEL_GPU_MAX_FREQ_ON_AC="$max"     INTEL_GPU_MAX_FREQ_ON_BAT="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                BAT) ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_BAT="$min"    INTEL_GPU_MIN_FREQ_ON_AC="" \
                                     INTEL_GPU_MAX_FREQ_ON_BAT="$max"    INTEL_GPU_MAX_FREQ_ON_AC="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
            esac

            # expect change
            compare_sysf "$min" "${_gpu_base}/gt_min_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " min/%s=ok" "$min"
            else
                printf_msg " min/%s=err(%s)" "$min" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$max" "${_gpu_base}/gt_max_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " max/%s=ok" "$max"
            else
                printf_msg " max/%s=err(%s)" "$max" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$boost" "${_gpu_base}/gt_boost_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " boost/%s=ok" "$boost"
            else
                printf_msg " boost/%s=err(%s)" "$boost" "$rc"
                errcnt=$((errcnt + 1))
            fi

            # revert to initial frequencies
            case "$psfx" in
                AC)  ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_AC="$min_save"     INTEL_GPU_MIN_FREQ_ON_BAT="" \
                                     INTEL_GPU_MAX_FREQ_ON_AC="$max_save"     INTEL_GPU_MAX_FREQ_ON_BAT="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                BAT) ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_BAT="$min_save"    INTEL_GPU_MIN_FREQ_ON_AC="" \
                                     INTEL_GPU_MAX_FREQ_ON_BAT="$max_save"    INTEL_GPU_MAX_FREQ_ON_AC="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
            esac

            # expect initial frequencies
            compare_sysf "$min_save" "${_gpu_base}/gt_min_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " min/%s=ok" "$min_save"
            else
                printf_msg " min/%s=err(%s)" "$min_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$max_save" "${_gpu_base}/gt_max_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " max/%s=ok" "$max_save"
            else
                printf_msg " max/%s=err(%s)" "$max_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$boost_save" "${_gpu_base}/gt_boost_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " boost/%s=ok" "$boost_save"
            else
                printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
        else
            # --- test settings profile for inactive power source
            printf_msg "\n %s(inactive):" "$psfx"

            # try increased min, decreased max frequency again (from above)
            case "$psfx" in
                AC)  ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_AC="$min"     INTEL_GPU_MIN_FREQ_ON_BAT="" \
                                     INTEL_GPU_MAX_FREQ_ON_AC="$max"     INTEL_GPU_MAX_FREQ_ON_BAT="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
                BAT) ${TLP} start -- INTEL_GPU_MIN_FREQ_ON_BAT="$min"    INTEL_GPU_MIN_FREQ_ON_AC="" \
                                     INTEL_GPU_MAX_FREQ_ON_BAT="$max"    INTEL_GPU_MAX_FREQ_ON_AC="" \
                                     INTEL_GPU_BOOST_FREQ_ON_AC="$boost"  INTEL_GPU_BOOST_FREQ_ON_BAT="" > /dev/null 2>&1 ;;
            esac

            # do not expect change
            compare_sysf "$min_save" "${_gpu_base}/gt_min_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " min/%s=ignored(ok)" "$min_save"
            else
                printf_msg " min/%s=err(%s)" "$min_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$max_save" "${_gpu_base}/gt_max_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " max/%s=ignored(ok)" "$max_save"
            else
                printf_msg " max/%s=err(%s)" "$max_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$boost_save" "${_gpu_base}/gt_boost_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " boost/%s=ignored(ok)" "$boost_save"
            else
                printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                errcnt=$((errcnt + 1))
            fi

            # print resulting frequencies
            printf_msg "\n result: min/%s max/%s boost/%s\n" \
                "$(read_sysf "${_gpu_base}/gt_min_freq_mhz")" "$(read_sysf "${_gpu_base}/gt_max_freq_mhz")" \
                "$(read_sysf "${_gpu_base}/gt_boost_freq_mhz")"
        fi

    done # psfx

    # print summary
    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_amd_gpu_dpm_level () {
    # apply AMD gpu dpm level
    # global param: $_gpu_base, $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local dpm dpm_save dpm_seq dpm_cur
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_amd_gpu_dpm_level {{{\n"

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        if [ $sc -eq 1 ]; then
            # --- test settings profile for active power source

            # save initial dpm level
            dpm_save="$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"
            printf_msg " initial: %s\n" "$dpm_save"

            printf_msg " %s(active):" "$psfx"

            # iterate dpm levels supported by the driver, return to initial level
            case "$dpm_save" in
                auto) dpm_seq="low high auto" ;;
                low)  dpm_seq="high auto low" ;;
                high) dpm_seq="auto low high" ;;
            esac

            for dpm in $dpm_seq; do
                case "$psfx" in
                    AC)  ${TLP} start -- RADEON_DPM_PERF_LEVEL_ON_AC="$dpm" RADEON_DPM_PERF_LEVEL_ON_BAT="" > /dev/null 2>&1 ;;
                    BAT) ${TLP} start -- RADEON_DPM_PERF_LEVEL_ON_BAT="$dpm" RADEON_DPM_PERF_LEVEL_ON_AC="" > /dev/null 2>&1 ;;
                esac

                # expect change
                compare_sysf "$dpm" "${_gpu_base}/device/power_dpm_force_performance_level"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " %s=ok" "$dpm"
                else
                    printf_msg " %s=%s" "$dpm" "$rc"
                    errcnt=$((errcnt + 1))
                fi
            done # pol
        else
            # --- test settings profile for inactive power source
            printf_msg "\n %s(inactive):" "$psfx"

            # save current dpm level
            dpm_cur="$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"

            # try different dpm level
            case "$dpm_cur" in
                auto) dpm="low" ;;
                low)  dpm="high" ;;
                high) dpm="auto" ;;
            esac

            case "$psfx" in
                AC)  ${TLP} start -- RADEON_DPM_PERF_LEVEL_ON_AC="$dpm" RADEON_DPM_PERF_LEVEL_ON_BAT="" > /dev/null 2>&1 ;;
                BAT) ${TLP} start -- RADEON_DPM_PERF_LEVEL_ON_BAT="$dpm" RADEON_DPM_PERF_LEVEL_ON_AC="" > /dev/null 2>&1 ;;
            esac

            # do not expect change
            compare_sysf "$dpm_cur" "${_gpu_base}/device/power_dpm_force_performance_level"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ignored(ok)" "$dpm"
            else
                printf_msg " %s=err(%s)" "$dpm" "$rc"
                errcnt=$((errcnt + 1))
            fi

            # print resulting dpm level
            printf_msg "\n result: %s\n" "$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"
        fi

    done # psfx

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_amd_gpu_abm_level () {
    # apply AMD gpu dpm level
    # global param: $_gpu_base, $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local abm abm_save abm_seq abm_cur abm_sysf
    local psfx psfsq sc=0
    local rc=0 errcnt=0

    printf_msg "check_amd_gpu_abm_level {{{\n"

    abm_sysf="${_gpu_base}/${_gpu_base##/*/}-eDP-1/amdgpu/panel_power_savings"
    if [ ! -f "$abm_sysf" ]; then
        printf_msg "  Error: sysfile %s not present.\n" "$abm_sysf"
         _testcnt=$((_testcnt + 1))
        _failcnt=$((_failcnt + 1))
        printf_msg "}}} errcnt=%s\n\n" "1"
        return 1
    fi

    # determine test sequence for parameter suffix _AC/BAT, active power source goes first
    if on_ac; then
        psfsq="AC BAT"
    else
        psfsq="BAT AC"
    fi

    for psfx in $psfsq; do
        sc=$((sc + 1))

        if [ $sc -eq 1 ]; then
            # --- test settings profile for active power source

            # save initial abm level
            abm_save="$(read_sysf "$abm_sysf")"
            printf_msg " initial: %s\n" "$abm_save"

            printf_msg " %s(active):" "$psfx"

            # iterate abm levels supported by the driver, return to initial level
            case "$abm_save" in
                0) abm_seq="1 2 3 4 0" ;;
                1) abm_seq="2 3 4 0 1" ;;
                2) abm_seq="3 4 0 1 2" ;;
                3) abm_seq="4 0 1 2 3" ;;
            esac

            for abm in $abm_seq; do
                case "$psfx" in
                    AC)  ${TLP} start -- AMDGPU_ABM_LEVEL_ON_AC="$abm" AMDGPU_ABM_LEVEL_ON_BAT="" > /dev/null 2>&1 ;;
                    BAT) ${TLP} start -- AMDGPU_ABM_LEVEL_ON_BAT="$abm" AMDGPU_ABM_LEVEL_ON_AC="" > /dev/null 2>&1 ;;
                esac

                # expect change
                compare_sysf "$abm" "$abm_sysf"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " %s=ok" "$abm"
                else
                    printf_msg " %s=%s" "$abm" "$rc"
                    errcnt=$((errcnt + 1))
                fi
            done # pol
        else
            # --- test settings profile for inactive power source
            printf_msg "\n %s(inactive):" "$psfx"

            # save current abm level
            abm_cur="$(read_sysf "$abm_sysf")"

            # try different abm level
            case "$abm_cur" in
                0) abm="1" ;;
                1) abm="2" ;;
                2) abm="3" ;;
                3) abm="4" ;;
            esac

            case "$psfx" in
                AC)  ${TLP} start -- AMDGPU_ABM_LEVEL_ON_AC="$abm" AMDGPU_ABM_LEVEL_ON_BAT="" > /dev/null 2>&1 ;;
                BAT) ${TLP} start -- AMDGPU_ABM_LEVEL_ON_BAT="$abm" AMDGPU_ABM_LEVEL_ON_AC="" > /dev/null 2>&1 ;;
            esac

            # do not expect change
            compare_sysf "$abm_cur" "$abm_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ignored(ok)" "$abm"
            else
                printf_msg " %s=err(%s)" "$abm" "$rc"
                errcnt=$((errcnt + 1))
            fi

            # print resulting abm level
            printf_msg "\n result: %s\n" "$(read_sysf "$abm_sysf")"
        fi

    done # psfx

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

# shellcheck disable=SC2034
_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

# --- Iterate GPUs

for _gpu_base in $GPUGLOB; do
    [ -d "$_gpu_base" ] || break

    # determine gpu driver
    _gpu_driver="$(readlink "${_gpu_base}/device/driver")"
    _gpu_driver="${_gpu_driver##*/}"

    printf_msg "+++ gpu: %s --- driver: %s\n\n" "$_gpu_base" "$_gpu_driver"

    # checks
    case "$_gpu_driver" in
        i915)
            check_intel_gpu_freq
            ;;

        amdgpu)
            check_amd_gpu_dpm_level
            check_amd_gpu_abm_level
            ;;

        *)
            printf "%s has no test coverage. Skipped.\n" "$_gpu_driver"
            ;;
    esac

done # gpud

printf_msg "+++ Test results: %d run, %d failed.\n\n" "$_testcnt" "$_failcnt"

# --- Exit
exit $_failcnt
