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
	[ -f $(DESTDIR)/etc/default/tlp ] || install -m 644 default $(DESTDIR)/etc/default/tlp
	install -m 755 tlp-ifup $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	install -m 755 99tlp $(DESTDIR)/usr/lib/pm-utils/power.d/99tlp
	install -m 755 49wwan $(DESTDIR)/usr/lib/pm-utils/sleep.d/49wwan
	install -m 644 tlp.desktop $(DESTDIR)/etc/xdg/autostart/tlp.desktop

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
	rm $(DESTDIR)/etc/xdg/autostart/tlp.desktop
	
