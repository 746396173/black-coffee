all: functions-26-bit.js functions-28-bit.js functions-30-bit.js long.js \
	primes.js ring.js ring-26-bit.js ring-28-bit.js ring-30-bit.js rsa.js power-tree.js \
	test-functions-26-bit.js test-functions-28-bit.js test-functions-30-bit.js
#	mul.js mul-26-bit.js mul-28-bit.js mul-30-bit.js \

clean:
	rm -f *.js functions-??-bit.coffee mul-??-bit.coffee mul.coffee

%.js: %.coffee
	coffee -c $<

functions-26-bit.coffee functions-28-bit.coffee functions-30-bit.coffee: functions.coffee specialize-functions.coffee
	coffee specialize-functions.coffee

#mul.coffee: mul-prefix.coffee make-mul.coffee
#	coffee make-mul.coffee

mul-26-bit.coffee mul-28-bit.coffee mul-30-bit.coffee: mul.coffee specialize-mul.coffee
	coffee specialize-mul.coffee

ring-26-bit.coffee ring-28-bit.coffee ring-30-bit.coffee: ring.coffee specialize-ring.coffee
	coffee specialize-ring.coffee

test-functions-26-bit.coffee test-functions-28-bit.coffee test-functions-30-bit.coffee: test-functions.coffee specialize-test-functions.coffee
	coffee specialize-test-functions.coffee

.PHONY: all clean



