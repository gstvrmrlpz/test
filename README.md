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

example:
	test.sh -c 2 -p file.pre -q 20 -s "Arquitectura de Computadores" -t 32

where file.pre is a file with questions following the next format:
	p ¿How much is 2 + 2?
	a 1
	b 2
	c 3
	d 4
	s d

