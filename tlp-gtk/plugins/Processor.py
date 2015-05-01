#!/usr/bin/python3
from gi.repository import Gtk
from plugins.utils import addToListbox, addPercentageToListbox, f_g_c

import subprocess

class Processor():
    def __init__(self):
        # Perform basic initialization
        self.autoupdate = 3

    def getHeader(self):
        # Return a title as shown in the sidebar
        return 'Processor'

    def shouldDisplay(self):
        # Perform checks whether this plugin is available on this ThinkPad
        return True

    def _parseShell(self, cmd):
        toReturn = {}
        output = subprocess.check_output(cmd, shell=True).decode('utf-8')

        for line in output.split('\n'):
            try:
                info = line.split(':')
                toReturn[info[0].strip()] = info[1].strip()
            except: continue

        return toReturn

    def _lscpu(self):
        return self._parseShell('lscpu')

    def _fans(self):
        return self._parseShell('sensors thinkpad-isa-0000')

    def getListboxRows(self):
        # Return a list of GtkWidgets for the main area
        rows = []

        lscpu = self._lscpu()

        rows.append(addToListbox('Model name', lscpu['Model name'].split('CPU @')[0], plain=True))
        rows.append(addToListbox('Number of cores', int(lscpu['Core(s) per socket'])*int(lscpu['Socket(s)']), plain=True))
        rows.append(addToListbox('Threads per core', int(lscpu['Thread(s) per core']), plain=True))

        rows.append(addToListbox('L3 cache', float(lscpu['L3 cache'][:-1])/1024, frmt='%.fM', plain=True))
        rows.append(addToListbox('Architecture', lscpu['Architecture'], plain=True))


        for key,value in self._fans().items():
            rows.append(addToListbox('Speed '+key, value, plain=True))

        rows.append(addPercentageToListbox('CPU frequency',
                (float(lscpu['CPU MHz'])-float(lscpu['CPU min MHz']))/(float(lscpu['CPU max MHz'])-float(lscpu['CPU min MHz'])),
                "%.0f/%.0f MHz" % (float(lscpu['CPU MHz']), float(lscpu['CPU max MHz']))
        ))

        return rows
