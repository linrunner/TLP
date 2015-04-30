#!/usr/bin/python3
from gi.repository import Gtk
from plugins.utils import addToListbox, addPercentageToListbox, f_g_c

class Battery():
    def __init__(self, battery):
        self.bat = battery
        self.autoupdate = True

    def getHeader(self):
        if self.bat != 1: return 'Main Battery'
        return 'Secondary Battery'

    def shouldDisplay(self):
        return int(f_g_c('/sys/devices/platform/smapi/BAT%s/installed' % self.bat)) == 1

    def getListboxRows(self):
        rows = []

        rows.append(addToListbox('Manufacturer', '/sys/devices/platform/smapi/BAT%s/manufacturer' % self.bat, True))
        rows.append(addToListbox('Model', '/sys/devices/platform/smapi/BAT%s/model' % self.bat))

        rows.append(addToListbox('Cycle Count', '/sys/devices/platform/smapi/BAT%s/cycle_count' % self.bat))

        temperatureVal = f_g_c('/sys/devices/platform/smapi/BAT%s/temperature' % self.bat)
        row = rows.append(addToListbox('Temperature', int(temperatureVal)/1000, frmt='%d°C', plain=True))

        rows.append(addToListbox('Current state', '/sys/devices/platform/smapi/BAT%s/state' % self.bat, True))
        stateVal = f_g_c('/sys/devices/platform/smapi/BAT%s/state' % self.bat)
        if stateVal == 'charging':
            rows.append(addToListbox('Remainging charging time',
                '/sys/devices/platform/smapi/BAT%s/remaining_charging_time' % self.bat,
                frmt='%s minutes'
            ))
        elif stateVal == 'idle':
            pass
        else:
            rows.append(addToListbox('Remainging running time',
                '/sys/devices/platform/smapi/BAT%s/remaining_running_time_now' % self.bat,
                frmt='%s minutes'
            ))

        designCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT%s/design_capacity' % self.bat)
        lastFullCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT%s/last_full_capacity' % self.bat)
        remainingCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT%s/remaining_capacity' % self.bat)
        remainingPercentVal = f_g_c('/sys/devices/platform/smapi/BAT%s/remaining_percent' % self.bat)

        rows.append(addPercentageToListbox('Battery Health',
            float(lastFullCapacityVal)/float(designCapacityVal),
            "%s of %s mWh" % (lastFullCapacityVal, designCapacityVal)
        ))

        rows.append(addPercentageToListbox('Remaining Charge',
            float(remainingPercentVal)/100.0,
            "%s of %s mWh" % (remainingCapacityVal, lastFullCapacityVal)
        ))

        voltageVal = int(f_g_c('/sys/devices/platform/smapi/BAT%s/voltage' % self.bat))
        rows.append(addPercentageToListbox('Battery Voltage',
            float(voltageVal-10200)/2400.0,
            "%s mV" % voltageVal
        ))

        for i in range(4):
            groupVoltageVal = int(f_g_c('/sys/devices/platform/smapi/BAT%s/group%s_voltage' % (self.bat, str(i))))
            if groupVoltageVal > 0:
                rows.append(addPercentageToListbox('Voltage Cell Group %s' % str(i),
                    float(groupVoltageVal-3400)/800.0,
                    "%s mV" % groupVoltageVal
                ))

        return rows
