#!/usr/bin/env bash

###############################################################################

LC_NUMERIC=C

###############################################################################

answer='5.0' # width of answer column in mm
cols=2       # number of columns
date=`date  '+%d/%m/%Y'`
empty='\ifodd\value{page}\cleardoublepage\else\null\cleardoublepage\fi'
filename=''
image='/home/gustavo/docencia/logotipos'
MAXQ=20      # answer longest line in number of questions
MAXT=35      # longest answer table in the short format
questions=0  # number of questions
seed=0
subject=''
tests=1

###############################################################################

help()
{
	echo "usage: $(basename $0) -p file.pre [options]"
	echo -e "\t -c \t number of columns (1|2), $cols by default"
	echo -e "\t -d \t today by default, '' to avoid"
	echo -e "\t -e \t avoid empty pages"
	echo -e "\t -f \t default test name is the same as the question file"
	echo -e "\t -h \t show this help"
	echo -e "\t -i \t image directory {atc,etsiit,ugr}-logo.png"
	echo -e "\t -p \t question file *.pre, mandatory"
	echo -e "\t -q \t number of questions, all by default ($questions)"
	echo -e "\t -r \t random seed, $seed by default"
	echo -e "\t -s \t subject"
	echo -e "\t -t \t number of tests, $tests by default"
	exit 1
}

###############################################################################

if [ $# -lt 2 ]; then
	help
fi

###############################################################################

declare -a args=("$@")

for (( i=0; i<${#args[@]}; ++i )); do
	next=${args[$((i+1))]}
	case ${args[$i]} in
		-c) (( ++i )); cols=${args[$i]};;
		-d) if [ "${next:0:1}" != "-" ]; then (( ++i )); date=$next; fi;;
		-e) empty='';;
		-f) (( ++i )); filename=${args[$i]};;
		-h) help;;
		-i) (( ++i )); image=${args[$i]};;
		-p) (( ++i )); pre=${args[$i]};;
		-q) (( ++i )); questions=${args[$i]};;
		-r) (( ++i )); seed=${args[$i]:-$seed};;
		-s) (( ++i )); subject=${args[$i]};;
		-t) (( ++i )); tests=${args[$i]};;
		 *) echo unknown option \"${args[$i]}\"; exit 1;;
	esac
done

if (( cols < 0 || cols > 2 )); then
	echo "$0: Only 1 or 2 columns supported!"
	exit 1
fi

if [ "$date" ]; then
	date="\hfill Fecha: $date"
fi

if [ ! -d "$image" ]; then
	echo "$0: $image directory doesn't exist!"
	exit 1
fi

if [ -z "$pre" ]; then
	echo "$0: mandatory question file!"
	exit 1
fi

for i in $pre $style; do
	if [ ! -e "$i" ]; then
		echo "$0: '$i' doesn't exist!"
		exit 1
	fi
done

tex=${pre/.pre/.tex}

(( w4 = 12 / cols )) # max width of 4 columns
(( w2 = w4 * 2 ))    # max width of 2 columns

if [ -z "$filename" ]; then
	filename=${tex/.tex}
    filename=${filename##*/}
fi

RANDOM=$seed

###############################################################################
# read *.pre and check for errors
###############################################################################

linenumber=1
while read -r clave linea; do
	# missing line after valid key avoiding comments
	if [[ -n "$clave" && -z "$linea" && "${clave:0:1}" != "#" && "${clave:0:1}" != "%" ]]; then
		echo "error in line $linenumber: \"$clave $linea\""
		exit 1
	fi

	# wrong answer?
	if [[ "$clave" == "s" ]]; then
		case $linea in
			a|b|c|d);;
			*) echo "error in line $linenumber: \"$clave $linea\""; exit 1;;
		esac
	fi

#	# remove lines with partial comments
#	linea=${linea%%\%*}

	case $clave in
		''|'#'*|'%'*) ;;  # avoid empty & commented lines
		p) p+=("$linea");;
		a) a+=("$linea");;
		b) b+=("$linea");;
		c) c+=("$linea");;
		d) d+=("$linea");;
		s) s+=("$linea");;
		*) echo "error in line $linenumber: \"$clave $linea\""; exit 1;;
	esac

	(( ++linenumber ));
done < "$pre"

if (( ${#a[@]} != ${#p[@]} || ${#b[@]} != ${#p[@]} || ${#c[@]} != ${#p[@]} || ${#d[@]} != ${#p[@]} || ${#s[@]} != ${#p[@]} )); then
	echo "$(basename $0): number of p, a, b, c, d, s mismatch!!!";
	echo -e "\t \${#p[@]} = ${#p[@]}"
	echo -e "\t \${#a[@]} = ${#a[@]}"
	echo -e "\t \${#b[@]} = ${#b[@]}"
	echo -e "\t \${#c[@]} = ${#c[@]}"
	echo -e "\t \${#d[@]} = ${#d[@]}"
	echo -e "\t \${#s[@]} = ${#s[@]}"
	exit 1
fi

# all questions by default and no more than maximun
if (( questions < 1 )) || (( questions > ${#p[@]} )); then
	questions=${#p[@]}
fi

###############################################################################
# *.tex header
###############################################################################

cat > "$tex" <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\documentclass[a4paper,11pt]{article}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{array}               % m
\usepackage{amsmath}             % texto en modo matemático
\usepackage[spanish]{babel}      % español
\usepackage{caption}             % captionof
\usepackage[ddmmyyyy]{datetime}  % formato fecha (\today)
\usepackage{epsfig}              % epsfig
\usepackage[T1]{fontenc}         % soporte idiomas
\usepackage{geometry}            % geometry
\usepackage{graphicx}            % includegraphics
\usepackage{listings}            % listado de fuentes
\usepackage{minted}              % código \usepackage[cache=false]{minted}
\usepackage{multicol}            % varias columnas
\usepackage{wrapfig}             % protect includegraphics inside multicols
\usepackage{xcolor}              % gray

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\geometry{margin=7mm,top=15mm,bottom=15mm}

\lstset{
	aboveskip=0pt,
	alsoletter={\%},
	basicstyle=\ttfamily,
	belowskip=0pt,
	breaklines=true,
	extendedchars=true,
	inputencoding=utf8,
	keepspaces=true,
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
	showspaces=false,
	showstringspaces=false,
	showtabs=false,
	tabsize=2
}

\lstdefinestyle{n}{numbers=left}
\lstdefinestyle{s}{basicstyle=\small\ttfamily}
\lstdefinestyle{fn}{basicstyle=\footnotesize\ttfamily}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\setminted{autogobble,breaklines,tabsize=2}

%\usemintedstyle{xcode} % B/W solution to red square problem
\usepackage{etoolbox,xpatch} % color solution to red square problem
\makeatletter
\AtBeginEnvironment{minted}{\dontdofcolorbox}
\def\dontdofcolorbox{\renewcommand\fcolorbox[4][]{##4}}
\xpatchcmd{\inputminted}{\minted@fvset}{\minted@fvset\dontdofcolorbox}{}{}
\xpatchcmd{\mintinline}{\minted@fvset}{\minted@fvset\dontdofcolorbox}{}{} % see https://tex.stackexchange.com/a/401250/
\makeatother

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\encabezado}{
\begin{center}
\bfseries \large
\begin{tabular}{*{3}{p{0.31\textwidth}}}
	\includegraphics[height=12mm]{$image/ugr-logo.png} & \multicolumn{1}{c}{\includegraphics[height=12mm]{$image/etsiit-logo.png}} & \multicolumn{1}{r}{\includegraphics[height=12mm]{$image/icar-logo.png}} \\\\
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

	printf '%79s\n' | tr ' ' '%' >> "$tex"
	echo "% test $t" >> "$tex"
	printf '%79s\n' | tr ' ' '%' >> "$tex"
	echo >> "$tex"
	echo '\encabezado' >> "$tex"
	echo >> "$tex"
	echo "{\Large \bfseries \noindent Test $t: 10 puntos.}" >> "$tex"
	echo >> "$tex"
	good=`printf '%2.2f' $(bc -l <<< "10/$questions")`
	bad=`printf '%2.2f' $(bc -l <<< "10/(3*$questions)")`
	echo "\noindent Escriba la opción correcta dentro de la casilla debajo de cada número de pregunta. Cada respuesta correcta vale \$10/$questions = $good\$ puntos, \$0\$ si no se contesta o está claramente tachada y \$10/(3 \times $questions) = -$bad\$ si es errónea o no está claramente contestada. Se aconseja terminar de leer completamente cada pregunta antes de contestarla." >> "$tex"
	echo >> "$tex"
	echo '\vspace{1mm}' >> "$tex"
	echo >> "$tex"

	echo '\begin{minipage}{0.95\textwidth}' >> "$tex"
	echo '\begin{center}' >> "$tex"
	echo '\renewcommand\arraystretch{1.45}' >> "$tex"
	if ((questions <= MAXQ)); then
################################################################################
		echo "\begin{tabular}{|*{$questions}{m{${answer}mm}|}}" >> "$tex"
		echo '\hline' >> "$tex"
		for (( j = 1; j <= questions; ++j )); do
			echo -n $j >> "$tex"
			if (( j < questions )); then
				echo -n ' & ' >> "$tex"
			fi
		done
		echo '\\' >> "$tex"
		echo '\hline' >> "$tex"
		for (( j=1; j<$questions; ++j )); do
			echo -n '&' >> "$tex"
		done
		echo '\\' >> "$tex"
		echo '\hline' >> "$tex"
################################################################################
	else
################################################################################
		echo "\begin{tabular}{|*{$MAXQ}{m{${answer}mm}|}}" >> "$tex"
		echo '\hline' >> "$tex"
		for (( maxq = 1 ; maxq <= questions; maxq += MAXQ )); do
			for (( j = maxq; j < maxq + MAXQ ; ++j )); do
				if (( j <= questions )); then
					echo -n $j >> "$tex"
				else
					echo -n >> "$tex"
				fi
				if (( j < maxq + MAXQ - 1 )); then
					echo -n ' & ' >> "$tex"
				fi
			done
			echo '\\' >> "$tex"
			echo '\hline' >> "$tex"
			for (( j = maxq; j < maxq + MAXQ - 1; ++j )); do
				echo -n '&' >> "$tex"
			done
			echo '\\' >> "$tex"
			echo '\hline' >> "$tex"
		done
################################################################################
	fi
	echo '\end{tabular}' >> "$tex"
	echo '\end{center}' >> "$tex"
	echo '\end{minipage}' >> "$tex"
	echo >> "$tex"

################################################################################
# examen
################################################################################

	if (( $cols == 2 )); then
		echo "\begin{multicols}{$cols}" >> "$tex" # inicio de multicols
	fi

	echo '\begin{enumerate}' >> "$tex" # inicio de la lista de preguntas

	echo >> "$tex"
	printf '%79s\n' | tr ' ' '%' >> "$tex"
	echo >> "$tex"

	for (( i=0; i<$questions; ++i )); do
		n=$(( $RANDOM % ${#p2[@]} ))
		echo "\item ${p2[$n]}" >> "$tex"
		declare -a orden=("${a2[$n]}" "${b2[$n]}" "${c2[$n]}" "${d2[$n]}")
		width=0
		for o in "${orden[@]}"; do
			if [ "$width" -lt "${#o}" ]; then
				width=${#o}
			fi
		done
		if (( $width < $w4 )); then
			echo '\begin{multicols}{4}' >> "$tex"
		elif (( $width < $w2 )); then
			echo '\begin{multicols}{2}' >> "$tex"
		fi
   		echo "\begin{enumerate}" >> "$tex" # inicio de la lista de respuestas
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
			*) echo "respuesta incorrecta en ${p2[$n]}"; exit 1;;
		esac
		for j in a b c d; do
			respuesta="${desorden[$pos]}"
			echo "\item $respuesta" >> "$tex"
			if [ "$respuesta" == "$correcta" ]; then
				if [ "${sol[$t]}" ]; then
					sol[$t]="${sol[$t]} & $j"
				else
					sol[$t]="$j"
				fi
			fi
			(( ++pos ))
		done
		echo '\end{enumerate}' >> "$tex" # fin de la lista de respuestas
		if (( $width < $w2 )); then
			echo '\end{multicols}' >> "$tex"
		fi
		echo >> "$tex"
		printf '%79s\n' | tr ' ' '%' >> "$tex"
		echo >> "$tex"
		p2=("${p2[@]:0:$n}" "${p2[@]:$(($n + 1))}")
		a2=("${a2[@]:0:$n}" "${a2[@]:$(($n + 1))}")
		b2=("${b2[@]:0:$n}" "${b2[@]:$(($n + 1))}")
		c2=("${c2[@]:0:$n}" "${c2[@]:$(($n + 1))}")
		d2=("${d2[@]:0:$n}" "${d2[@]:$(($n + 1))}")
		s2=("${s2[@]:0:$n}" "${s2[@]:$(($n + 1))}")
	done

	echo '\end{enumerate}' >> "$tex" # fin de la lista de preguntas

	if (( $cols == 2 )); then
		echo '\end{multicols}' >> "$tex" # fin de multicols
	fi

	echo "\cleardoublepage$empty" >> "$tex"
	echo >> "$tex"
done

################################################################################
# tabla de respuestas
################################################################################

printf '%79s\n' | tr ' ' '%' >> "$tex"
echo '% soluciones' >> "$tex"
printf '%79s\n' | tr ' ' '%' >> "$tex"
echo "{\large \bf Asignatura: $subject \hfill Examen: $filename \hfill $date}" >> "$tex"
echo >> "$tex"

################################################################################
# short
################################################################################
if (( questions <= MAXQ )); then
	for (( t2 = 1; t2 <= tests; t2 += MAXT )); do # split long tables
		echo '\begin{center}' >> "$tex"
		echo '\renewcommand\arraystretch{1.45}' >> "$tex"
		echo "\begin{tabular}{c|*{$questions}{m{${answer}mm}|}}" >> "$tex"
		echo "\cline{2-$((questions + 1))}" >> "$tex"
		echo -n 'n' >> "$tex"
		for (( q = 1; q <= $questions; ++q )); do
			echo -n " & $q" >> "$tex"
		done
		echo '\\' >> "$tex"
		echo "\cline{2-$((questions + 1))}" >> "$tex"
		echo "\cline{2-$((questions + 1))}" >> "$tex"
		for (( t = t2; t <= t2 + MAXT - 1 && t <= tests; ++t )); do
			partial="${sol[$t]}"
			position=$(( 4 * (questions -1) + 1 ))
			echo "$t & ${partial:0:$position} \\\\ \cline{2-$((questions + 1))}" >> "$tex"
		done
		echo '\end{tabular}' >> "$tex"
		echo '\end{center}' >> "$tex"
		echo >> "$tex"
	done
################################################################################
# long
################################################################################
else
	for (( t = 1; t <= tests; ++t )); do
		echo "$t" >> "$tex"
		echo '\begin{center}' >> "$tex"
		echo '\renewcommand\arraystretch{1.45}' >> "$tex"
		echo "\begin{tabular}{|*{$MAXQ}{m{${answer}mm}|}}" >> "$tex"
		echo '\hline' >> "$tex"
		all=${sol[$t]}
		for (( maxq = 0; maxq < questions; maxq += MAXQ )); do
			for (( j = maxq; j < maxq + MAXQ; ++j )); do
				if (( j < questions )); then
					echo -n $((j + 1)) >> "$tex"
				else
					echo -n >> "$tex"
				fi
				if (( j < maxq + MAXQ - 1 )); then
					echo -n ' & ' >> "$tex"
				fi
			done
			echo '\\' >> "$tex"
			echo '\hline' >> "$tex"
			for (( j = maxq; j < maxq + MAXQ; ++j )); do
				if (( j < questions)); then
					echo -n ${all:$((4 * j)):1} >> "$tex"
				else
					echo -n >> "$tex"
				fi
				if (( j < maxq + MAXQ - 1)); then
					echo -n ' & ' >> "$tex"
				fi
			done
			echo '\\' >> "$tex"
			echo '\hline' >> "$tex"
		done
		echo '\end{tabular}' >> "$tex"
		echo '\end{center}' >> "$tex"
		echo >> "$tex"
	done
fi
################################################################################

printf '%79s\n' | tr ' ' '%' >> "$tex"
echo >> "$tex"
echo '\end{document}' >> "$tex"

###############################################################################
