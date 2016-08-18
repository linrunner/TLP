# Makefile for TLP

# Evaluate parameters
TLP_SBIN   ?= /usr/sbin
TLP_BIN    ?= /usr/bin
TLP_TLIB   ?= /usr/share/tlp-pm
TLP_PLIB   ?= /usr/lib/pm-utils
TLP_ULIB   ?= /lib/udev
TLP_NMDSP  ?= /etc/NetworkManager/dispatcher.d
TLP_CONF   ?= /etc/default/tlp
TLP_SYSD   ?= /lib/systemd/system
TLP_SHCPL  ?= /usr/share/bash-completion/completions
TLP_MAN    ?= /usr/share/man

# Catenate DESTDIR to paths
_SBIN  = $(DESTDIR)$(TLP_SBIN)
_BIN   = $(DESTDIR)$(TLP_BIN)
_TLIB  = $(DESTDIR)$(TLP_TLIB)
_PLIB  = $(DESTDIR)$(TLP_PLIB)
_ULIB  = $(DESTDIR)$(TLP_ULIB)
_NMDSP = $(DESTDIR)$(TLP_NMDSP)
_CONF  = $(DESTDIR)$(TLP_CONF)
_SYSD  = $(DESTDIR)$(TLP_SYSD)
_SHCPL = $(DESTDIR)$(TLP_SHCPL)
_MAN   = $(DESTDIR)$(TLP_MAN)

SED = sed \
	-e "s|@TLP_SBIN@|$(TLP_SBIN)|g" \
	-e "s|@TLP_TLIB@|$(TLP_TLIB)|g" \
	-e "s|@TLP_PLIB@|$(TLP_PLIB)|g" \
	-e "s|@TLP_ULIB@|$(TLP_ULIB)|g" \
	-e "s|@TLP_CONF@|$(TLP_CONF)|g"

INFILES = \
	tlp \
	tlp-functions \
	tlp-nop \
	tlp-rdw-nm \
	tlp-rdw.rules \
	tlp-rdw-udev \
	tlp-rf \
	tlp.rules \
	tlp-run-on \
	tlp.service \
	tlp-sleep.service \
	tlp-stat \
	tlp.upstart \
	tlp-usb-udev

# Make targets
all: $(INFILES)

$(INFILES): %: %.in
	$(SED) $< > $@

clean:
	rm -f $(INFILES)

install-tlp: all
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
	install -D -m 755 tlp-usb-udev $(_ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(_ULIB)/rules.d/85-tlp.rules
	[ -f $(_CONF) ] || install -D -m 644 default $(_CONF)
ifneq ($(TLP_NO_INIT),1)
	install -D -m 755 tlp.init $(DESTDIR)/etc/init.d/tlp
endif
ifeq ($(TLP_WITH_SYSTEMD),1)
	install -D -m 644 tlp.service $(_SYSD)/tlp.service
	install -m 644 tlp-sleep.service $(_SYSD)/
endif
ifneq ($(TLP_NO_PMUTILS),1)
	install -m 755 tlp-nop $(_TLIB)/
	install -D -m 755 49tlp $(_PLIB)/sleep.d/49tlp
endif
ifneq ($(TLP_NO_BASHCOMP),1)
	install -D -m 644 tlp.bash_completion $(_SHCPL)/tlp
	ln -sf tlp $(_SHCPL)/tlp-stat
	ln -sf tlp $(_SHCPL)/bluetooth
	ln -sf tlp $(_SHCPL)/wifi
	ln -sf tlp $(_SHCPL)/wwan
endif

install-rdw: all
	# Package tlp-rdw
	install -D -m 644 tlp-rdw.rules $(_ULIB)/rules.d/85-tlp-rdw.rules
	install -D -m 755 tlp-rdw-udev $(_ULIB)/tlp-rdw-udev
	install -D -m 755 tlp-rdw-nm $(_NMDSP)/99tlp-rdw-nm

install-man:
	# manpages
	install -d -m 755 $(_MAN)/man1
	install -m 644 man/{bluetooth,run-on-ac,run-on-bat,wifi,wwan}.1 $(_MAN)/man1/
	install -d -m 755 $(_MAN)/man8
	install -m 644 man/{tlp,tlp-stat}.8 $(_MAN)/man8/

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
	rm $(_TLIB)/tlp-nop
	rmdir $(_TLIB)
	rm $(_ULIB)/tlp-usb-udev
	rm $(_ULIB)/rules.d/85-tlp.rules
	rm -f $(DESTDIR)/etc/init.d/tlp
	rm -f $(_SYSD)/tlp.service
	rm -f $(_SYSD)/tlp-sleep.service
	rm -f $(_PLIB)/sleep.d/49tlp
	rm -f $(_SHCPL)/tlp-stat
	rm -f $(_SHCPL)/bluetooth
	rm -f $(_SHCPL)/wifi
	rm -f $(_SHCPL)/wwan
	rm -f $(_SHCPL)/tlp

uninstall-rdw:
	# Package tlp-rdw
	rm $(_ULIB)/rules.d/85-tlp-rdw.rules
	rm $(_ULIB)/tlp-rdw-udev
	rm $(_NMDSP)/99tlp-rdw-nm

uninstall-man:
	# manpages
	rm $(_MAN)/man1/{bluetooth,run-on-ac,run-on-bat,wifi,wwan}.1
	rm $(_MAN)/man8/{tlp,tlp-stat}.8

uninstall: uninstall-tlp uninstall-rdw

