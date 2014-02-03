request     = require('request')
cheerio     = require('cheerio')
crypto      = require('crypto')
cache       = require('memory-cache')
parseString = require('xml2js').parseString

class Turbik
  signin: (credentials, callback) ->
    options =
      url: 'https://turbik.tv/Signin'
      jar: request.jar()
      method: 'post'
      form: credentials
      headers:
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

    request options, (err, response, body) =>
      cookie = options.jar.getCookieString('http://turbik.tv')
      callback(!!cookie, cookie)

  getCookieJar: (session) ->
    jar = request.jar()
    jar.setCookie(session, 'http://turbik.tv')
    jar

  markAsWatched: (session, episodeId, callback) ->
    options =
      url: 'https://turbik.tv/services/epwatch'
      jar: @getCookieJar(session)
      method: 'post'
      form:
        watch: 1
        eid: episodeId
      headers:
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

    request options, (err, response, body) ->
      callback()


  fetchMyShows: (session, callback) ->
    if shows = cache.get("myShows#{session}")
      callback(shows)
    else
      options =
        url: 'https://turbik.tv/My/Series'
        jar: @getCookieJar(session)
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

      request options, (err, response, body) ->
        $ = cheerio.load(body)
        shows = []
        $('.myseriesbox').each ->
          episodes = []
          $('.myseriesblock, .myseriesblockc', @).each ->
            episodes.push
              img: 'https:' + $('img', @).attr('src')
              title: $('.myseriesbten', @).text()
              subtitle: $('.myseriesbbs', @).map( -> $(@).text() ).toArray().join(', ')
              url: $(@).closest('a').attr('href')

          shows.push
            id: $(@).attr('id')
            title: $('.myseriesent', @).text()
            episodes: episodes

        cache.put("myShows#{session}", shows, 60000)
        callback?(shows)

  fetchAllShows: (session, callback) ->
    if shows = cache.get("allShows#{session}")
      callback(shows)
    else
      options =
        url: 'https://turbik.tv/Series'
        jar: @getCookieJar(session)
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

      request options, (err, response, body) ->
        $ = cheerio.load(body)
        shows = []
        $('.serieslistbox').each ->
          shows.push
            img: 'https:' + $('img', @).attr('src').replace('s.jpg', 'ts.jpg')
            url: $(@).closest('a').attr('href')
            title: $('.serieslistboxen', @).text()
            description: $('.serieslistboxdesc', @).text()
            genre: $('.serieslistboxpersr .serieslistboxperstext', @).last().text()[6..]
            episodeCount: $($('.serieslistboxpersl .serieslistboxperstext', @)[1]).text()

        cache.put("allShows#{session}", shows, 600000)
        callback(shows)


  meta_decoder: (param1) ->
    param1 = unescape(param1)
    enc_replace = (param1, param2) ->
      loc_4 = []
      loc_5 = []
      loc_6 = ['2','I','0','=','3','Q','8','V','7','X','G','M','R','U','H','4','1','Z','5','D','N','6','L','9','B','W'];
      loc_7 = ['x','u','Y','o','k','n','g','r','m','T','w','f','d','c','e','s','i','l','y','t','p','b','z','a','J','v'];
      if (param2 == 'e')
        loc_4 = loc_6
        loc_5 = loc_7
      if (param2 == 'd')
        loc_4 = loc_7
        loc_5 = loc_6
      loc_8 = 0
      while (loc_8 < loc_4.length)
        param1 = param1.replace(new RegExp(loc_4[loc_8], 'g'), '___')
        param1 = param1.replace(new RegExp(loc_5[loc_8], 'g'), loc_4[loc_8])
        param1 = param1.replace(/___/g, loc_5[loc_8])
        loc_8 += 1
      return param1

    param1 = param1.replace('%2b', '+')
    param1 = param1.replace('%3d', '=')
    param1 = param1.replace('%2f', '/')
    param1 = enc_replace(param1, 'd')
    new Buffer(param1, 'base64').toString()

  fetchShowSeasons: (session, showUrl, callback) ->
    if info = cache.get('showInfo' + showUrl + session)
      callback(info)
    else
      options =
        url: showUrl
        jar: @getCookieJar(session)
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'
      request options, (err, response, body) =>
        $ = cheerio.load(body)
        info =
          seasons: $('.seasonnum a').map( -> {url: $(@).closest('a').attr('href'), name: $(@).text() }).toArray().reverse()
          img: 'https:' + $('.topimgseries img').attr('src')
          title: $('.sseriestitleten').text()
          description: $('#desccnt').text()

        cache.put('showInfo' + showUrl + session, info, 60000)
        callback(info)

  fetchSeasonInfo: (session, seasonUrl, callback) ->
    if info = cache.get('seasonInfo' + seasonUrl + session)
      callback(info)
    else
      options =
        url: seasonUrl
        jar: @getCookieJar(session)
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'
      request options, (err, response, body) =>
        $ = cheerio.load(body)
        info =
          img: 'https:' + $('.topimgseries img').attr('src')
          title: $('.sseriestitleten').text()
          seasonTitle: $('.seasonnumactive').text()
          description: $('#desccnt').text()
          episodes: []

        $('.sserieslistone').each ->
          info.episodes.push
            thumb: 'https:' + $('img', @).attr('src')
            name: $('.sserieslistonetxten', @).text()
            season: $('.sserieslistonetxtse', @).text()
            episode: $('.sserieslistonetxtep', @).text()
            url: $(@).closest('a').attr('href')

        info.episodes.reverse()

        cache.put('seasonInfo' + seasonUrl + session, info, 60000)
        callback(info)



  getSubtitles: (url, callback) ->
    if subtitles = cache.get('subs' + url)
      callback(subtitles)
    else
      options =
        url: url
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

      request options, (err, response, body) =>
        $ = cheerio.load(body, xmlMode: true)
        result = []
        $('subtitle').each ->
          result.push
            from: parseFloat($('start', @).text().replace(',', '.'))
            to: parseFloat($('end', @).text().replace(',', '.'))
            text: $('text', @).text().replace(/[\r\n]+/g, ' ')

        callback(result)




  getEpisodeInfo: (params, episodeUrl, callback) ->
    cacheKey = episodeUrl + JSON.stringify(params)

    if info = cache.get(cacheKey)
      callback(info)
    else
      options =
        url: episodeUrl
        jar: @getCookieJar(params.session)
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36'

      request options, (err, response, body) =>
        $ = cheerio.load(body)

        metadata = cheerio.load(@meta_decoder($('#metadata').val()), xmlMode: true)
        cookie = options.jar.getCookieString('http://turbik.tv')[7..]

        quality = if params['settings[videoQuality]'] == 'hq' && metadata('movie > hq').text() == '1' then 'hq' else 'default'

        if params['settings[videoLang]'] == 'en'
          videoLang = if metadata('langs en').text() == '1' then 'en' else 'ru'
        else
          videoLang = if metadata('langs ru').text() == '1' then 'ru' else 'en'

        if params['settings[subsLang]'] == 'en'
          subsLang = if metadata('subtitles > en').text() == '1' then 'en' else 'ru'
        else if params['settings[subsLang]'] == 'ru'
          subsLang = if metadata('subtitles > ru').text() == '1' then 'ru' else 'en'
        else
          subsLang = 'none'

        episode_id  = metadata('eid').text()
        source_hash = metadata("sources2 #{quality}").text()
        position = 0

        hash = crypto.createHash('sha1')
        hash.update(cookie + Math.random())
        b = hash.digest('hex')

        hash = crypto.createHash('sha1')
        hash.update(b + episode_id + "A2DC51DE0F8BC1E9")
        a = hash.digest('hex')

        hash = crypto.createHash('sha1')
        hash.update(videoLang)
        lang_hash = hash.digest('hex')

        url = "http://cdn.turbik.tv/#{lang_hash}/#{episode_id}/#{source_hash}/#{position}/#{cookie}/#{b}/#{a}"

        currentEpisode = $('.epbox > span').closest('.epbox')
        nextEpisode = currentEpisode.next('.epbox')
        if nextEpisode.length == 0
          li = currentEpisode.closest('li')
          li = li.next('li')
          if li.length > 0
            nextEpisode = li.find('.epbox').first()
          else
            nextEpisode = null

        if nextEpisode
          nextEpisodeUrl = nextEpisode.find('a').attr('href')
        else
          nextEpisodeUrl = null

        info =
          id: episode_id
          stream_url: url
          next_episode_url: nextEpisodeUrl

        if subsLang == 'none'
          cache.put(cacheKey, info, 60000)
          callback(info)
        else
          subtitlesUrl = 'https:' + metadata("subtitles sources #{subsLang}").text()
          @getSubtitles subtitlesUrl, (subtitles) ->
            info.subtitles = JSON.stringify(subtitles)
            cache.put(cacheKey, info, 60000)
            callback(info)


# <?xml version="1.0" encoding="utf-16"?>
# <movie>
#   <sources2>
#     <default>8cccd9bc58abed038e43e0f5a6de87ce</default>
#     <hq>ae6dbc211c89e75638df4b0887eb5dc7</hq>
#   </sources2>
#   <aspect>169</aspect>
#   <duration>1298</duration>
#   <hq>1</hq>
#   <eid>14415</eid>
#   <screen>//img.turbik.tv/2BrokeGirls/e1fd2fa58efc1c32e2578d581a89dfa9b.jpg</screen>
#   <sizes>
#     <default>109924377</default>
#     <hq>352243679</hq>
#   </sizes>
#   <langs>
#     <en>1</en>
#     <ru>1</ru>
#   </langs>
#   <subtitles>
#     <en>1</en>
#     <ru>1</ru>
#     <sources>
#       <en>//sub.turbik.tv/en/e1fd2fa58efc1c32e2578d581a89dfa9</en>
#       <ru>//sub.turbik.tv/ru/e1fd2fa58efc1c32e2578d581a89dfa9</ru>
#     </sources>
#   </subtitles>
# </movie>


# <?xml version="1.0" encoding="utf-16"?>
# <movie>
#   <sources2>
#     <default>5a95bb06e9f564330a1a5e7fde793cec</default>
#     <hq>87c9e51f31d034276f052c64e772c564</hq>
#   </sources2>
#   <aspect>43</aspect>
#   <duration>1304</duration>
#   <hq>0</hq>
#   <eid>810</eid>
#   <screen>//img.turbik.tv/Scrubs/4c1e40c69859cb80e8c31d02e0699686b.jpg</screen>
#   <sizes>
#     <default>98209239</default>
#     <hq>0</hq>
#   </sizes>
#   <langs>
#     <en>1</en>
#     <ru>1</ru>
#   </langs>
#   <subtitles>
#     <en>0</en>
#     <ru>0</ru>
#     <sources />
#   </subtitles>
# </movie>
module.exports =  new Turbik()