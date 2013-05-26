#
# * Copyright 2012 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 

window |> (scope) ->

  forEach = Array::forEach.call.bind(Array::forEach)
  concat = Array::concat.call.bind(Array::concat)
  slice = Array::slice.call.bind(Array::slice)

  stylizer =
    hostRuleRe: /@host[^{]*{(([^}]*?{[^{]*?}[\s\S]*?)+)}/g

    selectorRe: /([^{]*)({[\s\S]*?})/g

    hostFixableRe: /^[.\[:]/

    cssCommentRe: /\/\*[^*]*\*+([^/*][^*]*\*+)*\//g

    cssPolyfillCommentRe: /\/\*\s*@polyfill ([^*]*\*+([^/*][^*]*\*+)*\/)([^{]*?){/g

    selectorReSuffix: "([>\\s~+[.,{:][\\s\\S]*)?$"

    hostRe: /@host/g

    cache: {}

    shimStyling: (element) ->
      if window.ShadowDOMPolyfill and element
        name = element.options.name
        stylizer.cacheDefinition element
        stylizer.shimPolyfillDirectives element.styles, name
        stylizer.applyShimming stylizer.stylesForElement(element), name

    shimShadowDOMStyling: (styles, name) ->
      if window.ShadowDOMPolyfill
        stylizer.shimPolyfillDirectives styles, name
        stylizer.applyShimming styles, name

    applyShimming: (styles, name) ->
      @shimAtHost styles, name
      @shimScoping styles, name

    #TODO(sorvell): use SideTable
    cacheDefinition: (element) ->
      name = element.options.name
      template = element.querySelector \template
      content = template and (template |> templateContent)
      styles = content and (\style |> content.querySelectorAll)
      element.styles = if styles then slice(styles) else []
      element.templateContent = content
      stylizer.cache[name] = element

    stylesForElement: (element) ->
      styles = element.styles
      shadow = element.templateContent and element.templateContent.querySelector \shadow

      if shadow or (element.templateContent is null)
        extendee = @findExtendee element.options.name

        if extendee
          extendeeStyles = @stylesForElement(extendee)
          styles = concat (extendeeStyles |> slice), (styles |> slice)

      styles

    findExtendee: (name) ->
      element = @cache[name]
      element and @cache[element.options.extends]

    shimPolyfillDirectives: (styles, name) ->
      if window.ShadowDOMPolyfill
        if styles
          forEach styles, ((s) ->
            s.textContent = @convertPolyfillDirectives(s.textContent, name)
          ), this

    shimAtHost: (styles, name) ->
      if styles
        cssText = @convertAtHostStyles styles, name
        @addCssToDocument cssText

    shimScoping: (styles, name) ->
      @applyPseudoScoping styles, name  if styles

    convertPolyfillDirectives: (cssText, name) ->
      r = ""
      l = 0
      matches = void
      while matches = @cssPolyfillCommentRe.exec cssText
        r += cssText.substring(l, matches.index)
        # remove end comment delimiter (*/)
        r += matches[1].slice(0, -2) + "{"
        l = @cssPolyfillCommentRe.lastIndex
      r += cssText.substring(l, cssText.length)
      r

    findAtHostRules: (cssRules, matcher) ->
      Array::filter.call cssRules, @isHostRule.bind(this, matcher)

    isHostRule: (matcher, cssRule) ->
      (cssRule.selectorText and cssRule.selectorText.match(matcher)) or (cssRule.cssRules and @findAtHostRules(cssRule.cssRules, matcher).length) or (cssRule.type is CSSRule.WEBKIT_KEYFRAMES_RULE)

    convertAtHostStyles: (styles, name) ->
      cssText = @stylesToCssText(styles)
      r = ""
      l = 0
      matches = void
      while matches = @hostRuleRe.exec cssText
        r += cssText.substring l, matches.index
        r += @scopeHostCss matches[1], name
        l = @hostRuleRe.lastIndex
      r += cssText.substring l, cssText.length
      selectorRe = new RegExp "^#{name}#{@selectorReSuffix}", \m
      cssText = ( @findAtHostRules ( r |> @cssToRules ), selectorRe ) |> @rulesToCss
      cssText

    scopeHostCss: (cssText, name) ->
      r = ''
      matches = void
      while matches = @selectorRe.exec cssText
        r += "#{(@scopeHostSelector matches[1], name)} #{matches[2]}\n\t"
      r

    scopeHostSelector: (selector, name) ->
      r = []
      parts = selector.split(",")
      parts.forEach ((p) ->
        p = p.trim!

        if p.indexOf("*") >= 0
          p = p.replace("*", name)
        else p = name + p  if p.match(@hostFixableRe)

        r.push p

      ), this
      r.join ", "

    applyPseudoScoping: (styles, name) ->
      forEach styles, (s) ->
        s.parentNode.removeChild s  if s.parentNode

      # TODO(sorvell): remove @host rules (use cssom rather than regex?)
      cssText = @stylesToCssText(styles).replace(@hostRuleRe, "")
      rules = @cssToRules(cssText)
      cssText = @pseudoScopeRules(rules, name)
      @addCssToDocument cssText

    pseudoScopeRules: (cssRules, name) ->
      cssText = ""
      forEach cssRules, ((rule) ->
        if rule.selectorText and (rule.style and rule.style.cssText)
          cssText += @pseudoScopeSelector(rule.selectorText, name) + " {\n\t"
          cssText += rule.style.cssText + "\n}\n\n"
        else if rule.media
          cssText += "@media " + rule.media.mediaText + " {\n"
          cssText += @pseudoScopeRules(rule.cssRules, name)
          cssText += "\n}\n\n"
        else cssText += rule.cssText + \\n\n if rule.cssText
      ), this
      cssText

    pseudoScopeSelector: (selector, name) ->
      r = []
      parts = selector.split \,
      parts.forEach (p) ->
        r.push name + " " + p.trim!

      r.join ", "

    stylesToCssText: (styles, preserveComments) ->
      cssText = ""
      forEach styles, (s) ->
        cssText += s.textContent + \\n\n

      cssText = @stripCssComments(cssText)  unless preserveComments
      cssText

    stripCssComments: (cssText) ->
      cssText.replace @cssCommentRe, ""

    cssToRules: (cssText) ->
      style = document.createElement \style
      style.textContent = cssText
      document.head.appendChild style
      rules = style.sheet.cssRules
      style.parentNode.removeChild style
      rules

    rulesToCss: (cssRules) ->
      i = 0
      css = []

      while i < cssRules.length
        css.push cssRules[i].cssText
        i++
      css.join "\n\n"

    addCssToDocument: (cssText) ->
      @getSheet!.appendChild document.createTextNode(cssText)  if cssText

    getSheet: ->
      @sheet = document.createElement("style")  unless @sheet
      @sheet

    apply: ->
      @addCssToDocument "style { display: none !important; }\n"
      # TODO(sorvell): change back to insertBefore when ShadowDOM polyfill
      # supports this.
      document.head.appendChild @getSheet!

  document.addEventListener \WebComponentsReady, ->
    stylizer.apply!

  # exports
  Polymer.shimStyling = stylizer.shimStyling
  Polymer.shimShadowDOMStyling = stylizer.shimShadowDOMStyling
  Polymer.shimPolyfillDirectives = stylizer.shimPolyfillDirectives.bind stylizer
