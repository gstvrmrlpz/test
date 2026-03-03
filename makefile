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
	-rm -frv $(PDF) $(TEX) _minted-* *~
	-killall -KILL -q inotifywait latexmk pdflatex || true

###############################################################################

%.tex: %.pre $(TST) makefile
	$(TST) -p '$<' -s "Asignatura X" -t 3

%.pdf: %.tex
	latexmk -pdf -shell-escape '$*'

###############################################################################

.PHONY: all auto clean
.NOEXPORT:

###############################################################################
