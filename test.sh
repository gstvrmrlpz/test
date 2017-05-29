#!/bin/bash

###############################################################################

answer='5.0' # width of answer column in mm
cols=2       # number of columns
date=`date  '+%d/%m/%Y'`
empty='\ifodd\value{page}\cleardoublepage\else\null\cleardoublepage\fi'
filename=''
image='/home/gustavo/docencia/logotipos'
MAXQ=20      # answer longest line in number of questions
questions=10 # number of questions
RANDOM=0
subject=''
tests=1

###############################################################################

help()
{
	echo "usage: $(basename $0) -p file.pre [options]"
	echo -e "\t -c \t number of columns (1|2), $cols by default"
	echo -e "\t -d \t don't show date, $date by default"
	echo -e "\t -e \t avoid empty pages"
	echo -e "\t -f \t default test name is filename"
	echo -e "\t -h \t show this help"
	echo -e "\t -i \t image directory {atc,etsiit,ugr}-log.png"
	echo -e "\t -p \t pre file, mandatory"
	echo -e "\t -q \t number of questions, $questions by default"
	echo -e "\t -s \t subject, mandatory"
	echo -e "\t -t \t number of tests, $tests by default"
	exit 1
}

###############################################################################

if [[ $# < 1 ]]; then
	help
fi

###############################################################################

declare -a args=("$@")

for (( i=0; i<${#args[@]}; ++i )); do
	case ${args[$i]} in
		-c) (( ++i )); cols=${args[$i]};;
		-d) date='';;
		-e) empty='';;
		-f) (( ++i )); filename=${args[$i]};;
		-h) help;;
		-i) (( ++i )); image=${args[$i]};;
		-p) (( ++i )); pre=${args[$i]};;
		-q) (( ++i )); questions=${args[$i]};;
		-s) (( ++i )); subject=${args[$i]};;
		-t) (( ++i )); tests=${args[$i]};;
		 *) echo unknown option \"${args[$i]}\"; exit 1;;
	esac
done

if (( cols < 0 || cols > 2 )); then
	echo 'Only 1 or 2 columns supported!'
	exit 1
fi

if [ "$date" ]; then
	date="\hfill Fecha: $date"
fi

if [ ! -d "$image" ]; then
	echo "$image directory doesn't exist!"
	exit 1
fi

if [ -z "$pre" ] || [ -z "$subject" ]; then
	help
fi

for i in $pre $style; do
	if [ ! -e "$i" ]; then
		echo "'$i' doesn't exist!"
		exit 1
	fi
done

tex=${pre/.pre/.tex}

(( w4 = 16 / cols ))
(( w2 = 32 / cols ))

if [ -z "$filename" ]; then
	filename=${tex/.tex}
	filename="\lstinline[basicstyle=\bfseries\rmfamily]{${filename^^}}"
fi

###############################################################################
# read *.pre and check for errors
###############################################################################

linenumber=1
while read -r clave linea; do
#	if [ "$clave" ] && [ "${clave:0:1}" != "%" ]; then
#		eval "$clave+=('$linea')"
#	fi

	# missing line after valid key avoiding comments
	if [[ -n "$clave" && -z "$linea" && "${clave:0:1}" != "#" && "${clave:0:1}" != "%" ]]; then
		echo "error in line $linenumber: \"$clave $linea\""
		exit 1
	fi
	
	# wrong answer
	if [[ "$clave" == "s" ]]; then
		case $linea in
			a|b|c|d);;
			*) echo "error in line $linenumber: \"$clave $linea\""; exit 1;;
		esac
	fi
	
	case $clave in
		''|'#'*|'%'*) ;;  # comments with # and %
		p) p+=("$linea");;
		a) a+=("$linea");;
		b) b+=("$linea");;
		c) c+=("$linea");;
		d) d+=("$linea");;
		s) s+=("$linea");;
		*) echo "error in line $linenumber: \"$clave $linea\""; exit 1;;
	esac
	
	(( ++linenumber ));
done < "./$pre"

if (( ${#a[@]} != ${#p[@]} || ${#b[@]} != ${#p[@]} || ${#c[@]} != ${#p[@]} || ${#d[@]} != ${#p[@]} || ${#s[@]} != ${#p[@]} )); then
	echo "$(basename $0): number of p, a, b, c, d, s mismatch!!!";
	echo -e "\t \${#p[@]} = ${#p[@]}"
	echo -e "\t \${#a[@]} = ${#a[@]}"
	echo -e "\t \${#b[@]} = ${#b[@]}"
	echo -e "\t \${#c[@]} = ${#c[@]}"
	echo -e "\t \${#d[@]} = ${#d[@]}"
	echo -e "\t \${#s[@]} = ${#s[@]}"
	exit 1;
fi

# questions <= number of questions in test
if (( ${#p[@]} < questions )); then
	questions=${#p[@]}
fi

###############################################################################
# *.tex header
###############################################################################

rm -f "./$tex"

cat > "./$tex" <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\documentclass[a4paper,11pt]{article}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{array}              % m
\usepackage{amsmath}            % texto en modo matemático
\usepackage[spanish]{babel}     % español
\usepackage{caption}            % captionof
\usepackage[ddmmyyyy]{datetime} % formato fecha (\today)
\usepackage{epsfig}             % epsfig
\usepackage{geometry}           % geometry
\usepackage{graphicx}           % includegraphics
\usepackage[utf8]{inputenc}     % tildes
\usepackage{listings}           % listado de fuentes
\usepackage{multicol}           % varias columnas
\usepackage{xcolor}             % gray

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\geometry{margin=8mm,top=16mm,bottom=16mm}

\lstset{
	alsoletter={\%},
	basicstyle=\ttfamily,
	breaklines=true,
	extendedchars=true,
	inputencoding=utf8,
	keepspaces=true,
	language=C++,
	literate={á}{{\'a}}1 {é}{{\'e}}1 {í}{{\'i}}1 {ó}{{\'o}}1 {ú}{{\'u}}1
	         {Á}{{\'A}}1 {É}{{\'E}}1 {Í}{{\'I}}1 {Ó}{{\'O}}1 {Ú}{{\'U}}1
	         {à}{{\`a}}1 {è}{{\`e}}1 {ì}{{\`i}}1 {ò}{{\`o}}1 {ù}{{\`u}}1
	         {À}{{\`A}}1 {È}{{\'E}}1 {Ì}{{\`I}}1 {Ò}{{\`O}}1 {Ù}{{\`U}}1
	         {ä}{{\"a}}1 {ë}{{\"e}}1 {ï}{{\"i}}1 {ö}{{\"o}}1 {ü}{{\"u}}1
	         {Ä}{{\"A}}1 {Ë}{{\"E}}1 {Ï}{{\"I}}1 {Ö}{{\"O}}1 {Ü}{{\"U}}1
	         {â}{{\^a}}1 {ê}{{\^e}}1 {î}{{\^i}}1 {ô}{{\^o}}1 {û}{{\^u}}1
	         {Â}{{\^A}}1 {Ê}{{\^E}}1 {Î}{{\^I}}1 {Ô}{{\^O}}1 {Û}{{\^U}}1
	         {œ}{{\oe}}1 {Œ}{{\OE}}1 {æ}{{\ae}}1 {Æ}{{\AE}}1 {ß}{{\ss}}1
	         {ű}{{\H{u}}}1 {Ű}{{\H{U}}}1 {ő}{{\H{o}}}1 {Ő}{{\H{O}}}1
	         {ç}{{\c c}}1 {Ç}{{\c C}}1 {ø}{{\o}}1 {å}{{\r a}}1 {Å}{{\r A}}1
	         {ñ}{{\~{n}}}1 {Ñ}{{\~{N}}}1 {€}{{\EUR}}1 {£}{{\pounds}}1,
	numberstyle=\tiny\color{gray},
	language=C++,
	showspaces=false,
	showstringspaces=false,
	showtabs=false,
	tabsize=2,
}

\lstdefinestyle{n}{numbers=left}
\lstdefinestyle{s}{basicstyle=\small\ttfamily}
\lstdefinestyle{fn}{basicstyle=\footnotesize\ttfamily}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\encabezado}{
\begin{center}
\bfseries \large
\begin{tabular}{*{3}{p{0.31\textwidth}}}
	\epsfig{file=$image/ugr-logo.png,height=12mm} & \multicolumn{1}{c}{\epsfig{file=$image/etsiit-logo.png,height=12mm}} & \multicolumn{1}{r}{\epsfig{file=$image/atc-logo.png,height=12mm}} \\\\
	\\\\
	\multicolumn{3}{c}{$subject \hfill Examen: $filename $date} \\\\
	\\\\
	\multicolumn{1}{l}{Nombre:} & & DNI: \hspace{24mm} Grupo: \hspace{6mm} \\\\
	\hline
\end{tabular}
\end{center}
\vspace{5mm}
}

\newenvironment{mfigure}
	{\par\medskip\noindent\minipage{\linewidth}}
	{\endminipage\par\medskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\begin{document}
\pagenumbering{gobble}

EOF

###############################################################################
# test loop
###############################################################################

for (( t = 1; t <= $tests; ++t )); do
	p2=("${p[@]}")
	a2=("${a[@]}")
	b2=("${b[@]}")
	c2=("${c[@]}")
	d2=("${d[@]}")
	s2=("${s[@]}")

	echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
	echo "% test $t" >> "./$tex"
	echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
	echo >> "./$tex"
	echo '\encabezado' >> "./$tex"
	echo >> "./$tex"
	echo "{\Large \bfseries \noindent Test $t: 10 puntos.}" >> "./$tex"
	echo >> "./$tex"
	valor1=`LANG=C printf '%2.3f' $(bc -l <<< "10/$questions")`
	valor2=`LANG=C printf '%2.3f' $(bc -l <<< "10/(3*$questions)")`
	echo "\noindent Escriba la opción correcta dentro de la casilla debajo de cada número de pregunta. Cada respuesta correcta vale \$10/$questions = $valor1\$ puntos, \$0\$ si no se contesta o está claramente tachada y \$10/(3 \times $questions) = -$valor2\$ si es errónea o no está claramente contestada. Se aconseja terminar de leer completamente cada pregunta antes de contestarla." >> "./$tex"
	echo >> "./$tex"
	echo '\vspace{1mm}' >> "./$tex"
	echo >> "./$tex"

	echo '\begin{minipage}{0.95\textwidth}' >> "./$tex"
	echo '\begin{center}' >> "./$tex"
#	echo '\renewcommand\arraystretch{1.50}' >> "./$tex"
	echo '\renewcommand\arraystretch{1.45}' >> "./$tex"
	if ((questions <= MAXQ)); then
################################################################################
		echo "\begin{tabular}{|*{$questions}{m{${answer}mm}|}}" >> "./$tex"
		echo '\hline' >> "./$tex"
		for (( j = 1; j <= questions; ++j )); do
			echo -n $j >> "./$tex"
			if (( j < questions )); then
				echo -n ' & ' >> "./$tex"
			fi
		done
		echo '\\' >> "./$tex"
		echo '\hline' >> "./$tex"
		for (( j=1; j<$questions; ++j )); do
			echo -n '&' >> "./$tex"
		done
		echo '\\' >> "./$tex"
		echo '\hline' >> "./$tex"
################################################################################
	else
################################################################################
		echo "\begin{tabular}{|*{$MAXQ}{m{${answer}mm}|}}" >> "./$tex"
		echo '\hline' >> "./$tex"
		for (( maxq = 1 ; maxq <= questions; maxq += MAXQ )); do
			for (( j = maxq; j < maxq + MAXQ ; ++j )); do
				if (( j <= questions )); then
					echo -n $j >> "./$tex"
				else
					echo -n >> "./$tex"
				fi
				if (( j < maxq + MAXQ - 1 )); then
					echo -n ' & ' >> "./$tex"
				fi
			done
			echo '\\' >> "./$tex"
			echo '\hline' >> "./$tex"
			for (( j = maxq; j < maxq + MAXQ - 1; ++j )); do
				echo -n '&' >> "./$tex"
			done
			echo '\\' >> "./$tex"
			echo '\hline' >> "./$tex"
		done
################################################################################
	fi
	echo '\end{tabular}' >> "./$tex"
	echo '\end{center}' >> "./$tex"
	echo '\end{minipage}' >> "./$tex"
	echo >> "./$tex"

	if (( $cols == 2 )); then
		echo "\begin{multicols}{$cols}" >> "./$tex"
	fi

	echo '\begin{enumerate}' >> "./$tex"
	echo >> "./$tex"
	echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
	echo >> "./$tex"

	for (( i=0; i<$questions; ++i )); do
		n=`bc <<< $RANDOM%${#p2[@]}`
		echo "\item ${p2[$n]}" >> "./$tex"
		echo "\begin{enumerate}" >> "./$tex"
		declare -a orden=("${a2[$n]}" "${b2[$n]}" "${c2[$n]}" "${d2[$n]}")
		width=0
		for o in "${orden[@]}"; do
			if [ "$width" -lt "${#o}" ]; then
				width=${#o}
			fi
		done
		if (( $width < $w4 )); then
			echo '\begin{multicols}{4}' >> "./$tex"
		elif (( $width < $w2 )); then
			echo '\begin{multicols}{2}' >> "./$tex"
		fi
		declare -a desorden
		pos=0
		for r in `seq 0 3 | shuf`; do
			desorden[$pos]="${orden[$r]}"
			(( ++pos ))
		done
		pos=0
		case "${s2[$n]}" in
			a) correcta="${a2[$n]}";;
			b) correcta="${b2[$n]}";;
			c) correcta="${c2[$n]}";;
			d) correcta="${d2[$n]}";;
			b) echo "respuesta incorrecta en ${p2[$n]}"; exit 1;;
		esac
		for j in a b c d; do
			respuesta="${desorden[$pos]}"
			echo -en "\t\item " >> "./$tex"
			echo "$respuesta \par" >> "./$tex" # \par needed for listings
			if [ "$respuesta" == "$correcta" ]; then
				if [ "${sol[$t]}" ]; then
					sol[$t]="${sol[$t]} & $j"
				else
					sol[$t]="$j"
				fi
			fi
			(( ++pos ))
		done
		if (( $width < $w2 )); then
			echo '\end{multicols}' >> "./$tex"
		fi
		echo '\end{enumerate}' >> "./$tex"
		echo >> "./$tex"
		echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
		echo >> "./$tex"
		p2=("${p2[@]:0:$n}" "${p2[@]:$(($n + 1))}")
		a2=("${a2[@]:0:$n}" "${a2[@]:$(($n + 1))}")
		b2=("${b2[@]:0:$n}" "${b2[@]:$(($n + 1))}")
		c2=("${c2[@]:0:$n}" "${c2[@]:$(($n + 1))}")
		d2=("${d2[@]:0:$n}" "${d2[@]:$(($n + 1))}")
		s2=("${s2[@]:0:$n}" "${s2[@]:$(($n + 1))}")
	done

	echo '\end{enumerate}' >> "./$tex"

	if (( $cols == 2 )); then
		echo '\end{multicols}' >> "./$tex"
	fi

	echo "\cleardoublepage $empty" >> "./$tex"
	echo >> "./$tex"
done

echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
echo '% soluciones' >> "./$tex"
echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
echo "{\large Examen: $filename \hfill $date}" >> "./$tex"
echo >> "./$tex"

################################################################################
# short
################################################################################
if (( questions <= MAXQ )); then
	echo '\begin{center}' >> "./$tex"
	echo '\renewcommand\arraystretch{1.45}' >> "./$tex"
	echo "\begin{tabular}{c|*{$questions}{m{${answer}mm}|}}" >> "./$tex"
	echo "\cline{2-$((questions + 1))}" >> "./$tex"
	echo -n 'n' >> "./$tex"
	for (( q = 1; q <= $questions; ++q )); do
		echo -n " & $q" >> "./$tex"
	done
	echo '\\' >> "./$tex"
	echo "\cline{2-$((questions + 1))}" >> "./$tex"
	echo "\cline{2-$((questions + 1))}" >> "./$tex"
	for (( t = 1; t <= $tests; ++t )); do
		partial="${sol[$t]}"
		position=$(( 4 * (questions -1) + 1 ))
		echo "$t & ${partial:0:$position} \\\\ \cline{2-$((questions + 1))}" >> "./$tex"
	done
	echo '\end{tabular}' >> "./$tex"
	echo '\end{center}' >> "./$tex"
	echo >> "./$tex"
################################################################################
# long
################################################################################
else
	for (( t = 1; t <= tests; ++t )); do
		echo "$t" >> "./$tex"
		echo '\begin{center}' >> "./$tex"
		echo '\renewcommand\arraystretch{1.45}' >> "./$tex"
		echo "\begin{tabular}{|*{$MAXQ}{m{${answer}mm}|}}" >> "./$tex"
		echo '\hline' >> "./$tex"
		all=${sol[$t]}
		for (( maxq = 0; maxq < questions; maxq += MAXQ )); do
			for (( j = maxq; j < maxq + MAXQ; ++j )); do
				if (( j < questions )); then
					echo -n $((j + 1)) >> "./$tex"
				else
					echo -n >> "./$tex"
				fi
				if (( j < maxq + MAXQ - 1 )); then
					echo -n ' & ' >> "./$tex"
				fi
			done
			echo '\\' >> "./$tex"
			echo '\hline' >> "./$tex"
			for (( j = maxq; j < maxq + MAXQ; ++j )); do
				if (( j < questions)); then
					echo -n ${all:$((4 * j)):1} >> "./$tex"
				else
					echo -n >> "./$tex"
				fi
				if (( j < maxq + MAXQ - 1)); then
					echo -n ' & ' >> "./$tex"
				fi
			done
			echo '\\' >> "./$tex"
			echo '\hline' >> "./$tex"
		done
		echo '\end{tabular}' >> "./$tex"
		echo '\end{center}' >> "./$tex"
		echo >> "./$tex"
	done
fi
################################################################################

echo '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' >> "./$tex"
echo >> "./$tex"
echo '\end{document}' >> "./$tex"

###############################################################################

