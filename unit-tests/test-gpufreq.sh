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
# Copyright (c) 2026 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later

# --- Constants
readonly TLP="tlp"
readonly SUDO="sudo"

readonly GPUGLOB='/sys/class/drm/card[0-9]'

# --- Tests
check_intel_gpu_freq () {
    # apply Intel gpu min/max/boost frequencies
    # global param: $_gpu_base, $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local min min_save max max_save boost boost_save
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_intel_gpu_freq {{{\n"

    if [ -f "${_gpu_base}/gt_min_freq_mhz" ]; then
        # save initial frequencies
        min_save="$(read_sysf "${_gpu_base}/gt_min_freq_mhz")"
        max_save="$(read_sysf "${_gpu_base}/gt_max_freq_mhz")"
        boost_save="$(read_sysf "${_gpu_base}/gt_boost_freq_mhz")"

        # target frequencies: increase min, decrease max/boost
        min=$((min_save + 100))
        max=$((max_save - 200))
        boost=$((boost_save - 100))

        printf_msg " initial(%s): min/%s max/%s boost/%s\n" "$prof_save" "$min_save" "$max_save" "$boost_save"

        for prof in $prof_seq; do
            # --- test profile; ensure different values from other profiles do not spill over
            printf_msg " %s:\n" "$prof"

            # apply target frequencies
            case "$prof" in
                performance)  ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_AC="$min"     INTEL_GPU_MIN_FREQ_ON_BAT="$min_save"     INTEL_GPU_MIN_FREQ_ON_SAV="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_AC="$max"     INTEL_GPU_MAX_FREQ_ON_BAT="$max_save"     INTEL_GPU_MAX_FREQ_ON_SAV="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_MIN_FREQ_ON_SAV="$boost_save" \
                    > /dev/null 2>&1 ;;

                balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_BAT="$min"     INTEL_GPU_MIN_FREQ_ON_SAV="$min_save"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_BAT="$max"     INTEL_GPU_MAX_FREQ_ON_SAV="$max_save"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_BAT="$boost" INTEL_GPU_BOOST_FREQ_ON_SAV="$boost_save" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" \
                    > /dev/null 2>&1 ;;

                power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_SAV="$min"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_SAV="$max"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_SAV="$boost" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" \
                    > /dev/null 2>&1 ;;
            esac

            # expect target frequencies
            compare_sysf "$min" "${_gpu_base}/gt_min_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg "  min/%s=ok" "$min"
            else
                printf_msg "  min/%s=err(%s)" "$min" "$rc"
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
            printf_msg "\n"

            # revert to initial frequencies
            case "$prof" in
                performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_AC="$min_save"     INTEL_GPU_MIN_FREQ_ON_BAT="$min"     INTEL_GPU_MIN_FREQ_ON_SAV="$min" \
                    INTEL_GPU_MAX_FREQ_ON_AC="$max_save"     INTEL_GPU_MAX_FREQ_ON_BAT="$max"     INTEL_GPU_MAX_FREQ_ON_SAV="$max" \
                    INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost" INTEL_GPU_MIN_FREQ_ON_SAV="$boost" \
                    > /dev/null 2>&1 ;;

                balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_BAT="$min_save"     INTEL_GPU_MIN_FREQ_ON_SAV="$min"     INTEL_GPU_MIN_FREQ_ON_AC="$min" \
                    INTEL_GPU_MAX_FREQ_ON_BAT="$max_save"     INTEL_GPU_MAX_FREQ_ON_SAV="$max"     INTEL_GPU_MAX_FREQ_ON_AC="$max" \
                    INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_BOOST_FREQ_ON_SAV="$boost" INTEL_GPU_BOOST_FREQ_ON_AC="$boost" \
                    > /dev/null 2>&1 ;;

                power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_SAV="$min_save"     INTEL_GPU_MIN_FREQ_ON_AC="$min"     INTEL_GPU_MIN_FREQ_ON_AC="$min" \
                    INTEL_GPU_MAX_FREQ_ON_SAV="$max_save"     INTEL_GPU_MAX_FREQ_ON_AC="$max"     INTEL_GPU_MAX_FREQ_ON_AC="$max" \
                    INTEL_GPU_BOOST_FREQ_ON_SAV="$boost_save" INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_AC="$boost" \
                    > /dev/null 2>&1 ;;
            esac

            # expect change: initial frequencies
            compare_sysf "$min_save" "${_gpu_base}/gt_min_freq_mhz"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg "  min/%s=ok" "$min_save"
            else
                printf_msg "  min/%s=err(%s)" "$min_save" "$rc"
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
            printf_msg "\n"

        done # prof

        # print resulting frequencies
        printf_msg " result(%s): min/%s max/%s boost/%s\n" \
            "$prof" \
            "$(read_sysf "${_gpu_base}/gt_min_freq_mhz")" \
            "$(read_sysf "${_gpu_base}/gt_max_freq_mhz")" \
            "$(read_sysf "${_gpu_base}/gt_boost_freq_mhz")"

    else
        printf_msg "*** unsupported gpu\n"
    fi

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

    local dpm dpm_save dpm_seq
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_amd_gpu_dpm_level {{{\n"

    # save initial dpm level
    dpm_save="$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"
    printf_msg " initial(%s): %s\n" "$prof_save" "$dpm_save"

    for prof in $prof_seq; do
        # --- test profile; ensure different values from other profiles do not spill over
        printf_msg " %s:" "$prof"

        # iterate dpm levels supported by the driver, return to initial level
        case "$dpm_save" in
            auto) dpm_seq="low high auto" ;;
            low)  dpm_seq="high auto low" ;;
            high) dpm_seq="auto low high" ;;
        esac

        for dpm in $dpm_seq; do
            # apply dpm level
            case "$prof" in
                performance) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    RADEON_DPM_PERF_LEVEL_ON_AC="$dpm" RADEON_DPM_PERF_LEVEL_ON_BAT="$dpm_save" RADEON_DPM_PERF_LEVEL_ON_SAV="$dpm_save" \
                    > /dev/null 2>&1 ;;
                balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    RADEON_DPM_PERF_LEVEL_ON_BAT="$dpm" RADEON_DPM_PERF_LEVEL_ON_SAV="$dpm_save" RADEON_DPM_PERF_LEVEL_ON_AC="$dpm_save" \
                    > /dev/null 2>&1 ;;
                power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    RADEON_DPM_PERF_LEVEL_ON_SAV="$dpm" RADEON_DPM_PERF_LEVEL_ON_AC="$dpm_save" RADEON_DPM_PERF_LEVEL_ON_BAT="$dpm_save" \
                    > /dev/null 2>&1 ;;
            esac

            # expect change
            compare_sysf "$dpm" "${_gpu_base}/device/power_dpm_force_performance_level"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ok" "$dpm"
            else
                printf_msg " %s=err(%s)" "$dpm" "$rc"
                errcnt=$((errcnt + 1))
            fi

        done # dpm

        printf_msg "\n"

    done # prof

    # print resulting dpm level
    printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_amd_gpu_abm_level () {
    # apply AMD gpu dpm level
    # global param: $_gpu_base, $_testcnt, $_failcnt
    # retval: $_testcnt++, $_failcnt++

    local abm abm_save abm_seq abm_sysf
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_amd_gpu_abm_level {{{\n"

    abm_sysf="${_gpu_base}/${_gpu_base##/*/}-eDP-1/amdgpu/panel_power_savings"
    if [ ! -f "$abm_sysf" ]; then
        printf_msg "  Error: sysfile %s not present.\n" "$abm_sysf"
         _testcnt=$((_testcnt + 1))
        _failcnt=$((_failcnt + 1))
        printf_msg "}}} errcnt=%s\n\n" "1"
        return 1
    fi

    # save initial abm level
    abm_save="$(read_sysf "$abm_sysf")"
    printf_msg " initial(%s): %s\n" "$prof_save" "$abm_save"

    for prof in $prof_seq; do
        # --- test profile; ensure different values from other profiles do not spill over
        printf_msg " %s:" "$prof"

        # iterate abm levels supported by the driver, return to initial level
        case "$abm_save" in
            0) abm_seq="1 2 3 4 0" ;;
            1) abm_seq="2 3 4 0 1" ;;
            2) abm_seq="3 4 0 1 2" ;;
            3) abm_seq="4 0 1 2 3" ;;
        esac

        for abm in $abm_seq; do
            case "$prof" in
                performance)  ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    AMDGPU_ABM_LEVEL_ON_AC="$abm" AMDGPU_ABM_LEVEL_ON_BAT="$abm_save" AMDGPU_ABM_LEVEL_ON_SAV="$abm_save" \
                    > /dev/null 2>&1 ;;
                balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    AMDGPU_ABM_LEVEL_ON_BAT="$abm" AMDGPU_ABM_LEVEL_ON_SAV="$abm_save" AMDGPU_ABM_LEVEL_ON_AC="$abm_save" \
                    > /dev/null 2>&1 ;;
                power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    AMDGPU_ABM_LEVEL_ON_SAV="$abm" AMDGPU_ABM_LEVEL_ON_AC="$abm_save" AMDGPU_ABM_LEVEL_ON_BAT="$abm_save" \
                    > /dev/null 2>&1 ;;
            esac

            # expect change
            compare_sysf "$abm" "$abm_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " %s=ok" "$abm"
            else
                printf_msg " %s=err(%s)" "$abm" "$rc"
                errcnt=$((errcnt + 1))
            fi

        done # abm

        printf_msg "\n"

    done # prof

    # print resulting abm level
    printf_msg " result(%s): %s\n" "$prof" "$(read_sysf "$abm_sysf")"

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
cache_root_cred
start_report

# shellcheck disable=SC2034
_basename="${0##*/}"
# shellcheck disable=SC2034
_logfile="$(date -Iseconds)_${_basename%.*}.log"
_testcnt=0
_failcnt=0

report_test "$_basename"

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

# --- TEST: iterate GPUs
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

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
