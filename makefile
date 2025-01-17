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
	latexmk -f -pdf -pvc -shell-escape '$<' && pkill -KILL $$! &
	while ps -q $$! > /dev/null; do inotifywait -qr -e modify .; make '$<'; done

clean:
	-latexmk -C -f $(TEX)
	-rm -fv $(PDF) $(TEX) *~
	-killall -KILL -q inotifywait latexmk pdflatex || true

###############################################################################

%.tex: %.pre $(TST) makefile
	$(TST) -c 2 -i logotipos -p '$<' -q 64 -s "Arquitectura de Computadores" -t 3

%.pdf: %.tex
	latexmk -pdf -shell-escape '$*'

###############################################################################

.PHONY: all auto clean
.NOEXPORT:

###############################################################################
