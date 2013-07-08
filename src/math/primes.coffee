assert = do () ->

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

  (cond) -> if not cond then throw stackTrace()

class Primes
  { floor } = Math
  
  top = new Long 2

  primes = [top, (new Long 3), (new Long 5)]

  @get: (n) ->
    while n > primes.length-1
      x = top.add 1
      primes.push x if @check x
      top = x

    primes[n]

  @check: (x) ->
    prime = false
    if x.bit 0
      t = x.msb() >> 1
      i = 0
      ok = true

      while ok and (p = @get i++)? and t >= p.msb()
        ok = (x.mod p).gt 0

      prime = ok

    prime

  @all: () -> primes.slice()

  @find: (bits) ->
    start = new Date

    # Compute product of P consecutive low primes such that bit length P < bits - 10.  This will
    # be used as the increment from one candidate to the next.
    # 
    i = 0
    P = new Long 1
    while P.msb() + (Primes.get i).msb() < bits - 10
      P = P.mul Primes.get i++

    p = null
    tries = 0
    while not p?
      
      # find x0 of target bit length which is not divisible by any of 
      x0 = null
      while not x0?
        x = Long.random bits
        x.bitset 0, 1
        x.bitset bits-1, 1
        t = new LowPrimesTest x, trials: i
        while t.check() then null
        if t.result then x0 = x

      x = x0
      while not p? and  x.msb() == bits-1
        t = new IntegratedPrimalityTest x, LowPrimes: skip: i, trials: floor bits * 1.5
        while t.check() then null
        if t.result then p = x
        tries++
        x = x.add(P)

      x = x0.sub(P)
      while not p? and x.msb() == bits-1
        t = new IntegratedPrimalityTest x, LowPrimes: skip: i, trials: floor bits * 1.5
        while t.check() then null
        if t.result then p = x
        tries++
        x = x.sub(P)

      
#      console.log i
#      if i % 100 == 0

    p: p
    trials: tries
    time: (new Date) - start
    
  @findA: (bits) ->
    start = new Date
    i = 0
    p = null
    x = Long.random bits
    x.digits[0] |= 1
    x.bitset bits-1, 1
    
    while not p?
      t = new IntegratedPrimalityTest x
      while t.check() then null
      if t.result then p = x
      i++
      x = x.add(2)
#      console.log i
#      if i % 100 == 0

    p: p
    trials: i
    time: (new Date) - start


class PrimalityTest
  check: () ->
    @next() if not @finished()
    @result = true if not @result? and @trials.length == 0
    not @finished()

  progress: () -> if @finished() then 1 else (@T - @trials.length) / @T

  finished: () -> @result? or @trials.length is 0


class LowPrimesTest extends PrimalityTest

  constructor: (@N, @options) ->
    @options or= {}

    @T = @options.trials or 3000
#    @interval = @options.interval or 100
    @skip = @options.skip or 0

    Primes.get @T
    @trials = Primes.all().slice @skip, @T

  next: () ->
 #   start = new Date
    while not @finished()# and (new Date) - start < @interval
      p = @trials.pop()
      @result = false if (@N.mod p).eq 0
    this


class MillerRabinTest extends PrimalityTest
  { floor, random } = Math

  { _bit, _bshr, _repr } = Long

  randomHex = do () ->
    codex = do () -> i.toString(16) for i in [0...16]
    (n) ->
      (codex[floor 16*random()] for i in [1...n]).join ''

  randomDigits = (bits) -> _repr randomHex bits >> 2

  randomLong = (bits) -> new Long randomDigits bits

  @randomLong: randomLong

  constructor: (@M, @options) ->
    @options or= {}

    if (@M.eq 1) or (@M.bit 0) is 0
      @result = false
      return

    @result = null

    @n = @M.sub 1

    # Montgomery reduction parameters
    @W = @M.cofactorMont()
    @M1 = @M.liftMont [1]

    @s = 0
    while not @n.bit @s
      @s++

    @r = @n.bshr @s
    @t = @r.msb()

    @T = @options.trials or 2
    Primes.get @T
    @trials = Primes.all().slice 0, 1#@T


#   next: () ->
#     a = @trials.pop()
#     y = a.powmod @r, @M
#     if not (y.eq 1) and not y.eq @n
#       j = 1
#       while j++ < @s
#         y = y.sqmod @M
#         if y.eq 1
#           @result = false
#           return

#         if y.eq @n then return

#       @result = false
      
  next: () ->
    { _eq, _liftMont, _slidingWindowPowMontA, _sqMont } = @M
    ms = @M.digits
    xs = _liftMont @trials.pop().digits, ms
    ns = @n.digits
    m1s = @M1.digits
    ys = _slidingWindowPowMontA xs, @r.digits, ms, @t, @W, m1s.slice()
    if not (_eq ys, m1s) and not _eq ys, ns
      j = 1
      while j++ < @s
        ys = _sqMont ys, ms, @W
        if _eq ys, m1s
          @result = false
          return

        if _eq ys, ns then return

      @result = false
      

  @test: () ->
    name = 'basic consistency'
    passed = 0
    try
      for bits in [10..30] by 10
        console.log 'bits: ' + bits
        for i in [0...100]
          x = (randomLong bits).add (new Long 1).bshl bits
          t = new MillerRabinTest x, bits >> 1
          while t.check() then null
          expected = Primes.check x
          actual = t.result
          assert expected is actual
          passed++

      console.log name + ': ' + passed

    catch err
      console.log name + ' test failed on pass ' + (passed+1) + '.'
      console.log 'x:', x.valueOf() if x?
      console.log 'expected:', expected
      console.log 'actual:', actual
      console.log err
      console.log err.message


class IntegratedPrimalityTest extends PrimalityTest

  constructor: (@N, @options) ->
    @options or= {}
    @lp = new LowPrimesTest @N, @options.LowPrimes
    @mr = new MillerRabinTest @N, @options.MillerRabin

  progress: () -> (@lp.progress() + @mr.progress()) / 2

  check: () ->
    @next() if not @finished()
    not @finished()

  next: () ->
    if not @lp.finished() then @lp.check()
    else if not @mr.finished() then @mr.check()

    if not @result?
      @result = false if @lp.result? and not @lp.result
      @result = @mr.result if @mr.result?

  finished: () -> @result? or @lp.finished() and @mr.finished()


window.Primes = Primes
Primes.MillerRabinTest = MillerRabinTest
Primes.LowPrimesTest = LowPrimesTest
Primes.IntegratedTest = IntegratedPrimalityTest