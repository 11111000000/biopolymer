# 
# Copyright 2013 The Polymer Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.
#

( ->

  bindPattern = Polymer.bindPattern

  published$ = \__published
  attributes$ = \attributes
  attrProps$ = \publish
  #var attrProps$ = \attributeDefaults

  publishAttributes = (inElement, inPrototype) ->

    published = {}

    if attributes = inElement.getAttribute(attributes$)

      names = attributes.split((if (attributes.indexOf \,) >= 0 then \, else " "))
      names.forEach -> published[p] = null if it.trim!

    inherited = inElement.options::

    Object.keys(published).forEach (p) ->
      inPrototype[p] = published[p] if (p not of inPrototype) and (p not of inherited)

    imperative = inPrototype[attrProps$]

    if imperative
      Object.keys(imperative).forEach (p) ->
        inPrototype[p] = imperative[p]
      published = mixin(published, imperative)

    inPrototype[published$] = mixin({}, inherited[published$], published)

  takeAttributes = ->
    forEach @attributes, (->
      name = propertyForAttribute.call(this, it.name)
      if name
        return if it.value.search(bindPattern) >= 0
        defaultValue = this[name]
        value = deserializeValue(it.value, defaultValue)
        this[name] = value if value isnt defaultValue
    ), this

  propertyForAttribute = (name) ->
    properties = Object.keys this[published$]
    properties[properties.map(lowerCase).indexOf name.toLowerCase!]

  deserializeValue = (value, defaultValue) ->
    inferredType = typeof defaultValue
    inferredType = \date if defaultValue instanceof Date

    switch inferredType
      | "string" => return value
      | "date" => return new Date(Date.parse(value) or Date.now!)
      | "boolean" => return true  if value is ""

    switch value
      | "true" => return true
      | "false" => return false

    float = parseFloat value

    (if (String(float) is value) then float else value)

  lowerCase = String::toLowerCase.call.bind String::toLowerCase

  #
  # exports
  #

  Polymer.takeAttributes = takeAttributes
  Polymer.publishAttributes = publishAttributes
  Polymer.propertyForAttribute = propertyForAttribute

)!

