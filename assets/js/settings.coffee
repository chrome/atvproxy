settings = {}
settings.get = (key) ->
  options = atv.localStorage['settings'] || {}
  if key
    options[key]
  else
    options

settings.set = (key, value) ->
  utils.log 'Set: ' + key + ' = ' + value

  options = settings.get()
  options[key] = value
  atv.localStorage.setItem('settings', options)
  settings.apply()


toggleCheckmark = (id, toggle) ->
  item = document.getElementById(id)
  accessories = item.getElementByTagName('accessories')
  unless accessories
    accessories = document.makeElementNamed("accessories")
    item.appendChild(accessories)

  if toggle
    unless accessories.getElementByTagName('checkMark')
      checkmark = document.makeElementNamed("checkMark")
      accessories.appendChild(checkmark)
  else
    mark = accessories.getElementByTagName('checkMark')
    mark.removeFromParent() if mark


settings.apply = ->
  options = settings.get()
  if options.videoLang == 'ru'
    toggleCheckmark('videoLang_ru', true)
    toggleCheckmark('videoLang_en', false)

  if options.videoLang == 'en'
    toggleCheckmark('videoLang_en', true)
    toggleCheckmark('videoLang_ru', false)

  if options.subsLang == 'ru'
    toggleCheckmark('subsLang_ru', true)
    toggleCheckmark('subsLang_en', false)
    toggleCheckmark('subsLang_none', false)

  if options.subsLang == 'en'
    toggleCheckmark('subsLang_en', true)
    toggleCheckmark('subsLang_ru', false)
    toggleCheckmark('subsLang_none', false)

  if options.subsLang == 'none'
    toggleCheckmark('subsLang_en', false)
    toggleCheckmark('subsLang_ru', false)
    toggleCheckmark('subsLang_none', true)

  toggleCheckmark('autoview', !!settings.get('autoview'))

settings.signout = ->
  utils.log 'Logout!'
  atv.localStorage.removeItem('session')
  atv.logout()
  atv.loadURL(atv.config.ROOT_URL + '/page/static/login')


settings.apply()
