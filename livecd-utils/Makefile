# $Id: Makefile,v 1.1 2003/11/21 19:21:08 jaco Exp $

include Rules.mk

all: livecd-utils

version:
	@echo "$(PKGNAME), $(UTILSVER)-$(UTILSREL)"

livecd-utils:
	$(MKDIR) -p $(DISTDIR)
	$(CAT) $(SRCDIR)/livecd-install \
		>$(DISTDIR)/livecd-install

install:
	$(MKDIR) -p $(DESTDIR)$(SBINDIR)
	$(INSTALL) -m 755 $(DISTDIR)/livecd-install $(DESTDIR)$(SBINDIR)

spec:
	$(MKDIR) -p $(DISTDIR)
	$(CAT) $(PKGNAME).spec.in | \
		$(SED) -e 's,@UTILSVER@,$(UTILSVER),g' | \
		$(SED) -e 's,@UTILSREL@,$(UTILSREL),g' | \
		$(SED) -e 's,@SPECDATE@,$(SPECDATE),g' | \
		$(SED) -e 's,@ARCHIVEVER@,$(ARCHIVEVER),g' \
			>$(DISTDIR)/$(PKGNAME).spec

clean:
	$(RM) -rf $(UTILSDIST)
	$(RM) -rf $(DISTDIR)

dist: spec
	$(MKDIR) -p $(UTILSDIST)/$(SRCDIR)
	$(CP) $(DOCDIST) $(UTILSDIST)
	$(CP) $(SRCDIST) $(UTILSDIST)/$(SRCDIR)
	$(TAR) -c $(UTILSDIST) | \
		$(BZIP2) >$(DISTDIR)/$(UTILSDIST).tar.bz2
	$(MD5SUM) $(DISTDIR)/$(UTILSDIST).tar.bz2 \
		>$(DISTDIR)/$(UTILSDIST).tar.bz2.md5
	$(RM) -rf $(UTILSDIST)

rpm: dist
	$(RPMBUILD) -ta $(DISTDIR)/$(UTILSDIST).tar.bz2