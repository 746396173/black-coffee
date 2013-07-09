exports = exports or window

# Mainly used to add a set of specialized functions to a Long subclass, creating a Long
# specialized to a specific digit bit width.
# 
install = (obj) ->
  obj or= window
  for name, x of Functions__width__ when name isnt 'install'
    obj[name] = x
  null
    
{ ceil, max, min, pow, random } = Math

## %% Begin Remove for Specialize %%
#
# These ubiquitous and constant variables are replaced with literals by specialize-functions.
# This creates separate files for each digit bit width, thereby allowing the compiler to create
# faster code by both removing the dereference and by reducing the size of the namespaces to be
# searched.

__width__  = 28
__base__   = 1 << __width__
__mask__   = __base__ - 1

__half_widthA__ = __width__ >>> 1
__half_baseA__  = 1 << __half_widthA__
__half_maskA__  = __half_baseA__ - 1
__half_widthB__ = __width__ - __half_widthA__
__half_baseB__  = 1 << __half_widthB__
__half_maskB__  = __half_baseB__ - 1

## %% End Remove for Specialize %%

# Uint8Array automatically initializes to zero, unlike Array, which contains undefined.
_zeros = [].slice.call new Uint8Array 10240

# On all browsers but Firefox _empty.slice 0, k is a fast way to initialize and array to zeros.
# This is particularly important for speed on Chrome.  Firefox seems to have a very slow slice
# method, so we use other means (bitwise casting -- xs[i]|0).
#
if Browser.name is 'Firefox'
  _empty = []
else
  _empty = _zeros

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
  i = t % __width__
  k = t/__width__ & -1
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
          a = (x_k << -j | xs[k-1] >>> __width__ + j) & mask
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
        i += __width__

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
    c = z_i >>> __width__
    zs[i++] = z_i & __mask__

  while c
    z_i = (xs[i] & -1) + c
    c = z_i >>> __width__
    zs[i] = z_i & __mask__
    i++

  zs


__add = (xs, j, ys, i, c, n) ->
  while --n >= 0
    w = ys[i++] + xs[j] + c
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

# adder-multipliers  xs[j...j+n] += t * ys[i...i+n] + c
# returns final carry

# Use with digits <= 15 bits wide
__addmul_SmallDigit = (xs, j, t, ys, i, c, n) ->
  while --n >= 0
    x_j = (xs[j]|0) + t * (ys[i++]|0) + c
    c = x_j >>> __width__
    xs[j++] = x_j & __mask__

  c

# Use with digits of even width > 15 bits   
__addmul_LargeDigit = (xs, j, t, ys, i, c, n) ->
  t_l = t & __half_maskA__
  t_h = t >>> __half_widthA__
  while --n >= 0
    y_l = ys[i] & __half_maskB__
    y_h = ys[i++] >>> __half_widthB__
    m = t_h * y_l + (y_h * t_l << (__width__ & 1))
    l = t_l * y_l + ((m & __half_maskB__) << __half_widthA__) + (xs[j]|0) + c
    c = (l >>> __width__) + (m >>> __half_widthB__) + t_h * y_h
    xs[j++] = l & __mask__

  c

# Use with digits of even width > 15 bits
__addmul_WithCarryMask = (xs, j, t, ys, i, c, n) ->
  t_l = t & __half_maskA__
  t_h = t >>> __half_widthA__
  while --n >= 0
    y_l = ys[i] & __half_maskB__
    y_h = ys[i++] >>> __half_widthB__
    m = t_h * y_l + (y_h * t_l << (__width__ & 1))
    l = t_l * y_l + ((m & __half_maskB__) << __half_widthA__) + (xs[j]|0) + (c & __mask__)
    c = (l >>> __width__) + (m >>> __half_widthB__) + t_h * y_h + (c >>> __width__)
    xs[j++] = l & __mask__

  c

__addmul0_SmallDigit = (xs, t, ys, n) ->
  i = j = c = 0
  while --n >= 0
    x_j = (xs[j]|0) + t * (ys[i++]|0) + c
    c = x_j >>> __width__
    xs[j++] = x_j & __mask__

  xs[j] = (xs[j]|0) + c

  while xs[j] >= __base__
    xs[j+1] = (xs[j+1]|0) + (xs[j] >>> __width__)
    xs[j++] &= __mask__

  xs

__addmul0_LargeDigit = (xs, t, ys, n) ->
  t_l = t & __half_maskA__
  t_h = t >>> __half_widthA__
  i = j = c = 0
  while --n >= 0
    y_l = ys[i] & __half_maskB__
    y_h = ys[i++] >>> __half_widthB__
    m = t_h * y_l + (y_h * t_l << (__width__ & 1))
    l = t_l * y_l + ((m & __half_maskB__) << __half_widthA__) + (xs[j]|0) + c
    c = (l >>> __width__) + (m >>> __half_widthB__) + t_h * y_h
    xs[j++] = l & __mask__

  xs[j] = (xs[j]|0) + c

  while xs[j] >= __base__
    xs[j+1] = (xs[j+1]|0) + (xs[j] >>> __width__)
    xs[j++] &= __mask__

  xs

__addmul0_WithCarryMask = (xs, t, ys, n) ->
  t_l = t & __half_maskA__
  t_h = t >>> __half_widthA__
  i = j = c = 0
  while --n >= 0
    y_l = ys[i] & __half_maskB__
    y_h = ys[i++] >>> __half_widthB__
    m = t_h * y_l + (y_h * t_l << (__width__ & 1))
    l = t_l * y_l + ((m & __half_maskB__) << __half_widthA__) + (xs[j]|0) + (c & __mask__)
    c = (l >>> __width__) + (m >>> __half_widthB__) + t_h * y_h + (c >>> __width__)
    xs[j++] = l & __mask__

  xs[j] = (xs[j]|0) + c

  while xs[j] >= __base__
    xs[j+1] = (xs[j+1]|0) + (xs[j] >>> __width__)
    xs[j++] &= __mask__

  xs


_mul_SmallDigit = (xs, ys) ->
  n_xs = xs.length
  n_ys = ys.length

  zs = _empty.slice 0, n_xs + n_ys

  if n_xs > 0 and n_ys > 0
    for j in [0...n_xs] by 1
      x_j = xs[j] & __mask__
      i = c = 0
      k = j
      n = n_ys
      while --n >= 0
        z_j = (zs[j]|0) + x_j * ys[i++] + c
        c = z_j >>> __width__
        zs[j++] = z_j & __mask__
      zs[j] = c
  _trim zs


_mul_LargeDigit = (xs, ys) ->
  n_xs = xs.length
  n_ys = ys.length

  zs = _empty.slice 0, n_xs + n_ys

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
        m = x_h * yl_i + (yh_i * x_l << (__width__ & 1))
        z_j = (zs[j]|0) + x_l*yl_i + ((m & __half_maskB__) << __half_widthA__) + c
        c = (z_j >>> __width__) + (m >>> __half_widthB__) + x_h*yh_i
        zs[j++] = z_j & __mask__
      zs[j] = c
  _trim zs


_mul_WithCarryMask = (xs, ys) ->
  n_xs = xs.length
  n_ys = ys.length

  # pre-initializing the array helps
  zs = _empty.slice 0, n_xs + n_ys

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
        m = x_h*yl_i + (yh_i * x_l << (__width__ & 1))
        z_j = (zs[j]|0) + x_l*yl_i + ((m & __half_maskB__) << __half_widthA__) + (c & __mask__)
        c = (z_j >>> __width__) + (m >>> __half_widthB__) + x_h*yh_i + (c >>> __width__)
        zs[j++] = z_j & __mask__
      zs[j] = c
  _trim zs


if __width__ <= 15
  __addmul = __addmul_SmallDigit
  __addmul0 = __addmul0_SmallDigit
  _mul = _mul_SmallDigit
  
else if __width__ <= 29
  __addmul = __addmul_LargeDigit
  __addmul0 = __addmul0_LargeDigit
  _mul = _mul_LargeDigit

else
  __addmul = __addmul_WithCarryMask
  __addmul0 = __addmul0_WithCarryMask
  _mul = _mul_WithCarryMask

  
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

_kmul.Threshold = Infinity


_sq = do (__addmul, _empty) ->
  (xs) ->
    i = 0
    j = n = xs.length
    zs = _empty.slice 0, 2*n

    while n > 1
      c = __addmul zs, 2*i, xs[i], xs, i, 0, 1
      if (zs[j] = (zs[j]|0) + __addmul zs, 2*i + 1, xs[i] << 1, xs, i + 1, c, --n) >= __base__
        zs[j+1] = (zs[j+1]|0) + (zs[j] >>> __width__)
        zs[j] &= __mask__
      i++
      j++

    if n > 0
      zs[j] = (zs[j]|0) + __addmul zs, 2*i, xs[i], xs, i, 0, 1

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

# for 28 bit width
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
    if __width__ >= 26
      ys_t = (ys_t0 * (1 << 52 - __width__)) + (ys[t-1] >>> 2 * __width__ - 52)
    else
      digits = ceil 52/__width__
      if digits > ys.length
        ys_t = _value _bshl ys.slice(), 52 - __width__ * ys.length
      else
        ys_t = _value _bshr (ys.slice -digits), __width__ * digits - 52

    d1 = (pow 2, 52)/ys_t
    d2 = (pow 2, 52 - __width__)/ys_t
    e = pow 2, 2 * __width__ - 52

    # create local namespace for speedy access to loop variables
    do (xs, neg_ys, qs, i, k, ys_t0, d1, d2, e, __addmul, __add) ->
      n = t + 1

      # 14.20.3
      while --k >= 0
        # 14.20.3.1
        x_i = xs[i] & __mask__
        
        if x_i == ys_t0
          # __base__ - 1... highest digit value
          q_i = __mask__

        else
          q_i = x_i * d1 + (xs[i-1] + e) * d2 & __mask__

        if xs[i] = x_i + (__addmul xs, k, q_i, neg_ys, 0, 0, n) - q_i
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
    _trim ys
    y_t = ys[ys.length-1]
    c = 1
    while (y_t >>>= 1) > 0 then c++

    k = __width__ - c
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
      zs = _mul zs, xs if k & 1
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
    y = (y*(2 - x*y % __base__)) % __base__      # y == 1/x mod 2^__width__

    # we really want the negative inverse, and -__base__ < y < __base__
    if y > 0
      y = __base__ - y
    else
      y = -y
  y


# Here is another way to compute the same result.  This version is slower; the clever algebraic version above
# has less than 2/3rds the running time of this one.
# 
_cofactorMontB = (ms) ->
  x = ms[0]
  y = 0
  z = 0
  b = 1
  while b < __base__
    if (y & 1) is 0
      y = y + x & __mask__
      z |= b
    y >>>= 1
    b <<= 1
  z
  

_liftMont = do (_mod, _shl) -> (xs, ms) -> _mod (_shl xs.slice(), ms.length), ms

_reduceMont = do (_lt, _shr, _sub, _trim, _empty) ->

  # computes xs * R^-1 mod ms
  (xs, ms, W) ->
    addmul0 = __addmul0
    W_l = W & __half_maskA__
    W_h = W >>> __half_widthA__

    n_ms = ms.length

    i = 0
    zs = _empty.slice 0, 2 + 2*n_ms
    while i < n_ms
      z = zs[0] = (zs[0]|0) + xs[i++] & -1
      j = 0
      while zs[j] >= __base__
        zs[j+1] = (zs[j+1]|0) + (zs[j] >>> __width__)
        zs[j++] &= __mask__

      # Montgomery reduction step
      z_l = zs[0] & __half_maskB__
      z_h = zs[0] >>> __half_widthB__

      u_i = W_l * z_l + (((W_l * z_h << (__width__ & 1)) + W_h * z_l & __half_maskB__) << __half_widthA__) & __mask__
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
_sqMont = do (_lt, _sub, _empty) ->
  # computes xs * xs * R^-1 mod ms
  (xs, ms, W) ->
    addmul = __addmul
    addmul0 = __addmul0
    
    W_l = W & __half_maskA__
    W_h = W >>> __half_widthA__
    
    i = 0
    n = n_ms = ms.length
    zs = _empty.slice 0, 2 * n_ms + 2

    while n > 0
      x_i = xs[i] & -1

      # zs[i] <-- zs[i] + xs[i]^2
      xi_l = x_i & __half_maskB__
      xi_h = x_i >>> __half_widthB__
      
      m = (xi_h * xi_l) << 1
      l = xi_l * xi_l + ((m & __half_maskA__) << __half_widthB__) + (zs[i]|0)
      zs[i++] = l & __mask__

      # propagate carries
      j = i
      zs[j] = (zs[j]|0) + (l >>> __width__) + (m >>> __half_widthA__) + (xi_h * xi_h << (__width__ & 1))
      while zs[j] >= __base__
        zs[j+1] = (zs[j+1]|0) + (zs[j] >>> __width__)
        zs[j++] &= __mask__

      # zs[i + j] <-- zs[i + j] + xs[i] * xs[j] for j in i+1...n_ms
      if (zs[n_ms] = (zs[n_ms]|0) + addmul zs, i, x_i << 1, xs, i, 0, --n) >= __base__
        zs[n_ms+1] = (zs[n_ms+1]|0) + (zs[n_ms] >>> __width__)
        zs[n_ms] &= __mask__

      # Montgomery reduction step
      z_l = zs[0] & __half_maskB__
      z_h = zs[0] >>> __half_widthB__

      u_i = W_l * z_l + (((W_l * z_h << (__width__ & 1)) + W_h * z_l & __half_maskB__) << __half_widthA__) & __mask__
        
      addmul0 zs, u_i, ms, n_ms

      #_shr zs, 1
      zs.shift()
      
    _sub zs, ms if not _lt zs, ms
    zs.length = n_ms
    zs



_mulMont = do (_lt, _shr, _sub, _trim, _empty) ->

  # computes xs * ys * R^-1 mod ms
  (xs, ys, ms, W) ->
    addmul0 = __addmul0
    W_l = W & __half_maskA__
    W_h = W >>> __half_widthA__

    y0_l = ys[0] & __half_maskA__
    y0_h = ys[0] >>> __half_widthA__

    n_ms = ms.length
    n_ys = ys.length

    i = 0
    zs = _empty.slice 0, 2*n_ms + 2
    while i < n_ms
      x_i = xs[i++] & -1

      xi_l = x_i & __half_maskB__
      xi_h = x_i >>> __half_widthB__

      u = y0_l * xi_l + (((y0_l * xi_h << (__width__ & 1)) + y0_h * xi_l) << __half_widthA__)
      u = u + (zs[0]|0) & __mask__

      z_l = u & __half_maskB__
      z_h = u >>> __half_widthB__

      u_i = W_l * z_l + (((W_l * z_h << (__width__ & 1)) + W_h * z_l & __half_maskB__) << __half_widthA__) & __mask__

      addmul0 zs, x_i, ys, n_ys
      addmul0 zs, u_i, ms, n_ms

      #_shr zs, 1
      zs.shift()

    _sub zs, ms if not _lt zs, ms
    zs.length = n_ms
    zs


# modular arithmetic

_negateMod = (xs, ms) -> if _eq xs, [0] then xs else _sub ms.slice(), xs

_mulmod = do (_divmod, _mul) ->
  (xs, ys, ms) -> (_divmod (_mul xs, ys), ms)[1]


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

_sqmod.SimpleSqmodBitLimit = Infinity


_simplePowmod = do (_mul, _mod, _sq) ->
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
    
    
_slidingWindowPowmod = do (_mul, _mod, _sq, _windowSize) ->
  (xs, ys, ms, t) ->
    
    xs = _mod xs, ms

    # precompute odd powers of the base from 3...2^w - 1

    gns = [ [1], xs ]
    gs = xs
    g2s = _mod (_sq xs), ms
    w = _windowSize[t]
    count = 1 << w
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
        j = i + 1 - w
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


_simplePowMont = do (_mulMont, _sqMont) ->
  (xs, ys, ms, W) ->
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
        return _mulMont zs, [1], ms, W
      i += __width__
      d = ys[--j]

    zs = _sqMont zs, ms, W

    loop
      if d & (1 << i)
        zs = _mulMont zs, xs, ms, W

      if --i < 0
        if j == 0
          return _mulMont zs, [1], ms, W
        i += __width__
        d = ys[--j]

      zs = _sqMont zs, ms, W

    # for large (>1024 bits) operands, there is no measurable difference between the two lines below.
    # In theory, they are equivalent, and the _reduceMont should be faster.  There is some indication
    # that a reduced working set (of code) helps Chrome/Chromium run faster.
    
    #_reduceMont zs, ms, W

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
    i = t % __width__
    t = t/__width__ & -1
    y_t = ys[t]
    while i >= 0
      if (y_t & (1 << i)) is 0
        zs = _mulMont zs, zs, ms, W
        i--

      else
        j = i + 1 - w
        if j < 0
          if t > 0
            y = (y_t << -j | ys[t-1] >>> __width__ + j) & mask
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
          i += __width__


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
    i = t % __width__
    t = t/__width__ & -1
    y_t = ys[t]
    while i >= 0
      if (y_t & (1 << i)) is 0
        zs = _sqMont zs, ms, W
        i--

      else
        j = i + 1 - w
        if j < 0
          if t > 0
            y = (y_t << -j | ys[t-1] >>> __width__ + j) & mask
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
          i += __width__


    # for large (>1024 bits) operands, there is no measurable difference between the two lines below.
    # In theory, they are equivalent, and the _reduceMont should be faster.  There is some indication
    # that a reduced working set (of code) helps Chrome/Chromium run faster.
    _mulMont zs, [1], ms, W
    #_reduceMont zs, ms, W


if Browser.name is 'Chrome'
  _slidingWindowPowMont = _slidingWindowPowMontA
else
  _slidingWindowPowMont = _slidingWindowPowMontB
        
_montgomeryPowmod = do (_cofactorMont, _liftMont, _mod, _slidingWindowPowMont, _trim) ->
    # computes xs ^ ys mod ms
  (xs, ys, ms, t) ->
    W = _cofactorMont _trim ms
    _slidingWindowPowMont (_liftMont xs, ms), (_trim ys), ms, t, W, _liftMont [1], ms


_powmod = do (_mod, _msb, _simplePowMont, _shl, _simplePowmod, _slidingWindowPowmod, _trim) ->
  (xs, ys, ms) ->
    t = _msb ys

    if t == -1
      [1]

    else if t <= _powmod.SimplePowmodBitLimit
      # improves Firefox for base > 1024b, exp 0x10001
      #W = _cofactorMont _trim ms
      #_simplePowMont (_liftMont xs, ms), (_trim ys), ms, W, _liftMont [1], ms
      _simplePowmod xs, ys, ms

    else if t <= _powmod.SlidingWindowPowmodBitLimit
      _slidingWindowPowmod xs, ys, ms, t

    else
      _montgomeryPowmod xs, ys, ms, t

# See compare/modular-exponentiation.html
_powmod.SimplePowmodBitLimit = 17

# See compare/modular-exponentiation.html

_powmod.SlidingWindowPowmodBitLimit = (
  Chrome:   1
  Firefox:  512
  Opera:    256
  Safari:   1)[Browser.name] or 512


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
  _cofactorMontB:           _cofactorMontB
  _div:                     _div
  _divmod:                  _divmod
  __divmod:                 __divmod
  _empty:                   _empty
  _eq:                      _eq
  _estimateWindowSizeMap:   _estimateWindowSizeMap
  _estimateWindowSizeTransitions: _estimateWindowSizeTransitions
  install:                  install
  _kmul:                    _kmul
  _ksq:                     _ksq
  _liftMont:                _liftMont
  _lt:                      _lt
  _mod:                     _mod
  _montgomeryPowmod:        _montgomeryPowmod
  _msb:                     _msb
  _mul:                     _mul
  _mulmod:                  _mulmod
  _mulMont:                 _mulMont
  _negateMod:               _negateMod
  _pack:                    _pack
  _parseHex:                _parseHex
  _pow:                     _pow
  _powmod:                  _powmod
  _random:                  _random
  _reduceMont:              _reduceMont
  _shl:                     _shl
  _shr:                     _shr
  _simplePowmod:            _simplePowmod
  _simplePowMont:           _simplePowMont
  _simpleSqmod:             _simpleSqmod
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
  _width:                   __width__
  _windowSize:              _windowSize
  _zeros:                   _zeros
exports.Functions__width__ = Functions
## %% Begin Remove for Specialize %%
exports.Functions = Functions
## %% End Remove for Specialize %%
  