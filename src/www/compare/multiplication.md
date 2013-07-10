<html>
<head>
<script src="../lib/BigInt.js"></script>

<script src="../lib/jsbn/jsbn.js"></script>
<script src="../lib/jsbn/jsbn2.js"></script>
<script src="../lib/jsbn/prng4.js"></script>
<script src="../lib/jsbn/rng.js"></script>

<!--
Unrolled multipliers.
<script src="math/mul.js"></script>
<script src="math/mul-26-bit.js"></script>
<script src="math/mul-28-bit.js"></script>
<script src="math/mul-30-bit.js"></script>
-->

<script src="../platform.js"></script>
<script src="../math/functions-14-bit.js"></script>
<script src="../math/functions-15-bit.js"></script>
<script src="../math/functions-26-bit.js"></script>
<script src="../math/functions-28-bit.js"></script>
<script src="../math/functions-29-bit.js"></script>
<script src="../math/functions-30-bit.js"></script>
<script src="../math/long.js"></script>


<script src="../lib/jquery-1.8.2.min.js"></script>
<script src="../lib/highcharts.js"></script>

<script src="charts.js"></script>
<script src="multiplication.js"></script>

<style type="text/css">
body {
  font-family: "Lucida Grande", "Lucida Sans Unicode", Verdana, Arial, Helvetica, sans-serif;
}

h1, p {
  margin-left: 100px;
  width: 1024px;
}

pre {
  margin-left: 155px;
}

.chart {
  margin-left: 210px;
  width: 805px;
  height: 500px;
  border: 1px solid gray;
  display: none;
}

.spinner {
  position: relative;
  left: 369px;
  top: 217px;
}

div.codehilite pre span.c1 {
  color: blue;
}

.consistency_failure {
  border: 2px solid red;
}

.link {
  color: #3050e0;
  cursor: hand;
  text-decoration: underline;
  font-style: italic;
}

.clickable:hover {
  background: #5080f0;
  border: 0.5em solid #5080f0;
}

p .margin_centered {
  align: center;
}

.consistency_error {
  font-weight: bold;
  color: red;
  border: 3px solid black;
  padding: .5em;
  background: white;
  display: none;
}

</style>
</head>
<body> 

Multiplication
==============

Ordinary multiplication is not a performance-constraining operation in most cryptographic
algorithms, making this a less useful comparison than Modular Exponentiation or the Miller-Rabin
Probable Prime Test.  Nonetheless, it does expose the efficiency of the underlying digit
representation and multiplier technique.  While the ordinary multiplication operation per se
are not heavily used in cryptographic algorithms, each library uses only one technique to 
compute products, and the choice of technique affects the operations which are important.

Javascript uses 32-bit words internally when it can reliably determine that the values in a
computation are sufficiently small.  In some cases, this is explicit, as in a literal assignment
or a bit operation (|, &, <<, etc), in other cases, it is by inference.  The depth of inference is
largely the same, with one significant exception.  Where operations are entirely word-sized, all
of the popular engines produce significantly faster code.  The trick to making multiple-precision
fast in Javascript is to keep computations to within a single word and to give the compiler enough
hints that it can infer the use of 32 bit words is safe.

There are two main techinques for achieving this.  One is to choose a base small enough so that
the product of two digits is word-sized.  This typically means 15 bits, since 15 * 2 = 30 < 32;
one might think that 16 would work, except that all engines seem to promote all 32 bit products to
float, probably due to sign representation.  BigInt.js uses this approach with 15 bits per digit.
The other option is to fill the word in storage, but to split each word into two subdigits and
compute a four-term, two-word product.  jsbn.js and this library both take that approach.  The
best size for this depends on the platform.  Chrome and Opera both perform best with 29-bit
digits, while Firefox and Safari work best with 30.

Another design decision is the functional structure of the multiplier. The obvious way to perform
a multiple-precision product with operands of length M and N digits will require M+N single digit
multiplications, and one might implement this as a single function with a nested loop, or as two
functions, one implementing the outer loop, the other the inner. This library uses a single
function, while both BigInt.js and jsbn.js use two functions.

<!-- build table for this -->
On Chrome 27/Mac BigInt.js and jsbn.js have approximately 5x and 2.5x the running time of this
library; on Safari, BigInt.js takes 9x as long, and jsbn.js about 50x; the relative run times on
Firefox are unstable from page load to page load, but this library runs in about 1/3 the time of
BigInt.js, and jsbn.js is usually intermediate between the two; on Opera, jsbn.js takes about 3x
as long to run, BigInt.js, just over 10x.

The one case in which inference is obviously dissimilar relates to type propagation through array
reference.  Both Chrome and Safari can infer that 

    :::JavaScript
    x[i] = y & mask   // use bit operation to tell compiler that the value is word-sized
    ...
    z = x[i] + 2      // Chrome and Safari know that z is also word-sized

Firefox and Opera fail to do so.  They require a bitwise operation on the reference 

    :::JavaScript
    z = (x[i]|0) + 2  // Firefox and Opera need a hint

<p>
  <div id="multiplication_group">
    <p>
      <span class="link">
	Compute and show chart comparing running time of ordinary multiplication by BigInt, jsbn,
	and Long.
      </span>
    </p>
    <div class="chart">
    </div>
    <span class="consistency_error">
      Inconsistent results in comparison.  View console for details.
    </span>
  </div>
</p>

This library can support digit sizes from 2 bits to 30.  It is built with 14, 15, 26, 28, 29, and
30 bit digit integers; adding others require a slight change to the build scripts, but it is
essentially trivial.  The chart below shows the execution time of integers in various bases relative
to the default base for this platform.

<p>
  <div id="digit_size_group">
    <p>
      <span class="link">
	Compute and show chart comparing running time of ordinary multiplication by Longs with various
	digit sizes.
      </span>
    </p>
    <div class="chart">
    </div>
    <span class="consistency_error">
      Inconsistent results in comparison.  View console for details.
    </span>
  </div>
</p>

</body>
</html>

<!--
Local Variables:
mode: html
end:
--->
