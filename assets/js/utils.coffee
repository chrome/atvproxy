atv.config =
  doesJavaScriptLoadRoot: true,
  DISPLAY_NAME: "Turbofilm",
  DEBUG_LEVEL: 4,
  ROOT_URL: "https://trailers.apple.com"


require = (module) ->
  xhr = new XMLHttpRequest()
  xhr.open("GET", atv.config.ROOT_URL + "/js/" + module, false)
  xhr.send()
  eval(xhr.responseText)

utils = require('helpers')

loadMenuPage = (event) ->
  id = event.navigationItemId
  utils.Ajax.get atv.config.ROOT_URL + '/page/' + id, {}, (page) ->
    event.success(page)