###############################################################################
# makefile
###############################################################################

PRE = $(wildcard *.pre)
TEX = $(PRE:.pre=.tex)
PDF = $(TEX:.tex=.pdf)
TST = $(shell which test.sh)

###############################################################################

all: $(PDF)

auto: $(TEX)
	while true; do inotifywait -qr -e modify .; make '$<'; done &
	latexmk -f -pdf -pvc '$<'

clean:
	-[ -e $(TEX) ] && latexmk -C
	-rm -fv $(PDF) $(TEX) *~

###############################################################################

%.tex: %.pre $(TST) makefile
	$(TST) -c 2 -i logotipos -p '$<' -q 64 -s "Arquitectura de Computadores" -t 3

%.pdf: %.tex
	latexmk -pdf '$*'

###############################################################################

.PHONY: all auto clean
.NOEXPORT:

###############################################################################
