#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->
  observeProperties = ->
    for p of this
      observeProperty.call this, p

  observeProperty = (inName) ->
    if isObservable.call(this, inName)

      log.observe and console.log("[" + @localName + "] watching [" + inName + "]")

      observer = new PathObserver this, inName, ((inNew, inOld) ->
        log.data and console.log("[%s#%s] watch: [%s] now [%s] was [%s]", @localName, @node.id or "", inName, this[inName], inOld)
        propertyChanged.call this, inName, inOld
      ).bind this

  isObservable = (inName) ->
    (inName[0] isnt "_") and (inName not of Object::) and Boolean(this[inName + OBSERVE_SUFFIX])

  propertyChanged = (inName, inOldValue) ->
    fn = inName + OBSERVE_SUFFIX
    this[fn] inOldValue  if this[fn]

  log = window.logFlags or {}
  OBSERVE_SUFFIX = \Changed

  Polymer.observeProperties = observeProperties
)!
