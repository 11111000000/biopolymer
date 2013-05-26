window.Polymer |> (scope)->

  log = window.logFlags or {}

  base =

    super: $super

    isPolymerElement: yes

    bind: -> Polymer.bind.apply this, arguments_

    unbind: -> Polymer.unbind.apply this, arguments_

    job: -> Polymer.job.apply this, arguments_

    asyncMethod: (inMethod, inArgs, inTimeout) ->

      args = (if (inArgs and inArgs.length) then inArgs else [inArgs])

      window.setTimeout (->
        (this[inMethod] or inMethod).apply this, args
      ).bind(this), inTimeout or 0

    dispatch: (inMethodName, inArguments)->
      this[inMethodName].apply this, inArguments if this[inMethodName]

    fire: (inType, inDetail, inToNode)->
      node = inToNode or this

      log.events and console.log("[%s]: sending [%s]", node.localName, inType)

      node.dispatchEvent new CustomEvent inType, { bubbles: on detail: inDetail }
      inDetail

    asend: -> @asyncMethod \send, arguments_

    classFollows: (anew, old, className) ->
      old.classList.remove className if old
      anew.classList.add className if anew

  base.send = base.fire

  #exports

  scope.base = base
