# Makefile for TLP

SBIN  = $(DESTDIR)/usr/sbin
BIN   = $(DESTDIR)/usr/bin
PMETC = $(DESTDIR)/etc/pm/power.d
TLIB  = $(DESTDIR)/usr/lib/tlp-pm
PLIB  = $(DESTDIR)/usr/lib/pm-utils
ULIB  = $(DESTDIR)/lib/udev
NMDSP = $(DESTDIR)/etc/NetworkManager/dispatcher.d

# Location of TLP's config file
# Hint: solely changing this will render the installation unusable,
# you have to change constant definitions in scripts too!
CONFFILE = $(DESTDIR)/etc/default/tlp

all: 
	@/bin/true 

clean:
	@/bin/true 
	
install-tlp: 
	# Package tlp
	install -D -m 755 tlp $(SBIN)/tlp
	install -D -m 755 tlp-rf $(BIN)/bluetooth
	ln -f $(BIN)/bluetooth $(BIN)/wifi
	ln -f $(BIN)/bluetooth $(BIN)/wwan
	install -m 755 tlp-run-on $(BIN)/run-on-ac
	ln -f $(BIN)/run-on-ac $(BIN)/run-on-bat
	install -m 755 tlp-stat $(BIN)/
	install -m 755 tlp-usblist $(BIN)/
	install -D -m 755 tlp-functions $(TLIB)/tlp-functions
	install -m 755 tlp-rf-func $(TLIB)/
	install -m 755 tlp-nop $(TLIB)/
	install -D -m 755 tlp-usb-udev $(ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(ULIB)/rules.d/40-tlp.rules
	[ -f $(CONFFILE) ] || install -D -m 644 default $(CONFFILE)
	install -D -m 755 tlp.init $(DESTDIR)/etc/init.d/tlp
	install -D -m 755 zztlp $(PLIB)/power.d/zztlp
	install -D -m 755 49wwan $(PLIB)/sleep.d/49wwan
	install -m 755 49bay $(PLIB)/sleep.d/49bay
	install -D -m 644 tlp.desktop $(DESTDIR)/etc/xdg/autostart/tlp.desktop
	install -D -m 644 tlp.bash_completion $(DESTDIR)/etc/bash_completion.d/tlp

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
	rm $(TLIB)/tlp-functions
	rm $(TLIB)/tlp-rf-func
	rmdir $(TLIB)
	rm $(ULIB)/tlp-usb-udev
	rm $(ULIB)/rules.d/40-tlp.rules
	rm $(DESTDIR)/etc/init.d/tlp
	rm $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	rm $(PLIB)/power.d/zztlp
	rm $(PLIB)/sleep.d/49wwan
	rm $(PLIB)/sleep.d/49bay
	rm $(DESTDIR)/etc/xdg/autostart/tlp.desktop
	rm $(DESTDIR)/etc/bash_completion.d/tlp

uninstall-rdw: 	
	# Package tlp-rdw
	rm $(ULIB)/rules.d/40-tlp-rdw.rules
	rm $(ULIB)/tlp-rdw-udev
	rm $(NMDSP)/99tlp-rdw-nm
	
uninstall: uninstall-tlp uninstall-rdw
	
