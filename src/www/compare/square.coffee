$ () ->
  class Chart extends DataTypeComparisonChart
    title:      'Computation Time of Square by Implentation'
    container:  'square_chart'

    dataTypes:  ['jsbn', 'Long']
    bitLengths: [1024, 1280, 1536, 1792, 2048, 2560, 3072, 3584, 4096]
    blockSize:  100
    
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
  
