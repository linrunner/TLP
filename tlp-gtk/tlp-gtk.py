#!/usr/bin/python3
from gi.repository import Gtk, GLib, GObject
import signal
import threading
import time

def f_g_c(filename):
    with open(filename) as f:
        return f.read().strip()

class MainWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title='Thinkpad Dashboard')

        box = Gtk.Box()
        self.add(box)

        self.listbox = Gtk.ListBox()
        box.pack_start(self.listbox, True, True, 0)

        self.resize(250,500)
        self.activity_mode = False

        self.updateBattery()

    def prepareListboxRow(self, title):
        row = Gtk.ListBoxRow()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=50)
        box.set_homogeneous(True)
        row.add(box)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.pack_start(vbox, False, True, 0)

        label1 = Gtk.Label(title)
        vbox.pack_start(label1, True, True, 0)

        return (row, box)

    def addToListbox(self, title, f, camelCase=False, frmt='%s'):
        row, box = self.prepareListboxRow(title)

        labelText = frmt % f_g_c(f) if not camelCase else f_g_c(f).title()
        label1 = Gtk.Label(labelText)
        box.pack_start(label1, True, True, 0)

        self.listbox.add(row)
    def addPercentageToListbox(self, title, percent, subtitle):
        row, box = self.prepareListboxRow(title)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        box.pack_start(vbox, False, True, 0)

        label1 = Gtk.Label(subtitle)

        progressBar = Gtk.ProgressBar()
        progressBar.set_fraction(percent)

        vbox.pack_start(progressBar, True, True, 0)
        vbox.pack_start(label1, True, True, 0)

        self.listbox.add(row)

    def updateBattery(self):
        children = self.listbox.get_children()
        for c in children:
            c.destroy()

        self.addToListbox('Manufacturer', '/sys/devices/platform/smapi/BAT0/manufacturer', True)
        self.addToListbox('Model', '/sys/devices/platform/smapi/BAT0/model')
        self.addToListbox('Cycle Count', '/sys/devices/platform/smapi/BAT0/cycle_count')

        self.addToListbox('Current state', '/sys/devices/platform/smapi/BAT0/state', True)
        stateVal = f_g_c('/sys/devices/platform/smapi/BAT0/state')
        if stateVal == 'charging':
            self.addToListbox('Remainging charging time',
                '/sys/devices/platform/smapi/BAT0/remaining_charging_time',
                frmt='%s minutes'
            )
        else:
            self.addToListbox('Remainging running time',
                '/sys/devices/platform/smapi/BAT0/remaining_running_time_now',
                frmt='%s minutes'
            )

        designCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/design_capacity')
        lastFullCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/last_full_capacity')

        self.addPercentageToListbox('Battery Capacity',
            float(lastFullCapacityVal)/float(designCapacityVal),
            "%s of %s mWh" % (lastFullCapacityVal, designCapacityVal)
        )

        remainingCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/remaining_capacity')
        remainingPercentVal = f_g_c('/sys/devices/platform/smapi/BAT0/remaining_percent')

        self.addPercentageToListbox('Remaining Charge',
            float(remainingPercentVal)/100.0,
            "%s of %s mWh" % (remainingCapacityVal, lastFullCapacityVal)
        )

        for i in range(4):
            groupVoltageVal = int(f_g_c('/sys/devices/platform/smapi/BAT0/group%s_voltage' % str(i)))
            if groupVoltageVal > 0:
                self.addPercentageToListbox('Cell Group %s Voltage' % str(i),
                    float(groupVoltageVal-3800)/400.0,
                    "%s mV" % groupVoltageVal
                )

        self.show_all()

GObject.threads_init()
m = MainWindow()
m.connect("delete-event", Gtk.main_quit)
m.show_all()

def updateUI():
    while True:
        GLib.idle_add(m.updateBattery)
        time.sleep(2)

thread = threading.Thread(target=updateUI)
thread.daemon = True
thread.start()

signal.signal(signal.SIGINT, signal.SIG_DFL)
Gtk.main()

# And so on, and so forth. A split view like gtk-tweak-tool would be nice.
