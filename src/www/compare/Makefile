all: charts.js modulus.html modulus.js modular-exponentiation.html modular-exponentiation.js \
	montgomery-square.html montgomery-square.js \
	multiplication.html multiplication.js square.html square.js

clean:
	rm -f *.html *.js

%.js: %.coffee
	coffee -c $<

%.html: %.md
	python -m markdown -x codehilite $< -f $@ 

.PHONY: all clean
