###############################################################################
# Makefile
###############################################################################

PRE = $(wildcard *.pre)
TEX = $(PRE:.pre=.tex)
PDF = $(TEX:.tex=.pdf)
TST = $(shell which test.sh)

###############################################################################

all: $(PDF)

auto: $(TEX)
	while pgrep latexmk > /dev/null; do $(MAKE) -s; sleep 1; done &
	latexmk -f -pdf -pvc `ls -t $(TEX) | head -n 1`

clean:
	if [ -e "$(TEX)" ]; then latexmk -C; fi
	$(RM) $(TEX) *~

###############################################################################

%.tex: %.pre $(TST) Makefile
	$(TST) -c 2 -i logotipos -p $< -q 15 -s "Arquitectura de Computadores" -t 32

%.pdf: %.tex
	latexmk -pdf $*

###############################################################################

.PHONY: all auto clean
.NOEXPORT:

###############################################################################