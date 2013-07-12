  
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

    
