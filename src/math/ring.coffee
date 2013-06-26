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


class Residue extends Long__radix__

class RingMod

  { _add, __addmul, _bit, _bshr, _div, _eq, _lt, _kmul, _mod, _msb, _mul1, _shl, _shr, _size, _sub, _trim, _zeros } = Long__radix__
  { floor, pow } = Math

  @MontgomeryThreshold: 128

  ## %% Begin Remove for Specialize %%
  __radix__  = 28
  __base__   = 1 << __radix__
  __base2__  = pow __base__, 2
  __mask__   = __base__ - 1

  __demiradix__ = __radix__ >> 1
  __demibase__  = 1 << __demiradix__
  __demimask__  = __demibase__ - 1

  _setRadix = (radix) ->
    __radix__  = radix
    __base__   = 1 << __radix__
    __base2__  = pow __base__, 2
    __mask__   = __base__ - 1

    __demiradix__ = __radix__ >> 1
    __demibase__  = 1 << __demiradix__
    __demimask__  = __demibase__ - 1

  ## %% End Remove for Specialize %%

  # (- M)^-1 mod b
  # algorithm taken from bnpInvDigit in jsbn2.js
  # (protected) return "-1/this % 2^DB"; useful for Mont. reduction
  # justification:
  #         xy == 1 (mod m)
  #         xy =  1+km
  #   xy(2-xy) = (1+km)(1-km)
  # x[y(2-xy)] = 1-k^2m^2
  # x[y(2-xy)] == 1 (mod m^2)
  # if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
  # should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
  # JS multiply "overflows" differently from C/C++, so care is needed here.
  _cofactor = (ms) ->
    x = ms[0]

    if (x & 1) == 0
      return [0]

    y = x & 3
    y = (y*(2 - (x&0xf)*y))&0xf	                 # y == 1/x mod 2^4
    y = (y*(2 - (x&0xff)*y))&0xff	               # y == 1/x mod 2^8
    y = (y*(2 - (((x&0xffff)*y)&0xffff)))&0xffff # y == 1/x mod 2^16
    
    # last step - calculate inverse mod __base__ directly;
    # assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
    # 
    y = (y*(2 - x*y % __base__)) % __base__      # y == 1/x mod 2^__radix__
    
    # we really want the negative inverse, and -__base__ < y < __base__
    if y > 0
      [__base__ - y]
    else
      [-y]
    
    #w = (new Long__radix__ ms).negate().invmod [0, 1]
    #ws = if w? then w.digits else [0]
    #ws

  @_cofactor = _cofactor

  constructor: (M) ->
    M = (if M instanceof Long__radix__ then M else new Long__radix__ M).digits

    if M.length is 0 or M.length is 1 and (M[0] == 0 or M[0] == 1)
      throw 'illegal modulus:' + M

    return class RingResidue extends Residue
                                    # HAC equivalent
      @M  = _trim M                 # m
      @K  = K  = _size M            # t
      @R  = R  = _shl [1], K        # R = b^K, where b is __base__
      @R2 = R2 = _shl [1], 2*K      # R^2 = b^2*K
      @W  = W  = _cofactor M        # m-prime

      # for pow

      @R_M  = R_M  = _mod R, M
      @R2_M = R2_M = _mod R2, M

      # Montgomery reduction only works with odd moduli (modulus must be relatively prime to the
      # base).
      @MontgomeryReduction = M[0] & 1

      # Don't bother with Barrett reduction for small moduli
      @BarrettReduction = not @MontgomeryReduction or _lt M, _shl [1], 1
      if @BarrettReduction
        @B  = B  = _div R2, M         # mu (per 14.42)
        @Rb = Rb = _shl [1], K+1      # R = b^K+1

      _modM = do () ->
        if not @BarretReduction
          (xs) -> _mod xs, M

        else
          (xs) ->
            if (_size xs) >= 2*K
              _mod xs, M

            else
              qs = _shr (_kmul (_shr xs.slice(), K-1), B), K+1

              rs_1 = xs.slice 0, K+1
              rs_2 = (_kmul qs, M).slice 0, K+1
              _add rs_1, Rb if _lt rs_1, rs_2
              assert not _lt rs_1, rs_2
              rs = _sub rs_1, rs_2

              while not _lt rs, M then _sub rs, M
              rs


      if @MontgomeryReduction
        _lift = (xs) -> _modM _shl xs, K

      else
        _lift = (xs) -> xs

                    
      _reduceSlow = (xs) ->
        for i in [0...K] by 1                 # 14.32.2
          u_i = (_mul1 [xs[i]], W)[0]         # 14.32.2.1  u_i = (x_i * w) mod b
          _add xs, (_mul1 M, [u_i]), i        # 14.32.2.2  xs = xs + (u_i * b^i) * ms

        _shr xs, K                            # 14.32.3    xs = xs / b^k
        _sub xs, M if not _lt xs, M           # 14.32.4    if xs > ms then xs = ms - xs
        xs

        
      _reduceOptimized = do () ->
        W_l = W[0] & __demimask__
        W_h = W[0] >>> __demiradix__
        
        addmul = (xs, j, t, ys, n) ->
          t_l = t & __demimask__
          t_h = t >> __demiradix__
          i = c = 0
          while --n >= 0
            y_l = ys[i] & __demimask__
            y_h = ys[i++] >> __demiradix__
            m = t_h * y_l + y_h * t_l
            l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + c
            c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h + (c >>> __radix__)
            xs[j++] = l & __mask__

          xs[j] += c
          
          while xs[j] >= __base__
            xs[j] -= __base__
            xs[++j]++

          xs

        lt = Long__radix__._lt
        shr = Long__radix__._shr
        sub = Long__radix__._sub
        trim = Long__radix__._trim

        (xs) ->
          i = 0
          ms = M
          n_ms = ms.length
          [].push.apply xs, _zeros.slice 0, 2*n_ms
          # for i in [0...K] by 1                 # 14.32.2
          while i < n_ms
            xi_l = xs[i] & __demimask__
            xi_h = xs[i] >>> __demiradix__

            # u_i = (_mul [xs[i]], W)[0]          # 14.32.2.1  u_i = (x_i * w) mod b
            u_i = W_l * xi_l + ((W_l * xi_h + W_h * xi_l & __demimask__) << __demiradix__)

            #add xs, (mul1 ms, [u_i]), i++        # 14.32.2.2  xs = xs + (u_i * b^i) * ms
            addmul xs, i++, u_i, ms, n_ms

          shr xs, n_ms                           # 14.32.3    xs = xs / b^k
          sub xs, ms if not lt xs, ms           # 14.32.4    if xs > ms then xs = ms - xs
          trim xs

        
      if not @MontgomeryReduction
        _reduce = _modM

      else
        _reduce = _reduceOptimized

      _toRing = _reduce

      _toLong = _lift

      _negate = (xs) -> if _eq xs, [0] then xs else _sub M.slice(), xs

      _montSlow = (xs, ys) ->
        zs = _zeros.slice 0, K
        y_0 = ys[0]
        
        for i in [0...K] by 1
          x_i = xs[i]
          u_i = (_mul1 (_add [zs[0]], _mul1 [x_i], [y_0]), W)[0]

          _add zs, _mul1 M, [u_i]
          _add zs, _mul1 ys, [x_i]
          
          # assert zs[0] is 0
          _shr zs, 1

        _sub zs, M if not _lt zs, M
        zs

      _montMedium = do () ->
        W_l = W[0] & __demimask__
        W_h = W[0] >>> __demiradix__
        
        addmul = (xs, t, ys, n) ->
          t_l = t & __demimask__
          t_h = t >> __demiradix__
          i = j = c = 0
          while --n >= 0
            y_l = ys[i] & __demimask__
            y_h = ys[i++] >> __demiradix__
            m = t_h * y_l + y_h * t_l
            l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + c
            c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h + (c >>> __radix__)
            xs[j++] = l & __mask__

          xs[j] = (xs[j] & -1) + c
          
          while xs[j] >= __base__
            c = xs[j] >>> __radix__
            xs[j++] &= __mask__
            xs[j] = (xs[j] & -1) + c

        (xs, ys) ->
          addmul = Long__radix__.__addmul          

          y0_l = ys[0] & __demimask__
          y0_h = ys[0] >>> __demiradix__
          
          ms = M
          n_ms = ms.length
          n_ys = ys.length

          i = 0
          zs = _zeros.slice 0, K
#           y_0 = ys[0]
          while i < n_ms
            x_i = xs[i++]
#          for i in [0...n_ms] by 1
#            x_i = xs[i]
            
#             u_i = (_mul1 (_add [zs[0]], _mul1 [x_i], [y_0]), W)[0]
            xi_l = x_i & __demimask__
            xi_h = x_i >>> __demiradix__

            u = y0_l * xi_l + ((y0_l * xi_h + y0_h * xi_l & __demimask__) << __demiradix__)
            u = u + zs[0] & __mask__

            u_l = u & __demimask__
            u_h = u >>> __demiradix__

            u_i = W_l * u_l + ((W_l * u_h + W_h * u_l & __demimask__) << __demiradix__) & __mask__

            _add zs, _mul1 ys, [x_i]
#             j = n_ys
#             zs[j] = (zs[j] & -1) + addmul zs, 0, x_i, ys, 0, 0, n_ys
#             while zs[j] >= __base__
#               zs[j++] -= __base__
#               zs[j] = (zs[j] & -1) + 1
            
            _add zs, _mul1 M, [u_i]
#             j = n_ms
#             zs[j] = (zs[j] & -1) + addmul zs, 0, u_i, ms, 0, 0, n_ms
#             while zs[j] >= __base__
#               zs[j++] -= __base__
#               zs[j] = (zs[j] & -1) + 1

            # assert zs[0] is 0
            _shr zs, 1

          _sub zs, M if not _lt zs, M
          zs

      _montOptimized = do () ->
        W_l = W[0] & __demimask__
        W_h = W[0] >>> __demiradix__

        lt = Long__radix__._lt
        shr = Long__radix__._shr
        sub = Long__radix__._sub
        trim = Long__radix__._trim

        addmul = (xs, t, ys, n) ->
          t_l = t & __demimask__
          t_h = t >> __demiradix__
          i = j = c = 0
          while --n >= 0
            y_l = ys[i] & __demimask__
            y_h = ys[i++] >> __demiradix__
            m = t_h * y_l + y_h * t_l
            l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + c
            c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h + (c >>> __radix__)
            xs[j++] = l & __mask__

          xs[j] += c
          
          while xs[j] >= __base__
            xs[j] -= __base__
            xs[++j]++

          xs

        (xs, ys) ->
          y0_l = ys[0] & __demimask__
          y0_h = ys[0] >>> __demiradix__
          
          ms = M
          n_ms = ms.length
          n_ys = ys.length
          
          i = 0
          zs = _zeros.slice 0, 2*K
          while i < n_ms
            x_i = xs[i++]
            
            # u_i = (_mul W, _add [zs[0]], _mul [x_i], [y_0])[0]
            xi_l = x_i & __demimask__
            xi_h = x_i >>> __demiradix__

            u = y0_l * xi_l + ((y0_l * xi_h + y0_h * xi_l & __demimask__) << __demiradix__)
            u = u + zs[0] & __mask__

            u_l = u & __demimask__
            u_h = u >>> __demiradix__

            u_i = W_l * u_l + ((W_l * u_h + W_h * u_l & __demimask__) << __demiradix__) & __mask__

            # add zs, mul1 ys, [x_i]
            # add zs, mul1 ms, [u_i]
            addmul zs, x_i, ys, n_ys
            addmul zs, u_i, ms, n_ms
            
            shr zs, 1

          sub zs, ms if not lt zs, ms
          trim zs


      _mont = _montOptimized
#       _mont = do () ->
#         montMap =
#           'none':   _montSlow
#           'medium': _montMedium
#           'full':   _montOptimized
#         (xs, ys) -> montMap[RingResidue.Optimize or 'none'] xs, ys

#       if @MontgomeryReduction
#         _mul = (xs, ys) -> _lift _mont xs, ys
#       else
      _mul = do () ->
        kmul = Long__radix__._kmul
        modM = _modM
        (xs, ys) -> modM kmul xs, ys
        

      # TODO: measure which is faster
#       if @MontgomeryReduction
#         _sq = (xs) -> _lift _mont xs, xs
#       else
      _sq = do () ->
        sq = Long__radix__._sq
        modM = _modM
        (xs) -> modM sq xs


      _pow1494 = (xs, ys) ->
        ws = _mont xs, R2_M
        zs = R_M.slice()

        t = _msb ys
        for i in [t..0] by -1
          zs = _mont zs, zs
          zs = _mont zs, ws if _bit ys, i

        _mont zs, [1]
        
    
      _montgomeryPowmod = (xs, ys, t) ->
        # HAC 14.85 sliding window method with Montgomery multiplication (HAC 14.32)
        mul = _mul
        sq = _sq

        xs = _lift xs.slice()

        # precompute odd powers of the base from 3...2^w - 1

        gns = [ [1], xs ]
        gs = xs
        g2s = sq xs
        w = Long__radix__._windowSize[t]
        count = 1 << w
        while gns.length < count
          gs = mul gs, g2s
          gns.push undefined, gs

        zs = xs
        mask = count - 1
        t--
        i = t % __radix__
        t = floor t/__radix__
        y_t = ys[t]
        while i >= 0
          if (y_t & (1 << i)) is 0
            zs = sq zs
            i--

          else
            j = i + 1 - w
            if j < 0
              if t > 0
                y = (y_t << -j | ys[t-1] << __radix__ - j) & mask
              else
                y = y_t & (mask >> -j)
                j = 0
            else
              y = (y_t >> j) & mask

            k = i - j + 1
            while (y & 1) is 0
              j++
              k--
              y >>= 1

            while k-- > 0
              zs = sq zs

            zs = mul zs, gns[y]
            i = j - 1

          if i < 0
            if t > 0
              y_t = ys[--t]
              i += __radix__

        _reduce zs


      _pow = do () =>
        if @MontgomeryReduction
          return               _pow1494
          (xs, ys) ->
            t = _msb ys

            if t == -1
              [1]

            else if t == 0
              _modM xs

            else if t <= Long__radix__.PowmodThreshold
              Long__radix__._simplePowmod xs, ys, M

            else if t <= RingMod__radix__.MontgomeryThreshold
              Long__radix__._slidingWindowPowmod xs, ys, M, t

            else
              if @Use1494
                _pow1494 xs, ys
              else
#                Long__radix__._slidingWindowPowmod xs, ys, M, t
                _montgomeryPowmod xs, ys, t

        else
          (xs, ys) -> [1]

      @_modM:      _modM
      @_lift:      _lift
      @_reduceSlow:    _reduceSlow
      @_reduce:    _reduce
      @_toLong:    _toLong
      @_toRing:    _toRing
      @_negate:    _negate
      @_mont:      _mont
      @_pow:       _pow
      @_pow1494:   _pow1494


      Long: RingResidue

      constructor: (x) ->
        super x
        @digits = _negate @digits if @sign < 0
        @digits = _trim _modM @digits if not _lt @digits, M
        @sign = 1


      negate: () ->
        z = new @Long this
        z.digits = _negate z.digits
        z


      abs: () -> new @Long this


      mul: (y) ->
        y = new @Long y if not (y instanceof @Long)
        z = new @Long

        z.digits = _mul @digits, y.digits
        z


      kmul: (y) -> @mul y


      pow: (y) ->
        y = new Long__radix__ y if not (y instanceof Long__radix__)
        z = new @Long [1]

        if not y.eq [0]
          z.digits = _pow @digits, y.digits
          
        z

      sq: () ->
        new @Long _sq @digits        


  @test: () ->
    { floor, random } = Math

    { _bshl, _eq, _repr, _value } = Long

    randomHex = do () ->
      codex = do () -> i.toString(16) for i in [0...16]
      (n) ->
        (codex[floor 16*random()] for i in [1...n]).join ''

    randomDigits = (bits) -> _repr randomHex bits >> 2
    randomLong = (bits) -> new Long randomDigits bits

    testModuli = (N) ->
      N or= 15
      [[7], [65535], (new Long 2147483647).digits,
       (new Long 200560490131).digits, (_sub (_bshl [1], 61), 1),
       (randomDigits 100 for i in [0...N-5])...]

    testDigits = (M) ->
      [[1], (_sub M.slice(), 1), (_add M.slice(), 1), (randomDigits 200 for i in [0...995])...]

    testResidues = (R) -> new R xs for xs in testDigits R.M

    testRings = (N) ->
      R for R in (new RingMod ms for ms in testModuli N) when not _eq R.W, [0]


    do () ->
      name = 'Barret reduction'
      passed = 0
      try
        for R in testRings()
          for xs in testDigits R.M
            expected = _mod xs, R.M
            actual = R._modM xs
            assert _eq expected, actual
            passed++

        console.log name + ': ' + passed

      catch err
        console.log name + ' test failed.'
        console.log 'M:', R? and R.M
        console.log 'xs:', xs
        console.log 'expected:', expected
        console.log 'actual:', actual
        console.log err
        console.log err.message


    do () ->
      name = 'Montgomery lift-reduce consistency'
      passed = 0
      try
        for R in testRings()
          { _lift, _reduce } = R
          for xs in testDigits R.M
            expected = _mod xs, R.M
            actual = _reduce _lift xs.slice()
            assert _eq expected, actual
            passed++

        console.log name + ': ' + passed

      catch err
        console.log name + ' test failed.'
        console.log 'R.M:', R.M
        console.log 'xs:', xs
        console.log 'expected:', expected
        console.log 'actual:', actual
        console.log err
        console.log err.message


    do () ->
      name = 'M = 7 multiplication consistency'
      passed = 0
      try
        Rmod7 = new RingMod 7
        for i in [0..7]
          x = new Rmod7 i
          for j in [0..7]
            y = new Rmod7 j
            expected = ((new Long x).mul y).mod 7
            actual = x.mul y
            assert expected.eq actual
            passed++

        console.log name + ': ' + passed

      catch err
        console.log name + ' test failed on pass ' + (passed+1) + '.'
        console.log 'x:', x.valueOf() if x?
        console.log 'y:', y.valueOf() if y?
        console.log 'expected:', expected.valueOf() if expected?
        console.log 'actual:', actual.valueOf() if actual?
        console.log err
        console.log err.message


    do () ->
      name = 'multiplication consistency'
      passed = 0
      try
        for R in testRings()
          residues = testResidues R
          L = residues.length >> 1
          for i in [0...L]
            x = residues[i]
            y = residues[L+i]
            expected = ((new Long x).mul y).mod R.M
            actual = x.mul y
            assert expected.eq actual
            passed++

      catch err
        console.log name + ' test failed on pass ' + (passed+1) + '.'
        console.log 'M:', R.M.valueOf() if R?
        console.log 'x:', '0x' + x.toString(16) if x?
        console.log 'y:', '0x' + y.toString(16) if y?
        console.log 'expected:', expected.valueOf() if expected?
        console.log 'actual:', actual.valueOf() if actual?
        console.log err
        console.log err.message

      console.log name + ': ' + passed


    do () ->
      name = 'M = 7 pow consistency'
      passed = 0
      try
        Rmod7 = new RingMod 7
        for i in [0..7]
          x = new Rmod7 i
          for j in [0..256]
            y = new Rmod7 j
            expected = (new Long x).powmod y, 7
            actual = x.pow y
            assert expected.eq actual
            passed++

        console.log name + ': ' + passed

      catch err
        console.log name + ' test failed on pass ' + (passed+1) + '.'
        console.log 'x:', x.valueOf() if x?
        console.log 'y:', y.valueOf() if y?
        console.log 'expected:', expected.valueOf() if expected?
        console.log 'actual:', actual.valueOf() if actual?
        console.log err
        console.log err.message

    do () ->
      name = 'pow consistency'
      passed = 0
      try
        for R in testRings()
          for x in testResidues R
            y = new R floor 256*random()
            expected = (new Long x).powmod y, R.M
            actual = x.pow y
            assert expected.eq actual
            passed++

        console.log name + ': ' + passed

      catch err
        console.log name + ' test failed on pass ' + (passed+1) + '.'
        console.log 'x:', x.valueOf() if x?
        console.log 'y:', y.valueOf() if y?
        console.log 'expected:', expected.valueOf() if expected?
        console.log 'actual:', actual.valueOf() if actual?
        console.log err
        console.log err.message


exports = window
exports.Residue__radix__ = Residue
exports.RingMod__radix__ = RingMod
## %% Begin Remove for Specialize %%
exports.Residue = Residue
exports.RingMod = RingMod
## %% End Remove for Specialize %%
