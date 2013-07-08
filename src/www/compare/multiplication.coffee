$ ->
  class MultiplicationComparisonChart extends DataTypeComparisonChart
    title: 'Multiplication'
    
    operators:
      BigInt:     (A, B) -> mult A[j], B[j] for j in [0...A.length]
      jsbn: (A, B) ->
        for j in [0...A.length]
          c = new BigInteger
          A[j].multiplyTo B[j], c
          c
      Long:       (A, B) -> A[j].mul B[j] for j in [0...A.length]
      LongA:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      LongB:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long14:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long15:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long26:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long28:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long29:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long30:     (A, B) -> A[j].mul B[j] for j in [0...A.length]


    getOperandLengths: (L) -> [L, L]


  bitLengths = [1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584, 4096]
  dataTypes = ['BigInt', 'jsbn', 'Long']
  multiplicationChart = new MultiplicationComparisonChart 'multiplication_group', bitLengths, 200, dataTypes
  multiplicationChart.autoRepeat = true
  
  window.multiplicationChart = multiplicationChart

  class DigitSizeComparisonChart extends DataTypeComparisonChart
    title: 'Long Digit Size'

    constructor: (container, Ls, N) ->
      super container, Ls, N, ['Long14', 'Long15', 'Long26', 'Long28', 'Long29', 'Long30']
      @standardLong = Long.prototype.constructor.name
      @yAxisTitle = @standardLong + ' = 1.0'
    
    operators:
      BigInt:     (A, B) -> mult A[j], B[j] for j in [0...A.length]
      jsbn: (A, B) ->
        for j in [0...A.length]
          c = new BigInteger
          A[j].multiplyTo B[j], c
          c
      LongA:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      LongB:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long14:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long15:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long26:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long28:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long29:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long30:     (A, B) -> A[j].mul B[j] for j in [0...A.length]


    getOperandLengths: (L) -> [L, L]

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

  bitLengths = [1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584, 4096]
  digitSizeChart = new DigitSizeComparisonChart 'digit_size_group', bitLengths, 100
  digitSizeChart.autoRepeat = true
  window.digitSizeChart = digitSizeChart

  class KaratsubaComparisonChart extends ParameterComparisonChart
    title: 'Karatsuba Multiplier Threshold Parameter'
    
    operators:
      Long:  (v, A, B) ->
        Long._kmul.Threshold = v
        A[j].mul B[j] for j in [0...A.length]

    getOperandLengths: (L) -> [L, L]

  dataTypes = ['Long26', 'Long28', 'Long30']
  bitLengths = [1024, 1536, 2048, 2560, 3072]
  parameterValues = do () -> (v for v in [10..100] by 1)
  karatsubaChart = new KaratsubaComparisonChart 'karatsuba_chart', bitLengths, 200, parameterValues
  karatsubaChart.repeatCount = 10
  #karatsubaChart.scheduleCalculations taskQueue
  window.karatsubaChart = karatsubaChart

#  taskQueue.process()
#   x = new Long29 34765
#   y = new Long29 38613

  x = window.x = new Long Math.PI * Math.pow(2, 53)

  i = x.msb()
  while i >= 0
    if x.bit i
      x.bitset i, 0
      if x.sq()+0 == x*(x+0)
        x.bitset i, 1
    i--
    
#   i = 0
#   while i < 29
#     if x.bit i
#       x.bitset i, 0
#       if (x.mul y) + 0 == x * y
#         x.bitset i, 1
#     i++

#   i = 0
#   while i < 29
#     if y.bit i
#       y.bitset i, 0
#       if (x.mul y) + 0 == x * y
#         y.bitset i, 1
#     i++

#   window.x = x
#   window.y = y
#
  
