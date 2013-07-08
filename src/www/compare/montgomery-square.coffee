makeString = (ch, n) -> (ch for i in [0...n]).join ''
padRight = (s, n) -> if s.length >= n then s else s + makeString ' ', n - s.length

$ () ->
  { _cofactorMont, _liftMont, _mulMont, _reduceMont, _simpleSqmod, _sqMont, _trim } = Long
  
  class Chart extends DataTypeComparisonChart
    title:        'Relative Computation Time of Square-Modulo by Method'
    container:    'method_chart'
    yAxisTitle:   'LongA = 1.0'
    
    dataTypes:    ['LongA', 'LongB', 'LongC']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]    
#    bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#    bitLengths:   [8, 16, 32, 64, 128]
#    bitLengths:   [52, 56, 60, 64]
#    bitLengths:   [26, 28, 30, 32]
#    bitLengths:   [13, 14, 15, 16]
    blockSize:    100

    constructors:
      LongA:      (Xs) -> new Long x for x in Xs
      LongB:      (Xs) -> new Long _liftMont x.digits, @M.digits for x in Xs
      LongC:      (Xs) -> new Long _liftMont x.digits, @M.digits for x in Xs

    operators:
      LongA:     (A) -> new Long _simpleSqmod A[j].digits, @M.digits for j in [0...A.length]
      LongB:     (A) -> new Long _mulMont A[j].digits, A[j].digits, @M.digits, @w for j in [0...A.length]
      LongC:     (A) -> new Long _sqMont A[j].digits, @M.digits, @w for j in [0...A.length]

    standardizers:
      LongA:      (Xs) -> Xs
      LongB:      (Xs) -> new Long _reduceMont x.digits, @M.digits, @w for x in Xs
      LongC:      (Xs) -> new Long _reduceMont x.digits, @M.digits, @w for x in Xs

    standardLong: 'LongA'

    getOperandLengths: (L) -> [L]
    
    createOperands: (L, N) ->
      @M = Long.random L
      @M.digits[0] |= 1
      @w = _cofactorMont _trim @M.digits
      
      super L, N

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

  
    checkConsistency: () ->
      @report 'checking consistency for ' + @L + '-bit operands'
      @standardized = {}
      for name in @dataTypes
        @standardized[name] = @standardizers[name].call this, @results[name]
        
      for X, j in @standardized[@standardLong]
        for name in @dataTypes when name isnt @standardLong
          if not X.eq @standardized[name][j]
            return @reportConsistencyFailure j

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: ' + @M.digits

    new this


  class Chart extends DataTypeComparisonChart
    standardLong = Long.prototype.constructor.name
    
    title:        'Relative Computation Time of Square-Modulo by Digit Width'
    container:    'digit_width_chart'
    standardLong: standardLong
    yAxisTitle:   standardLong + ' = 1.0'
    
    dataTypes:    ['Long26', 'Long28', 'Long29', 'Long30']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]    
#    bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#    bitLengths:   [8, 16, 32, 64, 128]
#    bitLengths:   [52, 56, 60, 64]
#    bitLengths:   [26, 28, 30, 32]
#    bitLengths:   [8, 9, 10, 11, 12, 13, 14, 15, 16]
    blockSize:    10
    warmUpLength: 1
    
    constructors:
      Long26:      (Xs) -> new Long26 Long26._liftMont (new Long26 x).digits, @M26.digits for x in Xs
      Long28:      (Xs) -> new Long28 Long28._liftMont (new Long28 x).digits, @M28.digits for x in Xs
      Long29:      (Xs) -> new Long29 Long29._liftMont (new Long29 x).digits, @M29.digits for x in Xs
      Long30:      (Xs) -> new Long30 Long30._liftMont (new Long30 x).digits, @M30.digits for x in Xs

    operators:
      Long26:     (A) -> new Long26 Long26._sqMont A[j].digits, @M26.digits, @w26 for j in [0...A.length]
      Long28:     (A) -> new Long28 Long28._sqMont A[j].digits, @M28.digits, @w28 for j in [0...A.length]
      Long29:     (A) -> new Long29 Long29._sqMont A[j].digits, @M29.digits, @w29 for j in [0...A.length]
      Long30:     (A) -> new Long30 Long30._sqMont A[j].digits, @M30.digits, @w30 for j in [0...A.length]

    standardizers:
      Long26:      (Xs) -> new Long new Long26 Long26._reduceMont x.digits, @M26.digits, @w26 for x in Xs
      Long28:      (Xs) -> new Long new Long28 Long28._reduceMont x.digits, @M28.digits, @w28 for x in Xs
      Long29:      (Xs) -> new Long new Long29 Long29._reduceMont x.digits, @M29.digits, @w29 for x in Xs
      Long30:      (Xs) -> new Long new Long30 Long30._reduceMont x.digits, @M30.digits, @w30 for x in Xs
      
    getOperandLengths: (L) -> [L]

    createOperands: (L, N) ->
      @M = Long.random L
      @M.digits[0] |= 1

      @M26 = new Long26 @M
      @M28 = new Long28 @M
      @M29 = new Long29 @M
      @M30 = new Long30 @M
      
      @w26 = Long26._cofactorMont Long26._trim @M26.digits
      @w28 = Long28._cofactorMont Long28._trim @M28.digits
      @w29 = Long29._cofactorMont Long29._trim @M29.digits
      @w30 = Long30._cofactorMont Long30._trim @M30.digits
      
      super L, N

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

    checkConsistency: () ->
      @report 'checking consistency for ' + @L + '-bit operands'
      @standardized = {}
      for name in @dataTypes
        @standardized[name] = @standardizers[name].call this, @results[name]
        
      for X, j in @standardized[@standardLong]
        for name in @dataTypes when name isnt @standardLong
          if not X.eq @standardized[name][j]
            return @reportConsistencyFailure j

    reportConsistencyFailure: (j) ->
      ($ '#' + @container + ' div.chart').addClass 'consistency_failure'
      ($ '#' + @container + ' span.consistency_error').css 'display', 'inline'
      ($ '#' + @container + ' span.link').css 'display', 'none'

      @report 'consistency failure: set: ' + j
      for name in @dataTypes when (name.slice 0, 4) == 'Long'
        for op, i in @operands[name]
          @report name + ': op' + i + ': ' + op[j].digits
      for name in @dataTypes
        @report '  ' + (padRight name + ':', 12) + @standardized[name][j].toString()

      @repeatCount = 0
      @autoRepeat = false
      @queue.flush()
      @report 'base: (' + @standardLong + ') ' + @M.digits

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

  { log, max, random, sqrt } = Math
  { _bit, _bitset, _msb, _cofactorMont, _eq, _liftMont, _sqmod, _sqMont, _reduceMont } = Long
#   i = 0
#   ok = false
#   while ok and i < 100000
#     n = max 8, (log i)/(log 2) >>> 1
#     m = 1 | (1 << n) * random()
#     x = 1 | (1 << n) * random()
#     y = 1 | (1 << sqrt n) * random()

#     xs = [x]
#     ms = [m]
#     w = _cofactorMont ms

#     rs = _liftMont xs, ms, w
#     qs = _sqMont rs, ms, w

#     ys = _sqmod xs, ms
#     ts = _liftMont ys, ms, w

#     ok = _eq qs, ts
#     i++
    
#   if not ok
#     console.log 'inconsistency at ' + i
    
  xs = [30]
  ms = [31]
  w = _cofactorMont ms
  
  t = _msb xs
  while t >= 0
    if _bit xs, t
      _bitset xs, t, 0
      
      rs = _liftMont xs, ms, w
      qs = _mulMont rs, rs, ms, w
      
      ys = _sqmod xs, ms
      ts = _liftMont ys, ms, w

      if _eq qs, ts
        _bitset xs, t, 1

    t--
    
  rs = _liftMont xs, ms, w
  qs = _mulMont rs, rs, ms, w

  ys = _sqmod xs, ms
  ts = _liftMont ys, ms, w
  
  window.xs = xs
  window.ms = ms
  window.w = w
  window.rs = rs
  window.qs = qs
  window.ys = ys
  window.ts = ts
    
    