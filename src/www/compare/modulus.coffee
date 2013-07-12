$ () ->
  class Chart extends DataTypeComparisonChart
    title:      'Computation Time by Implementation'
    container:  'implementation_chart'
    autoRepeat: true
    
    dataTypes:    ['jsbn', 'Long']
    bitLengths:   [8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 448, 512, 640, 768, 896, 1024, 1280, 1536, 1792, 2048]
    blockSize:    200
    warmUpLength: 10
    standardLong: 'Long'
        
    operators:
      BigInt:     (A, M) -> mod A[j], M[j] for j in [0...A.length]
      jsbn:       (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long:       (A, M) -> A[j].mod M[j] for j in [0...A.length]

    getOperandLengths: (L) -> [2*L, L]

    new this

  class Chart extends DataTypeComparisonChart
    standardLong = Long.prototype.constructor.name
    
    title:        'Relative Computation Time by Digit Width'
    container:    'digit_width_chart'
    autoRepeat:   true
    standardLong: standardLong
    yAxisTitle:   standardLong + ' = 1.0'
    
    dataTypes:    ['Long14', 'Long15', 'Long26', 'Long28', 'Long29', 'Long30']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]    
#    bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#    bitLengths:   [8, 16, 32, 64, 128]
#    bitLengths:   [8, 16, 32, 64]
#    bitLengths:   [18, 20, 22, 24]
#     bitLengths:   [36, 40, 44, 48, 52, 56, 60]
#     bitLengths:   [36, 40, 44, 48]
#     bitLengths:   [49, 50, 51]
#     bitLengths:   [52]
    
#    bitLengths:   [52, 56, 60, 64]
#    bitLengths:   [26, 28, 30, 32]
#    bitLengths:   [8, 9, 10, 11, 12, 13, 14, 15, 16]
#    bitLengths: [450]
    blockSize:    200
    warmUpLength: 10
    
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

    new this


