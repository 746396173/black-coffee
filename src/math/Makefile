all: long.js primes.js

clean:
	rm -f *.js

%.js: %.coffee
	coffee -c $<

.PHONY: all clean



