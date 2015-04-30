#!/usr/bin/python3
from gi.repository import Gtk, GLib, GdkPixbuf
from plugins.utils import addToListbox, addPercentageToListbox, prepareListboxRow, f_g_c
import os
import sys
from urllib import request
import re
import threading
from distutils.version import StrictVersion
import webbrowser

class SystemOverview():
    def __init__(self):
        self.autoupdate=False

    def getHeader(self):
        return 'System Overview'

    def shouldDisplay(self):
        return True

    def runBIOSDialog(self):
        self.dialog_response = self.dialog.run()
        self.dialog.destroy()

        if self.dialog_response == Gtk.ResponseType.OK:
            webbrowser.open(self.bios_url,2)

    def _checkBIOS(self):
        try:
            name = f_g_c('/sys/devices/virtual/dmi/id/product_name')
            version = f_g_c('/sys/devices/virtual/dmi/id/bios_version')
            version = version.split('(')[1].split(')')[0].strip()
            html = request.urlopen(
            'http://support.lenovo.com/services/us/en/advancedsearch/getsearchresult/1c2d5342-a15b-4828-9095-13e5d52f9df6?dataSource=aca55143-0507-4b4d-a559-65147c1dec9a&SearchKey=%s' % name
            ).read()
            url = re.compile(b'<a href="(.*?)">(.*?)</a>').search(html).groups(0)[0].decode('utf-8')

            url = '/'.join(url.split('/')[4:])
            url = "http://support.lenovo.com/services/us/en/productdownload/getdownloadslister/b0f3479a-80db-493f-98c4-42714329d612?pageNumber=1&bySortOrder=Ascending&ProductSelection="+url+"&DataSource=ce8a46b7-b51e-4970-8659-bd20c7626d8e&SelectCategory=driver-and-software%2Fbios&ProductSelection="+url+"&BySortOrderCategory=Ascending&BySortOrder=Descend"
            html = request.urlopen(url).read().decode('utf-8')

            files = re.compile(r'<div class="cell4">.*?<a href="(.*?)".*?>(.*?)</a>.*?<div class="cell3">(.*?)</div>', re.DOTALL)
            files = files.findall(html)

            for u in files:
                if not 'BIOS Update' in u[1]:
                    continue

                if StrictVersion(u[2].strip()) > StrictVersion(version):
                    self.dialog = Gtk.MessageDialog(
                        None, 0, Gtk.MessageType.INFO,
                        Gtk.ButtonsType.OK_CANCEL,
                        'BIOS Update Available',
                    )
                    self.dialog.format_secondary_text(
                        "There is a BIOS update available:\nCurrent Version: "+version+'\nAvailable Update: '+u[2].strip()+"\n\nDo you want to go to Lenovo.com and download the update?"
                    )
                    self.bios_url = u[0] if u[0].startswith('http') else 'http://support.lenovo.com'+u[0]

                    GLib.idle_add(self.runBIOSDialog)
        except: pass

        GLib.idle_add(self.bios_spinner.destroy)


    def BIOSRow(self):
        bios_version = f_g_c('/sys/devices/virtual/dmi/id/bios_version')
        bios_row, grid = prepareListboxRow('BIOS Version')

        label1 = Gtk.Label(bios_version)
        label1.set_margin_end(4)

        box = Gtk.Box()
        box.add(label1)
        box.set_margin_start(9)

        self.bios_spinner = Gtk.Spinner()
        self.bios_spinner.start()
        box.add(self.bios_spinner)

        grid.attach(box,8,13,0,1)

        self.thread = threading.Thread(target=self._checkBIOS)
        self.thread.daemon = True
        self.thread.start()

        return bios_row

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

        rows.append(self.BIOSRow())
        #rows.append(addToListbox('Serial Number', '/sys/devices/virtual/dmi/id/product_serial'))
        rows.append(addToListbox('Operation System', ['lsb_release','-d','-s'], run=True))

        return rows
