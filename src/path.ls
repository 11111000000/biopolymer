# 
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->

  addResolvePath = (inPrototype, inElement) ->
    root = inElement |> calcElementPath
    inPrototype.resolvePath = (inPath) ->
      root + inPath

  urlToPath = ->
    if inUrl
      parts = it.split \/
      parts.pop!
      parts.push ''
      parts.join \/
    else
      ""
  calcElementPath = -> it.ownerDocument |> HTMLImports.getDocumentUrl |> urlToPath

  Polymer.addResolvePath = addResolvePath

)!

