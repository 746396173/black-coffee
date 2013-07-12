  # This file is concatenated with several other files in sequence; preamble.coffee precedes it,
  # and one of criticals-small.coffee, criticals-medium, or criticals-large follows it.
  #
  # Its base indent level is 2, since that is the indent level of its predecessor.

  # Uint8Array automatically initializes to zero, unlike Array, which contains undefined.
  _zeros = [].slice.call new Uint32Array 10240

  # Convert hexidecimal to a digit array.
  _parseHex = do () ->
    codex = []
    codex[i.toString 16] = i for i in [0...16]

    (hex) ->
      zs = []
      bits = 0
      acc = 0

      for i in [hex.length-1..0] by -1
        x = codex[hex[i]] or 0
        acc |= x << bits
        bits += 4
        if bits >= __width__
          zs.push acc & __mask__
          acc >>>= __width__
          bits -= __width__

      zs.push acc if bits > 0
      zs


  # Packs the digits from k bits per digit to n bits per digit.  n and k must be less than or equal
  # to 32.  The result is untrimmed and may have leading zeros.  k is optional and defaults to
  # __width__.
  _pack = (xs, n, k) ->
    k or= __width__

    if n == k
      return xs.slice()

    ys = []
    bits = 0
    acc = 0

    mask = if n < 32 then (1 << n) - 1 else -1
    i = 0
    t = xs.length
    while i < t
      x = xs[i++]

      acc |= x << bits
      bits += k

      while bits >= n
        if bits <= 32
          extra = 0
        else
          extra = bits - 32
          x >>>= k - extra
          bits = 32

        ys.push acc & mask
        bits -= n
        acc >>>= n
        acc &= (1 << bits) - 1

        if extra > 0
          acc |= x << bits
          bits += extra

    ys.push acc if bits > 0
    ys


  _random = (bits) ->
    xs = []
    while bits > __width__
      xs.push __base__ * random() & __mask__
      bits -= __width__

    if bits > 0
      xs.push __base__ * random() & ((1 << bits) - 1)

    xs


  _value = (xs) ->
    k = 0
    for i in [xs.length-1..0] by -1
      k = __base__ * k + (xs[i] & __mask__)
    k


  # digit-based functions

  _size = (xs) ->
    i = xs.length-1
    while (xs[i] & __mask__) is 0 and i >= 0 then i--
    i+1


  # On all browsers but Firefox _zeros.slice 0, k is a fast way to initialize and array to zeros.
  # This is particularly important for speed on Chrome.  Firefox seems to have a very slow slice
  # method.
  #
  _extend_Zeros = (xs, n) ->
    k = n - xs.length
    xs.push _zeros.slice 0, k if k > 0
    xs

  _extend_Empty = (xs, n) ->
    xs.length = n if n > xs.length
    xs

  _extend_None = (xs, n) ->
    xs

  _extend = switch Platform.name
    when 'Chrome'  then _extend_Zeros
    when 'Firefox' then _extend_Empty
    when 'Node'    then _extend_Zeros
    when 'Opera'   then _extend_Zeros
    when 'Safari'  then _extend_Zeros
    else _extend_Zeros

  _trim = (xs) ->
    xs.length = _size xs
    xs


  _shl = do (_zeros) ->
    (xs, k) ->
      [].unshift.apply xs, _zeros.slice 0, k
      xs


  _shr = (xs, k) ->
    xs.splice 0, k
    xs


  # Bitwise Functions

  _bitset = (xs, k, v) ->
    j = k % __width__
    i = (k - j)/__width__
    if not v? or v
      xs[i] |= 1 << j
    else
      xs[i] &= ~(1 << j)


  _bit = (xs, k) ->
    j = k % __width__
    i = (k - j)/__width__
    xs[i] >>> j & 1


  _bits = (xs, k) ->
    b = k % __width__
    j = (k - b)/__width__
    d =  __width__ - b
    xs[j] >>> b & (1 << d) - 1 | xs[j+1] << d | xs[j+2] << d + __width__


  _bitcount = (xs) ->
    c = 0
    i = 0
    n = xs.length * __width__
    # TODO optimized _bit out
    while i < n
      if _bit xs, i++
        c++
    c

  _msb = do (_size) ->
    (xs) ->
      k = (_size xs) - 1
      j = __width__
      if k == -1
        -1
      else
        x_k = xs[k]

        while --j >= 0 and not (x_k & 1 << j) then null

        j + k * __width__

  _bshl = do (_shl) ->
    (xs, k) ->
      b = k % __width__
      j = (k - b)/__width__ #

      _shl xs, j if j > 0

      b_l = b
      b_r = __width__ - b_l

      mask_l = (1 << b_r) - 1
      mask_h = ~mask_l

      c = 0
      zs = xs
      n_xs = xs.length
      i = 0
      while i < n_xs
        x_i = xs[i]
        z_i = (x_i & mask_l) << b_l | c
        c = (x_i & mask_h) >>> b_r
        zs[i++] = z_i & __mask__

      zs[xs.length] = c if c

      zs

  _bshr = do (_shr) ->
    (xs, k) ->
      b = k % __width__
      j = (k - b)/__width__

      _shr xs, j if j > 0

      b_r = b
      b_l = __width__ - b_r

      mask_l = (1 << b_r) - 1
      mask_h = ~mask_l

      c = 0
      zs = xs
      i = xs.length - 1
      while i >= 0
        x_i = xs[i]
        z_i = (x_i & mask_h) >>> b_r | c
        c = (x_i & mask_l) << b_l
        zs[i--] = z_i & __mask__

      zs


  # comparators

  _lt = (xs, ys, k) ->
    k or= 0
    i = max xs.length, ys.length+k
    while --i >= k
      x_i = xs[i] & -1
      y_i = ys[i-k] & -1
      if x_i < y_i then return true
      if x_i > y_i then return false
    false


  _eq = (xs, ys, k) ->
    k or=0
    i = max xs.length, ys.length+k
    while --i >= k
      if (xs[i] & -1) isnt (ys[i] & -1) then return false
    true

  # This file is concatenated with several other files in sequence; preamble.coffee precedes it,
  # and one of criticals-small.coffee, criticals-medium, or criticals-large follows it.
