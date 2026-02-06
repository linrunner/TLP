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

check_intel_gpu_power_profile () {
    # apply Intel gpu power profile
    # global param: $_gpu_base, $_gpu_driver, $_testcnt, $_failcnt, $_prof_save, $_prof_seq
    # retval: $_testcnt++, $_failcnt++

    local pp pp_save pp_seq pp_sysf
    local prof gtfd
    local rc=0
    local errcnt=0

    printf_msg "check_intel_gpu_power_profile (%s) {{{\n" "$_gpu_driver"

    if [ "$_gpu_driver" = "xe" ]; then
        for gtfd in "${_gpu_base}"/device/tile*/gt*/freq*; do
            [ -d "$gtfd" ] || break

            pp_sysf="${gtfd}/power_profile"
            if [ ! -f "$pp_sysf" ]; then
                printf_msg "  Error: sysfile %s not present.\n" "$pp_sysf"
                _testcnt=$((_testcnt + 1))
                _failcnt=$((_failcnt + 1))
                printf_msg "}}} errcnt=%s\n\n" "1"
                return 1
            fi
        done

       # save initial abm level
        pp_save="$(get_listitem "$(read_sysf "$pp_sysf")")"
        printf_msg " initial(%s): %s\n" "$_prof_save" "$pp_save"

        for prof in $_prof_seq; do
            # --- test profile; ensure different values from other profiles do not spill over
            printf_msg " %s:" "$prof"

            # iterate abm levels supported by the driver, return to initial level
            case "$pp_save" in
                base)         pp_seq="power_saving base" ;;
                power_saving) pp_seq="base power_saving" ;;
            esac

            for pp in $pp_seq; do
                case "$prof" in
                    performance)  ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        INTEL_GPU_POWER_PROFILE_ON_AC="$pp" INTEL_GPU_POWER_PROFILE_ON_BAT="$pp_save" INTEL_GPU_POWER_PROFILE_ON_SAV="$pp_save"  \
                        INTEL_GPU_MIN_FREQ_ON_AC=""         INTEL_GPU_MIN_FREQ_ON_BAT=""              INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        INTEL_GPU_MAX_FREQ_ON_AC=""         INTEL_GPU_MAX_FREQ_ON_BAT=""              INTEL_GPU_MAX_FREQ_ON_SAV="" \
                        INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        > /dev/null 2>&1 ;;
                    balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        INTEL_GPU_POWER_PROFILE_ON_AC="$pp_save" INTEL_GPU_POWER_PROFILE_ON_BAT="$pp" INTEL_GPU_POWER_PROFILE_ON_SAV="$pp_save"  \
                        INTEL_GPU_MIN_FREQ_ON_AC=""         INTEL_GPU_MIN_FREQ_ON_BAT=""              INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        INTEL_GPU_MAX_FREQ_ON_AC=""         INTEL_GPU_MAX_FREQ_ON_BAT=""              INTEL_GPU_MAX_FREQ_ON_SAV="" \
                        INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        > /dev/null 2>&1 ;;
                    power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                        INTEL_GPU_POWER_PROFILE_ON_AC="$pp_save" INTEL_GPU_POWER_PROFILE_ON_BAT="$pp_save" INTEL_GPU_POWER_PROFILE_ON_SAV="$pp"  \
                        INTEL_GPU_MIN_FREQ_ON_AC=""         INTEL_GPU_MIN_FREQ_ON_BAT=""              INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        INTEL_GPU_MAX_FREQ_ON_AC=""         INTEL_GPU_MAX_FREQ_ON_BAT=""              INTEL_GPU_MAX_FREQ_ON_SAV="" \
                        INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_MIN_FREQ_ON_SAV="" \
                        > /dev/null 2>&1 ;;
                esac

                # expect change
                compare_sysf_list "$pp" "$pp_sysf"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " %s=ok" "$pp"
                else
                    printf_msg " %s=err(%s)" "$pp" "$rc"
                    errcnt=$((errcnt + 1))
                fi

            done # abm

            printf_msg "\n"

        done # prof

    else
        printf_msg "*** unsupported gpu\n"
    fi

    # print resulting abm level
    printf_msg " result(%s): %s\n" "$prof" "$(get_listitem "$(read_sysf "$pp_sysf")")"

    printf_msg "}}} errcnt=%s\n\n" "$errcnt"
    _testcnt=$((_testcnt + 1))
    [ "$errcnt" -gt 0 ] && _failcnt=$((_failcnt + 1))
    return $errcnt
}

check_intel_gpu_freq () {
    # apply Intel gpu min/max/boost frequencies
    # global param: $_gpu_base, $_gpu_driver, $_testcnt, $_failcnt, $_prof_save, $_prof_seq
    # retval: $_testcnt++, $_failcnt++

    local min_sysf="" max_sysf="" boost_sysf=""
    local min min_save max max_save boost boost_save
    local prof gtfd
    local rc=0
    local errcnt=0

    printf_msg "check_intel_gpu_freq (%s) {{{\n" "$_gpu_driver"

    case "$_gpu_driver" in
        i915)
            min_sysf="${_gpu_base}/gt_min_freq_mhz"
            max_sysf="${_gpu_base}/gt_max_freq_mhz"
            boost_sysf="${_gpu_base}/gt_boost_freq_mhz"
            ;;

        xe)
            for gtfd in "${_gpu_base}"/device/tile*/gt*/freq*; do
                [ -d "$gtfd" ] || break

                min_sysf="${gtfd}/min_freq"
                max_sysf="${gtfd}/max_freq"
                boost_sysf=""
                break
            done
            ;;
    esac

    if [ -f "$min_sysf" ]; then
        # save initial frequencies and calculate target frequencies
        min_save="$(read_sysf "$min_sysf")"
        max_save="$(read_sysf "$max_sysf")"
        if [ "$_gpu_driver" = "i915" ]; then
            min=$((min_save + 100))
        else
            min=$((min_save + 100))
        fi
        max=$((max_save - 200))
        if [ "$_gpu_driver" = "i915" ]; then
            boost_save="$(read_sysf "$boost_sysf")"
            boost=$((boost_save - 100))
            printf_msg " initial(%s): min/%s max/%s boost/%s\n" "$_prof_save" "$min_save" "$max_save" "$boost_save"
        else
            boost_save=0
            boost=0
            printf_msg " initial(%s): min/%s max/%s\n" "$_prof_save" "$min_save" "$max_save"
        fi


        for prof in $_prof_seq; do
            # --- test profile; ensure different values from other profiles do not spill over
            printf_msg " %s:\n" "$prof"

            # apply target frequencies
            case "$prof" in
                performance)  ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_AC="$min"     INTEL_GPU_MIN_FREQ_ON_BAT="$min_save"     INTEL_GPU_MIN_FREQ_ON_SAV="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_AC="$max"     INTEL_GPU_MAX_FREQ_ON_BAT="$max_save"     INTEL_GPU_MAX_FREQ_ON_SAV="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_AC="$boost" INTEL_GPU_BOOST_FREQ_ON_BAT="$boost_save" INTEL_GPU_MIN_FREQ_ON_SAV="$boost_save" \
                    INTEL_GPU_POWER_PROFILE_ON_AC=""    INTEL_GPU_POWER_PROFILE_ON_BAT=""         INTEL_GPU_POWER_PROFILE_ON_SAV=""  \
                    > /dev/null 2>&1 ;;

                balanced) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_BAT="$min"     INTEL_GPU_MIN_FREQ_ON_SAV="$min_save"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_BAT="$max"     INTEL_GPU_MAX_FREQ_ON_SAV="$max_save"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_BAT="$boost" INTEL_GPU_BOOST_FREQ_ON_SAV="$boost_save" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" \
                    INTEL_GPU_POWER_PROFILE_ON_AC=""    INTEL_GPU_POWER_PROFILE_ON_BAT=""         INTEL_GPU_POWER_PROFILE_ON_SAV=""  \
                    > /dev/null 2>&1 ;;

                power-saver) ${SUDO} ${TLP} "$prof" -- TLP_AUTO_SWITCH=2 TLP_DEFAULT_MODE="" \
                    INTEL_GPU_MIN_FREQ_ON_SAV="$min"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save"     INTEL_GPU_MIN_FREQ_ON_AC="$min_save" \
                    INTEL_GPU_MAX_FREQ_ON_SAV="$max"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save"     INTEL_GPU_MAX_FREQ_ON_AC="$max_save" \
                    INTEL_GPU_BOOST_FREQ_ON_SAV="$boost" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" INTEL_GPU_BOOST_FREQ_ON_AC="$boost_save" \
                    INTEL_GPU_POWER_PROFILE_ON_AC=""    INTEL_GPU_POWER_PROFILE_ON_BAT=""         INTEL_GPU_POWER_PROFILE_ON_SAV=""  \
                    > /dev/null 2>&1 ;;
            esac

            # expect target frequencies
            compare_sysf "$min" "$min_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg "  min/%s=ok" "$min"
            else
                printf_msg "  min/%s=err(%s)" "$min" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$max" "$max_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " max/%s=ok" "$max"
            else
                printf_msg " max/%s=err(%s)" "$max" "$rc"
                errcnt=$((errcnt + 1))
            fi
            if [ "$_gpu_driver" = "i915" ]; then
                compare_sysf "$boost" "$boost_sysf"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " boost/%s=ok" "$boost"
                else
                    printf_msg " boost/%s=err(%s)" "$boost" "$rc"
                    errcnt=$((errcnt + 1))
                fi
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
            compare_sysf "$min_save" "$min_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg "  min/%s=ok" "$min_save"
            else
                printf_msg "  min/%s=err(%s)" "$min_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            compare_sysf "$max_save" "$max_sysf"
            rc=$?
            if [ "$rc" -eq 0 ]; then
                printf_msg " max/%s=ok" "$max_save"
            else
                printf_msg " max/%s=err(%s)" "$max_save" "$rc"
                errcnt=$((errcnt + 1))
            fi
            if [ "$_gpu_driver" = "i915" ]; then
                compare_sysf "$boost_save" "$boost_sysf"
                rc=$?
                if [ "$rc" -eq 0 ]; then
                    printf_msg " boost/%s=ok" "$boost_save"
                else
                    printf_msg " boost/%s=err(%s)" "$boost_save" "$rc"
                    errcnt=$((errcnt + 1))
                fi
            fi
            printf_msg "\n"

        done # prof

        # print resulting frequencies
        printf_msg " result(%s): min/%s max/%s boost/%s\n" \
            "$prof" \
            "$(read_sysf "$min_sysf")" \
            "$(read_sysf "$max_sysf")" \
            "$(read_sysf "$boost_sysf")"

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
    # global param: $_gpu_base, $_testcnt, $_failcnt, $_prof_save, $_prof_seq
    # retval: $_testcnt++, $_failcnt++

    local dpm dpm_save dpm_seq
    local prof
    local rc=0
    local errcnt=0

    printf_msg "check_amd_gpu_dpm_level {{{\n"

    # save initial dpm level
    dpm_save="$(read_sysf "${_gpu_base}/device/power_dpm_force_performance_level")"
    printf_msg " initial(%s): %s\n" "$_prof_save" "$dpm_save"

    for prof in $_prof_seq; do
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
    # global param: $_gpu_base, $_testcnt, $_failcnt, $_prof_save
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
    printf_msg " initial(%s): %s\n" "$_prof_save" "$abm_save"

    for prof in $_prof_seq; do
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
_prof_save="$(pp2str "$_prof")"

# iterate supported profiles, return to initial profile
case "$_prof_save" in
    performance) _prof_seq="balanced power-saver performance" ;;
    balanced)    _prof_seq="power-saver performance balanced" ;;
    power-saver) _prof_seq="performance balanced power-saver" ;;
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

        xe)
            check_intel_gpu_power_profile
            check_intel_gpu_freq
            ;;


        amdgpu)
            check_amd_gpu_dpm_level
            check_amd_gpu_abm_level
            ;;

        *)
            printf "GPU driver %s has no test coverage. Skipped.\n" "$_gpu_driver"
            ;;
    esac

done # gpud

report_result "$_testcnt" "$_failcnt"

print_report

# --- Exit
exit $_failcnt
