#!/usr/bin/python3
from gi.repository import Gtk, GdkPixbuf
from plugins.utils import addToListbox, addPercentageToListbox, f_g_c
import os
import sys

class SystemOverview():
    def __init__(self):
        self.autoupdate=False

    def getHeader(self):
        return 'System Overview'

    def shouldDisplay(self):
        return True

    def getListboxRows(self):
        rows = []
        image = GdkPixbuf.Pixbuf.new_from_file_at_size(
            os.path.dirname(sys.argv[0])+'/images/%s.png' % f_g_c('/sys/devices/virtual/dmi/id/product_version'),
            250,
            250
        )
        rows.append(Gtk.Image.new_from_pixbuf(image))


        rows.append(addToListbox('Manufacturer', '/sys/devices/virtual/dmi/id/sys_vendor', True))
        rows.append(addToListbox('Model', '/sys/devices/virtual/dmi/id/product_version'))
        rows.append(addToListbox('Name', '/sys/devices/virtual/dmi/id/product_name'))
        rows.append(addToListbox('BIOS Version', '/sys/devices/virtual/dmi/id/bios_version'))
        #rows.append(addToListbox('Serial Number', '/sys/devices/virtual/dmi/id/product_serial'))
        rows.append(addToListbox('Operation System', ['lsb_release','-d','-s'], run=True))

        return rows
