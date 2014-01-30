fs     = require('fs')
path   = require('path')
print  = require('util').print
mustache = require('mustache')

turbik = require('./turbik')


class TurbikProvider

  signin: (credentials, callback) ->
    options =
      login: credentials.login
      passwd: credentials.password
    turbik.signin options, callback

  renderPage: (params, page, callback) ->
    switch page
      when 'all_shows'
        turbik.fetchAllShows params.session, (shows) =>
          callback(@renderTemplate('all_shows', {shows}))

      when 'my_shows'
        turbik.fetchMyShows params.session, (shows) =>
          callback(@renderTemplate('my_shows', {shows}))

      when 'show'
        turbik.fetchShowSeasons params.session, 'https://turbik.tv' + params.showUrl, (info) =>
          callback(@renderTemplate('show', info))

      when 'season'
        turbik.fetchSeasonInfo params.session, 'https://turbik.tv' + params.seasonUrl, (info) =>
          callback(@renderTemplate('season', info))

      when 'video'
        turbik.getEpisodeInfo params, 'https://turbik.tv' + params.episodeUrl, (info) =>
          callback(@renderTemplate('video', info))

      when 'watch'
        turbik.markAsWatched params.session, params.episodeId, =>
          callback('ok')

      else
        callback '404'

  renderTemplate: (templateName, params = {}) ->
    template = fs.readFileSync("providers/turbik/templates/" + templateName + '.xml').toString()
    mustache.render(template, params)

module.exports = new TurbikProvider()