#!/usr/bin/python3
from gi.repository import Gtk, GLib, GObject, Gdk
import signal
import threading
import time
import sys
import os
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop

from plugins.Batteries import Battery
from plugins.SystemOverview import SystemOverview

PLUGINS = [
    SystemOverview(),
    Battery(0),
    Battery(1)
]

DBusGMainLoop(set_as_default=True)

bus = dbus.SessionBus()
if bus.name_has_owner("org.tlp.thinkvantage"):
    proxy = bus.get_object('org.tlp.thinkvantage', '/org/tlp/thinkvantage')
    proxy.get_dbus_method('bringWindowToFocus', 'org.tlp.thinkvantage')()
    sys.exit(0)

class MainWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title='ThinkVantage Dashboard')
        self.set_wmclass ("ThinkVantage", "ThinkVantage")

        settings = Gtk.Settings.get_default()
        settings.set_property('gtk-application-prefer-dark-theme', True)
        self.set_icon_from_file(os.path.dirname(sys.argv[0])+'/icons/256x256.png')

        paned = Gtk.Paned()
        paned.set_position(200)
        self.add(paned)

        divisionBox = Gtk.ListBox()
        divisionBox.set_activate_on_single_click(True)
        divisionBox.connect('row-activated', self.rowClicked)
        paned.add1(divisionBox)

        for plugin in PLUGINS:
            if not plugin.shouldDisplay():
                PLUGINS.remove(plugin)
                continue

            row = Gtk.ListBoxRow()
            label = Gtk.Label(plugin.getHeader())
            row.add(label)
            divisionBox.add(row)

        self.plugin = PLUGINS[0]
        self.thread = threading.Thread(target=self.updateUI)
        self.thread.daemon = True
        self.thread.start()

        box = Gtk.Box(spacing=12)
        paned.add2(box)
        self.listbox = Gtk.ListBox()
        box.pack_start(self.listbox, True, True, 0)

        self.resize(900,450)
        self.activity_mode = False

        self.updateListbox()

    def updateUI(self):
        while True:
            if self.plugin.autoupdate:
                GLib.idle_add(self.updateListbox)
            time.sleep(5)

    def rowClicked(self, listbox, row):
        self.plugin = PLUGINS[row.get_index()]
        self.updateListbox()

    def updateListbox(self):
        children = self.listbox.get_children()
        for c in children:
            c.destroy()

        for row in self.plugin.getListboxRows():
            self.listbox.add(row)
            row = self.listbox.get_children()[-1]
            row.set_selectable(False)
            row.set_activatable(False)


        self.show_all()


GObject.threads_init()
m = MainWindow()
m.connect("delete-event", Gtk.main_quit)
#m.show_all()

class MyDBUSService(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.tlp.thinkvantage', bus=dbus.SessionBus())
        dbus.service.Object.__init__(self, bus_name, '/org/tlp/thinkvantage')

    @dbus.service.method('org.tlp.thinkvantage')
    def bringWindowToFocus(self):
        print('bringWindowToFocus received')
        m.show()
        m.present()
myservice = MyDBUSService()

signal.signal(signal.SIGINT, signal.SIG_DFL)
Gtk.main()

# If you want to be real fancy-shmancy, link it to the ThinkVantage button:
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'ThinkVantage'
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding 'Launch1'
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "python3 /path/to/tlp-gtk.py"
