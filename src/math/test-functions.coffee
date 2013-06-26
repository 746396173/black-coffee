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


test_bpart = (Ls, N) ->
  { ceil, log } = Math

  log2 = (x) -> (log x)/(log 2)
  
  { _bitset, _bpart, _eq, _random } = Functions__radix__
  
  do () ->
    try
      for L in Ls
        K = ceil (log2 L)/2
        for i in [1..N]
          xs = _random L
          for j in [1..K]
            parts = _bpart xs, j
            base2 = (x.toString 2 for x in parts).join ''
            ys = []
            t = 0
            k = base2.length
            while --k >= 0
              if base2[k] is '1'
                _bitset ys, t
              t++
            expected = xs
            actual = ys
            assert _eq actual, expected
    catch err
      console.log name + ' test failed.'
      console.log 'xs:', xs
      console.log 'ys:', ys
      console.log 'j:', j
      console.log 'expected:', expected
      console.log 'actual:', actual
      console.log err
      console.log err.message


test_mulMont = (Ls, N) ->
  { _cofactorMont, _eq, _kmul, _mod, _mulMont, _random, _shl, _trim } = Functions__radix__
  
  do () ->
    try
      for L in Ls
        for i in [1..N]
          ms = _trim _random L
          ms[0] |= 1
          R = _shl [1], ms.length
          W = _cofactorMont ms

          xs = _mod (_random L), ms
          ys = _mod (_random L), ms

          expected = _mod (_kmul xs, ys), ms
          actual = _mod (_shl (_mulMont xs, ys, ms, W), ms.length), ms
          assert _eq actual, expected
        
    catch err
      console.log name + ' test failed.'
      console.log 'xs:', xs
      console.log 'ys:', ys
      console.log 'ms:', ms
      console.log 'expected:', expected
      console.log 'actual:', actual
      console.log err
      console.log err.message

Functions__radix__.Test =
  test_bpart:   test_bpart
  test_mulMont: test_mulMont

