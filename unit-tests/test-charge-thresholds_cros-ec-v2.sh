#!/bin/sh
CLI=./charge-thresholds_cros-ec-v2

if [ -d /sys/class/power_supply/BAT0/ ]; then
    export bata=BAT0
    export batb=BAT1
elif [ -d /sys/class/power_supply/BAT1/ ]; then
    export bata=BAT1
    export batb=BAT0
else
    echo "Error: neither BAT0 nor BAT1 exists." 1>&2
    exit 1
fi

if [ -f $CLI ]; then
    $CLI
else
    echo "Error: clitest file $CLI not found." 1>&2
    exit 1
fi
