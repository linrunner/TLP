# Makefile for TLP

# Evaluate parameters
TLP_SBIN   ?= /usr/sbin
TLP_BIN    ?= /usr/bin
TLP_TLIB   ?= /usr/share/tlp
TLP_FLIB   ?= /usr/share/tlp/func.d
TLP_ULIB   ?= /lib/udev
TLP_NMDSP  ?= /etc/NetworkManager/dispatcher.d
TLP_CONF   ?= /etc/default/tlp
TLP_SYSD   ?= /lib/systemd/system
TLP_SDSL   ?= /lib/systemd/system-sleep
TLP_SYSV   ?= /etc/init.d
TLP_ELOD   ?= /lib/elogind/system-sleep
TLP_SHCPL  ?= /usr/share/bash-completion/completions
TLP_MAN    ?= /usr/share/man
TLP_META   ?= /usr/share/metainfo
TLP_RUN    ?= /run/tlp
TLP_RUNCONF    ?= /run/tlp/tlp.conf
TLP_VAR    ?= /var/lib/tlp
TLP_CUSTOMIZE    ?= /etc/tlp.conf.d

# Catenate DESTDIR to paths
_SBIN  = $(DESTDIR)$(TLP_SBIN)
_BIN   = $(DESTDIR)$(TLP_BIN)
_TLIB  = $(DESTDIR)$(TLP_TLIB)
_FLIB  = $(DESTDIR)$(TLP_FLIB)
_ULIB  = $(DESTDIR)$(TLP_ULIB)
_NMDSP = $(DESTDIR)$(TLP_NMDSP)
_CONF  = $(DESTDIR)$(TLP_CONF)
_SYSD  = $(DESTDIR)$(TLP_SYSD)
_SDSL  = $(DESTDIR)$(TLP_SDSL)
_SYSV  = $(DESTDIR)$(TLP_SYSV)
_ELOD  = $(DESTDIR)$(TLP_ELOD)
_SHCPL = $(DESTDIR)$(TLP_SHCPL)
_MAN   = $(DESTDIR)$(TLP_MAN)
_META  = $(DESTDIR)$(TLP_META)
_RUN   = $(DESTDIR)$(TLP_RUN)
_VAR   = $(DESTDIR)$(TLP_VAR)

SED = sed \
	-e "s|@TLP_SBIN@|$(TLP_SBIN)|g" \
	-e "s|@TLP_TLIB@|$(TLP_TLIB)|g" \
	-e "s|@TLP_FLIB@|$(TLP_FLIB)|g" \
	-e "s|@TLP_ULIB@|$(TLP_ULIB)|g" \
	-e "s|@TLP_CONF@|$(TLP_CONF)|g" \
	-e "s|@TLP_CUSTOMIZE@|$(TLP_CUSTOMIZE)|g" \
	-e "s|@TLP_RUN@|$(TLP_RUN)|g"   \
	-e "s|@TLP_RUNCONF@|$(TLP_RUNCONF)|g"   \
	-e "s|@TLP_VAR@|$(TLP_VAR)|g"

INFILES = \
	tlp \
	tlp-func-base \
	tlp-rdw-nm \
	tlp-rdw.rules \
	tlp-rdw-udev \
	tlp-rdw \
	tlp-rf \
	tlp.rules \
	tlp-run-on \
	tlp.service \
	tlp-stat \
	tlp.upstart \
	tlp-usb-udev

MANFILES1 = \
	bluetooth.1 \
	run-on-ac.1 \
	run-on-bat.1 \
	tlp-pcilist.1 \
	tlp-usblist.1 \
	wifi.1 \
	wwan.1

MANFILES8 = \
	tlp.8 \
	tlp-stat.8 \
	tlp.service.8

MANFILESRDW8 = \
	tlp-rdw.8

SHFILES = \
	tlp.in \
	tlp-func-base.in \
	func.d/* \
	tlp-rdw.in \
	tlp-rdw-nm.in \
	tlp-rdw-udev.in \
	tlp-rf.in \
	tlp-run-on.in \
	tlp-sleep \
	tlp-sleep.elogind \
	tlp-stat.in \
	tlp-usb-udev.in

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
	install -D -m 755 tlp-func-base $(_TLIB)/tlp-func-base
	install -D -m 755 --target-directory $(_TLIB)/func.d func.d/*
	install -D -m 755 tlp-usb-udev $(_ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(_ULIB)/rules.d/85-tlp.rules
	[ -f $(_CONF) ] || install -D -m 644 default $(_CONF)
ifneq ($(TLP_NO_INIT),1)
	install -D -m 755 tlp.init $(_SYSV)/tlp
endif
ifneq ($(TLP_WITH_SYSTEMD),0)
	install -D -m 644 tlp.service $(_SYSD)/tlp.service
	install -D -m 755 tlp-sleep $(_SDSL)/tlp
endif
ifneq ($(TLP_WITH_ELOGIND),0)
	install -D -m 755 tlp-sleep.elogind $(_ELOD)/49-tlp-sleep
endif
ifneq ($(TLP_NO_BASHCOMP),1)
	install -D -m 644 tlp.bash_completion $(_SHCPL)/tlp
	ln -sf tlp $(_SHCPL)/tlp-stat
	ln -sf tlp $(_SHCPL)/bluetooth
	ln -sf tlp $(_SHCPL)/wifi
	ln -sf tlp $(_SHCPL)/wwan
endif
	install -D -m 644 de.linrunner.tlp.metainfo.xml $(_META)/de.linrunner.tlp.metainfo.xml
	install -d -m 755 $(_VAR)

install-rdw: all
	# Package tlp-rdw
	install -D -m 755 tlp-rdw $(_BIN)/tlp-rdw
	install -D -m 644 tlp-rdw.rules $(_ULIB)/rules.d/85-tlp-rdw.rules
	install -D -m 755 tlp-rdw-udev $(_ULIB)/tlp-rdw-udev
	install -D -m 755 tlp-rdw-nm $(_NMDSP)/99tlp-rdw-nm
ifneq ($(TLP_NO_BASHCOMP),1)
	install -D -m 644 tlp-rdw.bash_completion $(_SHCPL)/tlp-rdw
endif

install-man-tlp:
	# manpages
	install -d -m 755 $(_MAN)/man1
	cd man && install -m 644 $(MANFILES1) $(_MAN)/man1/
	install -d -m 755 $(_MAN)/man8
	cd man && install -m 644 $(MANFILES8) $(_MAN)/man8/

install-man-rdw:
	# manpages
	install -d -m 755 $(_MAN)/man8
	cd man-rdw && install -m 644 $(MANFILESRDW8) $(_MAN)/man8/

install: install-tlp install-rdw

install-man: install-man-tlp install-man-rdw

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
	rm -r $(_TLIB)
	rm $(_ULIB)/tlp-usb-udev
	rm $(_ULIB)/rules.d/85-tlp.rules
	rm -f $(_SYSV)/tlp
	rm -f $(_SYSD)/tlp.service
	rm -f $(_SDSL)/tlp-sleep
	rm -f $(_ELOD)/49-tlp-sleep
	rm -f $(_SHCPL)/tlp-stat
	rm -f $(_SHCPL)/bluetooth
	rm -f $(_SHCPL)/wifi
	rm -f $(_SHCPL)/wwan
	rm -f $(_SHCPL)/tlp
	rm -f $(_META)/de.linrunner.tlp.metainfo.xml
	rm -r $(_VAR)

uninstall-rdw:
	# Package tlp-rdw
	rm $(_BIN)/tlp-rdw
	rm $(_ULIB)/rules.d/85-tlp-rdw.rules
	rm $(_ULIB)/tlp-rdw-udev
	rm $(_NMDSP)/99tlp-rdw-nm
	rm -f $(_SHCPL)/tlp-rdw

uninstall-man-tlp:
	# manpages
	cd $(_MAN)/man1 && rm -f $(MANFILES1)
	cd $(_MAN)/man8 && rm -f $(MANFILES8)

uninstall-man-rdw:
	# manpages
	cd $(_MAN)/man8 && rm -f $(MANFILESRDW8)

uninstall: uninstall-tlp uninstall-rdw

uninstall-man: uninstall-man-tlp uninstall-man-rdw

checkall: checkbashisms shellcheck checkdupconst checkwip

checkbashisms:
	checkbashisms $(SHFILES) || true

shellcheck:
	shellcheck -s dash $(SHFILES) || true

checkdupconst:
	{ sed -n -r -e 's,^.*readonly\s+([A-Za-z_][A-Za-z_0-9]*)=.*$$,\1,p' $(SHFILES) | sort | uniq -d; } || true

checkwip:
	grep -E -n "### (DEBUG|DEVEL|TODO)" $(SHFILES) || true
