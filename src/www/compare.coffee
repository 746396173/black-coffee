$ ->
  { _bit, _bshr, _repr } = Long

  { floor, random } = Math

  makeString = (ch, n) -> (ch for i in [0...n]).join ''
  indents = do () -> (makeString ' ', i for i in [0...100])

  stackTrace = () ->
    try
      (null)()
    catch err
      calls = (err.stack.split '\n').slice 3
      calls.reverse()
      lines = (indents[i] + call.slice 4 for call, i in calls)
      lines.join '\n'

  assert = (cond) -> if not cond then throw stackTrace()

  randomHex = do () ->
    codex = do () -> i.toString(16) for i in [0...16]
    (n) ->
      (codex[floor 16*random()] for i in [1...n]).join ''

  randomDigits = (bits) -> _repr randomHex bits >> 2

  randomLong = (bits) -> new Long randomDigits bits

  padRight = (s, n) -> if s.length >= n then s else s + makeString ' ', n - s.length

  rng = new SecureRandom()
  
  E_BigInt = str2bigInt '100001', 16, 0
  E_jsbn = new BigInteger '100001', 16
  E_Long = new Long '100001'

  time = (fn) ->
    start = new Date
    fn()
    (new Date) - start

  window.time = time
  
  shuffle = (A) ->
    B = A.slice()
    n = A.length
    for i in [0...n]
      j = floor n*random()
      [B[i], B[j]] = [B[j], B[i]]
    B

  window.shuffle = shuffle

  class Queue
    constructor: (@taskInterval) ->
      @queue = []
      @taskInterval or= 0
      @pauseRequested = false
      
    pause: () ->
      @pauseRequested = true

    process: () ->
      if @pauseRequested
        @pauseRequested = false
        
      else if @queue.length > 0
        task = @queue.shift()
        task()
        setTimeout (=> @process()), @taskInterval

    push: (task) ->
      @queue.push task

  taskQueue = new Queue
  window.taskQueue = taskQueue


  class ComparisonChart
    constructor: (@container, @Ls, @N, @dataTypes) ->
      @times = {}
      @times[name] = [] for name in @dataTypes
      @reporting = true
      @totalTimes = null
      @warmUpLength = 10
      @runCount = 0
      @autoRepeat = false
      @repeatCount = 0

    # bpe is a global defined in BigInt.js
    makeBigInt = (x) -> Long28._repack x.digits, bpe

    makeBigInteger = (x) ->
      z = nbi()
      if z.DB == 28
        digits = x.digits
      else
        digits = Long28._repack x.digits, z.DB
        
      for d, i in digits
        z[i] = d

      z.s = 0
      z.t = digits.length
      z.clamp()
      z

    constructors =
      BigInt:     (Xs) -> makeBigInt x for x in Xs
      jsbn:       (Xs) -> makeBigInteger x for x in Xs
      Long:       (Xs) -> new Long Long28._repack x.digits, Long._radix for x in Xs
      LongA:      (Xs) -> Xs
      LongB:      (Xs) -> Xs
      LongC:      (Xs) -> Xs
      LongD:      (Xs) -> Xs
      LongE:      (Xs) -> Xs
      Long26:     (Xs) -> new Long26 Long28._repack x.digits, 26 for x in Xs
      Long28:     (Xs) -> Xs
      Long30:     (Xs) -> new Long30 Long28._repack x.digits, 30 for x in Xs

    @constructors: constructors

    createOperands: (@L, N) ->
      # @L is the bit-length
      # N is the number of operations that will be performed; equiv, the number of operand sets
      @report 'creating ' + N + ' ' + @L + '-bit operands'

      @operands = {}
      @operands[name] = [] for name in @dataTypes
      for n in @getOperandLengths @L
        Xs = (Long28.random n for j in [0...N])
        @operands[name].push constructors[name] Xs for name in @dataTypes

      @results = {}

                        
    hexifiers = 
      BigInt:     (X) -> (bigInt2str X, 16).toLowerCase()
      jsbn:       (X) -> X.toString 16
      Long:       (X) -> X.toString 16
      LongA:      (X) -> X.toString 16
      LongB:      (X) -> X.toString 16
      LongC:      (X) -> X.toString 16
      LongD:      (X) -> X.toString 16
      LongE:      (X) -> X.toString 16
      Long26:     (X) -> X.toString 16
      Long28:     (X) -> X.toString 16
      Long30:     (X) -> X.toString 16

    @hexifiers = hexifiers

    checkConsistency: () ->
      @report 'checking consistency for ' + @L + '-bit operands'
      for j in [0...@N]
        resultSet = {}
        for name in @dataTypes
          resultSet[hexifiers[name] @results[name][j]] = true

        if (Object.keys resultSet).length > 1
          return @reportConsistencyFailure j

    reportConsistencyFailure: (j) ->
      @report 'consistency failure: set: ' + j
      for name in @dataTypes when (name.slice 0, 4) == 'Long'
        for op, i in @operands[name]
          console.log name + ': op' + i + ': ' + op[j].digits
      for name in @dataTypes
        @report '  ' + (padRight name + ':', 12) + hexifiers[name] @results[name][j]
        

    displayChart: () ->
      @updateTotals()
      if @chart?
        for d, i in @getData()
          @chart.series[i].setData d.data

      else
        @createChart()

      if @autoRepeat or @repeatCount-- > 0
        @scheduleCalculations @queue, warmUp: false
      

    report: (msg) ->
      if @reporting
        console.log @title + '[' + @runCount + ']: ' + msg


  window.ComparisonChart = ComparisonChart
  
  class DataTypeComparisonChart extends ComparisonChart
    constructor: (container, Ls, N, dataTypes) ->
      super container, Ls, N, dataTypes
      @operationCount = 0
      @rangeType = 'logarithmic'
      @yAxisTitle = 'milliseconds/1000 operations'

    warmUp: () ->
      @report 'warming up...'
 #     @reporting = false

      for L in @Ls
        @createOperands L, @warmUpLength
        for name in @dataTypes
          @doOperation name

      @reporting = true


    doOperation: (name) ->
      @results[name] = @operators[name].apply this, @operands[name]

            
    timeOperation: (name) ->
      @report 'timing ' + name + ' on ' + @L + '-bit operands'
      @times[name].push time () => @doOperation name


    updateTotals: () ->
      if @runCount is 0
        @totalTimes = {}
        @totalCounts = {}
        @totalTimes[name] = times for name, times of @times
        @totalCounts[name] = @N for name, _ of @times

      else
        for name, times of @times
          totals = @totalTimes[name]
          if totals?
            for t, i in times
              totals[i] += times[i]
            @totalCounts[name] += @N
          else
            @totalTimes[name] = times
            @totalCounts[name] = @N

      @runCount++
      @times[name] = [] for name in @dataTypes


    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: (1000/@totalCounts[name])*t for t in @totalTimes[name]


    createChart: () ->
      ($ '#' + @container).highcharts
        chart:
          type: 'line'

        title:
          text: @title

        xAxis:
          categories: @Ls
          title:
            text:
              'operand bit size'

        yAxis:
          type: @rangeType
          title:
            text: @yAxisTitle

        series: @getData()
        
      @chart = ($ '#' + @container).highcharts()
      
      
    scheduleCalculations: (@queue, options) ->
      @times[name] = [] for name in @dataTypes
        
      options or= {}
      
      if not options.warmUp? or options.warmUp
        @queue.push () => @warmUp()
        
      for L in @Ls
        do (L) =>
          @queue.push () => @createOperands L, @N
          for name in shuffle @dataTypes
            do (name) =>
              @queue.push () => @timeOperation name
          if @dataTypes.length > 1
            @queue.push () => @checkConsistency()

      @queue.push () => @displayChart()
      

  class ParameterComparisonChart extends ComparisonChart
    constructor: (container, L, N, @parameterValues, dataTypes) ->
      super container, [L], N, dataTypes or ['Long28']
      @rangeType = 'linear'
      @chartType = 'scatter'

            
    warmUp: () ->
      @report 'warming up...'
      @reporting = false

      for L in @Ls
        @createOperands L, @warmUpLength
        for name in @dataTypes
          for v in @parameterValues
            @doOperation name, v

      @reporting = true


    doOperation: (name, v) ->
      @operators[name].apply null, [v, @operands[name]...]

            
    timeOperation: (name, v) ->
      @report 'timing ' + name + ' at ' + v
      @times[name].push [v, (1000/@N) * time () => @doOperation name, v]


    updateTotals: () ->
      if @runCount is 0
        @totalTimes = {}
        @totalTimes[name] = times for name, times of @times

      else
        for name, times of @times
          totals = @totalTimes[name]
          if totals?
            [].push.apply totals, times
          else
            @totalTimes[name] = times

      @runCount++
      @times[name] = [] for name in @dataTypes


    getData: () ->
      for name, times of @totalTimes
        name: name
        data: times


    createChart: () ->
      ($ '#' + @container).highcharts
        chart:
          type: @chartType

        title:
          text: @title

        xAxis:
          title:
            text:
              'parameter value'

        yAxis:
          type: @rangeType
          title:
            text: @yAxisTitle

        series: @getData()
        
      @chart = ($ '#' + @container).highcharts()
      
    scheduleCalculations: (@queue, options) ->
      @times[name] = [] for name in @dataTypes
        
      options or= {}
      
      if not options.warmUp? or options.warmUp
        @queue.push () => @warmUp()
        
      for L in @Ls
        do (L) => @queue.push () => @createOperands L, @N
        for name in shuffle @dataTypes
          for v in shuffle @parameterValues
            do (name, v) => @queue.push () => @timeOperation name, v

      @queue.push () => @displayChart()
      

            
  class MultiplicationComparisonChart extends DataTypeComparisonChart
    title: 'Multiplication'
    
    operators:
      BigInt:     (A, B) -> mult A[j], B[j] for j in [0...A.length]
      jsbn: (A, B) ->
        for j in [0...A.length]
          c = new BigInteger
          A[j].multiplyTo B[j], c
          c
      LongA:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      LongB:      (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long26:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long28:     (A, B) -> A[j].mul B[j] for j in [0...A.length]
      Long30:     (A, B) -> A[j].mul B[j] for j in [0...A.length]


    getOperandLengths: (L) -> [L, L]


  bitLengths = [1024, 1280, 1526, 1792, 2048]
  dataTypes = ['BigInt', 'jsbn', 'Long26', 'Long28', 'Long30']
  multiplicationChart = new MultiplicationComparisonChart 'multiplication_chart', bitLengths, 1000, dataTypes
#  multiplicationChart.scheduleCalculations taskQueue
  multiplicationChart.repeatCount = 20
  window.multiplicationChart = multiplicationChart


  class ModulusComparisonChart extends DataTypeComparisonChart
    title: 'Modulo'
    
    operators:
      BigInt:     (A, M) -> mod A[j], M[j] for j in [0...A.length]
      jsbn:       (A, M) -> A[j].mod M[j] for j in [0...A.length]
      LongA:      (A, B) -> A[j].mod B[j] for j in [0...A.length]
      LongB:      (A, B) -> A[j].mod B[j] for j in [0...A.length]
      Long26:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long28:     (A, M) -> A[j].mod M[j] for j in [0...A.length]
      Long30:     (A, M) -> A[j].mod M[j] for j in [0...A.length]

    getOperandLengths: (L) -> [2*L, L]


  dataTypes = ['jsbn', 'Long26', 'Long28', 'Long30']
  modulusChart = new ModulusComparisonChart 'modulus_chart', bitLengths, 2000, dataTypes
  modulusChart.repeatCount = 40
#  modulusChart.scheduleCalculations taskQueue
  window.modulusChart = modulusChart
  

  class ModularExponentiationFixedExponentComparisonChart extends DataTypeComparisonChart
    #E = 'fa1ebebd' # random 32-bit prime
    E = '10001'
    E_BigInt = str2bigInt E, 16, 0
    E_BigInteger = new BigInteger E, 16
    E_Long = new Long E
    E_Long26 = new Long26 E
    E_Long28 = new Long28 E
    E_Long30 = new Long30 E
            
    title: 'Modular Exponentiation \u2014 (Fixed Exponent e = ' + E_Long.valueOf() + ')'

    operators:
      BigInt:     (A, M) -> powMod A[j], E_BigInt, M[j] for j in [0...A.length]
      jsbn:       (A, M) -> A[j].modPow E_BigInteger, M[j] for j in [0...A.length]
      LongA:      (A, M) ->
        for j in [0...A.length]
          R = new RingMod28 M[j]
          (new R A[j]).pow E_Long28 
        
      LongB:      (A, M) ->
        Long28.PowModThreshold = 32
        A[j].powmod E_Long28, M[j] for j in [0...A.length]
        
      Long26:     (A, M) -> A[j].powmod E_Long26, M[j] for j in [0...A.length]
      Long28:     (A, M) -> A[j].powmod E_Long28, M[j] for j in [0...A.length]
      Long30:     (A, M) -> A[j].powmod E_Long30, M[j] for j in [0...A.length]
#       Long30:     (A, M) ->
#         for j in [0...A.length]
#           console.log 'A[j]: ' + A[j].toString(16)
#           console.log 'M[j]: ' + M[j].toString(16)
#           A[j].powmod E_Long30, M[j] 

    getOperandLengths: (L) -> [L, L]
    
  #dataTypes = ['BigInt', 'jsbn', 'Long28', 'Long30']
  dataTypes = ['jsbn', 'Long28']
  bitLengths = [1024, 1280, 1536, 1792, 2048]
  modularExponentiationExpChart = new ModularExponentiationFixedExponentComparisonChart 'modular_exponentiation_fixed_exponent_chart', bitLengths, 100, dataTypes
  window.modularExponentiationExpChart = modularExponentiationExpChart

  modularExponentiationExpChart.repeatCount = 200
#  modularExponentiationExpChart.scheduleCalculations taskQueue


  class ModularExponentiationFixedBaseComparisonChart extends DataTypeComparisonChart
    title: 'Modular Exponentiation (Fixed Odd Base)'

    constructor: (container, Ls, N, dataTypes) ->
      super container, Ls, N, dataTypes
      @warmUpLength = 1
      @rangeType = 'logarithmic'
      @yAxisTitle = 'seconds/operation'
      
    operators:
      BigInt:     (A, E, M) -> powMod A[j], E[j], @bases.BigInt for j in [0...A.length]
      jsbn:       (A, E, M) -> A[j].modPow E[j], @bases.jsbn for j in [0...A.length]
      LongA:      (A, E, M) ->
        Functions28._montgomeryPowmod.option = 'A'
        A[j].powmod E[j], @bases.LongA for j in [0...A.length]
          
      LongB:      (A, E, M) ->
        Functions28._montgomeryPowmod.option = 'B'
        A[j].powmod E[j], @bases.LongB for j in [0...A.length]
          
      LongC:      (A, E, M) ->
        Functions28._montgomeryPowmod.option = 'C'
        A[j].powmod E[j], @bases.LongC for j in [0...A.length]
          
      Long:       (A, E, M) -> A[j].powmod E[j], @bases.Long for j in [0...A.length]
      Long26:     (A, E, M) -> A[j].powmod E[j], @bases.Long26 for j in [0...A.length]
      Long28:     (A, E, M) -> A[j].powmod E[j], @bases.Long28 for j in [0...A.length]
      Long30:     (A, E, M) -> A[j].powmod E[j], @bases.Long30 for j in [0...A.length]
      
    getOperandLengths: (L) -> [L, L]

    createOperands: (L, N) ->
      super L, N
      
      @bases = {}
      X = Long28.random L
      X.digits[0] |= 1
      for name in @dataTypes
        @bases[name] = (ComparisonChart.constructors[name] [X])[0]


    getData: () ->
      for name in @dataTypes when @totalCounts[name]?
        name: name
        data: t/(1000*@totalCounts[name]) for t in @totalTimes[name]


#     getData: () ->
#       for name in @dataTypes when @totalCounts[name]?
#         name: name
#         data: (t/@totalTimes.Long[i] for t, i in @totalTimes[name])


    reportConsistencyFailure: (j) ->
      @report 'consistency failure: set: ' + j
      for name in @dataTypes when (name.slice 0, 4) == 'Long'
        console.log name + ': base:' + @bases[name].digits
        for op, i in @operands[name]
          console.log name + ': op' + i + ': ' + op[j].digits
      for name in @dataTypes
        @report '  ' + (padRight name + ':', 12) + ComparisonChart.hexifiers[name] @results[name][j]
        
  #dataTypes = ['BigInt', 'jsbn', 'Long28', 'Long30']
  #dataTypes = ['BigInt', 'jsbn', 'LongC']
  #dataTypes = ['LongA', 'LongB', 'LongC']
  dataTypes = ['BigInt', 'jsbn', 'Long']
  #bitLengths = [8]#, 16, 32, 64, 128, 256, 512, 1024]
  bitLengths = [1024, 1280, 1536, 1792, 2048]
  modularExponentiationFixedBaseChart = new ModularExponentiationFixedBaseComparisonChart 'modular_exponentiation_fixed_odd_base_chart', bitLengths, 10, dataTypes
  window.modularExponentiationFixedBaseChart = modularExponentiationFixedBaseChart

  modularExponentiationFixedBaseChart.repeatCount = 100
  modularExponentiationFixedBaseChart.scheduleCalculations taskQueue


  class KaratsubaComparisonChart extends ParameterComparisonChart
    title: 'Karatsuba Multiplication'
    
    operators:
      Long26:  (v, A, B) ->
        Long26._kmul.Threshold = v
        A[j].mul B[j] for j in [0...A.length]

      Long28:  (v, A, B) ->
        Long28._kmul.Threshold = v
        A[j].mul B[j] for j in [0...A.length]

      Long30:  (v, A, B) ->
        Long30._kmul.Threshold = v
        A[j].mul B[j] for j in [0...A.length]

    getOperandLengths: (L) -> [L, L]


  dataTypes = ['Long26', 'Long28', 'Long30']
  karatsubaChart = new KaratsubaComparisonChart 'karatsuba_chart', 3072, 1000, (do () -> (v for v in [10..100] by 1)), dataTypes
  karatsubaChart.repeatCount = 10
#  karatsubaChart.scheduleCalculations taskQueue
  window.karatsubaChart = karatsubaChart

  class KaratsubaSquareComparisonChart extends ParameterComparisonChart
    title: 'Karatsuba Square'
    
    operators:
      Long28:  (v, A, B) ->
        Long28.KaratsubaSquareLimit = v
        A[j].ksq B[j] for j in [0...A.length]


    getOperandLengths: (L) -> [L, L]

        
  ksquareChart = new KaratsubaSquareComparisonChart 'ksquare_chart', 4096, 5000, do () -> (v for v in [27..47] by 1)
  ksquareChart.repeatCount = 10
  #ksquareChart.scheduleCalculations taskQueue
  window.ksquareChart = ksquareChart

  class ModExpMethodComparisonChart extends ParameterComparisonChart
    { random, round } = Math
    
    title: 'Modular Exponentiation Methods'

    constructor: (container, L, N, parameterValues, dataTypes) ->
      super container, L, N, parameterValues, dataTypes
      @rangeType = 'logarithmic'
      @chartType = 'line'

    operators:
      LongA: (v, e, A, M) ->
        Long28.PowmodThreshold = Infinity
        A[j].powmod e, M[j] for j in [0...A.length]
        
      LongB: (v, e, A, M) ->
        Long28.PowmodThreshold = 0
        A[j].powmod e, M[j] for j in [0...A.length]

    doOperation: (name, v) ->
      @operators[name].apply null, [v, @exponents[v], @operands[name]...]

    createExponents: () ->
      @exponents = []
      for v in @parameterValues
        E = 1
        # this works for parameters up to and including v == 52
        i = v
        while --i > 0
          E *= 2
          E += round random()
        @exponents[v] = new Long28 E

    createOperands: (L, N) ->
      super L, N
      @createExponents()

    getOperandLengths: (L) -> [2*L, L]

    getData: () ->
      for name, times of @totalTimes
        totalsPerParameter = []
        for pair in times
          [v, t] = pair
          totalsPerParameter[v] = (totalsPerParameter[v] or 0) + t/@runCount
        name: name
        data: ([v, t] for t, v in totalsPerParameter when t?)


  modexpMethodChart = new ModExpMethodComparisonChart 'modexp_method_chart', 3072, 500, (do () -> (v for v in [15..25])), ['LongA', 'LongB']
  modexpMethodChart.repeatCount = 50
  #modexpMethodChart.scheduleCalculations taskQueue
  window.modexpMethodChart = modexpMethodChart
  
  taskQueue.process()

#  window.setTimeout (() ->
#    console.log 'finding a 512-bit prime...'
#    console.log Primes.find 512), 2000
    
  window.foo = () ->
    m = Long28.random(2048)
    m = m.add(m.digits[0] % 2 + 1)
    R = new RingMod28 m
    x = new R Long28.random(2048)
    console.log 'timing in ring...'
    console.log time () ->
      for i in [0...1000]
        x.pow Long.random 2048

    x = new Long x
    console.log 'timing unaccelerated...'
    console.log time () ->
      for i in [0...1000]
        x.powmod (Long.random 2048), m


  