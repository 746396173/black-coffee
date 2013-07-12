do (global, require, window) ->
  if window?
    exports = window.Function__width__
    if not Platform?
      throw 'platform.js must be included before functions-__width__-bit.js'
      
  else
    Platform = require './platform'
    exports = module.exports

  # Mainly used to add a set of specialized functions to a Long subclass, creating a Long
  # specialized to a specific digit bit width.  Also convenient for debugging in the web console.
  # 
  install = (obj) ->
    obj or= (if window? then window else global)
    for name, x of Functions when name isnt 'install'
      obj[name] = x
    null

  exports.install = install

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
  __parity__ = __width__ & 1

  __half_widthA__ = __width__ >>> 1
  __half_baseA__  = 1 << __half_widthA__
  __half_maskA__  = __half_baseA__ - 1
  __half_widthB__ = __width__ - __half_widthA__
  __half_baseB__  = 1 << __half_widthB__
  __half_maskB__  = __half_baseB__ - 1

  ## %% End Remove for Specialize %%

  ## This file will be concatenated with several other files in sequence; the next is base.coffee.
