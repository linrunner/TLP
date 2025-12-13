#!/usr/bin/python3
# Test:
# - tlpctl [set] performance|balance|power-saver,
# - tlpctl get
# - tlpctl
# - tlpctl list
# - tlpctl loglevel

import re
import time
from typing import List

from testing import TestReport, run_executable, test_executable

# --- Constants
TLPCTL = "tlpctl"
AVAILABLE_PROFILES = ["performance", "balanced", "power-saver"]
WAIT_PROFILE_ACTIVATION = 1.5


# --- Helper functions
def reordered_profile_sequence(new_last: str) -> List[str]:
    # Cyclic reorder of AVAILABLE_PROFILES sequence
    # Args:
    #   new_last: dedicated last element
    #
    # Returns:
    #   reordered sequence

    try:
        idx = AVAILABLE_PROFILES.index(new_last)
        return AVAILABLE_PROFILES[idx + 1 :] + AVAILABLE_PROFILES[: idx + 1]
    except ValueError:
        return []


# --- Filter functions
def extract_loglevel(output: str) -> str:
    # Extract loglevel from 'tlpctl list' output
    #
    # Args:
    #   output: output from 'tlpctl list'
    #
    # Returns:
    #   loglevel "info" or "debug"

    match = re.search(r"tlp-pd LogLevel:\s*(\S+)", output)
    if match:
        return match.group(1)
    else:
        return ""


# --- Test cases
def test_set_direct(report: TestReport):
    # Cycle available profiles with 'tlpctl <profile>', returning to the initial profile
    # Check results with 'tlpctl get'
    #
    # Args: none
    # Returns: none

    errcnt = 0
    initial = run_executable(TLPCTL, ["get"]).rstrip("\n")
    sequence = reordered_profile_sequence(initial)
    print("Check tlpctl <profile> " + repr(sequence) + " {{{")

    for profile in sequence:
        print(f"  tlpctl {profile}: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=[profile],
            expected_output=f"Switched to {profile} profile.\n",
        ):
            errcnt += 1

        # Wait, tlp activates the profile asynchronously
        time.sleep(WAIT_PROFILE_ACTIVATION)

        print("  check result w/ tlpctl get: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=["get"],
            expected_output=f"{profile}\n",
        ):
            errcnt += 1

    print("}}} " + f"errcnt={str(errcnt)}\n")

    report.count_test(errcnt)


def test_set(report: TestReport):
    # Cycle available profiles with 'tlpctl <profile>', returning to the initial profile
    # Check results with 'tlpctl'
    #
    # Args: none
    # Returns: none

    ### global _testcnt
    ### global _failcnt

    errcnt = 0
    initial = run_executable(TLPCTL, ["get"]).rstrip("\n")
    sequence = reordered_profile_sequence(initial)
    print("Check tlpctl set <profile> " + repr(sequence) + " {{{")

    for profile in sequence:
        print(f"  tlpctl set {profile}: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=["set", profile],
            expected_output="",
        ):
            errcnt += 1

        # Wait, tlp activates the profile asynchronously
        time.sleep(WAIT_PROFILE_ACTIVATION)

        # Assemble expected output considering current profile
        exp_list = ""
        for item in AVAILABLE_PROFILES:
            if item == profile:
                exp_list += f"* {item}\n"
            else:
                exp_list += f"  {item}\n"

        print("  check result w/ tlpctl: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=[],
            expected_output=exp_list,
        ):
            errcnt += 1

    print("}}} " + f"errcnt={str(errcnt)}\n")

    report.count_test(errcnt)


TLPCTL_OUTPUT_LIST = """Available power profiles (* = active):

@P@ performance:
    CpuDriver      : tlp
    PlatformDriver : tlp
    Degraded       : no

@B@ balanced:
    CpuDriver      : tlp
    PlatformDriver : tlp

@S@ power-saver:
    CpuDriver      : tlp
    PlatformDriver : tlp

Dynamic changes from charger and battery events: no
tlp-pd LogLevel: @L@
"""


def test_list(report: TestReport):
    # Check output of 'tlpctl list' for active profile marker and loglevel
    #
    # Args: none
    # Returns: none

    ### global _testcnt
    ### lobal _failcnt

    errcnt = 0
    initial = run_executable(TLPCTL, ["get"]).rstrip("\n")
    sequence = reordered_profile_sequence(initial)

    loglevel = run_executable(TLPCTL, ["list"]).rstrip("\n")
    loglevel = extract_loglevel(loglevel)

    print("Check tlpctl list " + repr(sequence) + " {{{")

    for profile in sequence:
        # Set profile
        print(f"  tlpctl set {profile}: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=["set", profile],
            expected_output="",
        ):
            errcnt += 1

        time.sleep(WAIT_PROFILE_ACTIVATION)

        # Synthesize expected output from the template
        exp_out = TLPCTL_OUTPUT_LIST
        if profile == "performance":
            exp_out = exp_out.replace("@P@", "*")
            exp_out = exp_out.replace("@B@", " ")
            exp_out = exp_out.replace("@S@", " ")
        elif profile == "balanced":
            exp_out = exp_out.replace("@P@", " ")
            exp_out = exp_out.replace("@B@", "*")
            exp_out = exp_out.replace("@S@", " ")
        else:
            exp_out = exp_out.replace("@P@", " ")
            exp_out = exp_out.replace("@B@", " ")
            exp_out = exp_out.replace("@S@", "*")
        exp_out = exp_out.replace("@L@", loglevel)

        print("  check result w/ tlpctl list: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=["list"],
            expected_output=exp_out,
        ):
            errcnt += 1

    print("}}} " + f"errcnt={str(errcnt)}\n")

    report.count_test(errcnt)


def test_loglevel(report: TestReport):
    # Check output of 'tlpctl loglevel'
    #
    # Args: none
    # Returns: none

    global _testcnt
    global _failcnt

    errcnt = 0
    loglevel = run_executable(TLPCTL, ["list"]).rstrip("\n")
    loglevel = extract_loglevel(loglevel)

    if loglevel == "info":
        seqlevel = ["debug", "info"]
    else:
        seqlevel = ["info", "debug"]

    print("Check tlpctl loglevel " + repr(seqlevel) + " {{{")

    for loglevel in seqlevel:
        print(f"  tlpctl loglevel {loglevel}: ", end="")
        if not test_executable(
            executable_path=TLPCTL,
            args=["loglevel", loglevel],
            expected_output=f"tlp-pd loglevel set to '{loglevel}'.\n",
        ):
            errcnt += 1

    print("}}} " + f"errcnt={str(errcnt)}\n")

    report.count_test(errcnt)


# --- Run tests
if __name__ == "__main__":
    report = TestReport()

    test_set_direct(report)
    test_set(report)
    test_list(report)
    test_loglevel(report)

    report.print_result()
