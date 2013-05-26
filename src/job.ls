# 
# * Copyright 2013 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->
  job = (inJob, inCallback, inWait) ->
    job = inJob or new Job(this)
    job.stop!
    job.go inCallback, inWait
    job

  Job = (inContext) ->
    @context = inContext

  Job:: =
    go: (inCallback, inWait) ->
      @callback = inCallback
      @handle = setTimeout ( (->
        @handle = null
        inCallback.call @context ).bind this
      ), inWait

    stop: ->
      if @handle
        clearTimeout @handle
        @handle = null

    complete: ->
      if @handle
        @stop!
        @callback.call @context

  Polymer.job = job

)!

