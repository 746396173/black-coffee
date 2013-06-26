
  @test: () ->
    do () ->
      # test _repr and _hex functions

      codex = do () -> i.toString(16) for i in [0...16]
      randomHex = (n) -> (codex[floor 16*random()] for i in [1...n]).join ''

      for i in [0...10]
        try
          H = (randomHex 30).replace /^0+/, ''
          assert (result = _hex _repr H) == H
        catch err
          console.log '_hex and _repr test failed for H = ' + H
          console.log result
          console.log err
          console.log err.message


    for i in [1...__radix__*2]
      try
        k = floor __base__ * random()
        assert (_value _bshl [k], i) == k * pow 2, i
      catch err
        console.log '_bshl test failed for i = ' + i + '; k = ' + k
        console.log '' + (k * pow 2, i) + ' != ' + _value _bshl [k], i
        console.log err
        console.log err.message

    for i in [1...__radix__*2]
      try
        assert (_value (_bshr (_bshl [k], i), i)) == k
      catch err
        console.log '_bshl/_bshr consistency test failed for i = ' + i + '; k = ' + k
        console.log '' + k + ' != ' + _value _bshl [k], i
        console.log err
        console.log err.message

    i = 0
    while (pow 2, i) < 1 + (pow 2, i)
      K = pow 2, i++
      for k in [K-100...K+100]
        x = new Long k
        try
          assert k == Number x

        catch err
          console.log 'linear construction test #' + i + ' failed for ' + k
          console.log '' + k + ' != ' + Number x
          console.log err

          break

      for k in [-K-100...-K+100]
        x = new Long k
        try
          assert k == Number x

        catch err
          console.log 'linear construction test #' + i + ' failed for ' + k
          console.log '' + k + ' != ' + Number x
          console.log err

          break

    K = (pow 2, 3*__radix__ + 1) - 1
    C = (pow 2, 3*__radix__) - 1

    m = Infinity
    M = -Infinity

    N = 1000
    while N-- > 0
      k = floor K * random() - C

      try
        assert k == Number new Long k

      catch err
        console.log 'stochastic construction test #' + (1000 - N + 1) + ' failed for ' + k
        console.log '' + k + ' != ' + Number(x)
        console.log err
        N = 0

      m = min m, k
      M = max M, k


    i = 0
    while (pow 2, i) < 1 + (pow 2, i)
      K = pow 2, i++
      for k in [K-100...K+100]
        x = new Long k
        y = new Long -k
        try
          assert 0 == Number x.add y

        catch err
          console.log 'linear negate test #' + i + ' failed for ' + k
          console.log '' + (Number x.add y) + ' != 0'
          console.log err

          break

        try
          assert 0 == Number y.add x

        catch err
          console.log 'linear negate test #' + i + ' failed for ' + -k
          console.log '' + (Number y.add x) + ' != 0'
          console.log err

          break

    i = 0
    while (pow 2, i) < 1 + (pow 2, i)
      K = pow 2, i++
      C = floor K / 2
      N = min C, 100
      while N-- > 0
        k = floor K * random() - C
        h = floor K * random() - C

        try
          sum = Number (new Long h).add new Long k
          assert h + k == sum

        catch err
          console.log 'stochastic sum test #' + i + ' failed for ' + k + ' and ' + h
          console.log '' + (k + h) + ' != ' + sum
          console.log err
          N = 0


    I = floor (i-1) / 2 # So squares still fit in accurate JS arithmetic
    i = 0               # i falls through from above.
    while i < I
      K = pow 2, i++
      for k in [K-100...K+100]
        x = new Long k
        try
          assert x * x == Number x.mul x

        catch err
          console.log 'linear square test #' + i + ' failed for ' + k
          console.log '' + (Number x.mul x) + ' != ' + (x * x)
          console.log err

          break

    i = 0
    while i < I
      K = pow 2, i++
      C = floor K / 2
      N = min C, 100
      while N-- > 0
        k = floor K * random() - C
        h = floor K * random() - C

        try
          product = Number (new Long h).mul new Long k
          assert h * k == product

        catch err
          console.log 'stochastic product test #' + i + ' failed for ' + k + ' and ' + h
          console.log '' + (k * h) + ' != ' + product
          console.log err
          N = 0


    i = 0
    while i < I
      K = pow 2, i++
      for k in [K-100...K+100]
        x = new Long k
        try
          assert x * x == Number x.mul x

        catch err
          console.log 'linear Karatsuba square test #' + i + ' failed for ' + k
          console.log '' + (Number x.mul x) + ' != ' + (x * x)
          console.log err

          break

    i = 0
    while i < I
      K = pow 2, i++
      C = floor K / 2
      N = min C, 100
      while N-- > 0
        k = floor K * random() - C
        h = floor K * random() - C

        try
          product = Number (new Long h).kmul new Long k
          assert h * k == product

        catch err
          console.log 'stochastic Karatsuba product test #' + i + ' failed for ' + k + ' and ' + h
          console.log '' + (k * h) + ' != ' + product
          console.log err
          N = 0

    codex = do () -> i.toString(16) for i in [0...16]
    randomHex = (n) -> (codex[floor 16*random()] for i in [1...n]).join ''

    for i in [4...10]
      N = pow 2, i
      H = []
      K = []
      for j in [0...100]
        h = new Long _repr randomHex N
        k = new Long _repr randomHex N

        try
          assert _eq (h.mul k), h.kmul k

        catch err
          console.log 'stochastic multiplication consistency test failed'
          console.log err, err.message
          console.log 'H: '
          console.log _hex h.digits
          console.log 'K: '
          console.log _hex k.digits
          break

    do () ->
      try
        for i in [0..100] by 4
          i_long = (new Long 1).bshl i
          for j in [0..100] by 4
            j_long = (new Long 1).bshl j
            H = _hex (i_long.mul j_long).digits
            assert H.length is (i >> 2) + (j >> 2) + 1 and (H.match /^10*$/)?
      catch err
        console.log 'simple multiplication grid test failed for i = ' + i + '; j = ' + j
        console.log 'result: "' + H + '"'
        console.log err
        console.log err.message

    do () ->
      try
        for i in [1..50]
          h = new Long makeString 'f', i
          H = _hex (h.mul h).digits
          assert H.length is 2 * i and (H.match /^f*e0*1$/)?
      catch err
        console.log '0xfff...fff multiplication test failed for i = ' + i
        console.log 'result: "' + H + '"'
        console.log err
        console.log err.message

    h = new Long 50
    for i in [1...10]
      k = new Long i

      try
        [q, r] = h.divmod k
        if k is 0
          assert q is Infinity and (Number r) is 0
        else
          assert (Number k) * (Number q) + (Number r) == Number h

      catch err
        console.log 'positive-positive divmod test #' + i + ' failed for ' + (Number h) + ' and ' + (Number k)
        console.log '[' + (floor h/k) + ', ' + (h % k) + '] != [' + (Number q) + ', ' + (Number r) + ']'
        console.log err
        console.log err.message
        N = 0

    h = new Long 50
    for i in [1...10]
      k = new Long -i

      try
        [q, r] = h.divmod k
        if k is 0
          assert q is Infinity and (Number r) is 0
        else
          assert (Number k) * (Number q) + (Number r) == Number h

      catch err
        console.log 'positive-negative divmod test #' + i + ' failed for ' + (Number h) + ' and ' + (Number k)
        console.log '[' + (floor h/k) + ', ' + (h % i) + '] != [' + (Number q) + ', ' + (Number r) + ']'
        console.log err
        console.log err.message
        N = 0

    h = new Long -50
    for i in [1...10]
      k = new Long i

      try
        [q, r] = h.divmod k
        if k is 0
          assert q is Infinity and (Number r) is 0
        else
          assert (Number k) * (Number q) + (Number r) == Number h

      catch err
        console.log 'negative-positive divmod test #' + i + ' failed for ' + (Number h) + ' and ' + (Number k)
        console.log '[' + (floor h/k) + ', ' + (-h % i) + '] != [' + (Number q) + ', ' + (Number r) + ']'
        console.log err
        console.log err.message
        N = 0

    h = new Long -50
    for i in [1...10]
      k = new Long -i

      try
        [q, r] = h.divmod k
        if k is 0
          assert q is Infinity and (Number r) is 0
        else
          assert (Number k) * (Number q) + (Number r) == Number h

      catch err
        console.log 'negative-negative divmod test #' + i + ' failed for ' + (Number h) + ' and ' + (Number k)
        console.log '[' + (floor h/k) + ', ' + (-h % i) + '] != [' + (Number q) + ', ' + (Number r) + ']'
        console.log err
        console.log err.message
        N = 0

    i = 0
    while i < I
      K = pow 2, i++
      C1 = floor K / 2
      C2 = floor C1 / 2
      N = min C2, 100
      while N-- > 0
        k = floor K * random() - C1
        h = floor K * random() - C2

        try
          [q, r] = (new Long h).divmod new Long k
          if k is 0
            assert q is Infinity and (Number r) is 0
          else
            assert k * (Number q) + (Number r) == h

        catch err
          console.log 'stochastic divmod test #' + i + ' failed for ' + h + ' and ' + k
          console.log '[' + (floor h/k) + ', ' + (((h % k) + h) % k) + '] != [' + (Number q) + ', ' + (Number r) + ']'
          console.log err
          console.log err.message
          N = 0

    @test.divmod()
    @test.invmod()

    for i in [0...100]
      for k in [2, 5]
        B = [0, 0, 0x4000000, 0x40000, 0x2000, 0x400]
        b = ceil B[k] * random()

        try
          result = Number (new Long b).pow k
          assert (pow b, k) == result

        catch err
          console.log 'systematic pow test #' + i + ' failed for ' + b + ' and ' + k
          console.log '' + (pow b, k) + ' != ' + result
          console.log err
          console.log err.message
          N = 0


    for i in [4...10]
      N = pow 2, i
      for j in [0...100]
        h = new Long _repr randomHex N
        k = new Long _repr randomHex N
        m = new Long _repr randomHex N

        try
          assert _eq ((h.mul k).mod m), h.mulmod k, m

        catch err
          console.log 'stochastic mulmod consistency test failed'
          console.log err, err.message
          console.log 'h: '
          console.log _hex h.digits
          console.log 'k: '
          console.log _hex k.digits
          console.log 'm: '
          console.log _hex m.digits
          console.log err
          console.log err.message
          break

    for i in [4...10]
      N = pow 2, i
      k = 7 - (i >> 1)
      for j in [0...100]
        h = new Long _repr randomHex N
        m = new Long _repr randomHex N

        try
          assert _eq ((h.pow k).mod m), h.powmod k, m

        catch err
          console.log 'stochastic powmod consistency test failed for exponent ' + k
          console.log err, err.message
          console.log 'h: '
          console.log _hex h.digits
          console.log 'm: '
          console.log _hex m.digits
          console.log err
          console.log err.message
          break


    undefined


  @test.divmod = () ->
    randomHex = do () ->
      codex = do () -> i.toString(16) for i in [0...16]
      (n) ->
        (codex[floor 16*random()] for i in [1...n]).join ''

    randomDigits = (bits) -> _repr randomHex bits >> 2
    randomLong = (bits) -> new Long randomDigits bits

    name = 'divmod basic functionality'
    passed = 0
    try
      for bits in [12..60] by 4
        for i in [0...30]
          m = randomLong bits
          C = new Long _bshl [1], bits
          for j in [0...30]
            x = (randomLong bits+1).add C
            [q, r] = x.divmod m
            actual = r.add m.mul q
            expected = x
            assert actual.eq expected

            passed++

      console.log name + ': ' + passed

    catch err
      console.log name + ' test failed.'
      console.log 'm:', m? and m.valueOf()
      console.log 'x:', x? and x.valueOf()
      console.log 'q:', q? and q.valueOf()
      console.log 'r:', r? and r.valueOf()
      console.log 'expected:', expected
      console.log 'actual:', actual? and actual.valueOf()
      console.log err
      console.log err.message


  @test.invmod = () ->
    randomHex = do () ->
      codex = do () -> i.toString(16) for i in [0...16]
      (n) ->
        (codex[floor 16*random()] for i in [1...n]).join ''

    randomDigits = (bits) -> _repr randomHex bits >> 2
    randomLong = (bits) -> new Long randomDigits bits

    name = 'invmod basic functionality'
    passed = 0
    try
      for bits in [12..60] by 4
        for i in [0...30]
          m = randomLong bits
          C = new Long _bshl [1], bits
          for j in [0...30]
            x = (randomLong bits+1).sub C
            x_inv = x.invmod m
            if x_inv?
              xx_inv = x.mul x_inv
              actual = xx_inv.mod m
              expected = [1]
              assert actual.eq expected
            else if m.abs().lte [1]
              actual = x_inv
              expected = false
            else
              actual = x.gcd m
              expected = 'greater than 1'
              assert actual.gt [1]

            passed++

      console.log name + ': ' + passed

    catch err
      console.log name + ' test failed.'
      console.log 'm:', m? and m.valueOf()
      console.log 'x:', x? and x.valueOf()
      console.log 'x_inv:', x_inv? and x_inv.valueOf()
      console.log 'xx_inv:', xx_inv? and xx_inv.valueOf()
      console.log 'expected:', expected
      console.log 'actual:', actual? and actual.valueOf()
      console.log err
      console.log err.message


  @testKaratsubaThreshold: () ->
    # Performance on a Dell E4300 Linux Chromium platform while performing 100 4096-bit
    # multiplications
    #   Naive:                  180ms
    #   Karatsuba (limit = 40): 120ms
    #
    codex = do () -> i.toString(16) for i in [0...16]
    randomHex = (n) -> (codex[floor 16*random()] for i in [1...n]).join ''

    H = (new Long randomHex 2048 for j in [0...1000])
    K = (new Long randomHex 2048 for j in [0...1000])

    startKaratsuba = new Date

    H[i].kmul K[i] for i in [0...1000]

    endKaratsuba = new Date

    startNaive = new Date

    H[i].mul K[i] for i in [0...1000]

    endNaive = new Date

    console.log 'Naive', endNaive - startNaive
    console.log 'Karatsuba', endKaratsuba - startKaratsuba
