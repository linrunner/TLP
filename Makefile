# Makefile for TLP

# Important: solely changing destination paths via parameter will
#   render the installation unusable. You have to change several
#   definitions and absolute paths in scripts too!

# Evaluate parameters
TLP_LIBDIR ?= /usr/lib
TLP_SBIN   ?= /usr/sbin
TLP_BIN    ?= /usr/bin
TLP_TLIB    = $(TLP_LIBDIR)/tlp-pm
TLP_PLIB    = $(TLP_LIBDIR)/pm-utils
TLP_ULIB   ?= /lib/udev
TLP_ACPI   ?= /etc/acpi
TLP_NMDSP  ?= /etc/NetworkManager/dispatcher.d
TLP_CONF   ?= /etc/default/tlp

# Catenate DESTDIR to paths
_SBIN  = $(DESTDIR)$(TLP_SBIN)
_BIN   = $(DESTDIR)$(TLP_BIN)
_TLIB  = $(DESTDIR)$(TLP_TLIB)
_PLIB  = $(DESTDIR)$(TLP_PLIB)
_ULIB  = $(DESTDIR)$(TLP_ULIB)
_ACPI  = $(DESTDIR)$(TLP_ACPI)
_NMDSP = $(DESTDIR)$(TLP_NMDSP)
_CONF  = $(DESTDIR)$(TLP_CONF)

# Make targets
all:
	@true

clean:
	@true

install-tlp:
	# Package tlp
	install -D -m 755 tlp $(_SBIN)/tlp
	install -D -m 755 tlp-rf $(_BIN)/bluetooth
	ln -sf bluetooth $(_BIN)/wifi
	ln -sf bluetooth $(_BIN)/wwan
	install -m 755 tlp-run-on $(_BIN)/run-on-ac
	ln -sf run-on-ac $(_BIN)/run-on-bat
	install -m 755 tlp-stat $(_BIN)/
	install -m 755 tlp-usblist $(_BIN)/
	install -m 755 tlp-pcilist $(_BIN)/
ifneq ($(TLP_NO_TPACPI),1)
	install -D -m 755 tpacpi-bat $(_TLIB)/tpacpi-bat
endif
	install -D -m 755 tlp-functions $(_TLIB)/tlp-functions
	install -m 755 tlp-rf-func $(_TLIB)/
	install -m 755 tlp-nop $(_TLIB)/
	install -D -m 755 tlp-usb-udev $(_ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(_ULIB)/rules.d/40-tlp.rules
	[ -f $(_CONF) ] || install -D -m 644 default $(_CONF)
ifneq ($(TLP_NO_INIT),1)
	install -D -m 755 tlp.init $(DESTDIR)/etc/init.d/tlp
endif
ifneq ($(TLP_NO_PMUTILS),1)
	install -D -m 755 49tlp $(_PLIB)/sleep.d/49tlp
endif
	install -D -m 644 thinkpad-radiosw $(_ACPI)/events/thinkpad-radiosw
	install -m 755 thinkpad-radiosw.sh $(_ACPI)/
ifneq ($(TLP_NO_BASHCOMP),1)
	install -D -m 644 tlp.bash_completion $(DESTDIR)/etc/bash_completion.d/tlp
endif

install-rdw:
	# Package tlp-rdw
	install -D -m 644 tlp-rdw.rules $(_ULIB)/rules.d/40-tlp-rdw.rules
	install -D -m 755 tlp-rdw-udev $(_ULIB)/tlp-rdw-udev
	install -D -m 755 tlp-rdw-nm $(_NMDSP)/99tlp-rdw-nm

install: install-tlp install-rdw

uninstall-tlp:
	# Package tlp
	rm $(_SBIN)/tlp
	rm $(_BIN)/bluetooth
	rm $(_BIN)/wifi
	rm $(_BIN)/wwan
	rm $(_BIN)/run-on-ac
	rm $(_BIN)/run-on-bat
	rm $(_BIN)/tlp-stat
	rm $(_BIN)/tlp-usblist
	rm $(_BIN)/tlp-pcilist
	rm -f $(_TLIB)/tpacpi-bat
	rm $(_TLIB)/tlp-functions
	rm $(_TLIB)/tlp-rf-func
	rmdir $(_TLIB)
	rm $(_ULIB)/tlp-usb-udev
	rm $(_ULIB)/rules.d/40-tlp.rules
	rm -f $(DESTDIR)/etc/init.d/tlp
	rm -f $(_PLIB)/sleep.d/49tlp
	rm $(_ACPI)/events/thinkpad-radiosw
	rm $(_ACPI)/thinkpad-radiosw.sh
	rm -f $(DESTDIR)/etc/bash_completion.d/tlp

uninstall-rdw:
	# Package tlp-rdw
	rm $(_ULIB)/rules.d/40-tlp-rdw.rules
	rm $(_ULIB)/tlp-rdw-udev
	rm $(_NMDSP)/99tlp-rdw-nm

uninstall: uninstall-tlp uninstall-rdw

