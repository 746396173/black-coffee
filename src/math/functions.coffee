exports = exports or window

install = (obj) ->
  obj or= window
  for name, x of Functions__radix__ when name isnt 'install'
    obj[name] = x
  null
    
{ max, min, pow, random } = Math

_mantissa = do () ->
  c = 0
  while (pow 2, c) != 1 + pow 2, c then c++
  c

_width = do () ->
  c = 0                               # This determines the maximum size of an integer which can
  while ~~(pow 2, c) then c++         # be reliably manipulated with bitwise operations.
  c

## %% Begin Remove for Specialize %%
__radix__  = 28
__base__   = 1 << __radix__
__base2__  = pow __base__, 2
__mask__   = __base__ - 1

__demiradix__ = __radix__ >>> 1
__demibase__  = 1 << __demiradix__
__demimask__  = __demibase__ - 1

_setRadix = (radix) ->
  __radix__  = radix
  __base__   = 1 << __radix__
  __base2__  = pow __base__, 2
  __mask__   = __base__ - 1

  __demiradix__ = __radix__ >>> 1
  __demibase__  = 1 << __demiradix__
  __demimask__  = __demibase__ - 1

## %% End Remove for Specialize %%

_zeros = [].slice.call new Uint8Array 10240

_repr = do () ->
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
      if bits >= __radix__
        zs.push acc & __mask__
        acc >>>= __radix__
        bits -= __radix__

    zs.push acc if bits > 0
    zs

_hex = do () ->
  codex = (i.toString(16) for i in [0...16])

  (xs) ->
    chs = []
    bits = 0
    acc = 0

    for i in [0..._size xs] by 1
      for x in [xs[i] & __demimask__, xs[i] >>> __demiradix__]
        acc |= x << bits
        bits += __demiradix__
        while bits >= 4
          chs.push codex[acc & 0xf]
          acc >>>= 4
          bits -= 4

    chs.push codex[acc] if bits > 0
    while chs[chs.length-1] is '0' then chs.pop()
    chs = ['0'] if chs.length == 0
    chs.reverse().join ''


# Packs the digits from k bits per digit to n bits per digit.  n and k must be less than or equal
# to 32.  The result is untrimmed and may have leading zeros.  k is optional and defaults to
# __radix__.
_pack = (xs, n, k) ->
  k or= __radix__

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
  while bits > __radix__
    xs.push __base__ * random() & __mask__
    bits -= __radix__

  if bits > 0
    xs.push __base__ * random() & ((1 << bits) - 1)

  xs

  
_value = (xs) ->
  k = 0
  for i in [xs.length-1..0] by -1
    k = __base__ * k + (xs[i] & -1)
  k


# digit-based functions

_size = (xs) ->
  i = xs.length-1
  while (xs[i] & -1) is 0 and i >= 0 then i--
  i+1


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
#
# In general functions with a double underscore have more restrictive assumptions
# about their arguments (in terms of index validity and the lack of boundary checking).

_bitset = (xs, k, v) ->
  j = k % __radix__
  i = (k - j)/__radix__
  if not v? or v
    xs[i] |= 1 << j
  else
    xs[i] &= ~(1 << j)


_bit = (xs, k) ->
  j = k % __radix__
  i = (k - j)/__radix__
  xs[i] >>> j & 1


_bits = (xs, k) ->
  b = k % __radix__
  j = (k - b)/__radix__
  d =  __radix__ - b
  xs[j] >>> b & (1 << d) - 1 | xs[j+1] << d | xs[j+2] << d + __radix__


_bitcount = (xs) ->
  c = 0
  i = 0
  n = xs.length * __radix__
  # TODO optimized _bit out
  while i < n
    if _bit xs, i++
      c++
  c

_msb = do (_size) ->
  (xs) ->
    k = (_size xs) - 1
    j = __radix__
    if k == -1
      -1
    else
      x_k = xs[k]

      while --j >= 0 and not (x_k & 1 << j) then null

      j + k * __radix__

_bshl = do (_shl) ->
  (xs, k) ->
    b = k % __radix__
    j = (k - b)/__radix__ #

    _shl xs, j if j > 0

    b_l = b
    b_r = __radix__ - b_l

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
    b = k % __radix__
    j = (k - b)/__radix__

    _shr xs, j if j > 0

    b_r = b
    b_l = __radix__ - b_r

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


# partitions a bitstring (xs) into 1-bounded blocks of length at most n and arbitrarily long
# blocks of zeros; used in sliding window exponentiation.  Note that the list of partitions is in
# order from high bit to low bit, reverse that of the digit arrays; that is the most natural order
# for computing an exponential.
# 
_bpart = (xs, n) ->
  if n < 1
    return []
    
  n_xs = xs.length
  mask = (1 << n) - 1
  
  t = _msb xs
  i = t % __radix__
  k = t/__radix__ & -1
  x_k = xs[k]

  parts = []
  
  while i >= 0
    if (x_k & (1 << i)) is 0
      parts.push 0
      i--

    else
      j = i + 1 - n
      if j < 0
        if k > 0
          a = (x_k << -j | xs[k-1] >>> __radix__ + j) & mask
        else
          a = x_k & (mask >>> -j)
          j = 0
      else
        a = (x_k >>> j) & mask

      while (a & 1) is 0
        j++
        a >>>= 1

      parts.push a
      i = j - 1

    if i < 0
      if k > 0
        x_k = xs[--k]
        i += __radix__

  parts

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


# basic arithmetic

_add = (xs, ys, k) ->
  k or= 0
  c = 0
  zs = xs
  i = k
  n = ys.length + k
  while i < n
    z_i = (xs[i] & -1) + (ys[i-k] & -1) + c
    c = z_i >>> __radix__
    zs[i++] = z_i & __mask__

  while c
    z_i = (xs[i] & -1) + c
    c = z_i >>> __radix__
    zs[i] = z_i & __mask__
    i++

  zs


__add = (xs, j, ys, i, c, n) ->
  while --n >= 0
    w = ys[i++] + xs[j] + c
    c = w >>> __radix__
    xs[j++] = w & __mask__

  c

_sub = (xs, ys, k) ->
  k or= 0
  c = 0
  zs = xs
  i = k
  n = ys.length + k
  while i < n
    z_i = (xs[i] & -1) - (ys[i-k] & -1) - c
    if z_i < 0
      c = 1
      z_i += __base__
    else
      c = 0
    zs[i++] = z_i & __mask__


  n_xs = _size xs
  while c and i < n_xs
    z_i = (xs[i] & -1) - c
    if z_i < 0
      c = 1
      z_i += __base__
    else
      c = 0
    zs[i] = z_i & __mask__
    i++

  zs


# xs[j...j+n] <-- xs[j...j+n] + t * ys[i...i+n] + c
# --> c
# 30 bit wide digits can overlow 32 bits of available logic in the computation of the function
# in the else clause; adding mask and shift of the carry is enough to avoid the problem.  The
# result is slightly slower per digit.
# 
if __radix__ <= 28
  __addmul = (xs, j, t, ys, i, c, n) ->
    t_l = t & __demimask__
    t_h = t >>> __demiradix__
    while --n >= 0
      y_l = ys[i] & __demimask__
      y_h = ys[i++] >>> __demiradix__
      m = t_h * y_l + y_h * t_l
      l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + c
      c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h
      xs[j++] = l & __mask__

    c


  _mul1 = (xs, y) ->
    y_l = y & __demimask__
    y_h = y >>> __demiradix__

    zs = [0]
    n_xs = xs.length
    if n_xs > 0
      j = 0
      while j < n_xs
        x_l = xs[j] & __demimask__
        x_h = xs[j] >>> __demiradix__
        c = 0
        k = j

        m = x_h*y_l + y_h*x_l
        z_j = x_l*y_l + ((m & __demimask__) << __demiradix__) + c
        c = (z_j >>> __radix__) + (m >>> __demiradix__) + x_h*y_h
        zs[j++] = z_j & __mask__

      zs[j] = c
    zs


  _mul = (xs, ys) ->
    n_xs = xs.length
    n_ys = ys.length

    zs = _zeros.slice 0, n_xs + n_ys

    if n_xs > 0 and n_ys > 0
      for j in [0...n_xs] by 1
        x_l = xs[j] & __demimask__
        x_h = xs[j] >>> __demiradix__
        i = c = 0
        k = j
        n = n_ys
        while --n >= 0
          yl_i = ys[i] & __demimask__
          yh_i = ys[i++] >>> __demiradix__
          m = x_h*yl_i + yh_i*x_l
          z_j = zs[j] + x_l*yl_i + ((m & __demimask__) << __demiradix__) + c
          c = (z_j >>> __radix__) + (m >>> __demiradix__) + x_h*yh_i
          zs[j++] = z_j & __mask__
        zs[j] = c
    _trim zs
    
else
  __addmul = (xs, j, t, ys, i, c, n) ->
    t_l = t & __demimask__
    t_h = t >>> __demiradix__
    while --n >= 0
      y_l = ys[i] & __demimask__
      y_h = ys[i++] >>> __demiradix__
      m = t_h * y_l + y_h * t_l
      l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + (c & __mask__)
      c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h + (c >>> __radix__)
      xs[j++] = l & __mask__

    c


  _mul1 = (xs, y) ->
    y_l = y & __demimask__
    y_h = y >>> __demiradix__

    zs = [0]
    n_xs = xs.length
    if n_xs > 0
      j = 0
      while j < n_xs
        x_l = xs[j] & __demimask__
        x_h = xs[j] >>> __demiradix__
        c = 0
        k = j

        m = x_h*y_l + y_h*x_l
        z_j = x_l*y_l + ((m & __demimask__) << __demiradix__) + (c & __mask__)
        c = (z_j >>> __radix__) + (m >>> __demiradix__) + x_h*y_h + (c >>> __radix__)
        zs[j++] = z_j & __mask__

      zs[j] = c if c
    zs


  _mul = (xs, ys) ->
    n_xs = xs.length
    n_ys = ys.length

    zs = _zeros.slice 0, n_xs + n_ys

    if n_xs > 0 and n_ys > 0
      for j in [0...n_xs] by 1
        x_l = xs[j] & __demimask__
        x_h = xs[j] >>> __demiradix__
        i = c = 0
        k = j
        n = n_ys
        while --n >= 0
          yl_i = ys[i] & __demimask__
          yh_i = ys[i++] >>> __demiradix__
          m = x_h*yl_i + yh_i*x_l
          z_j = zs[j] + x_l*yl_i + ((m & __demimask__) << __demiradix__) + (c & __mask__)
          c = (z_j >>> __radix__) + (m >>> __demiradix__) + x_h*yh_i + (c >>> __radix__)
          zs[j++] = z_j & __mask__
        zs[j] = c
    _trim zs


_kmul = do (_add, _kmul, _mul, _shl, _sub) ->
  _kmul = (xs, ys) ->
    n_xs = xs.length
    n_ys = ys.length

    if (k = min n_xs, n_ys) < _kmul.Threshold
        _mul xs, ys

    else
      k >>>= 1

      xs_l = xs.slice 0, k
      ys_l = ys.slice 0, k

      xs_h = xs.slice k
      ys_h = ys.slice k

      as = _kmul xs_h, ys_h
      bs = _kmul (_add xs_h, xs_l), (_add ys_h, ys_l)
      cs = _kmul xs_l, ys_l

      ds = _sub (_sub bs, as), cs

      _shl as, 2*k
      _shl ds, k
      _add as, cs
      _add as, ds
      as

# Chrome
#   28 bit is fastest on Chrome
#   at best about 30ms/1000 on 2012 MacBook Pro 2.3GHz i7 16GB
#   for 26 bit radix:
#     2048            37-80 (as low as 21 is nearly as good)
#     3072            30-60
#   for 28 bit radix:
#     operand size    best range
#     1024            38+
#     1280            48+
#     1536            56+
#     2048            38-73
#     2560            47-93
#     3072            30-55 (but above 55 is less than 2% longer to run)
#   for 30 bit radix:
#     2048            35-70 (as low as 19 is nearly as good)
#     3072            27-81
#
# Safari
#   30 bits seem to be fastest on Safari
#   for 2048 bits per operand, at best about 45ms/1000 on 2012 MacBook Pro 2.3GHz i7 16GB
#   for 26 bit radix:
#     2048            81+
#     2560            51+
#     3072            61+
#   for 28 bit radix:
#     2048            75+
#     2560            93+
#     3072            56+
#   for 30 bit radix:
#     2048            71+
#     2560            87+
#     3072            86+
#  
# Firefox
#   30 bits seem to be fastest on Firefox
#   for 2048 bits per operand, at best about 215ms/1000 on 2012 MacBook Pro 2.3GHz i7 16GB
#   for 26 bit radix:
#     2048            81+
#     2560            51+
#     3072            31+
#   for 28 bit radix:
#     2048            75+
#     2560            47-92
#     3072            29+
#   for 30 bit radix:
#     2048            71+
#     2560            44-86 (as low as 23 is nearly as good)
#     3072            26+
#
# _kmul.Threshold = 50  # Chrome 26-bit
_kmul.Threshold = 57  # Chrome 28-bit
# _kmul.Threshold = 69  # Chrome 30-bit
# _kmul.Threshold = 81  # Firefox 26-bit
# _kmul.Threshold = 75  # Firefox 28-bit
# _kmul.Threshold = 71  # Firefox 30-bit
# _kmul.Threshold = 81  # Safari 26-bit
# _kmul.Threshold = 87  # Safari 28-bit
# _kmul.Threshold = 93  # Safari 30-bit


_sq = do (__addmul, _zeros) ->
  (xs) ->
    i = 0
    j = n = xs.length
    zs = _zeros.slice 0, 2*n

    while n > 1
      c = __addmul zs, 2*i, xs[i], xs, i, 0, 1
      if (zs[j] += (__addmul zs, 2*i + 1, xs[i] << 1, xs, i + 1, c, --n)) >= __base__
        zs[j] -= __base__
        zs[j+1] = 1
      i++
      j++

    if n > 0
      zs[j] += __addmul zs, 2*i, xs[i], xs, i, 0, 1

    while zs[j] == 0 then j--
    zs.length = j+1 if zs.length-1 > j

    zs


# Applying Karatsuba multiplication to squaring is only useful for operands >2048 bits
# in length. 
_ksq = do (_add, _ksq, _shl, _sq, _sub) ->
  _ksq = (xs) ->
    if (k = xs.length) < @Threshold
        _sq xs

    else
      k >>>= 1

      xs_l = xs.slice 0, k
      xs_h = xs.slice k

      as = _ksq xs_h
      bs = _ksq _add xs_h, xs_l
      cs = _ksq xs_l

      ds = _sub (_sub bs, as), cs

      _shl as, 2*k
      _shl ds, k
      _add as, cs
      _add as, ds
      as

# for 28 bit radix
#   operand size    best range
#   1024            38+
#   1280            47+
#   1536            56+
#   2048            74+
#   2560            47+
#   3072            111+
#   4096            38-73
_ksq.Threshold = 75



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
  (xs, ys) ->
    i = (_size xs)-1
    t = (_size ys)-1
    k = i - t

    if k < 0 then return [[0], xs]

    ys_t0 = ys[t]
    neg_ys = _sub [0], ys

    # 14.20.1
    # 14.20.2
    qs = []
    if not _lt xs, ys, k
      _sub xs, ys, k
      qs[k] = 1

    # 52 is the IEEE floating point standard mantissa length in bits (64 bit double)
    ys_t = (ys_t0 * (1 << 52 - __radix__)) + (ys[t-1] >>> 2 * __radix__ - 52)
    d1 = (pow 2, 52)/ys_t
    d2 = (1 << 52 - __radix__)/ys_t
    e = 1 << 2 * __radix__ - 52

    # create local namespace for speedy access to loop variables
    do (xs, neg_ys, qs, i, k, ys_t0, d1, d2, e, __addmul, __add) ->
      n = t + 1

      # 14.20.3
      while --k >= 0
        # 14.20.3.1
        if xs[i] == ys_t0
          # __base__ - 1... highest digit value
          q_i = __mask__

        else
          q_i = xs[i] * d1 + (xs[i-1] + e) * d2 & __mask__

        if xs[i] += (__addmul xs, k, q_i, neg_ys, 0, 0, n) - q_i
          xs[i] += (__add xs, k, ys, 0, 0, n) + 1
          q_i--

        i--
        qs[k] = q_i

      null

    xs.length = t + 1
    # 14.20.3.4-5
    [qs, xs]


_divmod = do (_bshl, _bshr, __divmod, _size) ->
  (xs, ys) ->
    # Note 14.23 on normalization
    y_t = ys[(_size ys)-1]
    c = 1
    while (y_t >>>= 1) > 0 then c++

    k = __radix__ - c
    ws = _bshl xs.slice(), k
    zs = _bshl ys.slice(), k

    [qs, rs] = __divmod ws, zs

    # assert _eq xs, _add (_mul qs, ys), _bshr rs.slice(), k

    [qs, _trim _bshr rs, k]


_div = do (_divmod) -> (xs, ys) -> (_divmod xs, ys)[0]
_mod = do (_divmod) -> (xs, ys) -> (_divmod xs, ys)[1]


_pow = do (_kmul, _sq) ->
  (xs, k) ->
    zs = [1]
    xs = xs.slice()
    while k > 0
      zs = _kmul zs, xs if k & 1
      xs = _sq xs
      k >>>= 1

    zs


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
    y = (y*(2 - x*y % __base__)) % __base__      # y == 1/x mod 2^__radix__

    # we really want the negative inverse, and -__base__ < y < __base__
    if y > 0
      y = __base__ - y
    else
      y = -y
  y


_liftMont = do (_mod, _shl) -> (xs, ms) -> _mod (_shl xs.slice(), ms.length), ms

if __radix__ <= 28
  __addmul0 = (xs, t, ys, n) ->
    t_l = t & __demimask__
    t_h = t >>> __demiradix__
    i = j = c = 0
    while --n >= 0
      y_l = ys[i] & __demimask__
      y_h = ys[i++] >>> __demiradix__
      m = t_h * y_l + y_h * t_l
      l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + c
      c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h
      xs[j++] = l & __mask__

    xs[j] += c

    while xs[j] >= __base__
      xs[j] -= __base__
      xs[++j]++

    xs

else
  __addmul0 = (xs, t, ys, n) ->
    t_l = t & __demimask__
    t_h = t >>> __demiradix__
    i = j = c = 0
    while --n >= 0
      y_l = ys[i] & __demimask__
      y_h = ys[i++] >>> __demiradix__
      m = t_h * y_l + y_h * t_l
      l = t_l * y_l + ((m & __demimask__) << __demiradix__) + xs[j] + (c & __mask__)
      c = (l >>> __radix__) + (m >>> __demiradix__) + t_h * y_h + (c >>> __radix__)
      xs[j++] = l & __mask__

    xs[j] += c

    while xs[j] >= __base__
      xs[j] -= __base__
      xs[++j]++

    xs


_reduceMont = do (_lt, _shr, _sub, _trim, _zeros) ->

  # computes xs * R^-1 mod ms
  (xs, ms, W) ->
    addmul0 = __addmul0
    W_l = W & __demimask__
    W_h = W >>> __demiradix__

    n_ms = ms.length

    i = 0
    zs = _zeros.slice 0, 2 + 2*n_ms
    while i < n_ms
      z = zs[0] += xs[i++] & -1
      j = 0
      while zs[j] >= __base__
        zs[j] -= __base__
        zs[++j]++

      u_l = z & __demimask__
      u_h = (z >>> __demiradix__) & __demimask__

      u_i = W_l * u_l + (W_l * u_h + W_h * u_l << __demiradix__) & __mask__
      addmul0 zs, u_i, ms, n_ms

      #_shr zs, 1
      zs.shift()

    _sub zs, ms if not _lt zs, ms
    zs.length = n_ms
    zs


# This is a hybrid of HAC 14.36 (Montgomery Multiplication) and HAC 14.16 (Multiple Precision
# Squaring).  It is has about 75% of the running time of the equivalent functionality using
# _mulMont below.
# 
_sqMont = do (_lt, _sub, _zeros) ->
  # computes xs * xs * R^-1 mod ms
  (xs, ms, W) ->
    addmul = __addmul
    addmul0 = __addmul0
    
    W_l = W & __demimask__
    W_h = W >>> __demiradix__
    
    i = 0
    n = n_ms = ms.length
    zs = _zeros.slice 0, 2 * n_ms + 2

    while n > 0
      x_i = xs[i] & -1

      # zs[i] <-- zs[i] + xs[i]^2
      xi_l = x_i & __demimask__
      xi_h = x_i >>> __demiradix__
      
      m = (xi_h * xi_l) << 1
      l = xi_l * xi_l + ((m & __demimask__) << __demiradix__) + zs[i]
      zs[i++] = l & __mask__

      # propagate carries
      j = i
      zs[j] += (l >>> __radix__) + (m >>> __demiradix__) + xi_h * xi_h
      while zs[j] >= __base__
        zs[j] -= __base__
        zs[++j]++

      # zs[i + j] <-- zs[i + j] + xs[i] * xs[j] for j in i+1...n_ms
      if (zs[n_ms] += (addmul zs, i, x_i << 1, xs, i, 0, --n)) >= __base__
        zs[n_ms] -= __base__
        zs[n_ms+1] = 1

      # Montgomery reduction step
      u_l = zs[0] & __demimask__
      u_h = zs[0] >>> __demiradix__

      u_i = W_l * u_l + (W_l * u_h + W_h * u_l << __demiradix__) & __mask__
      addmul0 zs, u_i, ms, n_ms

      #_shr zs, 1
      zs.shift()
      
    _sub zs, ms if not _lt zs, ms
    zs.length = n_ms
    zs


_mulMont = do (_lt, _shr, _sub, _trim, _zeros) ->

  # computes xs * ys * R^-1 mod ms
  (xs, ys, ms, W) ->
    addmul0 = __addmul0
    W_l = W & __demimask__
    W_h = W >>> __demiradix__

    y0_l = ys[0] & __demimask__
    y0_h = ys[0] >>> __demiradix__

    n_ms = ms.length
    n_ys = ys.length

    i = 0
    zs = _zeros.slice 0, 2*n_ms + 2
    while i < n_ms
      x_i = xs[i++] & -1

      xi_l = x_i & __demimask__
      xi_h = x_i >>> __demiradix__

      u = y0_l * xi_l + ((y0_l * xi_h + y0_h * xi_l) << __demiradix__)
      u = u + zs[0] & __mask__

      u_l = u & __demimask__
      u_h = u >>> __demiradix__

      u_i = W_l * u_l + ((W_l * u_h + W_h * u_l) << __demiradix__) & __mask__

      addmul0 zs, x_i, ys, n_ys
      addmul0 zs, u_i, ms, n_ms

      #_shr zs, 1
      zs.shift()

    _sub zs, ms if not _lt zs, ms
    zs.length = n_ms
    zs


# modular arithmetic

_mulmod = do (_divmod, _kmul) ->
  (xs, ys, ms) -> (_divmod (_kmul xs, ys), ms)[1]


_simpleSqmod = do (_divmod, _sq) ->
  (xs, ms) -> (_divmod (_sq xs), ms)[1]


_montgomerySqmod = do (_cofactorMont, _liftMont, _reduceMont, _sqMont, _trim) ->
  # computes xs ^ 2 mod ms
  (xs, ms) ->
    W = _cofactorMont _trim ms
    _reduceMont (_sqMont (_liftMont xs, ms), ms, W), ms, W


_sqmod = do (_montgomerySqmod, _msb, _simpleSqmod) ->
  (xs, ms) ->
    t = _msb ms

    if t == -1
      [1]

    else if t <= _sqmod.SimpleSqmodBitLimit
      _simpleSqmod xs, ms

    else
      _montgomerySqmod xs, ms

_sqmod.SimpleSqBitLimit = 0 


_simplePowmod = do (_kmul, _mod, _sq) ->
  (xs, ys, ms) ->
    xs = _mod xs, ms

    j = ys.length-1
    i = __radix__ - 1
    d = ys[j]
    while (d & (1 << i)) == 0
      if --i < 0
        if j == 0
          return [0]
        i += __radix__
        d = ys[--j]

    zs = xs

    if --i < 0
      if j == 0
        return zs
      i += __radix__
      d = ys[--j]

    zs = _mod (_sq xs), ms

    loop
      if d & (1 << i)
        zs = _mod (_kmul zs, xs), ms

      if --i < 0
        if j == 0
          return zs
        i += __radix__
        d = ys[--j]

      zs = _mod (_sq zs), ms


_estimateWindowSizeMap = (L, N) ->
  t = 0
  a = 1
  b = 2
  c = 3
  result = []
  while ++t <= L
    ma = mb = mc = 0
    
    for i in [1..N]
      xs = _random t
      ma += (x for x in _bpart xs, a when x).length + (1 << (a - 1))
      mb += (x for x in _bpart xs, b when x).length + (1 << (b - 1))
      mc += (x for x in _bpart xs, c when x).length + (1 << (c - 1))

    if ma < mb
      result.push a
      if a > 1
        a--; b--; c--

    else if mc < mb
      result.push c
      a++; b++; c++

    else
      result.push b
      
  return result

_estimateWindowSizeTransitions = (L, N) ->
  map = _estimateWindowSizeMap L, N
  rmap = map.slice().reverse()
  result = [-1, 0]
  for i in [1...map[L-1]]
    result[i+1] = ((map.indexOf i+1) + (L - rmap.indexOf i))/2
  result
  

_windowSize = do () ->
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
  for t in [0...10000]
    if t >= T[k+1]
      k++
    k
    
    
_slidingWindowPowmod = do (_kmul, _mod, _sq, _windowSize) ->
  (xs, ys, ms, t) ->
    
    xs = _mod xs, ms

    # precompute odd powers of the base from 3...2^w - 1

    gns = [ [1], xs ]
    gs = xs
    g2s = _mod (_sq xs), ms
    w = _windowSize[t]
    count = 1 << w
    while gns.length < count
      gs = _mod (_kmul gs, g2s), ms
      gns.push undefined, gs

    zs = xs
    mask = count - 1
    t--
    i = t % __radix__
    t = t/__radix__ & 1
    y_t = ys[t]
    while i >= 0
      if (y_t & (1 << i)) is 0
        zs = _mod (_sq zs), ms
        i--

      else
        j = i + 1 - w
        if j < 0
          if t > 0
            y = (y_t << -j | ys[t-1] >> __radix__ + j) & mask
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

        zs = _mod (_kmul zs, gns[y]), ms
        i = j - 1

      if i < 0
        if t > 0
          y_t = ys[--t]
          i += __radix__

    zs


_powMont = do (_bit, _mulMont) ->
  # computes xs ^ ys mod ms
  (xs, ys, ms, W, zs) ->

    #TODO optimize away bit ys, i call
    t = _msb ys
    for i in [t..0] by -1
      zs = _mulMont zs, zs, ms, W
      zs = _mulMont zs, xs, ms, W if _bit ys, i

    _mulMont zs, [1], ms, W

# There are two versions of _slidingWindowPowMont.  The first uses only _mulMont; the second uses
# _sqMont where appropriate.  Both in theory and in isolated timing _mulMont has about 75% of the
# running time of _mulMont, yet on Chrome _slidingWindowPowMont using _sqMont has a 7% longer
# running time (2048-bit operands).  On Firefox, Opera, and Safari, the _sqMont version runs at
# about 82% of the _mulMont one, which is what one would expect given the proportion of _mulMont
# calls to _sqMont calls in a typical 2048-bit exponentiation.
# 

_slidingWindowPowMontA = do (_mulMont, _mod, _sq, _windowSize) ->
  (xs, ys, ms, t, W, zs) ->

    # precompute odd powers of the base from 3...2^w - 1
    gns = [ zs, xs ]
    gs = xs
    g2s = _mulMont xs, xs, ms, W

    w = _windowSize[t]
    count = 1 << w
    while gns.length < count
      gs = _mulMont gs, g2s, ms, W
      gns.push undefined, gs

    zs = xs
    mask = count - 1
    t--
    i = t % __radix__
    t = t/__radix__ & -1
    y_t = ys[t]
    while i >= 0
      if (y_t & (1 << i)) is 0
        zs = _mulMont zs, zs, ms, W
        i--

      else
        j = i + 1 - w
        if j < 0
          if t > 0
            y = (y_t << -j | ys[t-1] >>> __radix__ + j) & mask
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
          zs = _mulMont zs, zs, ms, W

        zs = _mulMont zs, gns[y], ms, W
        i = j - 1

      if i < 0
        if t > 0
          y_t = ys[--t]
          i += __radix__


    # for large (>1024 bits) operands, there is no measurable difference between the two lines below.
    # In theory, they are equivalent, and the _reduceMont should be faster.  There is some indication
    # that a reduced working set (of code) helps Chrome/Chromium run faster.
    _mulMont zs, [1], ms, W
    #_reduceMont zs, ms, W

_slidingWindowPowMontB = do (_mulMont, _mod, _sq, _windowSize) ->
  (xs, ys, ms, t, W, zs) ->

    # precompute odd powers of the base from 3...2^w - 1
    gns = [ zs, xs ]
    gs = xs
    g2s = _sqMont xs, ms, W

    w = _windowSize[t]
    count = 1 << w
    while gns.length < count
      gs = _mulMont gs, g2s, ms, W
      gns.push undefined, gs

    zs = xs
    mask = count - 1
    t--
    i = t % __radix__
    t = t/__radix__ & -1
    y_t = ys[t]
    while i >= 0
      if (y_t & (1 << i)) is 0
        zs = _sqMont zs, ms, W
        i--

      else
        j = i + 1 - w
        if j < 0
          if t > 0
            y = (y_t << -j | ys[t-1] >>> __radix__ + j) & mask
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
          zs = _sqMont zs, ms, W

        zs = _mulMont zs, gns[y], ms, W
        i = j - 1

      if i < 0
        if t > 0
          y_t = ys[--t]
          i += __radix__


    # for large (>1024 bits) operands, there is no measurable difference between the two lines below.
    # In theory, they are equivalent, and the _reduceMont should be faster.  There is some indication
    # that a reduced working set (of code) helps Chrome/Chromium run faster.
    _mulMont zs, [1], ms, W
    #_reduceMont zs, ms, W

        
_montgomeryPowmod = do (_cofactorMont, _liftMont, _mod, _trim) ->
  if Browser.name is 'Chrome'
    _slidingWindowPowMont = _slidingWindowPowMontA
  else
    _slidingWindowPowMont = _slidingWindowPowMontB
    
    # computes xs ^ ys mod ms
  (xs, ys, ms, t) ->
    W = _cofactorMont _trim ms
    _slidingWindowPowMont (_liftMont xs, ms), (_trim ys), ms, t, W, _liftMont [1], ms


_powmod = do (_mod, _msb, _powMont, _shl, _simplePowmod, _slidingWindowPowmod, _trim) ->
  (xs, ys, ms) ->
    t = _msb ys

    if t == -1
      [1]

    else if t <= _powmod.SimplePowmodBitLimit
      _simplePowmod xs, ys, ms

    else if t <= _powmod.SlidingWindowPowmodBitLimit
      _slidingWindowPowmod xs, ys, ms, t

    else
      _montgomeryPowmod xs, ys, ms, t

# for 28 bit radix
#   operand size    best value
#   1024            17
#   2048            17
#   3072            19
#_powmod.SimplePowmodBitLimit = 17
_powmod.SimplePowmodBitLimit = 0 

# To be determined
_powmod.SlidingWindowPowmodBitLimit = 0


Functions =
  _add:                     _add
  __add:                    __add
  __addmul:                 __addmul
  _bit:                     _bit
  _bitcount:                _bitcount
  _bits:                    _bits
  _bitset:                  _bitset
  _bpart:                   _bpart
  _bshl:                    _bshl
  _bshr:                    _bshr
  _cofactorMont:            _cofactorMont
  _div:                     _div
  _divmod:                  _divmod
  __divmod:                 __divmod
  _eq:                      _eq
  _estimateWindowSizeMap:   _estimateWindowSizeMap
  _estimateWindowSizeTransitions: _estimateWindowSizeTransitions
  _hex:                     _hex
  install:                  install
  _kmul:                    _kmul
  _ksq:                     _ksq
  _liftMont:                _liftMont
  _lt:                      _lt
  _mod:                     _mod
  _montgomeryPowmod:        _montgomeryPowmod
  _msb:                     _msb
  _mul1:                    _mul1
  _mul:                     _mul
  _mulmod:                  _mulmod
  _mulMont:                 _mulMont
  _pack:                    _pack
  _pow:                     _pow
  _powmod:                  _powmod
  _powMont:                 _powMont
  _radix:                   __radix__
  _random:                  _random
  _reduceMont:              _reduceMont
  _repr:                    _repr
  _shl:                     _shl
  _shr:                     _shr
  _simplePowmod:            _simplePowmod
  _slidingWindowPowmod:     _slidingWindowPowmod
  _slidingWindowPowMontA:    _slidingWindowPowMontA
  _slidingWindowPowMontB:    _slidingWindowPowMontB
  _size:                    _size
  _sq:                      _sq
  _sqmod:                   _sqmod
  _sqMont:                  _sqMont
  _sub:                     _sub
  _trim:                    _trim
  _value:                   _value
  _windowSize:              _windowSize
  _zeros:                   _zeros

exports.Functions__radix__ = Functions
## %% Begin Remove for Specialize %%
exports.Functions = Functions
## %% End Remove for Specialize %%
  