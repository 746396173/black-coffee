{ abs, ceil, floor, LN2, log, max, min, pow, random, round } = Math

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

MANTISSA = 52

class Long
  @initializeFunctions = (functions) ->
    @Functions = functions
    for name, fn of functions
      this[name] = this.prototype[name] = fn

  # This member is used to provide generic constructors in the functions below, so that the value
  # type will propagate through a computation.  This supports the use of Long member functions
  # generically with Residue subclasses.

  Long:       Long

  @random: (bits) -> new Long @_random bits

  constructor: (x) ->
    if x instanceof Long
      @digits = x.digits.slice()
      @sign = x.sign

    else if x instanceof Array
      @digits = x
      @sign = 1

    else if x instanceof String or typeof x is 'string'
      @digits = @_repr x
      @sign = 1

    else
      x = (Number x) or 0
      @digits = @_repr x.toString 16
      @sign = if x >= 0 then 1 else -1

  valueOf: () -> @sign * @_value @digits

  codex = '0123456789abcdefghijklmnopqrstuvwxyz'
  
  toString: (radix) ->
    radix or= 10
    if @msb() < 52
      @valueOf().toString radix
      
    else if radix is 16
      (if @sign is -1 then '-' else '') + @_hex @digits
      
    else if radix in [2, 4, 8]
      digits = Long._pack @digits, [0, 0, 1, 0, 2, 0, 0, 0, 3][radix], Long._radix
      digits = [0] if digits.length is 0
      (if @sign is -1 then '-' else '') + digits.reverse().join('')
      
    else
      if not (2 <= radix <= 36)
        throw new RangeError 'toString() radix argument must be between 2 and 36'
        
      digits = []
      [q, r] = @_divmod @digits, [radix]
      # use unsigned lt, since sign is handled
      while @_lt [0], q
        digits.push codex[r[0]]
        [q, r] = @_divmod q, [radix]
        
      digits.push codex[r[0]]
      (if @sign is -1 then '-' else '') + digits.reverse().join('')

  
  # the data type of Leemon Baird's BigInt.js
  @fromBigInt: (x) -> new Long Long._pack x, Long._radix, bpe
  toBigInt: () -> Long28._pack @digits, bpe

    
  # the data type of Tom Wu's jsbn.js
  @fromBigInteger: (x) -> new Long Long._pack x, Long._radix, x.DB
  toBigInteger: () ->
    x = nbi()
    digits = Long28._pack @digits, x.DB

    x[i] = d for d, i in digits
    x.s = 0
    x.t = digits.length
    x.clamp()
    x


  negate: () ->
    z = new @Long this
    z.sign = if (@_size z.digits) > 0 then -1 * z.sign else 1
    z


  abs: () ->
    z = new @Long this
    z.sign = 1
    z


  add: (y) ->
    x = this
    y = new @Long y if not (y instanceof Long)
    z = new @Long

    if x.sign < y.sign
      [x, y] = [y, x]

    if x.sign > y.sign
      if @_lt x.digits, y.digits
        z.digits = @_sub y.digits.slice(), x.digits
        z.sign = -1
      else
        z.digits = @_sub x.digits.slice(), y.digits
        z.sign = 1

    else
      z.digits = @_add x.digits.slice(), y.digits
      z.sign = x.sign

    z

  sub: (y) -> @add (new @Long y).negate()

  mul: (y) ->
    x = this
    y = new @Long y if not (y instanceof Long)
    z = new @Long

    z.digits = @_kmul x.digits, y.digits
    z.sign = if (@_size z.digits) is 0 then 1 else x.sign * y.sign

    z

  divmod: (y) ->
    x = this
    y = new @Long y if not (y instanceof Long)

    xs = x.digits
    ys = y.digits

    if (@_size ys) is 0
      [Infinity, new @Long]

    else
      [qs, rs] = @_divmod xs, ys
      # assert _eq xs, _add (_mul qs, ys), rs

      q = new @Long qs
      r = new @Long rs

      # Euclidean division convention:
      #   0 <= r < q
      #   sign q is @sign for positive y
      #   sign q is -@sign for negative y
      #

      q.sign = x.sign * y.sign

      if x.sign < 0 and (@_size rs) > 0
        r.digits = @_sub ys.slice(), rs
        @_add qs, [1]

      if (@_size q.digits) is 0 and q.sign is -1
        q.sign = 1

      # assert x.eq r.add y.mul q
      [q, r]

  div: (y) -> (@divmod y)[0]
  mod: (y) -> (@divmod y)[1]

  bit: (k) -> @_bit @digits, k
  bitset: (k, v) -> @_bitset @digits, k, v
  bitcount: () -> @_bitcount @digits

  msb: () -> @_msb @digits

  eq: (y) ->
    if y instanceof Array
      ys = y
      sign_y = 1
    else
      y = new @Long y if not (y instanceof @Long)
      ys = y.digits
      sign_y = y.sign

    @sign is sign_y and @_eq @digits, ys


  lt: (y) ->
    if y instanceof Array
      ys = y
      sign_y = 1
    else
      y = new @Long y if not (y instanceof @Long)
      ys = y.digits
      sign_y = y.sign

    if @sign < sign_y then true
    else if @sign > sign_y then false
    else if @sign is 1 then @_lt @digits, ys
    else @_lt ys, @digits

  gt: (y) -> (new @Long y if not (y instanceof @Long)).lt this

  gte: (y) -> not @lt y
  lte: (y) -> not @gt y

  extendedGcd: (y) ->
    a = new @Long 1
    b = new @Long 0
    c = new @Long 0
    d = new @Long 1

    g = new @Long 1

    u = new @Long 0
    v = new @Long 0

    x = this
    y = new @Long y if not (y instanceof @Long)

    if (x.eq [0]) or (y.eq [0]) then return [a, b, c, d, Infinity, u, v]

    while (x.bit 0) is 0 and (y.bit 0) is 0
      x = x.bshr 1
      y = y.bshr 1
      g = g.mul 2

    u = x
    v = y

    while true
      while (u.bit 0) is 0
        u = u.bshr 1
        if (a.bit 0) is 0 and (b.bit 0) is 0
          a = a.bshr 1
          b = b.bshr 1
        else
          a = (a.add y).bshr 1
          b = (b.sub x).bshr 1
        # assert u.eq (a.mul x).add b.mul y

      while (v.bit 0) is 0
        v = v.bshr 1
        if (c.bit 0) is 0 and (d.bit 0) is 0
          c = c.bshr 1
          d = d.bshr 1
        else
          c = (c.add y).bshr 1
          d = (d.sub x).bshr 1
        # assert v.eq (c.mul x).add d.mul y

      if u.gte v
        u = u.sub v
        a = a.sub c
        b = b.sub d
      else
        v = v.sub u
        c = c.sub a
        d = d.sub b

      if u.eq [0]
        return [a, b, c, d, g, u, v]


  invmod: (m) ->
    m = new @Long m if not (m instanceof @Long)

    if (m = m.abs()).lte [1]
      null
    else
      [a, b, c, d, g, u, v] = m.extendedGcd @abs()

      if g is Infinity or not (g.mul v).eq [1]
        null
      else
        d = d.add m if d.lt [0]
        d = m.sub d if @sign < 0
        d


  gcd: (y) ->
    y = new @Long y if not (y instanceof Long)
    [a, b, c, d, g, u, v] = @abs().extendedGcd y.abs()
    h = if g is Infinity then new @Long else g.mul v
    h


  sq: () ->
    new Long @_sq @digits


  sqmod: (m) ->
    m = new @Long m if not (m instanceof Long)
    
    new Long @_sqmod @digits, m.digits


  pow: (y) ->
    y = Number y
    y = 0 if y < 0

    z = new @Long @_pow @digits, y
    z.sign = if y & 1 then @sign else 1

    z

  mulmod: (y, m) ->
    y = new @Long y if not (y instanceof Long)
    m = new @Long m if not (m instanceof Long)

    zs = @_mulmod @digits, y.digits, m.digits
    if @sign * y.sign < 0 and @_size zs > 0
      zs = @_sub m.digits.slice(), zs

    new @Long zs

  powmod: (y, m) ->
    y = new @Long y if not (y instanceof Long)
    m = new @Long m if not (m instanceof Long)

    if m.eq [0]
      new @Long [1]
    else
      zs = @_powmod @digits, y.digits, m.digits
      if @sign < 0 && y.digits[0] & 1 and @_size zs > 0
        zs = @_sub m.digits.slice(), zs

      new @Long zs

  shl: (k) ->
    z = new @Long
    z.digits = @_shl @digits.slice(), k
    z.sign = @sign
    z

  shr: (k) ->
    z = new @Long
    z.digits = @_shr @digits.slice(), k
    z.sign = @sign
    z

  bshl: (k) ->
    z = new @Long
    z.digits = @_bshl @digits.slice(), k
    z.sign = @sign
    z

  bshr: (k) ->
    z = new @Long
    z.digits = @_bshr @digits.slice(), k
    z.sign = @sign
    z


class Long26 extends Long
  Long: Long26
    
class Long28 extends Long
  Long: Long28
  
class Long30 extends Long
  Long: Long30

if Browser.name is 'Chrome'
  Long.initializeFunctions Functions28
else
  Long.initializeFunctions Functions30
  
Long26.initializeFunctions Functions26
Long28.initializeFunctions Functions28
Long30.initializeFunctions Functions30

exports = exports or window

exports.Long = Long
exports.Long26 = Long26
exports.Long28 = Long28
exports.Long30 = Long30

