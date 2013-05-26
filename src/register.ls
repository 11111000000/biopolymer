#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->

  # imports
  # api
  register = (inElement, inPrototype) ->

    return  if inElement is window
    throw "First argument to Polymer.register must be an HTMLElement"  if not inElement or (inElement not instanceof HTMLElement)

    prototype = mixin {}, Polymer.base, inPrototype

    prototype.elementElement = inElement

    Polymer.addResolvePath prototype, inElement

    prototype.installTemplate = ->
      @super!
      staticInstallTemplate.call this, inElement

    prototype.readyCallback = readyCallback

    Polymer.parseHostEvents inElement.attributes, prototype
    Polymer.publishAttributes inElement, prototype
    Polymer.installSheets inElement
    Polymer.shimStyling inElement

    inElement.register prototype: prototype

    logFlags.comps and console.log("Polymer: element registered" + inElement.options.name)

  readyCallback = ->
    @installTemplate!
    instanceReady.call this

  staticInstallTemplate = (inElement) ->
    template = inElement.querySelector \template
    if template
      root = @webkitCreateShadowRoot!

      root.applyAuthorStyles = @applyAuthorStyles

      CustomElements.watchShadow this

      root.host = this

      root.appendChild template.createInstance!

      PointerGestures.register root
      PointerEventsPolyfill.setTouchAction root, @getAttribute \touch-action
      rootCreated.call this, root
      root

  rootCreated = (inRoot) ->
    CustomElements.takeRecords!
    Polymer.bindModel.call this, inRoot
    Polymer.marshalNodeReferences.call this, inRoot
    rootEvents = Polymer.accumulateEvents inRoot
    Polymer.bindAccumulatedLocalEvents.call this, inRoot, rootEvents

  instanceReady = (inElement) ->
    Polymer.observeProperties.call this
    Polymer.takeAttributes.call this
    hostEvents = Polymer.accumulateHostEvents.call this
    Polymer.bindAccumulatedHostEvents.call this, hostEvents
    @ready! if @ready

  findDistributedTarget = (inTarget, inNodes) ->
    n = inTarget
    while n and n isnt this
      i = Array::indexOf.call inNodes, n
      return i if i >= 0
      n = n.parentNode

  log = window.logFlags or {}

  # exports
  window.Polymer =
    register: register
    findDistributedTarget: findDistributedTarget
    instanceReady: instanceReady

)!
