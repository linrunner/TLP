#!/usr/bin/python3
# test_func.py: Unit Test Helpers

import difflib
import os
import subprocess
import sys
import tempfile
from typing import Callable, List, Optional


# --- Testing functions ---
def run_executable(
    executable_path: str,
    args: List[str] = [],
    input_data: str = "",
    timeout: int = 10,
) -> str:
    # Run an executable and capture its stdout
    #
    # Args:
    #   executable_path: Path to the executable
    #   args: List of command-line arguments
    #   input_data: Input to pass via stdin (optional)
    #   timeout: Timeout in seconds
    #
    # Returns:
    #   stdout as a string

    cmd = [executable_path]
    if args:
        cmd.extend(args)

    try:
        result = subprocess.run(
            cmd,
            input=input_data,
            text=True,
            capture_output=True,
            timeout=timeout,
            check=True,
        )
        return result.stdout
    except subprocess.TimeoutExpired:
        sys.stderr.write(f"Error: {cmd} timed out after {timeout} seconds.\n")
        return ""
    except subprocess.CalledProcessError as err:
        sys.stderr.write(f"Error: {cmd} failed.\n{err.stderr}\n")
        return ""


def filter_output(
    output: str,
    filters: Optional[List[Callable[[str], str]]] = None,
) -> str:
    # Apply filters to the output (e.g., remove timestamps, normalize whitespace)
    #
    # Args:
    #   output: Raw output from the executable
    #   filters: List of filter functions (e.g., regex substitutions)
    #
    # Returns:
    #   Filtered output

    if not filters:
        return output

    filtered = output
    for filter_func in filters:
        filtered = filter_func(filtered)
    return filtered


def compare_outputs(
    actual: str,
    expected: str,
    ignore_whitespace: bool = False,
) -> bool:
    # Compare actual and expected outputs
    #
    # Args:
    #    actual: Actual output from the executable
    #    expected: Expected output
    #    ignore_whitespace: If True, normalize whitespace before comparison
    #
    #  Returns:
    #    True if outputs match, False otherwise

    if ignore_whitespace:
        actual = " ".join(actual.split())
        expected = " ".join(expected.split())

    return actual == expected


def generate_diff(
    actual: str,
    expected: str,
) -> str:
    # Generate a diff between actual and expected outputs
    #
    # Args:
    #   actual: Actual output
    #   expected: Expected output
    #
    # Returns:
    #   Diff as a string

    diff = difflib.ndiff(
        expected.splitlines(),
        actual.splitlines(),
    )
    return "\n".join(diff)


def test_executable(
    executable_path: str,
    args: List[str] = [],
    expected_output: str = "",
    input_data: str = "",
    filters: Optional[List[Callable[[str], str]]] = None,
    ignore_whitespace: bool = False,
) -> bool:
    # Test an executable by comparing its output to an expected output.
    #
    # Args:
    #   executable_path: Path to the executable.
    #   expected_output: Expected output.
    #   args: Command-line arguments.
    #   input_data: Input to pass via stdin.
    #   filters: List of filter functions.
    #   ignore_whitespace: If True, normalize whitespace before comparison.
    #
    # Returns:
    #   True if test passes, False otherwise.

    actual_output = run_executable(executable_path, args, input_data)
    filtered_output = filter_output(actual_output, filters)

    if compare_outputs(filtered_output, expected_output, ignore_whitespace):
        print("✅ passed")
        return True
    else:
        print("❌ failed")
        print("Diff exp->act:")
        print(generate_diff(filtered_output, expected_output))
        print()
        return False


# --- Reporting
ANSI_RED = "\033[31m"
ANSI_GREEN = "\033[32m"
ANSI_BLACK = "\033[m"


class TestReport:
    def __init__(self):
        self._testcnt = 0
        self._failcnt = 0

        report_fn = os.getenv("TLP_TEST_REPORT")
        if report_fn is None:
            new_report = True
        else:
            try:
                self._report_file = open(report_fn, "a")  # type: ignore[reportArgumentType]
                new_report = False
            except FileNotFoundError as e:
                sys.stderr.write(
                    f"Warning: given report file '{report_fn}' does not exist.\n"
                )
                sys.stderr.write(f"{e}\n")
                sys.stderr.write("Creating a new one instead.\n")
                new_report = True
            except IOError as e:
                sys.stderr.write(
                    f"Warning: could not open given report file '{report_fn}'.\n"
                )
                sys.stderr.write(f"{e}\n")
                sys.stderr.write("Creating a new one instead.\n")
                new_report = True

        if new_report:
            try:
                # Create temporary file
                self._report_file = tempfile.NamedTemporaryFile(
                    "w", prefix="tlp-test-report.", delete=False
                )
            except OSError as e:
                sys.stderr.write("Error: could not create report file.\n")
                sys.stderr.write(f"{e}\n")
                sys.exit(1)

        self._report_file.write(f"{os.path.basename(sys.argv[0]):<50} --> ")

    def count_test(self, errors: int):
        # Increment report counters
        #
        # Args:
        #   tested: number of tests run
        #   failed: number of failed tests
        self._testcnt += 1
        if errors > 0:
            self._failcnt += 1

    def print_line(self, line: str):
        # Write text line to stdout and report file
        #
        # Args:
        #   line: message text

        print(line)
        try:
            self._report_file.write(f"{line}\n")
        except IOError:
            pass  # Ignore write errors

    def print_result(self):
        # Write test result to terminal and report file,
        # then close the report file

        if self._failcnt == 0:
            self.print_line(
                f"{ANSI_GREEN}OK:{ANSI_BLACK} {self._testcnt} of {self._testcnt} tests passed\n"
            )
        else:
            self.print_line(
                f"{ANSI_GREEN}OK:{ANSI_BLACK} {self._failcnt} of {self._testcnt} tests failed\n"
            )

        self._report_file.close()
