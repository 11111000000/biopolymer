#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->
  installSheets = (inElementElement) ->
    inElementElement |> installLocalSheets
    inElementElement |> installGlobalStyles

  installLocalSheets = (inElementElement) ->
    sheets = inElementElement.querySelectorAll "[rel=stylesheet]"
    template = inElementElement.querySelector \template
    content = (templateContent template) if template

    if content
      forEach sheets, (sheet) ->
        unless sheet.hasAttribute SCOPE_ATTR
          sheet.parentNode.removeChild sheet
          style = createStyleElementFromSheet sheet
          if style
            content.insertBefore style, content.firstChild

  installGlobalStyles = (inElementElement) ->
    styles = inElementElement.globalStyles or (inElementElement.globalStyles = findStyles(inElementElement, "global"))
    applyStylesToScope styles, doc.head

  # TODO(sorvell): remove when spec issues are addressed
  installControllerStyles = (inElement, inElementElement) ->
    styles = inElementElement.controllerStyles or (inElementElement.controllerStyles = findStyles(inElementElement, "controller"))
    async.queue ->
      scope = findStyleController(inElement)
      if scope
        Polymer.shimPolyfillDirectives styles, inElement.localName
        applyStylesToScope styles, scope

  findStyleController = (inNode) ->
    n = inNode
    while n.parentNode and n.localName isnt \shadow-root
      n = n.parentNode

    if n is doc then doc.head else n

  createStyleElementFromSheet = (inSheet) ->
    if inSheet.__resource
      style = doc.createElement("style")
      style.textContent = inSheet.__resource
      style
    else
      console.warn "Could not find content for stylesheet", inSheet

  applyStylesToScope = (inStyles, inScope) ->
    inStyles.forEach (style) ->
      inScope.appendChild style.cloneNode(true)

  matchesSelector = (inNode, inSelector) ->
    matches.call inNode, inSelector  if matches

  # TODO(sorvell): it would be better to identify blocks of rules within
  # style declarations than require different style/link elements.
  findStyles = (inElementElement, inDescriptor) ->
    styleList = []
    sheets = inElementElement.querySelectorAll("[rel=stylesheet]")
    selector = "[" + SCOPE_ATTR + "=" + inDescriptor + "]"
    Array::forEach.call sheets, (sheet) ->
      if matchesSelector(sheet, selector)
        sheet.parentNode.removeChild sheet
        styleList.push createStyleElementFromSheet(sheet)

    styles = inElementElement.querySelectorAll("style")
    Array::forEach.call styles, (style) ->
      if matchesSelector(style, selector)
        style.parentNode.removeChild style
        styleList.push style

    styleList

  log = window.logFlags or {}

  doc = (if window.ShadowDOMPolyfill then ShadowDOMPolyfill.wrap(document) else document)

  async =
    list: []
    queue: (inFn) ->
      async.list.push inFn  if inFn
      async.queueFlush!

    queueFlush: ->
      unless async.flushing
        async.flushing = true
        requestAnimationFrame async.flush

    flush: ->
      async.list.forEach (fn) ->
        fn!

      async.list = []
      async.flushing = false

  eltProto = HTMLElement::
  matches = eltProto.matches or eltProto.matchesSelector or eltProto.webkitMatchesSelector or eltProto.mozMatchesSelector
  SCOPE_ATTR = \polymer-scope
  forEach = Array::forEach.call.bind Array::forEach

  # exports
  Polymer.installSheets = installSheets
  Polymer.installControllerStyles = installControllerStyles
)!

