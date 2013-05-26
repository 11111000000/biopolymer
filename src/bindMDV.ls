# 
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->
  registerBinding = (element, name, path) ->
    b$ = bindings.get element
    bindings.set element, b$ = {} unless b$
    b$[name.toLowerCase!] = path

  unregisterBinding = (element, name) ->
    b$ = bindings.get(element)
    delete b$[name.toLowerCase!] if b$

  overrideBinding = ->
    originalBind = it::bind
    originalUnbind = it::unbind

    it::bind = (name, model, path) ->
      originalBind.apply this, arguments
      registerBinding this, name, path

    it::unbind = (name) ->
      originalUnbind.apply this, arguments
      unregisterBinding this, name

  getBindings = (element) ->
    element and bindings.get(element) or emptyBindings

  getBinding = (element, name) ->
    getBindings(element)[name.toLowerCase!]

  bindModel = (inRoot) ->
    log.bind and console.group("[%s] bindModel", @localName)
    HTMLTemplateElement.bindAllMustachesFrom_ inRoot, this
    log.bind and console.groupEnd!

  bind = (name, model, path) ->
    property = Polymer.propertyForAttribute.call(this, name)

    if property
      registerBinding this, property, path
      Polymer.bindProperties this, property, model, path
    else
      HTMLElement::bind.apply this, arguments

  unbind = (name) ->
    property = Polymer.propertyForAttribute.call this, name

    if property
      unregisterBinding this, name
      Object.defineProperty this, name,
        value: this[name]
        enumerable: yes
        writable: yes
        configurable: yes

    else
      HTMLElement::unbind.apply this, arguments

  log = window.logFlags or {}

  bindings = new SideTable!

  [Node, Element, Text, HTMLInputElement].forEach overrideBinding

  emptyBindings = {}
  mustachePattern = /\{\{([^{}]*)}}/

  # exports

  Polymer.bind = bind
  Polymer.unbind = unbind
  Polymer.getBinding = getBinding
  Polymer.bindModel = bindModel
  Polymer.bindPattern = mustachePattern
)!
