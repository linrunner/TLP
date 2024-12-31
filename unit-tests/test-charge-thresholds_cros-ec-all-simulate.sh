#!/bin/sh
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

sudo tlp setcharge ${bata} 35 100 > /dev/null 2>&1 # preset start threshold for simulation
export xinc="X_BAT_PLUGIN_SIMULATE=cros-ec X_BAT_CROSCC_SIMULATE_ECVER=2"
echo "******  bata=${bata} batb=${batb} xinc=${xinc}"
./charge-thresholds_cros-ec-v2
echo
sudo tlp setcharge ${bata} 35 100 > /dev/null 2>&1 # # preset start threshold for simulation
export xinc="X_BAT_PLUGIN_SIMULATE=framework"
echo "******  bata=${bata} batb=${batb} xinc=${xinc}"
./charge-thresholds_cros-ec-v2
echo
export xinc="X_BAT_PLUGIN_SIMULATE=cros-ec"
echo "******  bata=${bata} batb=${batb} xinc=${xinc}"
./charge-thresholds_cros-ec-v3
echo
sudo tlp setcharge ${bata}  > /dev/null 2>&1 # reset test machine to configured thresholds
