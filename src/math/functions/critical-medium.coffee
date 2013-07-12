  # This file is concatenated with several other files in sequence; base.coffee precedes it, and
  # basic-operations.coffee follows it.
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
    t_l = t & __half_maskA__
    t_h = t >>> __half_widthA__
    while --n >= 0
      y_l = ys[i] & __half_maskB__
      y_h = ys[i++] >>> __half_widthB__
      m = t_h * y_l + (y_h * t_l << __parity__) | 0
      x_j = t_l * y_l + ((m & __half_maskB__) << __half_widthA__) + (xs[j]|0) + c | 0
      c = (x_j >>> __width__) + (m >>> __half_widthB__) + t_h * y_h | 0
      xs[j++] = x_j & __mask__

    x_j = (xs[j]|0) + c | 0
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
        x_l = xs[j] & __half_maskA__
        x_h = xs[j] >>> __half_widthA__
        i = c = 0
        k = j
        n = n_ys
        while --n >= 0
          yl_i = ys[i] & __half_maskB__
          yh_i = ys[i++] >>> __half_widthB__
          m = x_h * yl_i + (yh_i * x_l << __parity__) | 0
          z_j = (zs[j]|0) + x_l * yl_i + ((m & __half_maskB__) << __half_widthA__) + c | 0
          c = (z_j >>> __width__) + (m >>> __half_widthB__) + x_h * yh_i | 0
          zs[j++] = z_j & __mask__
        zs[j] = c
        
    _trim zs

  # HAC 14.32 (Montgomery reduction)
  _reduceMont = do (_extend, _lt, _shr, _sub) ->
    # computes xs * R^-1 mod ms
    (xs, ms, w) ->
      addmul = __addmul
      
      w_l = w & __half_maskA__
      w_h = w >>> __half_widthA__

      n_ms = ms.length
      i = 0
      _extend xs, 2*n_ms
      while i < n_ms
        x_l = xs[i] & __half_maskA__
        x_h = xs[i] >>> __half_widthA__
        u_i = w_l * x_l + ((w_l * x_h + w_h * x_l & __half_maskB__) << __half_widthA__) & __mask__
        addmul xs, i, u_i, ms, 0, 0, n_ms
        
        i++

      _shr xs, n_ms
      _sub xs, ms if not _lt xs, ms
      xs.length = n_ms
      xs
      
    
  # This file is concatenated with several other files in sequence; base.coffee precedes it, and
  # basic-operations.coffee follows it.
