-include Makefile.config

# OASIS_START
# DO NOT EDIT (digest: 2d4c24273300135e3c2348b6ba5b4a30)

SETUP = ocaml setup.ml

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

.PHONY: doc test all install uninstall reinstall clean

# OASIS_STOP

-include Makefile.local
