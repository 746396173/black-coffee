<html>
<head>
<script src="../lib/BigInt.js"></script>

<script src="../lib/jsbn/jsbn.js"></script>
<script src="../lib/jsbn/jsbn2.js"></script>
<script src="../lib/jsbn/prng4.js"></script>
<script src="../lib/jsbn/rng.js"></script>

<script>window.require = function () { return new Object }</script>
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
<script src="modular-exponentiation.js"></script>

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

p .margin_centered {
  align: center;
}

.consistency_error {
  font-weight: bold;
  display: none;
}

</style>
</head>
<body> 

Modular Exponentiation
======================

Modular exponentiation is a key operation in cryptography, perhaps _the_ key operation.  It is
imperative that this operation be as fast as possible.  Depending on the nature of the
computation, one of several algorithms may be used.  For small exponents, around 20 bits or less,
a very simply square-and-multiply approach is best.  For larger exponents, the sliding window
method is faster, and for very large exponents, Montgomery and Barrett reductions are more
efficient.

<p>
  <div id="fixed_exponent_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of modular exponentiation with a fixed
	small exponent by jsbn and Long.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="fixed_exponent_digit_width_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of modular exponentiation with a fixed
	small exponent by Longs with various digit sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>


<p>
  <div id="large_exponent_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of modular exponentiation with a large
	fixed odd base by BigInt, jsbn, and Long.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>



<p>
  <div id="large_exponent_digit_width_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of modular exponentiation with a large
	exponent by Longs with various digit sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>


<p>
  <div id="simple_v_sliding_chart_1024">
    <p>
      <span class="link">
	Compute and show a chart comparing square-and-multiply exponentiation with the sliding
	window method for 1024 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="simple_v_sliding_chart_2048">
    <p>
      <span class="link">
	Compute and show a chart comparing square-and-multiply exponentiation with the sliding
	window method for 2048 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="simple_v_sliding_chart_3072">
    <p>
      <span class="link">
	Compute and show a chart comparing square-and-multiply exponentiation with the sliding
	window method for 3072 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

The following three charts display the relative running time between ordinary sliding window
exponentiation (LongA) and sliding window exponentiation accelerated with Montgomery reduction
(LongB).  On both Chrome and Safari, the accelerated version is faster throughout the range of
exponent sizes, even for operands as small as 1024 bits.  On Firefox and Opera, smaller exponents
are better handled with the ordinary version.  The crossover for Firefox is at about 512 bits of
exponent, and on Opera about 256. (These observations were made on a 2.3GHz Intel i7 MacBook Pro
running OS/X 10.8.4 and the latest versions of the major browsers, as of July 2013.)

<p>
  <div id="sliding_v_montgomery_chart_1024">
    <p>
      <span class="link">
	Compute and show a chart comparing the sliding window method versus the sliding window
	method accelerated with Montgomery reduction
	for 1024 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="sliding_v_montgomery_chart_2048">
    <p>
      <span class="link">
	Compute and show a chart comparing the sliding window method versus the sliding window
	method accelerated with Montgomery reduction
	for 2048 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="sliding_v_montgomery_chart_3072">
    <p>
      <span class="link">
	Compute and show a chart comparing the sliding window method versus the sliding window
	method accelerated with Montgomery reduction
	for 3072 bit operands and various exponent sizes.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>

<p>
  <div id="sliding_v_montgomery_group_alt">
    <p>
      <span class="link">
	Compute and show a chart comparing the sliding window method versus the sliding window
	method accelerated with Montgomery reduction.
      </span>
      <span class="consistency_error">
	Computation halted: inconsistent results in comparison.  View console for details.
      </span>
    </p>
    <div class="chart">
    </div>
  </div>
</p>


</body>
</html>

<!--
Local Variables:
mode: html
end:
--->
