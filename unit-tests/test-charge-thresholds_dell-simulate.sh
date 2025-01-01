#!/bin/sh
export xinc="X_BAT_PLUGIN_SIMULATE=dell"
echo "******  xinc=${xinc}"
./charge-thresholds_dell
echo
sudo tlp setcharge BAT0  > /dev/null 2>&1 # reset test machine to configured thresholds
