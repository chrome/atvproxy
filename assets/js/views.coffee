do ->
  class View
    constructor: ->
      try
        @views = []

        @viewContainer = new atv.View()

        screenFrame = atv.device.screenFrame

        @viewContainer.frame =
          x: screenFrame.x
          y: screenFrame.y
          width:  screenFrame.width
          height: screenFrame.height

        @viewContainer.backgroundColor =
          red:   0.0
          blue:  0.0
          green: 0.0
          alpha: 0.0

        @viewContainer.alpha = 1

        @views.push @nextEpisodeMarkView()
        @views = @views.concat(@subtitleView())

        @viewContainer.subviews = @views

        atv.player.overlay = @viewContainer
      catch e
        utils.log 'Error: ' + e.message + e.name


    nextEpisodeMarkView: ->
      @_nextEpisodeMarkView ?= do =>
        messageView = new atv.TextView()
        topPadding        = 50
        horizontalPadding = 50 #@viewContainer.frame.width  * 0.05
        messageView.frame =
          x: horizontalPadding
          y: 0
          width:  @viewContainer.frame.width - (2 * horizontalPadding)
          height: @viewContainer.frame.height - topPadding

        messageView.__visible = false
        messageView


    container: -> @viewContainer

    setText: (text) ->
      @nextEpisodeMarkView().attributedString =
        string: text
        attributes:
          pointSize: 36.0
          color:
            red:   1
            blue:  1
            green: 1

    showView: ->
      return if @nextEpisodeMarkView().__visible
      animation =
        type:      "BasicAnimation"
        keyPath:   "opacity"
        fromValue: 0
        toValue:   1
        duration:  0.5
        removedOnCompletion: false
        fillMode:  "forwards"

      @nextEpisodeMarkView().__visible = true
      @nextEpisodeMarkView().addAnimation(animation, 'a')


    hideView: ->
      return unless @nextEpisodeMarkView().__visible
      animation =
        type:      "BasicAnimation"
        keyPath:   "opacity"
        fromValue: 1
        toValue:   0
        duration:  0.5
        removedOnCompletion: false
        fillMode:  "forwards"

      @nextEpisodeMarkView().__visible = false
      @nextEpisodeMarkView().addAnimation(animation, 'a')


    setSubtitles: (@subtitles) ->

    subtitleView: ->
      @_subtitleViews ?= do =>
        views = []
        for i in [0..2]
          subView = new atv.TextView()
          subView.backgroundColor = { red: 0, blue: 0, green: 0, alpha: 0.0}
          subView.frame =
            x: 150
            y: i * 65 + 50
            width:  @viewContainer.frame.width - 300
            height: 65
          views.push subView
        views

    updateSubtitles: (time) ->
      text = ''
      while true
        unless @subtitles[0]
          break

        if time >= @subtitles[0].from && time < @subtitles[0].to
          # utils.log "Found"
          text = @subtitles[0].text
          break

        if time < @subtitles[0].from
          break

        if time > @subtitles[0].to
          @subtitles.shift()

      # utils.log "Time: #{time}, Line: #{JSON.stringify(@subtitles[0])}, Text: #{text}"

      @setSubtitleText(text)



    setSubtitleText: (text) ->
      words = text.split(/\ +/)
      lines = []
      l = 0

      if text.length < 40
        lines[0] = text
      else
        limit = Math.ceil(text.length / 2)
        for word in words
          l++ if lines[l]?.length > limit || lines[l]?.length + word.length > 80
          lines[l] = if lines[l]
            lines[l] + ' ' + word
          else
            word

      if lines.length < 3
        @setSubtitleLineText(0, lines[1] || '')
        @setSubtitleLineText(1, lines[0] || '')
        @setSubtitleLineText(2, '')
      else
        @setSubtitleLineText(0, lines[2] || '')
        @setSubtitleLineText(1, lines[1] || '')
        @setSubtitleLineText(2, lines[0] || '')

    setSubtitleLineText: (i, text) ->
      try
        lines = @subtitleView()
        lines[i].attributedString =
          string: text
          attributes:
            pointSize: 36.0
            weight: 'normal'
            alignment: 'center'
            color:
              red:   1
              blue:  1
              green: 1
      catch e
        utils.log 'Sub Error: '+ i + e.name + e.message + e.stack


