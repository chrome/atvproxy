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
View  = require('views')


atv.player.willStartPlaying = ->
  atv.player.reachedEnd     = false
  atv.player.nextEpisodeUrl = atv.player.asset.getElementByTagName('nextEpisode').textContent
  atv.player.episodeId      = atv.player.asset.getElementByTagName('episodeId').textContent
  atv.player.episodeUrl     = atv.player.asset.getElementByTagName('episodeUrl').textContent
  atv.player.overlayView    = new View()

  unless atv.localStorage['settings']?['subsLang'] == 'none'
    subsText = atv.player.asset.getElementByTagName('subtitles').textContent
    atv.player.overlayView.setSubtitles(JSON.parse(subsText)) if subsText

atv.player.playerTimeDidChange = (time) ->
  time     = atv.player.convertGrossToNetTime(time)
  duration = atv.player.currentItem.duration
  timeLeft = Math.round(duration - time)

  atv.localStorage.setItem('savedPosition:' + atv.player.episodeUrl, Math.max(Math.round(time - 30), 0))

  unless atv.localStorage['settings']?['subsLang'] == 'none'
    atv.player.overlayView.updateSubtitles(time)

  if atv.player.nextEpisodeUrl && atv.localStorage['settings']?['autoview']
    if timeLeft > 165 && timeLeft < 180
      atv.player.overlayView.setText(utils.timeInWords(timeLeft) + ' до след. эпизода')
      atv.player.overlayView.showView()
    if timeLeft <= 165
      atv.player.overlayView.hideView()

  if time == duration
    atv.player.reachedEnd = true

  if time > (duration * 0.8) && !atv.localStorage.getItem('watched' + atv.player.episodeId)
    atv.localStorage.setItem('watched' + atv.player.episodeId, true)
    utils.Ajax.get(atv.config.ROOT_URL + '/page/watch', { episodeId: atv.player.episodeId })

atv.player.didStopPlaying = ->
  if atv.player.reachedEnd && atv.player.nextEpisodeUrl && atv.localStorage['settings']?['autoview']
    utils.loadPage(atv.config.ROOT_URL + '/page/video', {episodeUrl: atv.player.nextEpisodeUrl})


atv.onAuthenticate = (login, password, callback) ->
  if (!login || !password)
    callback.failure("Введите логин и пароль")
    return

  utils.Ajax.post atv.config.ROOT_URL + '/signin', {login, password}, (result) ->
    if result
      atv.localStorage.setItem('session', result)
      callback.success()
    else
      callback.failure()


atv.onAppEntry = ->
  defaultSettings =
    videoQuality: 'hq'
    videoLang: 'ru'
    subsLang: 'none'
    autoview: true

  unless atv.localStorage['settings']
    atv.localStorage.setItem 'settings', defaultSettings


  if atv.localStorage["session"]
    utils.loadPage(atv.config.ROOT_URL + '/page/static/nav')
  else
    utils.loadPage(atv.config.ROOT_URL + '/page/static/login')

