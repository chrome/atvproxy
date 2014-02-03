do ->
  if atv.Document
    atv.Document.prototype.getElementById = (id) ->
      elements = @evaluateXPath("//*[@id='#{id}']", @)
      if elements && elements.length > 0
        return elements[0]
      return undefined

  if atv.Element
    atv.Element.prototype.getElementsByTagName = (tagName) ->
      @ownerDocument.evaluateXPath("descendant::" + tagName, @)

    atv.Element.prototype.getElementByTagName = (tagName) ->
      elements = @getElementsByTagName(tagName)
      if elements && elements.length > 0
        return elements[0]
      return undefined


  serialize = (obj, prefix) ->
    str = []
    for p, v of obj
      k = if prefix then prefix + "[" + p + "]" else p
      if typeof v == "object"
        str.push(serialize(v, k))
      else
        str.push(encodeURIComponent(k) + "=" + encodeURIComponent(v))
    str.join("&")

  log = (msg) ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', atv.config.ROOT_URL + '/log?message=' + encodeURIComponent(msg), true)
    xhr.send()

  Helpers =

    log: log

    russianPlural: (count, one, few, many = few) ->
      count10  = count % 10
      count100 = count % 100
      if count == 0
        many
      else if count10 == 1 && count100 != 11
        one
      else if count10 >= 2 && count10 <= 4 && (count100 < 10 || count100 >= 20)
        few
      else
        many

    timeInWords: (time) ->
      seconds = Math.round(time)
      minutes = Math.floor(seconds / 60)
      hours = Math.floor(minutes / 60)
      seconds = seconds - (minutes * 60)
      minutes = minutes - (hours * 60)
      words = []
      words.push hours   + @russianPlural(hours,   ' час',     ' часа',    ' часов')  if hours > 0
      words.push minutes + @russianPlural(minutes, ' минута',  ' минуты',  ' минут')  if minutes > 0
      words.push seconds + @russianPlural(seconds, ' секунда', ' секунды', ' секунд') if seconds > 0
      words.join(' ')

    Ajax:
      get: (url, params, callback) ->
        if atv.localStorage['session'] && !params['session']
          params['session'] = atv.localStorage['session']

        xhr = new XMLHttpRequest()
        xhr.open 'GET', url + '?' + serialize(params), true
        xhr.onreadystatechange = =>
          try
            if xhr.readyState == 4
              if xhr.responseXML
                result = xhr.responseXML
              else
                result = xhr.responseText
              callback(result)
          catch e
            log 'Ajax Error: ' + e.name + e.message
            xhr.abort()
        xhr.send()

      post: (url, params, callback) ->
        if atv.localStorage['session'] && !params['session']
          params['session'] = atv.localStorage['session']

        xhr = new XMLHttpRequest()
        xhr.open 'POST', url, true
        xhr.setRequestHeader(
          'Content-Type'
          'application/x-www-form-urlencoded'
        )
        xhr.onreadystatechange = =>
          try
            if xhr.readyState == 4
              result = xhr.responseText
              callback?(result)
          catch e
            log 'Ajax Error: ' + e.name + e.message
            xhr.abort()
        xhr.send(serialize(params))

    loadPage: (url, params = {}) ->
      params.session  = atv.localStorage['session']
      params.settings = atv.localStorage['settings']
      url = url + '?' + serialize(params)
      atv.loadURL(url)

    reloadPage: (url, params = {}) ->
      params.session  = atv.localStorage['session']
      params.settings = atv.localStorage['settings']
      @Ajax.get url, params, (xml) ->
        atv.loadAndSwapXML(xml)


  Helpers

