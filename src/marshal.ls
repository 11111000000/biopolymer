#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 

Polymer.marshalNodeReferences = (inRoot) ->

  $ = @$ = @$ or {}

  if inRoot
    nodes = inRoot.querySelectorAll '[id]'

    forEach nodes, -> $[it.id] = it


