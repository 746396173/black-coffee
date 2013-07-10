<html>
<head>
<script src="../lib/BigInt.js"></script>

<script src="../lib/jsbn/jsbn.js"></script>
<script src="../lib/jsbn/jsbn2.js"></script>
<script src="../lib/jsbn/prng4.js"></script>
<script src="../lib/jsbn/rng.js"></script>

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
<script src="montgomery-square.js"></script>

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

Squaring With Montgomery Reduction
==================================

If there is a missig algorithm in The Handbook of Applied Cryptography, it is a squaring algorithm
with Montgomery reduction.  It is not difficult to derive from the algorithms presented, but it is
not entirely trivial either.

<p>
  <div id="method_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of square-modulo, reduce-square,
	and montgomery-square.
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
  <div id="digit_width_chart">
    <p>
      <span class="link">
	Compute and show a chart comparing the running time of squaring in various digit widths.
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
  <div id="AB_chart">
    <p>
      <span class="link">
	Compute and show LongA/LongB comparison chart.
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
