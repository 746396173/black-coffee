$ () ->
  class Chart extends DataTypeComparisonChart
    E = 65537
    
    title:        'Computation Time by Implementation \u2014 (Fixed Exponent e = ' + E + ')'
    container:    'fixed_exponent_chart'
    autoRepeat:   true
    
    dataTypes:    ['BigInt', 'jsbn', 'Long']
    bitLengths:   [1024, 1280, 1536, 1792, 2048]
#    bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#    bitLengths:   [36, 40, 44, 48, 52, 56]
#    bitLengths:   [58]
#     bitLengths:   [256, 288, 320, 352, 384, 416, 448, 480]
#     bitLengths:   [288, 320, 352, 384, 416, 448]
#     bitLengths:   [452, 456, 460, 464, 468, 472, 476]
#     bitLengths:   [449, 450]
#     bitLengths:   [448, 449]
    blockSize:    50
    warmUpLength: 1
    standardLong: 'Long'

    exp:
      BigInt: (new Long E).toBigInt()
      jsbn:   (new Long E).toBigInteger()
      Long:   new Long E
      
    operators:
      BigInt:     (A) -> powMod A[j], @exp.BigInt, @M.BigInt for j in [0...A.length]
      jsbn:       (A) -> A[j].modPow @exp.jsbn, @M.jsbn for j in [0...A.length]
      Long:       (A) -> A[j].powmod @exp.Long, @M.Long for j in [0...A.length]
      
    getOperandLengths: (L) -> [L]

    createOperands: (L, N) ->
      M = Long.random L
      M.digits[0] |= 1

      @M =
        BigInt: M.toBigInt()
        jsbn:   M.toBigInteger()
        Long:   M
      
      super L, N

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: (' + @standardLong + ') ' + @M[@standardLong].digits
      
    new this
    
  class Chart extends DataTypeComparisonChart
    standardLong = Long.prototype.constructor.name
    E = 65537
    
    title:        'Relative Computation Time by Digit Width \u2014 (Fixed Exponent e = ' + E + ')'
    container:    'fixed_exponent_digit_width_chart'
    autoRepeat:   true
    standardLong: standardLong
    yAxisTitle:   standardLong + ' = 1.0'
    
    dataTypes:    ['Long26', 'Long28', 'Long29', 'Long30']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]    
#     bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#     bitLengths:   [8, 16, 32, 64, 128]
#     bitLengths:   [8, 16, 32, 64]
#     bitLengths:   [8, 16, 32]
#     bitLengths:   [36, 40, 44, 48, 52, 56, 60]
#     bitLengths:   [36, 40, 44, 48]
#     bitLengths:   [49, 50, 51]
#     bitLengths:   [52]
    
#    bitLengths:   [52, 56, 60, 64]
#    bitLengths:   [26, 28, 30, 32]
#    bitLengths:   [8, 9, 10, 11, 12, 13, 14, 15, 16]
#    bitLengths: [450]
    blockSize:    10
    warmUpLength: 1
    
    exp:
      Long26:   new Long26 E
      Long28:   new Long28 E
      Long29:   new Long29 E
      Long30:   new Long30 E
      
    operators:
      Long26:     (A) -> A[j].powmod @exp.Long26, @M.Long26 for j in [0...A.length]
      Long28:     (A) -> A[j].powmod @exp.Long28, @M.Long28 for j in [0...A.length]
      Long29:     (A) -> A[j].powmod @exp.Long29, @M.Long29 for j in [0...A.length]
      Long30:     (A) -> A[j].powmod @exp.Long30, @M.Long30 for j in [0...A.length]

    getOperandLengths: (L) -> [L]

    createOperands: (L, N) ->
      M = Long.random L
      M.digits[0] |= 1

      @M =
        Long26:   new Long26 M
        Long28:   new Long28 M
        Long29:   new Long29 M
        Long30:   new Long30 M
      
      super L, N

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: (' + @standardLong + ') ' + @M[@standardLong].digits
      
    new this


  class Chart extends DataTypeComparisonChart
    title:        'Computation Time by Implementation \u2014 Large Exponent'
    container:    'large_exponent_chart'
    rangeType:    'logarithmic'
    yAxisTitle:   'seconds/operation'
    autoRepeat:   true
    
    dataTypes:    ['BigInt', 'jsbn', 'Long']
    bitLengths:   [1024, 1280, 1536, 1792, 2048]
    blockSize:    1
    warmUpLength: 1
    standardLong: 'Long'

    operators:
      BigInt:     (A) -> powMod A[j], @exp.BigInt, @M.BigInt for j in [0...A.length]
      jsbn:       (A) -> A[j].modPow @exp.jsbn, @M.jsbn for j in [0...A.length]
      Long:       (A) -> A[j].powmod @exp.Long, @M.Long for j in [0...A.length]
      
    getOperandLengths: (L) -> [L]

    createOperands: (L, N) ->
      E = Long.random L

      @exp =
        BigInt: (new Long E).toBigInt()
        jsbn:   (new Long E).toBigInteger()
        Long:   new Long E

      M = Long.random L
      M.digits[0] |= 1

      @M =
        BigInt: M.toBigInt()
        jsbn:   M.toBigInteger()
        Long:   M
      
      super L, N

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: t/(1000*@totalCounts[name]) for t in @totalTimes[name]
        
    new this
    

  class Chart extends DataTypeComparisonChart
    standardLong = Long.prototype.constructor.name
    
    title:        'Relative Computation Time by Digit Width \u2014 Large Exponent'
    container:    'large_exponent_digit_width_chart'
    autoRepeat:   true
    standardLong: standardLong
    yAxisTitle:   standardLong + ' = 1.0'
    
    dataTypes:    ['Long26', 'Long28', 'Long29', 'Long30']
    bitLengths:   [1024, 1280, 1536, 1792, 2048, 2304, 2560, 2816, 3072]
#    bitLengths:   [912, 928, 944, 960, 976, 992, 1008]
#    bitLengths:   [768]
#    bitLengths:   [8, 16, 32, 64, 128, 256, 512]
#    bitLengths:   [8, 16, 32, 64, 128]
#    bitLengths:   [52, 56, 60, 64]
#    bitLengths:   [26, 28, 30, 32]
#    bitLengths:   [8, 9, 10, 11, 12, 13, 14, 15, 16]
#    bitLengths: [450]
    blockSize:    1
    warmUpLength: 1
    
    operators:
      Long26:     (A) -> A[j].powmod @exp.Long26, @M.Long26 for j in [0...A.length]
      Long28:     (A) -> A[j].powmod @exp.Long28, @M.Long28 for j in [0...A.length]
      Long29:     (A) -> A[j].powmod @exp.Long29, @M.Long29 for j in [0...A.length]
      Long30:     (A) -> A[j].powmod @exp.Long30, @M.Long30 for j in [0...A.length]

    getOperandLengths: (L) -> [L]

    createOperands: (L, N) ->
      E = Long.random L

      @exp =
        Long26:   new Long26 E
        Long28:   new Long28 E
        Long29:   new Long29 E
        Long30:   new Long30 E
        
      M = Long.random L
      M.digits[0] |= 1

      @M =
        Long26:   new Long26 M
        Long28:   new Long28 M
        Long29:   new Long29 M
        Long30:   new Long30 M

      super L, N

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes[@standardLong][i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: (' + @standardLong + ') ' + @M[@standardLong].digits
      for name, E of @exp
        @report 'exp: ' + name + ': ' + E.digits
      
    window.chart = new this


  class Chart extends DataTypeComparisonChart
    title:      'Relative Computation Time by Method \u2014 Small Exponent, '
    yAxisTitle:   'LongA = 1.0'
    autoRepeat:   true

    dataTypes:    ['LongA', 'LongB']
    bitLengths:   [8, 10, 12, 14, 16, 18, 20, 22, 24]
#    bitLengths:   [16, 20, 24, 28, 32, 36, 40, 44, 48]
#    bitLengths:   [32, 40, 48, 56, 64, 72, 80, 88, 96]
#    bitLengths:   [128, 144, 160, 176, 192, 208, 224, 240]
    blockSize:    5
    warmUpLength: 1
    standardLong: 'LongA'
    
    constructor: (@container, @B) ->
      super()
      @title += @B + '-bit base'
      
    operators:
      LongA:  (A, E) ->
        prior = Long._powmod.SimplePowmodBitLimit
        Long._powmod.SimplePowmodBitLimit = Infinity
        
        R = A[j].powmod E[j], @M for j in [0...A.length]
        
        Long._powmod.SimplePowmodBitLimit = prior

        R

      LongB:  (A, E) ->
        priorA = Long._powmod.SimplePowmodBitLimit
        priorB = Long._powmod.SlidingWindowPowmodBitLimit
        
        Long._powmod.SimplePowmodBitLimit = 0
        Long._powmod.SlidingWindowPowmodBitLimit = Infinity
        
        R = A[j].powmod E[j], @M for j in [0...A.length]

        Long._powmod.SimplePowmodBitLimit = priorA
        Long._powmod.SlidingWindowPowmodBitLimit = priorB

        R
        
    getOperandLengths: (L) -> [@B, L]

    createOperands: (L, N) ->
      super L, N
      
      @M = Long.random @B
      @M.digits[0] |= 1

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes.LongA[i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: ' + @base.digits 

    new this 'simple_v_sliding_chart_1024', 1024
    new this 'simple_v_sliding_chart_2048', 2048
    new this 'simple_v_sliding_chart_3072', 3072


  class Chart extends DataTypeComparisonChart
    title:        'Relative Computation Time by Method \u2014 Small Exponent, '
    yAxisTitle:   'LongA = 1.0'
    autoRepeat:   true

    dataTypes:    ['LongA', 'LongB']
    bitLengths:   [16, 24, 32, 48, 64, 96, 128, 192, 256, 384, 512, 768, 1024, 1536, 2048, 3072]
    blockSize:    1
    warmUpLength: 1
    standardLong: 'LongA'
    
    constructor: (@container, @B) ->
      super()
      @title += @B + '-bit base'
      
    operators:
      LongA:  (A, E) ->
        prior = Long._powmod.SlidingWindowPowmodBitLimit
        
        Long._powmod.SlidingWindowPowmodBitLimit = Infinity
        
        R = A[j].powmod E[j], @M for j in [0...A.length]
        
        Long._powmod.SlidingWindowPowmodBitLimit = prior

        R

      LongB:  (A, E) ->
        prior = Long._powmod.SlidingWindowPowmodBitLimit
        
        Long._powmod.SlidingWindowPowmodBitLimit = 0
        
        R = A[j].powmod E[j], @M for j in [0...A.length]

        Long._powmod.SlidingWindowPowmodBitLimit = prior

        R
        
    getOperandLengths: (L) -> [@B, L]

    createOperands: (L, N) ->
      super L, N
      
      @M = Long.random @B
      @M.digits[0] |= 1

    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes.LongA[i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: ' + @base.digits 

    new this 'sliding_v_montgomery_chart_1024', 1024
    new this 'sliding_v_montgomery_chart_2048', 2048
    new this 'sliding_v_montgomery_chart_3072', 3072


  class SlidingVMontgomeryMethodComparisonChart extends DataTypeComparisonChart
    title: 'Sliding Window (Long A) Versus Montgomery (Long B)'
    

      

    getOperandLengths: (L) -> [@B, L]

    createOperands: (L, N) ->
      super L, N
      
      @base = Long.random @B
      @base.digits[0] |= 1
      
    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes.LongA[i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: ' + @base.digits 


  #bitLengths = [32, 36, 40, 44, 48, 52, 56, 60]
  #bitLengths = [64, 72, 80, 88, 96, 104, 112, 120]
  #bitLengths = [128, 144, 160, 176, 192, 208, 224, 240]
  #bitLengths = [512, 640, 768, 896]
  new SlidingVMontgomeryMethodComparisonChart 'sliding_v_montgomery_group_1024', bitLengths, 5, 1024
  new SlidingVMontgomeryMethodComparisonChart 'sliding_v_montgomery_group_2048', bitLengths, 5, 2048
  new SlidingVMontgomeryMethodComparisonChart 'sliding_v_montgomery_group_3072', bitLengths, 5, 3072
  
  class SlidingVMontgomeryMethodComparisonChartAlt extends DataTypeComparisonChart
    title: 'Sliding Window (Long A) Versus Montgomery (Long B)'
    
    constructor: (container, Ls, N) ->
      super container, Ls, N, ['LongA', 'LongB']
      @yAxisTitle = 'LongA = 1.0'
      @autoRepeat = true
      @warmUpLength = 1
      
    operators:
      LongA:  (A, E) ->
        Long._powmod.SlidingWindowPowmodBitLimit = Infinity
        A[j].powmod E[j], @base for j in [0...A.length]

      LongB:  (A, E) ->
        Long._powmod.SlidingWindowPowmodBitLimit = 0
        A[j].powmod E[j], @base for j in [0...A.length]

    getOperandLengths: (L) -> [L, L]

    createOperands: (L, N) ->
      super L, N
      
      @base = Long.random L
      @base.digits[0] |= 1
      
    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (t/@totalTimes.LongA[i] for t, i in @totalTimes[name])

    reportConsistencyFailure: (j) ->
      super j
      @report 'base: ' + @base.digits 

  bitLengths = [1024, 1536, 2048, 2560, 3072]
  new SlidingVMontgomeryMethodComparisonChartAlt 'sliding_v_montgomery_group_alt', bitLengths, 1
  
#   a26 = new Long26 2
#   e26 = new Long26 65537
#   m26 = new Long26 [8, 2]

#   a28 = new Long28 16636363
#   e28 = new Long28 [197042822, 41038957, 2]
#   m28 = new Long28 11471847
  
#   a28.powmod e28, m28
  
#   e26 = new Long26 0x10001
#   e28 = new Long28 0x10001
#   e29 = new Long29 0x10001
#   e30 = new Long30 0x10001
  

#   a26 = new Long26 [21719347, 26347404, 2417, 0]
#   m26 = new Long26 [14086776, 30]

#   a28 = new Long28 a26
#   m28 = new Long28 m26
#   a29 = new Long29 a26
#   m29 = new Long29 m26
#   a30 = new Long30 a26
#   m30 = new Long30 m26
  
#   x = new Long26 11379
#   a = new Long26 2
#   e = new Long26 65537
#   m = new Long26 12293


#   i = x.msb()
#   while i >= 0
#     if x.bit i
#       x.bitset i, 0

#       if x.sq() + 0 == x*x
#         x.bitset i, 1
#     i--

#   window.x = x
#   console.log x.toString 2
#  a.powmod e, m
  
#   i = a26.msb()
#   while i >= 0
#     if a26.bit i
#       a26.bitset i, 0
#       a28.bitset i, 0

#       if (a26.powmod e26, m26)+0 == (a28.powmod e28, m28)+0
#         a26.bitset i, 1
#         a28.bitset i, 1
#     i--

#   i = m26.msb()
#   while i >= 0
#     if m26.bit i
#       m26.bitset i, 0
#       m28.bitset i, 0

#       if (a26.powmod e26, m26)+0 == (a28.powmod e28, m28)+0
#         console.log '\ni:' + i
#         console.log m26+0, m28+0
#         m26.bitset i, 1
#         console.log m26+0, m28+0
#         m28.bitset i, 1
#         console.log m26+0, m28+0
#     i--

#   window.a26 = a26
#   window.e26 = e26
#   window.m26 = m26
  
#   window.a28 = a28
#   window.e28 = e28
#   window.m28 = m28
  
#   window.a29 = a29
#   window.e29 = e29
#   window.m29 = m29
  
#   window.a30 = a30
#   window.e30 = e30
#   window.m30 = m30
  
#   console.log a26.digits
#   console.log m26.digits
  
#   console.log a28.digits
#   console.log m28.digits
  
#   console.log a29.digits
#   console.log m29.digits
  
#   console.log a30.digits
#   console.log m30.digits


# Long28:
# Modular Exponentiation — (Fixed Exponent e = 65537)[0]: Long: op0: 153194032,172921621,74561936,77977956,232689224,240470412,164487356,209969948,193922238,1622854,53000173,188855322,195631486,86800179,99337699,160367461,243092441,21125296,233076762,31118067,31783327,2255263,184975951,206508408,55631697,247304724,254841113,199174883,116811863,184893618,221161254,112930055,122482873,13163296,153027641,125265976,53935 charts.js:569
# Modular Exponentiation — (Fixed Exponent e = 65537)[0]: Long: op1: 166081210,246481383,5506744,61353637,105480331,66874221,169147684,179892002,35270984,62514016,63657726,90233903,219486796,50898982,246242031,233138046,149322233,40374711,46512402,42006821,122581034,179089703,235115037,210924329,260621859,152204914,45099221,214640147,41525827,8868965,193510986,33266099,148622419,220540095,150165598,147891594,5163 charts.js:569
# Modular Exponentiation — (Fixed Exponent e = 65537)[0]:   jsbn:       baba97f3d222f1aa8a893f053f95363bdc147f9bd6d0d8205dd3ab38686aa6a15b013e2cd83270fe30cee97bb9a74c18cb6448e5537804114a7d45acb640a90e29210c9d5e80c9837144df374bd1652a375bb5b6fe9966ee2c6d280a37f4f860f14616560da883c799bdef20cdda08ce31ccae2a1912919656991f76bf119b0 charts.js:569
# Modular Exponentiation — (Fixed Exponent e = 65537)[0]:   Long:       0

#   a = new Long30 [969801430,122316682,122716992,554328291,677240875,814107013,447077627,345420120,956872626,925373715,979264566,476144426,521913012,43744984,665033259]
#   m = new Long30 [225030227,399663358,170407818,337370704,135201132,487639470,476248888,632413641,341711380,244840219,444716837,324379183,122381200,840863091,934653748]

#   e = new Long30 65537

#   a_bi = a.toBigInt()
#   m_bi = m.toBigInt()
#   e_bi = e.toBigInt()

#   t = m.msb()
#   while t >= 0
#     if not m.bit t
#       m.bitset t, 1

#       m_bi = m.toBigInt()
#       y_bi = powMod a_bi, e_bi, m_bi

#       y = a.powmod e, m

#       if not y.eq Long30.fromBigInt y_bi
#         m.bitset t, 0
      
#     t--

#   a_bi = a.toBigInt()
#   m_bi = m.toBigInt()
#   e_bi = e.toBigInt()

#   t = a.msb()
#   while t >= 0
#     if a.bit t
#       a.bitset t, 0

#       a_bi = a.toBigInt()
#       y_bi = powMod a_bi, e_bi, m_bi

#       y = a.powmod e, m

#       if not y.eq Long30.fromBigInt y_bi
#         a.bitset t, 1
      
#     t--

#   a_bi = a.toBigInt()
#   m_bi = m.toBigInt()
#   e_bi = e.toBigInt()
#   y_bi = powMod a_bi, e_bi, m_bi

#   y = a.powmod e, m

#   window.a = a
#   window.m = m
#   window.e = e
#   window.y = y

#   window.a_bi = a_bi
#   window.m_bi = m_bi
#   window.e_bi = e_bi
#   window.y_bi = y_bi
  
# Long Digit Size[0]: Long26: op0: 45547604,16741170,28169818,7825733,21208689,23798666,41317850,37198307,38758163,11699537,19914346,16778401,3021643,22190911,17346130,41595178,20355531,57940892,11377952,58343171,13898338,58836745,5841289,33265286,10601355,41590726,24315099,52933015,37791872,17823362,59532473,42081529,32260458,10335600,5439001,49702756,30196186,48023403,54237245,35177624,52581203,62010832,12763133,31703452,828378,24037725,33833662,7480978,55846275,48025409,32789275,39474908,32070037,44630437,7995008,60433280,46309841,53141980,66691654,18360227,34109939,59346157,60870815,64361598,24886642,34752505,7930200,49776868,6321551,33650113,53477314,41440664,37925327,47429442,1340302,40669272,32984245,8789190,539850,0 charts.js:569
# Long Digit Size[0]: Long26: op1: 40620494,19450576,31824565,31071489,45344601,44081851,44032306,44473925,26362822,23516678,50487126,65527253,53699113,22461513,56008471,7735725,34887574,12797935,32659233,58547892,21189315,25950105,59546055,62930663,58663188,26650421,11837198,66800560,38505662,54962539,31356242,31723007,8659382,41544548,37222333,53235878,62028714,19731689,40885976,699 charts.js:569
# Long Digit Size[0]: Long28: op0: 179765332,171957452,22732133,118611365,237585310,98196168,108586855,108083422,169166415,266234412,75858,48346292,88763644,151563858,194948170,118712732,34459758,202157469,40033935,29510977,35167751,240785497,29592446,245887370,120606137,211732061,172009600,155450784,242796107,111806579,96595009,236529517,165217583,203271129,52276684,194526647,103884339,35992888,248043331,12763133,175698023,121686589,199605029,172622914,92478601,63993154,87145331,156987892,156865942,171993438,127920138,241733120,46309841,113948791,150968868,255090846,62261369,10478179,85965325,198651736,153085307,151083140,232929543,101144827,134600452,53477314,262018406,10758940,149638877,23073907,213228324,120692596,63742488,8 charts.js:569
# Long Digit Size[0]: Long28: op1: 40620494,88748724,6183339,93808756,183415783,20097064,126970366,71068314,190323090,39802457,167212400,53879455,89846055,123117335,102597227,199312761,34802975,181531223,46391127,233198645,161248815,16490380,253826288,95014263,189395174,267202240,239832254,47295066,266200917,191336503,227574817,129867386,69837695,129674417,72591282,266262603,44774 charts.js:569
# Long Digit Size[0]: Long29: op0: 179765332,220196454,341227353,484588468,149066809,330224342,395961245,166519409,46798150,43511605,315621450,435706934,240276646,371542085,442969722,437112358,182047245,385121798,154469528,289148472,437803297,29736818,167535239,101300029,166487511,302334982,84932226,485592215,380242035,182515232,528894427,322642085,214031037,463007086,216948982,118252108,338830645,535782507,27013295,343625502,455439372,35741485,119695656,245910278,464991184,462398104,106322518,13810987,535300772,340197436,279475321,425135845,268018246,430114036,249045479,20956358,85965325,501979052,306706782,253766416,467542928,36715207,278927196,214327295,298819093,384324117,298728147,373828610,527747929,286013836,134962,0 charts.js:569
# Long Digit Size[0]: Long29: op1: 40620494,447027546,269981290,246607118,145681214,520721729,111035815,306739413,94066713,193015723,176061917,38692548,521622959,20298420,291395702,27523010,522547731,519748968,424727728,418144188,463441049,277510151,175332860,155065547,517139467,308045303,189180267,532401834,459771959,382222864,502228894,42284143,310094539,94543165,431979361,349 charts.js:569
# Long Digit Size[0]: Long30: op0: 179765332,378533683,622177750,664553334,747514179,496858774,954099598,294902212,648202773,77679607,565490688,312164107,277538085,779792682,655583644,881030171,264293081,273255290,544326221,560236071,192865697,1013090062,81501863,991524300,11043017,285173801,663512249,447226319,365030465,1065765339,429756498,858814127,460529069,416212495,892887826,902875284,738189000,599890992,13254055,963561821,614482987,369914406,869299522,290221788,378910495,396715606,11157609,939649018,567404168,773704458,966936266,293763647,906525171,670603470,301703376,794606945,153085307,507532833,1004413840,18357603,1009255895,362335231,723319265,330777232,21444843,376213592,832533707,858293788,131,0 charts.js:569
# Long Digit Size[0]: Long30: op1: 40620494,760384685,872801690,970349985,42659507,670583978,714766614,107254001,895851352,500547735,908238751,381438412,896135541,410388909,1004619129,478462791,397221669,223022973,587064916,1043490589,351276985,861797508,521037225,884671186,193773310,879400633,1037989202,765346015,764445729,1039099806,826448439,748612274,78926759,1000077238,10 charts.js:569
# Long Digit Size[0]:   Long26:     a3109496c007e5f442234d518660af69acc342cca1570a9f4a5850125fcae1effae587555866b02970dd53feb6abc8454f7b71edb6d922010c5d80d7e8fb99934ec4fdc8f6b23e66b80898b5471d62a1d94f80b76d26b1c10388174f8e1fd0de1a539fabb1fb0722a6a2b6df3836c13fc0b1f11f2cff020d537b73549933a490 charts.js:569
# Long Digit Size[0]:   Long28:     0 charts.js:569
# Long Digit Size[0]:   Long29:     a3109496c007e5f442234d518660af69acc342cca1570a9f4a5850125fcae1effae587555866b02970dd53feb6abc8454f7b71edb6d922010c5d80d7e8fb99934ec4fdc8f6b23e66b80898b5471d62a1d94f80b76d26b1c10388174f8e1fd0de1a539fabb1fb0722a6a2b6df3836c13fc0b1f11f2cff020d537b73549933a490 charts.js:569
# Long Digit Size[0]:   Long30:     a3109496c007e5f442234d518660af69acc342cca1570a9f4a5850125fcae1effae587555866b02970dd53feb6abc8454f7b71edb6d922010c5d80d7e8fb99934ec4fdc8f6b23e66b80898b5471d62a1d94f80b76d26b1c10388174f8e1fd0de1a539fabb1fb0722a6a2b6df3836c13fc0b1f11f2cff020d537b73549933a490
#
# FF
# [00:58:04.712] Modular Exponentiation — (Fixed Exponent e = 65537)[75]: Long: op0: 245923670,510390013,512914256,167768132,291563234,513540811,488893000,135402797,385675412,9795834,7880414,200304884,376267844,477532953,462504890,377201680,439631806,288888666,32481347,404117883,240014416,262574237,172930724,481830794,436012654,94208132,534826176,221248318,9596686,17875858,85046967,27632905,241835877,263743287,224281399,456327229,440452711,242954667,525773380,87354310,522516565,184294503,74071496,448550252,138631251,167182267,161651739,424646337,366502916,375435615,452764776,133457001,161095919
# [00:58:04.712] Modular Exponentiation — (Fixed Exponent e = 65537)[75]: Long: op1: 105133137,464155513,502223567,258352269,484872267,502187004,83943663,122543703,105465155,396867319,475984161,375070200,495886279,417429311,279768788,404471659,244228231,392799014,253308169,324306143,72619054,420058735,69855062,337375682,279907510,492430970,206816254,279934946,23526655,442716262,21502177,54212245,111064690,428431575,108081633,429165437,369395861,495115859,396024177,61847025,393265780,376233277,105734977,39898077,27055718,105620931,82409627,29376704,10837865,378979349,437970734,89341694,202459370
# [00:58:04.712] Modular Exponentiation — (Fixed Exponent e = 65537)[75]:   BigInt:     64a6a911ed61df85d29dd63abddf9d1c4bda569ee4df4a3ab8d28cec76ed48c1140ae20a965c98ebde82dcfa7dba603a13548b902df3494f0b38489a9c67d7b6b3ca6da41bc22da746cb749c0645e2620276275c94290808f521d6ffb93ba660ac005472324a8f2796f2924587fff05dfff366c85a1b2dd24763fbd8a6d0bced148fb59bb10cba0fd87226989b50c37ae625a9e44329bd4309b01fdf28ba48621d82e363230217d65bf2a5846fda698e741f2e1c7148b2236e1a1f2732542b24
# [00:58:04.712] Modular Exponentiation — (Fixed Exponent e = 65537)[75]:   jsbn:       64a6a911ed61df85d29dd63abddf9d1c4bda569ee4df4a3ab8d28cec76ed48c1140ae20a965c98ebde82dcfa7dba603a13548b902df3494f0b38489a9c67d7b6b3ca6da41bc22da746cb749c0645e2620276275c94290808f521d6ffb93ba660ac005472324a8f2796f2924587fff05dfff366c85a1b2dd24763fbd8a6d0bced148fb59bb10cba0fd87226989b50c37ae625a9e44329bd4309b01fdf28ba48621d82e363230217d65bf2a5846fda698e741f2e1c7148b2236e1a1f2732542b24
# [00:58:04.713] Modular Exponentiation — (Fixed Exponent e = 65537)[75]:   Long:       1a673caa605867ba7ca0df70697c9489404d9e31983d55a47519d5e6bdaa802dfb795478705e4469dfc740d80e704389b913663baae7ad1640517a90b8f8fd236012a317ca8f3bff134f7b6555c519ba0174324c3b7f35d38471da9ecf29cb8f6a43e59e9b49e8e65d3b1277c28f5e877bcd91a0e07ed1e31c54228b87f44b4642dc2512da64293b1da468536151cf23f1df2e73681d76f8c85fcc4ebb5ce1e462142dea4ef449417aec6abf7c648fd43987cbafb653a63944
#
# FF
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]: LongA: op0: 332414533,407637178,282366912,432116969,150467319,16993208,249764907,9363420,467974315,185203556,196989426,66756532,344418722,353236159,143010126,368867356,189279132,97304657,324560681,415551760,70470425,135087207,125871664,480859660,401602885,289088730,452320483,198985462,286993218,241702243,119088744,263641922,94952411,264199559,71273758,274
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]: LongA: op1: 213080656,74302872,313984296,389943769,90283001,95217896,197219753,183432270,221620562,177271376,197748468,160675156,156681317,451250728,520328832,381891214,75429835,431024007,535634950,335454477,446847590,192030314,473570777,126170308,272970936,468602819,507400101,128948534,331040946,267408284,443511540,289111253,462584595,531117297,505864614,472
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]: LongB: op0: 332414533,407637178,282366912,432116969,150467319,16993208,249764907,9363420,467974315,185203556,196989426,66756532,344418722,353236159,143010126,368867356,189279132,97304657,324560681,415551760,70470425,135087207,125871664,480859660,401602885,289088730,452320483,198985462,286993218,241702243,119088744,263641922,94952411,264199559,71273758,274
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]: LongB: op1: 213080656,74302872,313984296,389943769,90283001,95217896,197219753,183432270,221620562,177271376,197748468,160675156,156681317,451250728,520328832,381891214,75429835,431024007,535634950,335454477,446847590,192030314,473570777,126170308,272970936,468602819,507400101,128948534,331040946,267408284,443511540,289111253,462584595,531117297,505864614,472
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]:   LongA:      2419d8c5a71f7d86468d8a91393662eed8179014e4bf1d63403915ffc8dbddc562813894220e65bb4b5c32badad6f5b2423a16ca96f90537aede995c0f5bd8e80b78ffc34443764f78135d78b94165048d35d000cad48c2bc93248b6b283cb6290808949968ae453e31125dbf288a51ef6e3f20294fe1d0d1fadb80ad9864e
# [00:58:04.006] Sliding Window (Long A) Versus Montgomery (Long B)[0]:   LongB:      9090be167b8f4be343ca373f42b3e3816102f6e4d7be3320791b71991bc249f0213763d3a5fe25144774f03eeeace3383bf3838d815db048660ba3c95e4e462f3bbe75b48f0469f131acf50740ebd707e03fd2b49448854d2fe3a4f53aea8a624e55e86c67a4cf780c612591629322d11c7b377b625091c6f540e2
# [00:58:04.007] Sliding Window (Long A) Versus Montgomery (Long B)[0]: base: 465553771,233552072,129862221,274927693,483153897,71786376,323491031,114644225,423849247,186928996,396406868,118235145,244806570,511256802,403600537,273957336,6306894,62790328,523799796,173315522,4237567,366206891,215026846,40685847,333462208,233205425,460309844,349774853,517128532,374316325,534470642,312667363,525364315,415625873,344389388,285
#
# safari
# Computation Time by Implementation — (Fixed Exponent e = 65537)[0]: Long: op0: 883104620,445703216,1038413389,99074031,493946849,47474509,622064637,383273530,65881656,64551302,989819639,795909397,150941340,595916487,255117331,800472023,321935408,45700058,18683710,94235872,551427650,857593796,532562377,696315955,23833128,1020046395,1001182168,519464593,279277676,723882631,946225038,500419677,141966887,45557489,4
#
# safari: 450-bit operands
# Computation Time by Implementation — (Fixed Exponent e = 65537)[18]: Long: op0: 353630407,41150657,887226083,1072033845,824011630,494127123,395115645,595850004,1033794079,977796696,13203802,1016379702,956673592,655169761,952328138
# Computation Time by Implementation — (Fixed Exponent e = 65537)[18]:   BigInt:     879789676616579396625976839815818388745131683128652715342364853727135623197633465416128859686723919429436843399989286266699284488
# Computation Time by Implementation — (Fixed Exponent e = 65537)[18]:   Long:       21154153395669265884141962654335864746211363615965187918532715262522986359143669969382461443561481425531686718113548
#
#
#   { _bit, _bitset, _eq, _msb, _sq } = Long30
  
#   x0s = [279420612, 68027527, 494038374, 128583743, 394245245, 285874457, 804767112, 574195965, 254131509, 887612142, 1025721276, 480045451, 950016479, 1065293196, 949645434, 0]
#   xs = [279420612, 68027527, 494038374, 128583743, 394245245, 285874457, 804767112, 574195965, 254131509, 887612142, 1025721276, 480045451, 950016479, 1065293196, 949645434]

#   t = _msb xs
#   while t >= 0
#     if _bit xs, t
#       _bitset xs, t, 0
#       _bitset x0s, t, 0

#       if _eq (_sq xs), _sq x0s
#         _bitset xs, t, 1
#         _bitset x0s, t, 1
      
#     t--

#   window.xs = xs
#   window.x0s = x0s

#   xs = [231572009, 136897129, 257385275, 777757972, 131192579, 108687247, 120723626, 189893017, 1036542398, 701871193, 845457589, 229076743, 912317323, 1010971698, 930611183]
#   x = new Long30 xs

#   t = x.msb()
#   while t >= 0
#     if x.bit t
#       x.bitset t, 0

#       y = new Long28 x

#       if x.sq().eq y.sq()
#         x.bitset t, 1
      
#     t--

#   window.x = x

#   xs = [0, 0, 0, 0, 0, 0, 0, 0, 968884224, 700462169, 0, 0, 0, 536870912, 930611182]
#   x = new Long30 xs
#   y = new Long28 x

#   console.log 'Long30:'
#   x.sq()
  
#   console.log 'Long28:'
#  y.sq()


# Relative Computation Time by Digit Width — Large Exponent[1]: Long26: op0: 21113772,40594518,39350032,120025,21701082,63842029,60397162,9369808,66668915,24633068,23868561,51633994,32744052,6656179,52747558,58782079,33768224,55248024,65909692,58512096,8868360,24953534,43739198,19969216,62230406,16514444,66525868,10346907,24973443,64403028,16042724,9655607,11352702,38193760,37759906,27476154,58681178,50561026,37040430,42698049,61333749,21315710,36949508,22339014,45294161,15589503,5811117,33934485,28417329,34247288,65511993,52431639,67013981,28658586,38883279,14512068,55995116,49053505,41281111,2
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]: Long28: op0: 155331500,10148629,107316977,228591443,196430625,107672457,238303641,77017659,259765241,204771677,83350166,255469388,26624717,254074150,14695519,102773810,197995538,193195443,34135860,11503733,109307379,47383195,93292108,251618107,259107523,41387631,24973443,83209621,231689390,132271444,159427898,195203506,3056642,108373645,234883967,87109312,48320611,176033626,85262843,171167236,22361969,267072037,181647233,39082155,221348211,77470489,170104874,2908135,244145608,223536831,85261558,58048274,123103980,129703888,10968677,0
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]: Long29: op0: 423766956,139292042,228155836,62128362,163271858,213079964,251187430,522792548,366967731,347478600,489766388,94103364,489036132,506460454,218923904,92425280,517684173,117024193,505533570,130803221,318937960,130229782,534302422,238377085,125331199,199787545,332838484,463378780,132271444,348149405,183018604,436589696,526867048,7340123,416597179,189121184,532315663,270699136,499551475,71969446,394395315,206952093,6080849,56834659,427992222,50281745,360128523,97353681,352122581,450857256,362461965,392428046,175498839,0
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]: Long30: op0: 423766956,69646021,325474415,141983773,949728587,644192956,842785603,754864732,152428411,524966669,975653967,630240124,843960929,58782079,639644722,250825476,884489947,491266940,523284360,174956793,105655600,416208446,447495935,505003996,1024492327,1030448453,485804772,529085779,696298810,183018604,218294848,534369946,739115019,26037323,257568277,8317432,1021330709,350078604,724706581,888004735,625314490,885392844,614341401,512288266,134399486,804926839,258822886,1011434815,720123739,133438809,904288187,41
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]:   Long26:     293573639755744641787257843569523566182236376946881773188526116171855936114948872387937472629952721682396935764791592957936179125571724722952133215248761127256844233533871999588669555164344232787955125733519972952793534456259756975526998932714882375577751551141816942866349631931689713621421411591424854771434163321116318184114576832628837999831853194863593799471719815973256819475713729949819314231513182919
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]:   Long28:     282844763581265176388196243216145828532992563999184673125153286591564243179679996125421885284985982932948723211875618195172577877612557929988755215849324154263351481781494674949659523651992912485748378845338696223962236617388357619793825443356184949235711318426448998217737354284117794315232263164471991396199657693765289583351118899998698717642496558257578628867157768443962364719135361196149664723996118
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]:   Long29:     282844763581265176388196243216145828532992563999184673125153286591564243179679996125421885284985982932948723211875618195172577877612557929988755215849324154263351481781494674949659523651992912485748378845338696223962236617388357619793825443356184949235711318426448998217737354284117794315232263164471991396199657693765289583351118899998698717642496558257578628867157768443962364719135361196149664723996118
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]:   Long30:     282844763581265176388196243216145828532992563999184673125153286591564243179679996125421885284985982932948723211875618195172577877612557929988755215849324154263351481781494674949659523651992912485748378845338696223962236617388357619793825443356184949235711318426448998217737354284117794315232263164471991396199657693765289583351118899998698717642496558257578628867157768443962364719135361196149664723996118
# charts.js:582Relative Computation Time by Digit Width — Large Exponent[1]: base: (Long30) 870196865,841955907,941765336,685321124,176015359,827748770,206621214,823963446,122815288,581311655,515544226,896542040,999743846,859556083,235194764,480390626,496626273,934483386,448742797,626126375,859694818,523639728,859448152,773626548,328560715,1019332111,256374092,231472414,594147520,41289502,323611976,213789540,395857980,336145235,53039896,773264720,510055823,1024203630,1073173889,973221358,208754152,14417471,705655018,113855239,665842377,924943992,32676962,433013654,449994505,286785302,37532786,9
#
#
# Long26: op0: 46124956,64697217,0
# Long28: op0: 113233820,16174304
# Long29: op0: 113233820,8087152
# Long30: op0: 113233820,4043576
# Result Digits:
#   Long26:     61058768,1003061
#   Long28:     167044412,6101892
#   Long29:     167044412,6101892,0
#   Long30:     167044412,6101892,0
# Result Hex:
#   Long26:     269257197989584
#   Long28:     1637964328527164
#   Long29:     1637964328527164
#   Long30:     1637964328527164
# base: (Long28) 92195631,10173359
#
#   x = new Long28 [113233820,16174304]
#   m = new Long28 [92195631,10173359]

#   x26 = new Long26 x
#   m26 = new Long26 m

#   t = x.msb()
#   while t >= 0
#     if x.bit t
#       x.bitset t, 0
#       x26.bitset t, 0

#       y = x.powmod 65537, m
#       y26 = x26.powmod 65537, m26

#       if y.eq y26
#         x.bitset t, 1
#         x26.bitset t, 1
        
#     t--

#   window.x = x
#   window.m = m
#   window.x26 = x26
#   window.m26 = m26

# x.digits
# [77548440, 15911104]
# x26.digits
# [10439576, 63644417, 0]

#   x = new Long28 [77548440, 15911104]
#   m = new Long28 [92195631,10173359]

#   x26 = new Long26 x
#   m26 = new Long26 m

#   console.log 'Long26'
#   x26.powmod 65537, m26
  
#   console.log 'Long28'
#   x.powmod 65537, m
#
# Long26
# 0 578d10f208069
# sq 5b78d85b3c044
# sq 91b7720edefda
# sq 7fbce23c5f2b2
# sq 8c4134757109a
# sq 3a068862dfde8
# sq 5db5195c1e0ff
# sq 94aea732e2e20
# sq 4a8e17946fb2f <--
# sq 36efdb60daf83
# sq 5dbce102e1b0
# sq 25a9bf3ed721e
# sq 42c7234ccb57f
# sq 89e4edf11e990
# sq 890114e9da09d
# sq 270acbd57f59f
# sq 954f6e7194f39
# mul 1359432c47414
# Long28
# 0 578d10f208069
# sq 5b78d85b3c044
# sq 91b7720edefda
# sq 7fbce23c5f2b2
# sq 8c4134757109a
# sq 3a068862dfde8
# sq 5db5195c1e0ff
# sq 94aea732e2e20
# sq 4a8e17946fb2f <--
# sq 836f12829f1b
# sq 42363a11fb5be
# sq 2e1540a88edcf
# sq 4fa056a31f250
# sq 8759eb4933387
# sq 6170169fb8e44
# sq 2ce7c78f4cc2e
# sq 5b6fc499f1059
# mul 4bd5df017459c

  a = new Long(2)
  a30 = new Long30(a)
  m = new Long
  m.bitset(57, 1)
  m.bitset(0, 1)
  m30 = new Long30(m)
  a.powmod(88, m).toString()
  a30.powmod(88, m).toString()
