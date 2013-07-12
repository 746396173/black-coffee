  # This file is concatenated with several other files in sequence; one of critical-small.coffee,
  # critical-medium, or critical-large precedes it, and exports.coffee follows it.
  #
  # Its base indent level is 2, since that is the indent level of its predecessor.
  #
  # Most of the basic arithmetic operations are implemented below: addition, subtraction,
  # division and modulo, and squaring.  Multiplication has digit-width specific calculations,
  # and is in the preceeding file.  Exponentiation follows in a subsequent file (after Montgomery
  # reduction in the next file).
  # 

  _add = (xs, ys, k) ->
    k or= 0
    c = 0
    zs = xs
    i = k
    n = ys.length + k
    while i < n
      z_i = (xs[i]|0) + (ys[i-k]|0) + c
      c = z_i >>> __width__
      zs[i++] = z_i & __mask__

    while c
      z_i = (xs[i]|0) + c
      c = z_i >>> __width__
      zs[i] = z_i & __mask__
      i++

    zs


  __add = (xs, j, ys, i, c, n) ->
    while --n >= 0
      w = (ys[i++]|0) + (xs[j]|0) + c | 0
      c = w >>> __width__
      xs[j++] = w & __mask__

    c

  _sub = (xs, ys, k) ->
    k or= 0
    c = 0
    zs = xs
    i = k
    n = ys.length + k
    while i < n
      z_i = (xs[i]|0) - (ys[i-k]|0) - c
      if z_i < 0
        c = 1
        z_i += __base__
      else
        c = 0
      zs[i++] = z_i & __mask__


    n_xs = _size xs
    while c and i < n_xs
      z_i = (xs[i]|0) - c
      if z_i < 0
        c = 1
        z_i += __base__
      else
        c = 0
      zs[i] = z_i & __mask__
      i++

    zs

  _sq = do (__addmul, _extend) ->
    (xs) ->
      i = 0
      n = xs.length
      zs = _extend [0], 2*n

      while n > 1
        __addmul zs, 2*i, xs[i], xs, i, 0, 1
        __addmul zs, 2*i + 1, xs[i] << 1, xs, i + 1, 0, --n
        i++

      if n > 0
        __addmul zs, 2*i, xs[i], xs, i, 0, 1

      j = zs.length-1
      while zs[j] == 0 then j--
      zs.length = j+1 if zs.length-1 > j

      zs


  # This is implemented directly from the algorithm given in the Handbook of Applied Cryptography,
  # by A. Menezes, P. van Oorschot, and S. Vanstone, CRC Press, 1996.  In particular Chapter 14,
  # section 14.2.5, on page 598.  (The book is available online as PS and PDF downloads from
  # http://cacr.uwaterloo.ca/hac/.)  The numbers below refer to the steps in Algorithm 14.20.
  #
  # While this implementation does not presume that its inputs are normalized (HAC 14.23), it will
  # perform much better if they are.  In particular, this means that y_t0 >= __base__ >>> 1.  This can
  # be achieved by the application of _bshl to xs and ys before calling this function.  It does not
  # affect the result, as the ratio of xs and ys is unchanged.
  #
  # The arguments are signless magnitudes. The sign convention for division or modulo should be
  # handled by the caller.
  #
  __divmod = do (__add, __addmul, _lt, _size, _sub) ->
    pow2_52 = pow 2, 52

    (xs, ys) ->
      i = (_size xs)-1
      t = (_size ys)-1
      k = i - t

      if k < 0 then return [[0], xs]

      ys_t0 = ys[t]
      neg_ys = _sub [0], ys

      # 14.20.1
      # 14.20.2
      if not _lt xs, ys, k
        _sub xs, ys, k
        xs[i+1] = 1

      # 52 is the IEEE floating point standard mantissa length in bits (64 bit double)
      if __width__ * (t + 1) > 52
        ds = _bshr ys.slice(), __width__ * (t + 1) - 52
      else
        ds = _bshl ys.slice(), 52 - __width__ * (t + 1)

      d = _value ds

      c1 = pow2_52/d
      c2 = (pow 2, 52 - __width__)/d
      e = 1 << max 0, 2 * __width__ - 52

      # create local namespace for speedy access to loop variables
      do (xs, neg_ys, i, k, ys_t0, c1, c2, e, __addmul, __add) ->
        n = t + 1

        # 14.20.3
        while --k >= 0
          # 14.20.3.1
          x_i = xs[i] & __mask__

          if x_i == ys_t0
            # __base__ - 1... highest digit value
            q_i = __mask__

          else
            q_i = (min x_i * c1 + (xs[i-1] + e) * c2, __mask__) | 0

          __addmul xs, k, q_i, neg_ys, 0, 0, n
          if xs[i] != q_i
            xs[i] += (__add xs, k, ys, 0, 0, n) - 1 | 0
            q_i--

          if xs[i] != q_i
            throw 'optimization failed'
          i--

        null # prevents coffeescript from collecting loop results

      # 14.20.3.4-5
      [(xs.slice t + 1), xs.slice 0, t + 1]


  _divmod = do (_bshl, _bshr, __divmod, _size) ->
    (xs, ys) ->
      # Note 14.23 on normalization
      _trim ys
      y_t = ys[ys.length-1]
      c = 1
      while (y_t >>>= 1) > 0 then c++

      k = __width__ - c
      ws = _bshl xs.slice(), k
      zs = _bshl ys.slice(), k

      [qs, rs] = __divmod ws, zs
      [qs, _trim _bshr rs, k]


  _div = do (_divmod) -> (xs, ys) -> (_divmod xs, ys)[0]
  _mod = do (_divmod) -> (xs, ys) -> (_divmod xs, ys)[1]


  _pow = do (_kmul, _sq) ->
    (xs, k) ->
      zs = [1]
      xs = xs.slice()
      while k > 0
        zs = _mul zs, xs if k & 1
        xs = _sq xs
        k >>>= 1

      zs


  # modular arithmetic

  _negateMod = (xs, ms) -> if _eq xs, [0] then xs else _sub ms.slice(), xs

  _mulmod = do (_divmod, _mul) ->
    (xs, ys, ms) -> (_divmod (_mul xs, ys), ms)[1]

  _sqmod = do (_divmod, _sq) ->
    (xs, ms) -> (_divmod (_sq xs), ms)[1]

  _powmod_Simple = do (_mul, _mod, _sq) ->
    (xs, ys, ms) ->
      xs = _mod xs, ms

      j = ys.length-1
      i = __width__ - 1
      d = ys[j]
      while (d & (1 << i)) == 0
        if --i < 0
          if j == 0
            return [0]
          i += __width__
          d = ys[--j]

      zs = xs

      if --i < 0
        if j == 0
          return zs
        i += __width__
        d = ys[--j]

      zs = _mod (_sq xs), ms

      loop
        if d & (1 << i)
          zs = _mod (_mul zs, xs), ms

        if --i < 0
          if j == 0
            return zs
          i += __width__
          d = ys[--j]

        zs = _mod (_sq zs), ms


  _window = do () ->
    # _estimatedWindowSizeMap estimates the window size which will on average require the fewest
    # multiplications to compute x^y for y of a given bit size.  _estimateWindowSizeTransitions
    # reduces the resulting array to a few numbers indicating the size at which the window size
    # increases by one, so that the estimated map can be quickly recreated.
    # 
    #  >_estimateWindowSizeTransitions(10000, 1000)
    #  [-1, 0, 6, 25, 80, 241, 672, 1788, 4611.5]
    #  >_estimateWindowSizeTransitions(4650, 1000)
    #  [-1, 0, 6, 24, 79, 240.5, 676, 1792.5, 4601.5]
    #  >_estimateWindowSizeTransitions(4625, 1000)
    #  [-1, 0, 6, 24, 79, 239, 671.5, 1795, 4604]
    #  >_estimateWindowSizeTransitions(4625, 1000)
    #  [-1, 0, 6, 24, 80, 240, 674, 1791, 4611.5]
    #  >_estimateWindowSizeTransitions(4625, 1000)
    #  [-1, 0, 6, 24, 80, 241, 671, 1793.5, 4611]
    #
    # So... on average
    #  [-1, 0, 6, 24, 80, 240, 673, 1792, 4608]
    #

    T = [-1, 0, 6, 24, 80, 240, 673, 1792, 4608, Infinity]
    k = 0
    for i in [0...20000/__width__|0]
      if i * __width__ >= T[k+1]
        k++
      k


  _powmod_SlidingWindow = do (_mul, _mod, _sq, _windowSize) ->
    (xs, ys, ms) ->

      xs = _mod xs, ms

      # precompute odd powers of the base from 3...2^w - 1

      gns = [ [1], xs ]
      gs = xs
      g2s = _mod (_sq xs), ms
      d = _window[ms.length]
      count = 1 << d
      while gns.length < count
        gs = _mod (_mul gs, g2s), ms
        gns.push undefined, gs

      zs = xs
      mask = count - 1
      t--
      i = t % __width__
      t = t/__width__ | 0
      y_t = ys[t]
      while i >= 0
        if (y_t & (1 << i)) is 0
          zs = _mod (_sq zs), ms
          i--

        else
          j = i + 1 - d
          if j < 0
            if t > 0
              y = (y_t << -j | ys[t-1] >> __width__ + j) & mask
            else
              y = y_t & (mask >>> -j)
              j = 0
          else
            y = (y_t >>> j) & mask

          k = i - j + 1
          while (y & 1) is 0
            j++
            k--
            y >>>= 1

          while k-- > 0
            zs = _mod (_sq zs), ms

          zs = _mod (_mul zs, gns[y]), ms
          i = j - 1

        if i < 0
          if t > 0
            y_t = ys[--t]
            i += __width__

      zs

  _powmod_Simple_Mont = do (_liftMont, _mul, _reduceMont, _sq) ->
    (xs, ys, ms, w, vs) ->
      # xs <-- xs * R mod ms
      xs = _reduceMont (_mul xs, vs), ms, w

      j = ys.length-1
      i = __width__ - 1
      d = ys[j]
      while (d & (1 << i)) == 0
        if --i < 0
          if j == 0
            return [0]
          i += __width__
          d = ys[--j]

      if --i < 0
        if j == 0
          return xs
        i += __width__
        d = ys[--j]

      zs = _reduceMont (_sq xs), ms, w

      loop
        if d & (1 << i)
          zs = _reduceMont (_mul zs, xs), ms, w

        if --i < 0
          if j == 0
            return _reduceMont zs, ms, w
          i += __width__
          d = ys[--j]

        zs = _reduceMont (_sq zs), ms, w


  # Computes the exponential xs ^ ys mod ms using the sliding window method and Montgomery
  # reduction.
  # 
  _powmod_SlidingWindow_Mont = do (_liftMont, _mul, _reduceMont, _sq, _windowSize) ->
    # computes xs ^ ys mod ms, where w is the Montgomery cofactor and where vs is R^2 mod ms
    (xs, ys, ms, w, vs) ->
      # xs <-- xs * R mod ms
      xs = _reduceMont (_mul xs, vs), ms, w

      # precompute odd powers of the base from 3...2^w - 1

      gns = [ [1], xs ]
      gs = xs
      g2s = _reduceMont (_sq xs), ms, w
      d = _window[ms.length]
      count = 1 << d
      while gns.length < count
        gs = _reduceMont (_mul gs, g2s), ms, w
        gns.push undefined, gs

      zs = xs
      mask = count - 1
      t--
      i = t % __width__
      t = t/__width__ | 0
      y_t = ys[t]
      while i >= 0
        if (y_t & (1 << i)) is 0
          zs = _reduceMont (_sq zs), ms, w
          i--

        else
          j = i + 1 - d
          if j < 0
            if t > 0
              y = (y_t << -j | ys[t-1] >> __width__ + j) & mask
            else
              y = y_t & (mask >>> -j)
              j = 0
          else
            y = (y_t >>> j) & mask

          k = i - j + 1
          while (y & 1) is 0
            j++
            k--
            y >>>= 1

          while k-- > 0
            zs = _reduceMont (_sq zs), ms, w

          zs = _reduceMont (_mul zs, gns[y]), ms, w
          i = j - 1

        if i < 0
          if t > 0
            y_t = ys[--t]
            i += __width__

      _reduceMont zs, ms, w

  # Montgomery Reduction

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
  _cofactorMont = (ms) ->
    x = ms[0]
    y = 0

    if x & 1
      y = x & 3
      y = (y*(2 -   (x & 0x000f)*y)) & 0x000f	               # y == 1/x mod 2^4
      y = (y*(2 -   (x & 0x00ff)*y)) & 0x00ff	               # y == 1/x mod 2^8
      y = (y*(2 - (((x & 0xffff)*y)  & 0xffff))) & 0xffff    # y == 1/x mod 2^16

      # last step - calculate inverse mod __base__ directly;
      # assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
      # 
      y = (y*(2 - x*y % __base__)) % __base__      # y == 1/x mod 2^__width__

      # we really want the negative inverse, and -__base__ < y < __base__
      if y > 0
        y = __base__ - y
      else
        y = -y
    y


  # This file is concatenated with several other files in sequence; one of critical-small.coffee,
  # critical-medium, or critical-large precedes it, and exports.coffee follows it.
