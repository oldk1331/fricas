## ---------------------------------------
## -- Standard boilerplate dependencies --
## ---------------------------------------

.PRECIOUS: Makefile
Makefile: $(srcdir)/Makefile.in $(top_srcdir)/config/var-def.mk \
	  $(top_srcdir)/config/setup-dep.mk \
	  $(abs_top_builddir)/config.status
	cd $(abs_top_builddir) && $(SHELL) ./config.status $(subdir)$@
