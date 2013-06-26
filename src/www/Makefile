ROOT=../..

all: browser.js compare.js
	mkdir -p $(ROOT)/build/www/lib/jsbn
	mkdir -p $(ROOT)/build/www/math
	cp $(ROOT)/src/www/index.html $(ROOT)/build/www/
	cp $(ROOT)/src/www/browser.js $(ROOT)/build/www/
	cp $(ROOT)/src/www/compare.js $(ROOT)/build/www/
	cp $(ROOT)/lib/BigInt.js $(ROOT)/build/www/lib/
	cp $(ROOT)/lib/highcharts.js $(ROOT)/build/www/lib/
	cp $(ROOT)/lib/jquery-1.8.2.min.js $(ROOT)/build/www/lib/
	cp $(ROOT)/lib/jsbn/*.js $(ROOT)/build/www/lib/jsbn/
	cp $(ROOT)/src/math/*.js $(ROOT)/build/www/math/

clean:
	rm compare.js
	rm -rf $(ROOT)/build/www/

%.js: %.coffee
	coffee -c $<

.PHONY: all clean
