Uso:
----

1. crear un fichero de preguntas siguiendo el siguiente formato:


	p ¿Cuánto es 2 + 2?
	a 1
	b 2
	c 3
	d 4
	s d


2. Generar latex a partir de fichero de preguntas con test.sh


	test.sh -c 2 -p preguntas.pre -q 20 -s "Arquitectura de Computadores" -t 32


3. generar fichero pdf a partir de fichero latex


	latexmk -pdf preguntas.tex


Opciones del script:
--------------------

	usage: test.sh -p file.pre [options]
		 -c 	 number of columns (1|2), 1 by default
		 -d 	 don't show date, 01/04/2016 by default
		 -e 	 empty page after every test, by default no
		 -h 	 show this help
		 -i 	 image directory, 
		 -p 	 pre file, mandatory
		 -q 	 number of questions, 10 by default
		 -s 	 subject, mandatory
		 -t 	 number of tests, 1 by default
