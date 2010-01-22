#!/bin/sh
IWC=/sbin/iwconfig
TLP=/usr/sbin/tlp

[ -x $IWC ] || exit 0
[ -x $TLP ] || exit 0

if [ -z $($IWC $IFACE | grep "no wireless extensions") ]; then
    # interface is wifi
    $TLP wifi
fi

exit 0
