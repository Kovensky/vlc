# zvbi

ZVBI_VERSION := 0.2.33
ZVBI_URL := $(SF)/zapping/zvbi-$(ZVBI_VERSION).tar.bz2

PKGS += zvbi
ifeq ($(call need_pkg,"zvbi-0.2"),)
PKGS_FOUND += zvbi
endif

$(TARBALLS)/zvbi-$(ZVBI_VERSION).tar.bz2:
	$(call download,$(ZVBI_URL))

.sum-zvbi: zvbi-$(ZVBI_VERSION).tar.bz2

zvbi: zvbi-$(ZVBI_VERSION).tar.bz2 .sum-zvbi
	$(UNPACK)
	$(APPLY) $(SRC)/zvbi/zvbi-ssize_max.patch
	$(APPLY) $(SRC)/zvbi/zvbi-ioctl.patch
	$(APPLY) $(SRC)/zvbi/zvbi-png15.patch
ifdef HAVE_WIN32
ifdef HAVE_MINGW_W64
	$(APPLY) $(SRC)/zvbi/zvbi-win64.patch
else
	$(APPLY) $(SRC)/zvbi/zvbi-win32.patch
endif
endif
	$(MOVE)

DEPS_zvbi = pthreads iconv $(DEPS_iconv)

ZVBI_CFLAGS := $(CFLAGS)
ZVBICONF := \
	--disable-dvb --disable-bktr \
	--disable-nls --disable-proxy \
	--without-doxygen \
	$(HOSTCONF)
ifdef HAVE_MACOSX
ZVBI_CFLAGS += -fnested-functions
endif
ifdef HAVE_WIN32
ZVBI_CFLAGS += -DPTW32_STATIC_LIB
endif

.zvbi: zvbi
	$(RECONF)
ifdef HAVE_MACOSX
	#cd $< && $(HOSTVARS) CFLAGS="$(ZVBI_CFLAGS)" CC=gcc ./configure $(ZVBICONF)
	cd $< && $(HOSTVARS) CFLAGS="$(ZVBI_CFLAGS)" CC=llvm-gcc ./configure $(ZVBICONF)
else
	cd $< && $(HOSTVARS) CFLAGS="$(ZVBI_CFLAGS)" ./configure $(ZVBICONF)
endif
	cd $</src && $(MAKE) install
	cd $< && $(MAKE) SUBDIRS=. install
	sed -i.orig -e "s/\/[^ ]*libiconv.a/-liconv/" $(PREFIX)/lib/pkgconfig/zvbi-0.2.pc
	touch $@
