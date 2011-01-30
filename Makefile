# Makefile for tlp

SBIN  = $(DESTDIR)/usr/sbin
BIN   = $(DESTDIR)/usr/bin
PMETC = $(DESTDIR)/etc/pm/power.d
TLIB  = $(DESTDIR)/usr/lib/tlp-pm
TLREL = ../../../usr/lib/tlp-pm
PLIB  = $(DESTDIR)/usr/lib/pm-utils

all: 
	@/bin/true 

clean:
	@/bin/true 
	
install: 
	install -m 755 tlp $(SBIN)/
	install -m 755 tlp-rf $(BIN)/bluetooth
	ln -f $(BIN)/bluetooth $(BIN)/wifi
	ln -f $(BIN)/bluetooth $(BIN)/wwan
	install -m 755 tlp-run-on $(BIN)/run-on-ac
	ln -f $(BIN)/run-on-ac $(BIN)/run-on-bat
	install -m 755 tlp-stat $(BIN)/
	install -m 755 -d $(TLIB)
	install -m 755 tlp-functions $(TLIB)/
	install -m 755 tlp-rf-func $(TLIB)/
	install -m 755 tlp-nop $(TLIB)/
	[ -f $(DESTDIR)/etc/default/tlp ] || install -m 644 default $(DESTDIR)/etc/default/tlp
	install -m 755 tlp.init $(DESTDIR)/etc/init.d/tlp
	install -m 755 tlp-ifup $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	install -m 755 zztlp $(PLIB)/power.d/zztlp
	install -m 755 49wwan $(PLIB)/sleep.d/49wwan
	install -m 755 49bay $(PLIB)/sleep.d/49bay
	install -m 644 tlp.desktop $(DESTDIR)/etc/xdg/autostart/tlp.desktop
#	cd $(PMETC) ; \
#	  ln -s $(TLREL)/tlp-nop 95hdparm-apm ; \
#	  ln -s $(TLREL)/tlp-nop disable_wol ; \
#	  ln -s $(TLREL)/tlp-nop intel-audio-powersave ; \
#	  ln -s $(TLREL)/tlp-nop laptop-mode ; \
#	  ln -s $(TLREL)/tlp-nop journal-commit ; \
#	  ln -s $(TLREL)/tlp-nop pcie_aspm ; \
#	  ln -s $(TLREL)/tlp-nop sata_alpm ; \
#	  ln -s $(TLREL)/tlp-nop wireless ; \
#	  ln -s $(TLREL)/tlp-nop xfs_buffer
	  

uninstall: 
	rm $(SBIN)/tlp
	rm $(BIN)/bluetooth
	rm $(BIN)/wifi
	rm $(BIN)/wwan
	rm $(BIN)/run-on-ac
	rm $(BIN)/run-on-bat
	rm $(BIN)/tlp-stat
	rm $(TLIB)/tlp-functions
	rm $(TLIB)/tlp-rf-func
	rmdir $(TLIB)
	# rm $(DESTDIR)/etc/default/tlp
	rm $(DESTDIR)/etc/init.d/tlp
	rm $(DESTDIR)/etc/network/if-up.d/tlp-ifup
	rm $(PLIB)/power.d/zztlp
	rm $(PLIB)/sleep.d/49wwan
	rm $(PLIB)/sleep.d/49bay
	rm $(DESTDIR)/etc/xdg/autostart/tlp.desktop
#	rm $(PMETC)/95hdparm-apm
#	rm $(PMETC)/hal-cd-polling 
#	rm $(PMETC)/intel-audio-powersave 
#	rm $(PMETC)/laptop-mode 
#	rm $(PMETC)/journal-commit 
#	rm $(PMETC)/pcie_aspm 
#	rm $(PMETC)/sata_alpm 
#	rm $(PMETC)/wireless 
#	rm $(PMETC)/xfs_buffer 
	
