# Derived from http://www.quirksmode.org/js/detect.html.
# 
browserAssay = [
    name: 'Chrome'
    datum: navigator.userAgent
    pattern: 'Chrome'
    versionPattern: 'Chrome/(\\d+\\.?\\d*)'
  ,
    name: 'OmniWeb'
    datum: navigator.userAgent
    pattern: 'OmniWeb'
    versionPattern: 'OmniWeb/(\\d+\\.?\\d*)'
  ,
    name: 'Safari'
    datum: navigator.userAgent
    pattern: 'Apple'
    versionPattern: 'Version/(\\d+\\.?\\d*)'
  ,
    name: 'Opera'
    datum: navigator.userAgent
    pattern: 'Opera'
    versionPattern: 'Version/(\\d+\\.?\\d*)'
  ,
    name: 'iCab'
    datum: navigator.vendor
    pattern: 'iCab'
    versionPattern: 'iCab/(\\d+\\.?\\d*)'
  ,
    name: 'Konqueror'
    datum: navigator.vendor
    pattern: 'KDE'
    versionPattern: 'Konqueror/(\\d+\\.?\\d*)'
  ,
    name: 'Firefox'
    datum: navigator.userAgent
    pattern: 'Firefox'
    versionPattern: 'Firefox/(\\d+\\.?\\d*)'
  ,
    name: 'Camino'
    datum: navigator.vendor
    pattern: 'Camino'
    versionPattern: 'Camino/(\\d+\\.?\\d*)'
  ,
    # for newer Netscapes (6*)
    name: 'Netscape'
    datum: navigator.userAgent
    pattern: 'Netscape'
    versionPattern: 'Netscape/(\\d+\\.?\\d*)'
  ,
    name: 'Explorer'
    datum: navigator.userAgent
    pattern: 'MSIE'
    versionPattern: 'MSIE/(\\d+\\.?\\d*)'
  ,     
    name: 'Mozilla'
    datum: navigator.userAgent
    pattern: 'Gecko'
    versionPattern: 'rv/(\\d+\\.?\\d*)'
  ,
    #for older Netscapes (4-)
    name: 'Netscape'
    datum: navigator.userAgent
    pattern: 'Mozilla'
    versionPattern: 'Mozilla/(\\d+\\.?\\d*)'
]

specifier = do () ->
  for trial in browserAssay
    if (String trial.datum).match trial.pattern
      return trial

  name: 'unknown'
  datum: ''
  pattern: ''
  version: 'unknown'
  os: 'unknown'

if specifier.versionPattern
  m = (String specifier.datum).match specifier.versionPattern
  if m?
    specifier.version = parseFloat m[1]

OSAssay = [
    name: 'Windows'
    datum: navigator.platform
    pattern: 'Win'
  ,
    name: 'OS/X'
    datum: navigator.platform
    pattern: 'Mac'
  ,
    name: 'iPhone/iPod'
    datum: navigator.userAgent
    pattern: 'iPhone'
  ,
    name: 'Linux'
    datum: navigator.platform
    pattern: 'Linux'
]

do () ->
  for trial in OSAssay
    if trial.datum.match trial.pattern
      specifier.os = trial.name

window.Browser =
  name:      specifier.name
  version:   specifier.version
  os:        specifier.os
  specifier: specifier
  