.PHONY: build clean test install uninstall doc

build:
	jbuilder build --dev

clean:
	jbuilder clean

test:
	jbuilder runtest --dev

install:
	jbuilder install

uninstall:
	jbuilder uninstall

doc:
	jbuilder build @doc
