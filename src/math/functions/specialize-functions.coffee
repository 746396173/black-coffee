fs = require 'fs'

pow = Math.pow

digitSize = process.argv[2]

lines = (String fs.readFileSync 'functions-' + digitSize + '.coffee').split '\n'

widths = switch digitSize
  when 'small'  then [14, 15]
  when 'medium' then [26, 28, 29]
  when 'large'  then [30]

for width in widths
  base = 1 << width
  half_widthA = width >> 1
  half_baseA  = 1 << half_widthA
  half_widthB = width - half_widthA
  half_baseB  = 1 << half_widthB

  codex =
    width:      String width
    base:       '0x' + base.toString 16
    base2:      '0x' + (pow base, 2).toString 16
    mask:       '0x' + (base - 1).toString 16
    half_widthA: String half_widthA
    half_baseA:  '0x' + half_baseA.toString 16
    half_maskA:  '0x' + (half_baseA - 1).toString 16
    half_widthB: String half_widthB
    half_baseB:  '0x' + half_baseB.toString 16
    half_maskB:  '0x' + (half_baseB - 1).toString 16

  parity_adjust_expr = if width & 1 then ' << 1' else ''

  skipRE   = /%% Begin Remove for Specialize %%/
  unskipRE = /%% End Remove for Specialize %%/

  parityRE = /\s*<<\s*\__parity__/g
  targetRE = /__(width|base|base2|mask|half_widthA|half_baseA|half_maskA|half_widthB|half_baseB|half_maskB)__/g
  result = []
  skip = false
  for x in lines
    if      x.match skipRE   then skip = true
    else if x.match unskipRE then skip = false
    else if not skip
      x = x.replace parityRE, parity_adjust_expr
      result.push x.replace targetRE, (match, keyword) -> codex[keyword]

  fs.writeFileSync 'functions-' + width + '-bit.coffee', result.join '\n'