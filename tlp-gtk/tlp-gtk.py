#!/usr/bin/python3
from gi.repository import Gtk

def f_g_c(filename):
    with open(filename) as f:
        return f.read().strip()

class MainWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title='The Linux Program?')

        box = Gtk.Box(spacing=6)
        self.add(box)

        self.listbox = Gtk.ListBox()
        box.pack_start(self.listbox, True, True, 0)

        self.resize(250,500)
        self.activity_mode = False

        self.update()

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

    def addToListbox(self, title, f):
        row, box = self.prepareListboxRow(title)

        label1 = Gtk.Label(f_g_c(f))
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

    def update(self):
        self.addToListbox('Cycle Count', '/sys/devices/platform/smapi/BAT0/cycle_count')

        designCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/design_capacity')
        lastFullCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/last_full_capacity')

        self.addPercentageToListbox('Battery Capacity',
            float(lastFullCapacityVal)/float(designCapacityVal),
            "%s of %s mW" % (lastFullCapacityVal, designCapacityVal)
        )

        remainingCapacityVal = f_g_c('/sys/devices/platform/smapi/BAT0/remaining_capacity')
        remainingPercentVal = f_g_c('/sys/devices/platform/smapi/BAT0/remaining_percent')

        self.addPercentageToListbox('Remaining Capacity',
            float(remainingPercentVal)/100.0,
            "%s of %s mW" % (remainingCapacityVal, lastFullCapacityVal)
        )


m = MainWindow()
m.connect("delete-event", Gtk.main_quit)
m.show_all()

Gtk.main()
