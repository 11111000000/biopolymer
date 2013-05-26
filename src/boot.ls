#
# * Copyright 2012 The Polymer Authors. All rights reserved.
# * Use of this source code is governed by a BSD-style
# * license that can be found in the LICENSE file.
# 
(->

  document.write "<!-- begin Polymer injections -->\n"
  document.write "<!-- injected meta tags for mobile -->\n"

  document.write "<meta name=\"apple-mobile-web-app-capable\" content=\"yes\">\n"
  document.write "<meta name=\"viewport\" content=\"initial-scale=1.0, maximum-scale=1.0, user-scalable=no\">\n"

  document.write "<!-- injected FOUC prevention -->\n"
  document.write "<style>body {opacity: 0;}</style>"

  document.write "<!-- end Polymer injections -->\n"

  window.addEventListener "WebComponentsReady", ->
    document.body.style.webkitTransition = "opacity 0.3s"
    document.body.style.opacity = 1
)!

