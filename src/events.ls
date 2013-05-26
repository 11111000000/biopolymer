#
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->
  bindAccumulatedEvents = (inNode, inEvents, inListener) ->
    fn = inListener.bind(this)

    for n of inEvents
      log.events and console.log("[%s] bindAccumulatedEvents: addEventListener(\"%s\", listen)", inNode.localName or "root", n)
      inNode.addEventListener n, fn

  bindAccumulatedHostEvents = (inEvents) ->
    bindAccumulatedEvents.call this, this, inEvents, listenHost

  bindAccumulatedLocalEvents = (inNode, inEvents) ->
    bindAccumulatedEvents.call this, inNode, inEvents, listenLocal

  listenLocal = (inEvent) ->

    return  if inEvent.cancelBubble

    inEvent.on = prefix + inEvent.type
    log.events and console.group("[%s]: listenLocal [%s]", @localName, inEvent.on)
    t = inEvent.target

    while t and t isnt this
      c = findController t
      return if c and handleEvent.call c, t, inEvent
      t = t.parentNode

    log.events and console.groupEnd!

  listenHost = (inEvent) ->
    return if inEvent.cancelBubble

    log.events and console.group("[%s]: listenHost [%s]", @localName, inEvent.type)
    handleHostEvent.call this, this, inEvent
    log.events and console.groupEnd!

  getHandledListForEvent = (inEvent) ->
    handledList = eventHandledTable.get(inEvent)
    unless handledList
      handledList = []
      eventHandledTable.set inEvent, handledList
    handledList

  handleEvent = (inNode, inEvent) ->
    if inNode.attributes
      handledList = getHandledListForEvent(inEvent)
      if handledList.indexOf(inNode) < 0
        handledList.push inNode
        h = inNode.getAttribute(inEvent.on)
        if h
          log.events and console.log("[%s] found handler name [%s]", @localName, h)
          dispatch this, h, [inEvent, inEvent.detail, inNode]
    inEvent.cancelBubble

  handleHostEvent = (inNode, inEvent) ->
    h = findHostHandler.call(inNode, inEvent.type)
    if h
      log.events and console.log("[%s] found host handler name [%s]", inNode.localName, h)
      dispatch inNode, h, [inEvent, inEvent.detail, inNode]
    inEvent.cancelBubble

  log = window.logFlags or {}

  prefix = \on-

  parseHostEvents = (inAttributes, inPrototype) ->
    inPrototype.eventDelegates = parseEvents(inAttributes)

  parseEvents = (inAttributes) ->
    events = {}
    if inAttributes
      i = 0
      a = void

      while a = inAttributes[i]
        events[a.name.slice(prefix.length)] = a.value  if a.name.slice(0, prefix.length) is prefix
        i++
    events

  accumulateEvents = (inNode, inEvents) ->
    events = inEvents or {}
    accumulateNodeEvents inNode, events
    accumulateChildEvents inNode, events
    accumulateTemplatedEvents inNode, events
    events

  accumulateNodeEvents = (inNode, inEvents) ->
    a$ = inNode.attributes
    if a$
      i = 0
      a = void

      while (a = a$[i])
        accumulateEvent a.name.slice(prefix.length), inEvents  if a.name.slice(0, prefix.length) is prefix
        i++

  event_translations =
    webkitanimationstart: \webkitAnimationStart
    webkitanimationend: \webkitAnimationEnd
    webkittransitionend: \webkitTransitionEnd
    domfocusout: \DOMFocusOut
    domfocusin: \DOMFocusIn

  accumulateEvent = (inName, inEvents) ->
    n = event_translations[inName] or inName
    inEvents[n] = 1

  accumulateChildEvents = (inNode, inEvents) ->
    cn$ = inNode.childNodes
    i = 0

    while (child = cn$[i])
      accumulateEvents child, inEvents
      i++

  accumulateTemplatedEvents = (inNode, inEvents) ->
    if inNode.localName is \template
      content = getTemplateContent inNode
      accumulateChildEvents content, inEvents  if content

  getTemplateContent = (inTemplate) ->
    (if inTemplate.ref then inTemplate.ref.content else inTemplate.content)

  accumulateHostEvents = (inEvents) ->
    events = inEvents or {}
    p = @__proto__
    while p and p isnt HTMLElement::
      if p.hasOwnProperty("eventDelegates")
        for n of p.eventDelegates
          accumulateEvent n, events
      p = p.__proto__
    events

  findController = (inNode) ->
    n = inNode
    while n.parentNode and n.localName isnt \shadow-root
      n = n.parentNode
    n.host

  dispatch = (inNode, inHandlerName, inArguments) ->
    if inNode
      log.events and console.group "[%s] dispatch [%s]", inNode.localName, inHandlerName
      inNode.dispatch inHandlerName, inArguments
      log.events and console.groupEnd!

  eventHandledTable = new SideTable \handledList

  findHostHandler = (inEventName) ->
    p = this
    while p
      if p.hasOwnProperty \eventDelegates
        h = p.eventDelegates[inEventName] or p.eventDelegates[inEventName.toLowerCase!]
        return h  if h
      p = p.__proto__

  Polymer.parseHostEvents = parseHostEvents
  Polymer.accumulateEvents = accumulateEvents
  Polymer.accumulateHostEvents = accumulateHostEvents
  Polymer.bindAccumulatedHostEvents = bindAccumulatedHostEvents
  Polymer.bindAccumulatedLocalEvents = bindAccumulatedLocalEvents
)!
