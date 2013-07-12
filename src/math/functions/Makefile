all: functions-14-bit.js functions-15-bit.js functions-26-bit.js \
	functions-28-bit.js functions-29-bit.js functions-30-bit.js

clean:
	rm -f *.js functions-??-bit.coffee

%.js: %.coffee
	coffee -c $<

# specialize-functions.coffee replaces a number of variables which are essentially constants with
# literal values: __width__, __base__, and all other identifiers surrounded by double underscores.

functions-14-bit.coffee functions-15-bit.coffee: functions-small.coffee specialize-functions.coffee
	coffee specialize-functions.coffee small

functions-26-bit.coffee functions-28-bit.coffee functions-29-bit.coffee: functions-medium.coffee specialize-functions.coffee
	coffee specialize-functions.coffee medium

functions-30-bit.coffee: functions-large.coffee specialize-functions.coffee
	coffee specialize-functions.coffee large

FUNCTION_SECTIONS = base.coffee operations.coffee exports.coffee preamble.coffee 

functions-small.coffee: $(FUNCTION_SECTIONS) critical-small.coffee
	cat preamble.coffee base.coffee critical-small.coffee operations.coffee exports.coffee >$@

functions-medium.coffee: $(FUNCTION_SECTIONS) critical-medium.coffee
	cat preamble.coffee base.coffee critical-medium.coffee operations.coffee exports.coffee >$@

functions-large.coffee: $(FUNCTION_SECTIONS) critical-large.coffee
	cat preamble.coffee base.coffee critical-large.coffee operations.coffee exports.coffee >$@

.PHONY: all clean



