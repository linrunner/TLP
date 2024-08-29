# Makefile for TLP
# Copyright (c) 2024 Thomas Koch <linrunner at gmx.net> and others.
# SPDX-License-Identifier: GPL-2.0-or-later
TLPVER := $(shell read _ver _dummy < ./VERSION; printf '%s' "$${_ver:-undef}")

# Evaluate parameters
TLP_SBIN    ?= /usr/sbin
TLP_BIN     ?= /usr/bin
TLP_TLIB    ?= /usr/share/tlp
TLP_FLIB    ?= /usr/share/tlp/func.d
TLP_ULIB    ?= /usr/lib/udev
TLP_BATD    ?= /usr/share/tlp/bat.d
TLP_NMDSP   ?= /usr/lib/NetworkManager/dispatcher.d
TLP_CONFUSR ?= /etc/tlp.conf
TLP_CONFDIR ?= /etc/tlp.d
TLP_CONFDEF ?= /usr/share/tlp/defaults.conf
TLP_CONFREN ?= /usr/share/tlp/rename.conf
TLP_CONFDPR ?= /usr/share/tlp/deprecated.conf
TLP_CONF    ?= /etc/default/tlp
TLP_SYSD    ?= /usr/lib/systemd/system
TLP_SDSL    ?= /usr/lib/systemd/system-sleep
TLP_SYSV    ?= /etc/init.d
TLP_ELOD    ?= /usr/lib/elogind/system-sleep
TLP_SHCPL   ?= /usr/share/bash-completion/completions
TLP_ZSHCPL  ?= /usr/share/zsh/site-functions
TLP_FISHCPL ?= /usr/share/fish/vendor_completions.d
TLP_MAN     ?= /usr/share/man
TLP_META    ?= /usr/share/metainfo
TLP_RUN     ?= /run/tlp
TLP_VAR     ?= /var/lib/tlp

# Catenate DESTDIR to paths
_SBIN    = $(DESTDIR)$(TLP_SBIN)
_BIN     = $(DESTDIR)$(TLP_BIN)
_TLIB    = $(DESTDIR)$(TLP_TLIB)
_FLIB    = $(DESTDIR)$(TLP_FLIB)
_ULIB    = $(DESTDIR)$(TLP_ULIB)
_BATD    = $(DESTDIR)$(TLP_BATD)
_NMDSP   = $(DESTDIR)$(TLP_NMDSP)
_CONFUSR = $(DESTDIR)$(TLP_CONFUSR)
_CONFDIR = $(DESTDIR)$(TLP_CONFDIR)
_CONFDEF = $(DESTDIR)$(TLP_CONFDEF)
_CONFREN = $(DESTDIR)$(TLP_CONFREN)
_CONFDPR = $(DESTDIR)$(TLP_CONFDPR)
_CONF    = $(DESTDIR)$(TLP_CONF)
_SYSD    = $(DESTDIR)$(TLP_SYSD)
_SDSL    = $(DESTDIR)$(TLP_SDSL)
_SYSV    = $(DESTDIR)$(TLP_SYSV)
_ELOD    = $(DESTDIR)$(TLP_ELOD)
_SHCPL   = $(DESTDIR)$(TLP_SHCPL)
_ZSHCPL  = $(DESTDIR)$(TLP_ZSHCPL)
_FISHCPL = $(DESTDIR)$(TLP_FISHCPL)
_MAN     = $(DESTDIR)$(TLP_MAN)
_META    = $(DESTDIR)$(TLP_META)
_RUN     = $(DESTDIR)$(TLP_RUN)
_VAR     = $(DESTDIR)$(TLP_VAR)

SED = sed \
	-e "s|@TLPVER@|$(TLPVER)|g" \
	-e "s|@TLP_SBIN@|$(TLP_SBIN)|g" \
	-e "s|@TLP_TLIB@|$(TLP_TLIB)|g" \
	-e "s|@TLP_FLIB@|$(TLP_FLIB)|g" \
	-e "s|@TLP_ULIB@|$(TLP_ULIB)|g" \
	-e "s|@TLP_BATD@|$(TLP_BATD)|g" \
	-e "s|@TLP_CONFUSR@|$(TLP_CONFUSR)|g" \
	-e "s|@TLP_CONFDIR@|$(TLP_CONFDIR)|g" \
	-e "s|@TLP_CONFDEF@|$(TLP_CONFDEF)|g" \
	-e "s|@TLP_CONFREN@|$(TLP_CONFREN)|g" \
	-e "s|@TLP_CONFDPR@|$(TLP_CONFDPR)|g" \
	-e "s|@TLP_CONF@|$(TLP_CONF)|g" \
	-e "s|@TLP_RUN@|$(TLP_RUN)|g"   \
	-e "s|@TLP_VAR@|$(TLP_VAR)|g"

INFILES = \
	tlp \
	tlp.conf \
	tlp-func-base \
	tlp-rdw-nm \
	tlp-rdw.rules \
	tlp-rdw-udev \
	tlp-rdw \
	tlp-rf \
	tlp.rules \
	tlp-readconfs \
	tlp-run-on \
	tlp.service \
	tlp-stat \
	tlp.upstart \
	tlp-usb-udev

MANFILES1 = \
	bluetooth.1 \
	nfc.1 \
	run-on-ac.1 \
	run-on-bat.1 \
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
	bat.d/* \
	tlp-rdw.in \
	tlp-rdw-nm.in \
	tlp-rdw-udev.in \
	tlp-rf.in \
	tlp-run-on.in \
	tlp-sleep \
	tlp-sleep.elogind \
	tlp-stat.in \
	tlp-usb-udev.in \

UTSHFILES = \
	unit-tests/test-func \
	unit-tests/test-cpufreq.sh

PLFILES = \
	tlp-pcilist \
	tlp-readconfs.in \
	tlp-usblist

BATDRVFILES = $(foreach drv,$(wildcard bat.d/[0-9][0-9]-[a-z]*),$(drv)~)

# Make targets
all: $(INFILES)

$(INFILES): %: %.in
	$(SED) $< > $@

clean:
	rm -f $(INFILES)
	rm -f bat.d/*~

install-tlp: all
	# Package tlp
	install -D -m 755 tlp $(_SBIN)/tlp
	install -D -m 755 tlp-rf $(_BIN)/bluetooth
	ln -sf bluetooth $(_BIN)/nfc
	ln -sf bluetooth $(_BIN)/wifi
	ln -sf bluetooth $(_BIN)/wwan
	install -m 755 tlp-run-on $(_BIN)/run-on-ac
	ln -sf run-on-ac $(_BIN)/run-on-bat
	install -m 755 tlp-stat $(_BIN)/
	install -D -m 755 -t $(_TLIB)/func.d func.d/*
	install -m 755 tlp-func-base $(_TLIB)/
	install -D -m 755 -t $(_TLIB)/bat.d bat.d/*
	install -m 755 tlp-pcilist $(_TLIB)/
	install -m 755 tlp-readconfs $(_TLIB)/
	install -m 755 tlp-usblist $(_TLIB)/
	install -D -m 755 tlp-usb-udev $(_ULIB)/tlp-usb-udev
	install -D -m 644 tlp.rules $(_ULIB)/rules.d/85-tlp.rules
	[ -f $(_CONFUSR) ] || install -D -m 644 tlp.conf $(_CONFUSR)
	install -d $(_CONFDIR)
	install -D -m 644 README.d $(_CONFDIR)/README
	install -D -m 644 00-template.conf $(_CONFDIR)/00-template.conf
	install -D -m 644 defaults.conf $(_CONFDEF)
	install -D -m 644 rename.conf $(_CONFREN)
	install -D -m 644 deprecated.conf $(_CONFDPR)
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
	install -D -m 644 completion/bash/tlp.bash_completion $(_SHCPL)/tlp
	ln -sf tlp $(_SHCPL)/tlp-stat
	ln -sf tlp $(_SHCPL)/bluetooth
	ln -sf tlp $(_SHCPL)/nfc
	ln -sf tlp $(_SHCPL)/wifi
	ln -sf tlp $(_SHCPL)/wwan
	ln -sf tlp $(_SHCPL)/run-on-ac
	ln -sf tlp $(_SHCPL)/run-on-bat
endif
ifneq ($(TLP_NO_ZSHCOMP),1)
	install -D -m 644 completion/zsh/_tlp $(_ZSHCPL)/_tlp
	install -D -m 644 completion/zsh/_tlp-radio-device $(_ZSHCPL)/_tlp-radio-device
	install -D -m 644 completion/zsh/_tlp-run-on $(_ZSHCPL)/_tlp-run-on
	install -D -m 644 completion/zsh/_tlp-stat $(_ZSHCPL)/_tlp-stat
endif
ifneq ($(TLP_NO_FISHCOMP),1)
	install -D -m 644 completion/fish/tlp.fish $(_FISHCPL)/tlp.fish
	install -D -m 644 completion/fish/tlp-stat.fish $(_FISHCPL)/tlp-stat.fish
	ln -sf tlp.fish $(_FISHCPL)/bluetooth.fish
	ln -sf tlp.fish $(_FISHCPL)/nfc.fish
	ln -sf tlp.fish $(_FISHCPL)/wifi.fish
	ln -sf tlp.fish $(_FISHCPL)/wwan.fish
	ln -sf tlp.fish $(_FISHCPL)/run-on-ac.fish
	ln -sf tlp.fish $(_FISHCPL)/run-on-bat.fish
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
	install -D -m 644 completion/bash/tlp-rdw.bash_completion $(_SHCPL)/tlp-rdw
endif
ifneq ($(TLP_NO_ZSHCOMP),1)
	install -D -m 644 completion/zsh/_tlp-rdw $(_ZSHCPL)/_tlp-rdw
endif
ifneq ($(TLP_NO_FISHCOMP),1)
	install -D -m 644 completion/fish/tlp-rdw.fish $(_FISHCPL)/tlp-rdw.fish
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
	rm $(_BIN)/nfc
	rm $(_BIN)/wifi
	rm $(_BIN)/wwan
	rm $(_BIN)/run-on-ac
	rm $(_BIN)/run-on-bat
	rm $(_BIN)/tlp-stat
	rm $(_CONFDIR)/README
	rm $(_CONFDIR)/00-template.conf
	rm -r $(_TLIB)
	rm $(_ULIB)/tlp-usb-udev
	rm $(_ULIB)/rules.d/85-tlp.rules
	rm -f $(_SYSV)/tlp
	rm -f $(_SYSD)/tlp.service
	rm -f $(_SDSL)/tlp-sleep
	rm -f $(_ELOD)/49-tlp-sleep
	rm -f $(_SHCPL)/tlp
	rm -f $(_SHCPL)/tlp-stat
	rm -f $(_SHCPL)/bluetooth
	rm -f $(_SHCPL)/nfc
	rm -f $(_SHCPL)/wifi
	rm -f $(_SHCPL)/wwan
	rm -f $(_SHCPL)/run-on-ac
	rm -f $(_SHCPL)/run-on-bat
	rm -f $(_ZSHCPL)/_tlp
	rm -f $(_ZSHCPL)/_tlp-radio-device
	rm -f $(_ZSHCPL)/_tlp-run-on
	rm -f $(_ZSHCPL)/_tlp-stat
	rm -f $(_FISHCPL)/tlp.fish
	rm -f $(_FISHCPL)/tlp-stat.fish
	rm -f $(_FISHCPL)/bluetooth.fish
	rm -f $(_FISHCPL)/nfc.fish
	rm -f $(_FISHCPL)/wifi.fish
	rm -f $(_FISHCPL)/wwan.fish
	rm -f $(_FISHCPL)/run-on-ac.fish
	rm -f $(_FISHCPL)/run-on-bat.fish
	rm -f $(_META)/de.linrunner.tlp.metainfo.xml
	rm -r $(_VAR)

uninstall-rdw:
	# Package tlp-rdw
	rm $(_BIN)/tlp-rdw
	rm $(_ULIB)/rules.d/85-tlp-rdw.rules
	rm $(_ULIB)/tlp-rdw-udev
	rm $(_NMDSP)/99tlp-rdw-nm
	rm -f $(_SHCPL)/tlp-rdw
	rm -f $(_ZSHCPL)/_tlp-rdw
	rm -f $(_FISHCPL)/tlp-rdw.fish

uninstall-man-tlp:
	# manpages
	cd $(_MAN)/man1 && rm -f $(MANFILES1)
	cd $(_MAN)/man8 && rm -f $(MANFILES8)

uninstall-man-rdw:
	# manpages
	cd $(_MAN)/man8 && rm -f $(MANFILESRDW8)

uninstall: uninstall-tlp uninstall-rdw

uninstall-man: uninstall-man-tlp uninstall-man-rdw

checkall: checkbashisms shellcheck perlcritic checkdupconst checkbatdrv checkwip

checkbashisms:
	@echo "*** checkbashisms ***************************************************************************"
	@{ checkbashisms $(SHFILES) 2>&1 | sed -e '/test with unary -a (should be -e)/{N;d;}'; } || true

shellcheck:
	@echo "*** shellcheck ******************************************************************************"
	@shellcheck -s dash $(SHFILES) $(UTSHFILES) || true

perlcritic:
	@echo "*** perlcritic ******************************************************************************"
	@perlcritic --severity 4 --verbose "%F: [%p] %m at line %l, column %c.  (Severity: %s)\n" $(PLFILES) || true

checkdupconst:
	@echo "*** checkdupconst ***************************************************************************"
	@{ sed -n -r -e 's,^.*readonly\s+([A-Za-z_][A-Za-z_0-9]*)=.*$$,\1,p' $(SHFILES) | sort | uniq -d; } || true

checkwip:
	@echo "*** checkwip ********************************************************************************"
	@grep -E -n "### (DEBUG|DEVEL|TODO|WIP)" $(SHFILES) $(UTSHFILES) $(PLFILES) || true

bat.d/TEMPLATE~: bat.d/TEMPLATE
	@awk '/^batdrv_[a-z_]+ ()/ { print $$1; }' $< | grep -v 'batdrv_is' | sort > $@

bat.d/%~: bat.d/%
	@printf "*** checkbatdrv %-25s ***********************************************\n" "$<"
	@awk '/^batdrv_[a-z_]+ ()/ { print $$1; }' $< | grep -v 'batdrv_is' | sort > $@
	@diff -U 1 -s bat.d/TEMPLATE~  $@ || true

checkbatdrv: bat.d/TEMPLATE~ $(BATDRVFILES)
	rm -f bat.d/*~
