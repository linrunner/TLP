# Makefile for TLP

ifndef LIBDIR_NAME
	LIBDIR_NAME = lib
endif
LIBDIR = $(DESTDIR)/usr/$(LIBDIR_NAME)

ifndef SBIN
	SBIN  = $(DESTDIR)/usr/sbin
else
	SBIN  = $(DESTDIR)$(SBIN)
endif
BIN   = $(DESTDIR)/usr/bin
TLIB  = $(LIBDIR)/tlp-pm
PLIB  = $(LIBDIR)/pm-utils
ifndef ULIB
	ULIB  = $(DESTDIR)/lib/udev
else
	ULIB  = $(DESTDIR)$(ULIB)
endif
ACPI  = $(DESTDIR)/etc/acpi
NMDSP = $(DESTDIR)/etc/NetworkManager/dispatcher.d

# Location of TLP's config file
# Hint: solely changing this will render the installation unusable,
# you have to change constant definitions in scripts too!
CONFFILE = $(DESTDIR)/etc/default/tlp

all:
	@true

clean:
	@true

install-tlp:
	# Package tlp
	install -D -m 755 tlp $(SBIN)/tlp
	install -D -m 755 tlp-rf $(BIN)/bluetooth
	(cd $(BIN); ln -sf bluetooth wifi; ln -s bluetooth wwan)
	install -m 755 tlp-run-on $(BIN)/run-on-ac
	(cd $(BIN); ln -sf run-on-ac run-on-bat)
	install -m 755 tlp-stat $(BIN)/
	install -m 755 tlp-usblist $(BIN)/
	install -m 755 tlp-pcilist $(BIN)/
ifneq ($(TLP_NO_TPACPI),1)
	install -D -m 755 tpacpi-bat $(TLIB)/tpacpi-bat
endif
	install -D -m 755 tlp-functions $(TLIB)/tlp-functions
	install -m 755 tlp-rf-func $(TLIB)/
	install -m 755 tlp-nop $(TLIB)/
	install -D -m 755 tlp-usb-udev $(ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(ULIB)/rules.d/40-tlp.rules
	[ -f $(CONFFILE) ] || install -D -m 644 default $(CONFFILE)
ifneq ($(TLP_NO_INIT),1)
	install -D -m 755 tlp.init $(DESTDIR)/etc/init.d/tlp
endif
ifneq ($(TLP_NO_PMUTILS),1)
	install -D -m 755 49tlp $(PLIB)/sleep.d/49tlp
endif
	install -D -m 644 thinkpad-radiosw $(ACPI)/events/thinkpad-radiosw
	install -m 755 thinkpad-radiosw.sh $(ACPI)/
ifneq ($(TLP_NO_BASHCOMP),1)
	install -D -m 644 tlp.bash_completion $(DESTDIR)/etc/bash_completion.d/tlp
endif

install-rdw:
	# Package tlp-rdw
	install -D -m 644 tlp-rdw.rules $(ULIB)/rules.d/40-tlp-rdw.rules
	install -D -m 755 tlp-rdw-udev $(ULIB)/tlp-rdw-udev
	install -D -m 755 tlp-rdw-nm $(NMDSP)/99tlp-rdw-nm

install: install-tlp install-rdw

uninstall-tlp:
	# Package tlp
	rm $(SBIN)/tlp
	rm $(BIN)/bluetooth
	rm $(BIN)/wifi
	rm $(BIN)/wwan
	rm $(BIN)/run-on-ac
	rm $(BIN)/run-on-bat
	rm $(BIN)/tlp-stat
	rm $(BIN)/tlp-usblist
	rm $(BIN)/tlp-pcilist
	rm -f $(TLIB)/tpacpi-bat
	rm $(TLIB)/tlp-functions
	rm $(TLIB)/tlp-rf-func
	rmdir $(TLIB)
	rm $(ULIB)/tlp-usb-udev
	rm $(ULIB)/rules.d/40-tlp.rules
	rm -f $(DESTDIR)/etc/init.d/tlp
	rm $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	rm -f $(PLIB)/sleep.d/49tlp
	rm $(ACPI)/events/thinkpad-radiosw
	rm $(ACPI)/thinkpad-radiosw.sh
	rm -f $(DESTDIR)/etc/bash_completion.d/tlp

uninstall-rdw:
	# Package tlp-rdw
	rm $(ULIB)/rules.d/40-tlp-rdw.rules
	rm $(ULIB)/tlp-rdw-udev
	rm $(NMDSP)/99tlp-rdw-nm

uninstall: uninstall-tlp uninstall-rdw

