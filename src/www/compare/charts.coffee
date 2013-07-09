exports = if globals? then globals else window

makeString = (ch, n) -> (ch for i in [0...n]).join ''
padRight = (s, n) -> if s.length >= n then s else s + makeString ' ', n - s.length

time = (fn) ->
  start = new Date
  fn()
  (new Date) - start

{ floor, random } = Math

shuffle = (A) ->
  B = A.slice()
  n = A.length
  for i in [0...n]
    j = floor n*random()
    [B[i], B[j]] = [B[j], B[i]]
  B


class Queue
  constructor: (@taskInterval) ->
    @queue = []
    @taskInterval or= 0
    @pauseRequested = false

  flush: () ->
    @queue = []

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



class ComparisonChart
  Ls:            [1024, 1536, 2048, 2560, 3072]
  N:             100
  dataTypes:     ['BigInt', 'jsbn', 'Long']
  container:     'chart_group'
  reporting:     true
  warmUpLength:  10
  autoRepeat:    true
  repeatCount:   0
  queue:         new Queue
  chartType:     'line'
  rangeType:     'logarithmic'
  xAxisTitle:    'operand bit size'
  yAxisTitle:    'milliseconds/1000 operations'
  standardLong:  Long.prototype.constructor.name
  
  constructor: () ->
    @times = {}
    @totalTimes = null
    @runCount = 0

    @computationRunning = false
    @attachStartLink()

    @N = @blockSize
    @Ls = @bitLengths
    
  # bpe is a global defined in BigInt.js
  makeBigInt = (x) -> Long28._pack x.digits, bpe

  makeBigInteger = (x) ->
    z = nbi()
    if z.DB == 28
      digits = x.digits
    else
      digits = Long28._pack x.digits, z.DB

    for d, i in digits
      z[i] = d

    z.s = 0
    z.t = digits.length
    z.clamp()
    z

  constructors =
    BigInt:     (Xs) -> x.toBigInt() for x in Xs
    jsbn:       (Xs) -> x.toBigInteger() for x in Xs
    Long:       (Xs) -> new Long x for x in Xs
    LongA:      (Xs) -> new Long x for x in Xs
    LongB:      (Xs) -> new Long x for x in Xs
    LongC:      (Xs) -> new Long x for x in Xs
    LongD:      (Xs) -> new Long x for x in Xs
    LongE:      (Xs) -> new Long x for x in Xs
    Long14:     (Xs) -> new Long14 x for x in Xs
    Long15:     (Xs) -> new Long15 x for x in Xs
    Long26:     (Xs) -> new Long26 x for x in Xs
    Long28:     (Xs) -> new Long28 x for x in Xs
    Long29:     (Xs) -> new Long29 x for x in Xs
    Long30:     (Xs) -> new Long30 x for x in Xs

  constructors: constructors

  standardizers = 
    BigInt:     (Xs) -> Long.fromBigInt x for x in Xs
    jsbn:       (Xs) -> Long.fromBigInteger x for x in Xs
    Long:       (Xs) -> new Long x for x in Xs
    LongA:      (Xs) -> new Long x for x in Xs
    LongB:      (Xs) -> new Long x for x in Xs
    LongC:      (Xs) -> new Long x for x in Xs
    LongD:      (Xs) -> new Long x for x in Xs
    LongE:      (Xs) -> new Long x for x in Xs
    Long14:     (Xs) -> new Long x for x in Xs
    Long15:     (Xs) -> new Long x for x in Xs
    Long26:     (Xs) -> new Long x for x in Xs
    Long28:     (Xs) -> new Long x for x in Xs
    Long29:     (Xs) -> new Long x for x in Xs
    Long30:     (Xs) -> new Long x for x in Xs

  standardizers: standardizers
  @standardizers: standardizers

  createOperands: (@L, N) ->
    # @L is the bit-length
    # N is the number of operations that will be performed; equiv, the number of operand sets
    @report 'creating ' + N + ' ' + @L + '-bit operands'

    @operands = {}
    @operands[name] = [] for name in @dataTypes
    for n in @getOperandLengths @L
      Xs = (Long.random n for j in [0...N])
      @operands[name].push @constructors[name].call this, Xs for name in @dataTypes

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
    Long14:     (X) -> X.toString 16
    Long15:     (X) -> X.toString 16
    Long26:     (X) -> X.toString 16
    Long28:     (X) -> X.toString 16
    Long29:     (X) -> X.toString 16
    Long30:     (X) -> X.toString 16

  @hexifiers = hexifiers

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

    @report 'Result Digits:'
    for name in @dataTypes
      @report '  ' + (padRight name + ':', 12) + @standardized[name][j].digits

    @report 'Result Hex:'
    for name in @dataTypes
      @report '  ' + (padRight name + ':', 12) + @standardized[name][j].toString()

    @repeatCount = 0
    @autoRepeat = false
    @queue.flush()


  updateChart: () ->
    @updateTotals()
    @displayChart()
    if @autoRepeat or @repeatCount-- > 0
      @scheduleCalculations warmUp: false


  displayChart: () ->
    if @chart?
      @chart.setTitle text: @title + ' (N = ' + (Math.max (t for name, t of @totalCounts)...) + ')'
      for d, i in @getData()
        @chart.series[i].setData d.data

    else
      @createChart()


  report: (msg) ->
    if @reporting
      console.log @title + '[' + @runCount + ']: ' + msg


  attachStartLink: () ->
    @startLink = $ '#' + @container + ' span.link'
    @startLink.click () =>
      if @computationRunning
        @queue.flush()
        @startLink.text 'Resume computation.'
        @computationRunning = false
      else
        @displayChart()
        ($ '#' + @container + ' div.chart').css 'display', 'block'
        @startLink.text 'Pause computation.'
        @computationRunning = true
        @scheduleCalculations()
        @queue.process()




class DataTypeComparisonChart extends ComparisonChart
  chartType:  'line'
  rangeType:  'logarithmic'
  xAxisTitle: 'operand bit size'
  yAxisTitle: 'milliseconds/1000 operations'
  
  constructor: () ->
    super
    @times[name] = [] for name in @dataTypes
    @operationCount = 0
    @totalTimes = {}
    @totalCounts = {}
    @totalTimes[name] = times for name, times of @times
    @totalCounts[name] = 0 for name, _ of @times


  warmUp: () ->
    @report 'warming up...'

    for L in @Ls
      @createOperands L, @warmUpLength
      for name in @dataTypes
        @doOperation name


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
      data: (1000/(@totalCounts[name] or 1))*t for t in @totalTimes[name]


  createChart: () ->
    ($ '#' + @container + ' div.chart').highcharts
      chart:
        type: @chartType

      title:
        text: @title + ' (N = ' + (Math.max (t for name, t of @totalCounts)...) + ')'

      xAxis:
        categories: @Ls
        title:
          text:
            @xAxisTitle

      yAxis:
        type: @rangeType
        title:
          text: @yAxisTitle

      series: @getData()

    @chart = ($ '#' + @container + ' div.chart').highcharts()


  scheduleCalculations: (options) ->
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

    @queue.push () => @updateChart()


class ParameterComparisonChart extends ComparisonChart
  rangeType:       'logarithmic'
  chartType:       'scatter'
  xAxisTitle:      'parameter value'
  yAxisTitle:      'milliseconds/1000 operations'
  dataTypes:       ['Long']
  parameterValues: [0]
  
  constructor: () ->
    super()
    @times[L] = [] for L in @Ls


  warmUp: () ->
    @report 'warming up...'

    for L in @Ls
      @createOperands L, @warmUpLength
      for name in @dataTypes
        for v in @parameterValues
          @doOperation name, v


  doOperation: (name, v) ->
    @operators[name].apply null, [v, @operands[name]...]


  timeOperation: (name, v) ->
    @report 'timing ' + name + ' at ' + v
    @times[@L].push [v, (1000/@N) * time () => @doOperation name, v]


  updateTotals: () ->
    if @runCount is 0
      @totalTimes = {}
      @totalTimes[L] = times for L, times of @times

    else
      for L, times of @times
        totals = @totalTimes[L]
        if totals?
          [].push.apply totals, times
        else
          @totalTimes[L] = times

    @runCount++
    @times[L] = [] for name in @dataTypes


  getData: () ->
    for L, times of @totalTimes
      name: L
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
            @xAxisTitle

      yAxis:
        type: @rangeType
        title:
          text: @yAxisTitle

      series: @getData()

    @chart = ($ '#' + @container).highcharts()

  scheduleCalculations: (options) ->
    @times[name] = [] for name in @dataTypes

    options or= {}

    if not options.warmUp? or options.warmUp
      @queue.push () => @warmUp()

    for L in @Ls
      do (L) => @queue.push () => @createOperands L, @N
      for name in shuffle @dataTypes
        for v in shuffle @parameterValues
          do (name, v) => @queue.push () => @timeOperation name, v

    @queue.push () => @updateChart()



exports.time = time
exports.shuffle = shuffle
exports.ComparisonChart = ComparisonChart
exports.DataTypeComparisonChart = DataTypeComparisonChart
exports.ParameterComparisonChart = ParameterComparisonChart
