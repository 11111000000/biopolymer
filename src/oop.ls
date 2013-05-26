#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->

  $class = (inExtends, inProperties) ->

    if arguments.length is 1
      inProperties = inExtends
      inExtends = null

    if not inProperties or not inProperties.hasOwnProperty("constructor")
      inProperties.constructor = ->
        @super!

    ctor = inProperties.constructor

    basePrototype = inExtends and inExtends:: or Object::

    ctor:: = extend(basePrototype, inProperties)

    ctor::super = $super  unless "super" of ctor::

    ctor

  extend = (inBasePrototype, inProperties) ->
    Object.create inBasePrototype, getPropertyDescriptors(inProperties)

  getPropertyDescriptors = (inObject) ->
    descriptors = {}
    for n of inObject
      descriptors[n] = getPropertyDescriptor(inObject, n)
    descriptors

  getPropertyDescriptor = (inObject, inName) ->
    inObject and Object.getOwnPropertyDescriptor(inObject, inName) or getPropertyDescriptor(Object.getPrototypeOf(inObject), inName)

  # TODO(sjmiles):
  #    $super must be installed on an instance or prototype chain
  #    as `super`, and invoked via `this`, e.g.
  #      `this.super!;`
  #
  #    will not work if function objects are not unique, for example,
  #    when using mixins.
  #    The memoization strategy assumes each function exists on only one 
  #    prototype chain i.e. we use the function object for memoizing)
  #    perhaps we can bookkeep on the prototype itself instead
  $super = (inArgs) ->

    caller = $super.caller

    nom = caller._nom

    unless nom
      nom = caller._nom = nameInThis.call(this, caller)
      unless nom
        console.warn "called super! on a method not in \"this\""
        return

    memoizeSuper caller, nom, Object.getPrototypeOf(this)  unless "_super" of caller

    _super = caller._super
    if _super
      fn = _super[nom]

      memoizeSuper fn, nom, _super  unless "_super" of fn

      fn.apply this, inArgs or []

  nextSuper = (inProto, inName, inCaller) ->
    proto = inProto
    while proto and (not proto.hasOwnProperty(inName) or proto[inName] is inCaller)
      proto = Object.getPrototypeOf proto
    proto

  memoizeSuper = (inMethod, inName, inProto) ->

    inMethod._super = nextSuper(inProto, inName, inMethod)
    inMethod._super[inName]._nom = inName  if inMethod._super

  nameInThis = (inValue) ->
    for n of this
      d = getPropertyDescriptor(this, n)
      return n  if d.value is inValue

  mixin = (inObj) -> #, inProps, inMoreProps, ...
    obj = inObj or {}
    i = 1

    while i < arguments.length
      p = arguments[i]

      # TODO(sjmiles): (IE): trap here instead of copyProperty so we can 
      # abort copying altogether when we hit a bad property 
      try
        for n of p
          copyProperty n, p, obj
      i++
    obj

  copyProperty = (inName, inSource, inTarget) ->
    Object.defineProperty inTarget, inName, getPropertyDescriptor(inSource, inName)

  window.$class = $class
  window.extend = extend
  window.$super = $super
)!

