#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->

  bindProperties = (inA, inProperty, inB, inPath) ->

    log.bind and console.log("[%s]: bindProperties: [%s] to [%s].[%s]", inB.localName or "object", inPath, inA.localName, inProperty)

    v = PathObserver.getValueAtPath inB, inPath
    if not v? or v is void
      PathObserver.setValueAtPath inB, inPath, inA[inProperty]

    Object.defineProperty inA, inProperty,

      get: -> PathObserver.getValueAtPath inB, inPath

      set: -> PathObserver.setValueAtPath inB, inPath, it

      configurable: yes

      enumerable: yes

  log = window.logFlags or {}

  #exports

  Polymer.bindProperties = bindProperties

)!

