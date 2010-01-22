# Makefile for tlp

all: 
	@/bin/true 

clean:
	@/bin/true 
	
install: 
	install -m 755 tlp $(DESTDIR)/usr/sbin/
	install -m 755 tlp-rf $(DESTDIR)/usr/bin/bluetooth
	ln -f $(DESTDIR)/usr/bin/bluetooth $(DESTDIR)/usr/bin/wifi
	ln -f $(DESTDIR)/usr/bin/bluetooth $(DESTDIR)/usr/bin/wwan
	install -m 755 tlp-stat $(DESTDIR)/usr/bin/
	install -m 755 -d $(DESTDIR)/usr/lib/tlp
	install -m 755 tlp-functions $(DESTDIR)/usr/lib/tlp/
	install -m 755 tlp-rf-func $(DESTDIR)/usr/lib/tlp/
	[ -f $(DESTDIR)/etc/default/tlp ] || install -m 644 tlp-default $(DESTDIR)/etc/default/tlp
	install -m 755 tlp-if-up.d $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	install -m 755 tlp-power.d $(DESTDIR)/usr/lib/pm-utils/power.d/99tlp
	install -m 755 tlp-sleep.d $(DESTDIR)/usr/lib/pm-utils/sleep.d/49wwan
	install -m 755 tlp-usb-add $(DESTDIR)/lib/udev/
	install -m 644 tlp-usb.rules $(DESTDIR)/lib/udev/rules.d/85-tlp-usb.rules
	# [ -f $(DESTDIR)/etc/default/tlp-usb ] || install -m 644 tlp-def-usb $(DESTDIR)/etc/default/tlp-usb

uninstall: 
	rm $(DESTDIR)/usr/sbin/tlp
	rm $(DESTDIR)/usr/bin/bluetooth
	rm $(DESTDIR)/usr/bin/wifi
	rm $(DESTDIR)/usr/bin/wwan
	rm $(DESTDIR)/usr/bin/tlp-stat
	rm $(DESTDIR)/usr/lib/tlp/tlp-functions
	rm $(DESTDIR)/usr/lib/tlp/tlp-rf-func
	rmdir $(DESTDIR)/usr/lib/tlp
	# rm $(DESTDIR)/etc/default/tlp
	rm $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	rm $(DESTDIR)/usr/lib/pm-utils/power.d/99tlp
	rm $(DESTDIR)/usr/lib/pm-utils/sleep.d/49wwan
	rm $(DESTDIR)/lib/udev/tlp-usb-add
	rm $(DESTDIR)/lib/udev/rules.d/85-tlp-usb.rules
	# rm $(DESTDIR)/etc/default/tlp-usb
	
