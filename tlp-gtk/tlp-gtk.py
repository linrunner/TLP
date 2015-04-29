#!/usr/bin/python3
from gi.repository import Gtk, GLib, GObject
import signal
import threading
import time
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop

DBusGMainLoop(set_as_default=True)

bus = dbus.SessionBus()
if bus.name_has_owner("org.tlp.thinkvantage"):
    proxy = bus.get_object('org.tlp.thinkvantage', '/org/tlp/thinkvantage')
    proxy.get_dbus_method('bringWindowToFocus', 'org.tlp.thinkvantage')()
    sys.exit(0)

def f_g_c(filename):
    with open(filename) as f:
        return f.read().strip()

class MainWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title='ThinkVantage Dashboard')

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
        elif stateVal == 'idle':
            pass
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
        time.sleep(5)

thread = threading.Thread(target=updateUI)
thread.daemon = True
thread.start()

class MyDBUSService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.tlp.thinkvantage', bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/org/tlp/thinkvantage')

    @dbus.service.method('org.tlp.thinkvantage')
    def bringWindowToFocus(self):
        print('bringWindowToFocus received')
        m.present()
myservice = MyDBUSService()

signal.signal(signal.SIGINT, signal.SIG_DFL)
Gtk.main()

# And so on, and so forth. A split view like gtk-tweak-tool would be nice.

# If you want to be really fancy-shmancy, link it to the ThinkVantage button:
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'ThinkVantage'
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding 'Launch1'
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "python3 /path/to/tlp-gtk.py"
