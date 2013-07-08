$ () ->
  class ModulusComparisonChart extends DataTypeComparisonChart
    title: 'Modulo'
    
    operators:
      BigInt:     (A, M) -> mod A[j], M[j] for j in [0...A.length]
      jsbn:       (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long:       (A, M) -> A[j].mod M[j] for j in [0...A.length]

    getOperandLengths: (L) -> [2*L, L]

  bitLengths = [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]
  #bitLengths = [8, 16, 32, 64, 128]
  dataTypes = ['jsbn', 'Long']
  modulusChart = new ModulusComparisonChart 'modulus_group', bitLengths, 200, dataTypes
  modulusChart.autoRepeat = true
  window.modulusChart = modulusChart

  class DigitSizeComparisonChart extends DataTypeComparisonChart
    title: 'Long Digit Size'

    constructor: (container, Ls, N) ->
      #super container, Ls, N, ['Long14', 'Long15', 'Long26', 'Long28', 'Long29', 'Long30']
      super container, Ls, N, ['Long26', 'Long28', 'Long29', 'Long30']
      @standardLong = Long.prototype.constructor.name
      @yAxisTitle = @standardLong + ' = 1.0'
    
    operators:
      Long14:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long15:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long26:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long28:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long29:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long30:     (A, M) -> A[j].mod M[j] for j in [0...A.length]


    getOperandLengths: (L) -> [2*L, L]

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

  bitLengths = [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]
  #bitLengths = [8, 16, 32, 64, 128]
  digitSizeChart = new DigitSizeComparisonChart 'digit_size_group', bitLengths, 250
  digitSizeChart.autoRepeat = true
  window.digitSizeChart = digitSizeChart


  

