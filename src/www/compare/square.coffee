$ () ->
  class Chart extends DataTypeComparisonChart
    title:      'Computation Time of Square by Implentation'
    container:  'square_chart'

    dataTypes:  ['jsbn', 'Long']
    bitLengths: [1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584, 4096]
#    bitLengths: [8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80, 96, 112, 128]
#    bitLengths: [8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64]
#    bitLengths: [65, 66, 67]
    blockSize:  500
    standardLong: 'Long'
    
    operators:
      BigInt:     (A) -> mult A[j], A[j] for j in [0...A.length]
      jsbn:       (A) ->
        for j in [0...A.length]
          r = nbi()
          A[j].squareTo r
          r
      Long:       (A) -> A[j].sq() for j in [0...A.length]
      
    getOperandLengths: (L) -> [L]
    
    new this

  class Chart extends DataTypeComparisonChart
    standardLong = Long.prototype.constructor.name
    
    title:        'Relative Computation Time of Square by Digit Width'
    container:    'digit_width_chart'
    standardLong: standardLong
    yAxisTitle:   standardLong + ' = 1.0'
    
    dataTypes:    ['Long14', 'Long15', 'Long26', 'Long28', 'Long29', 'Long30']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584, 4096]    
    blockSize:    100
    
    operators:
      Long14:     (A) -> A[j].sq() for j in [0...A.length]
      Long15:     (A) -> A[j].sq() for j in [0...A.length]
      Long26:     (A) -> A[j].sq() for j in [0...A.length]
      Long28:     (A) -> A[j].sq() for j in [0...A.length]
      Long29:     (A) -> A[j].sq() for j in [0...A.length]
      Long30:     (A) -> A[j].sq() for j in [0...A.length]

    getOperandLengths: (L) -> [L]

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

  
    new this


  class Chart extends DataTypeComparisonChart
    title:      'Relative Computation Time of Square by Variant'
    container:  'AB_chart'
    yAxisTitle: 'LongA = 1.0'

    dataTypes:  ['LongA', 'LongB']
    bitLengths: [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]
    blockSize:  200
    
    operators:
      LongA:  (A) ->  new Long Long._sqA A[j].digits for j in [0...A.length]
      LongB:  (A) ->  new Long Long._sqB A[j].digits for j in [0...A.length]

    getOperandLengths: (L) -> [L]

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes.LongA[i] for t, i in @totalTimes[name])

    new this
  
#Computation Time of Square by Implentation[389]: Long: op0: 478993441,536870805,757 charts.js:589
# Computation Time of Square by Implentation[389]: Result Digits: charts.js:589
# Computation Time of Square by Implentation[389]:   jsbn:       425770049,465103279,304594790,536710052,574563 charts.js:589
# Computation Time of Square by Implentation[389]:   Long:       425770049,465103279,304594790,536710053,574562 charts.js:589
# Computation Time of Square by Implentation[389]: Result Hex: charts.js:589
# Computation Time of Square by Implentation[389]:   jsbn:       477329961743483678484298869669438481 charts.js:589
# Computation Time of Square by Implentation[389]:   Long:       477328265339939186374715345559999249473 charts.js:589
#
  x = new Long [233524513,536870909,74]
  t = x.msb()
  while t >= 0
    if x.bit t
      x.bitset t, 0

      z = x.sq()
      y = x.mul x
      if z.eq y
        x.bitset t, 1
        
    t--

  window.x = x