  # This file is concatenated with several other files in sequence; base.coffee precedes it, and
  # operations.coffee follows it.
  #
  # Its base indent level is 2, since that is the indent level of its predecessor.
  #
  # This file contains carefully-optimized innermost loops (hence critical), all related to
  # multiplication.  There are three flavors of this file: critical-small.coffee,
  # critical-medium.coffee, and critical-large.coffee.  For digits less than 16 bits wide,
  # digit-digit multiplication fits easily within to a 32-bit word.  Between 16 and 29 bit per
  # word inclusively, the digit needs to be split into two halves, each pair of which can be
  # multiplied within a 32-bit word.  For 30 bit digits, special handling is required to keep the
  # carry from overflowing.

  __addmul = (xs, j, t, ys, i, c, n) ->
    t |= 0
    while --n >= 0
      x_j = (xs[j]|0) + t * (ys[i++]|0) + c | 0
      c = x_j >>> __width__
      xs[j++] = x_j & __mask__

    while x_j >= __base__
      x_j = (xs[j]|0) + (x_j >>> __width__) | 0
      xs[j++] = x_j & __mask__

    xs


  _mul = (xs, ys) ->
    n_xs = xs.length
    n_ys = ys.length

    zs = _extend [0], n_xs + n_ys

    if n_xs > 0 and n_ys > 0
      for j in [0...n_xs] by 1
        x_j = xs[j] & __mask__
        i = c = 0
        k = j
        n = n_ys
        while --n >= 0
          z_j = (zs[j]|0) + x_j * ys[i++] + c | 0
          c = z_j >>> __width__
          zs[j++] = z_j & __mask__
        zs[j] = c
    _trim zs


  # HAC 14.32 (Montgomery reduction)
  _reduceMont = do (_extend, _lt, _shr, _sub) ->
    # computes xs * R^-1 mod ms
    (xs, ms, w) ->
      addmul = __addmul
      
      w |= 0
      
      n_ms = ms.length
      i = 0
      _extend xs, 2*n_ms
      while i < n_ms
        addmul xs, i, w * xs[i], ms, 0, 0, n_ms
        i++

      _shr xs, n_ms
      _sub xs, ms if not _lt xs, ms
      xs.length = n_ms
      xs



  # This file is concatenated with several other files in sequence; base.coffee precedes it, and
  # basic-operations.coffee follows it.
