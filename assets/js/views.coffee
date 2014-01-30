do ->
  class View
    constructor: ->
      @visible = false

      @viewContainer = new atv.View()
      @message       = new atv.TextView()

      screenFrame = atv.device.screenFrame
      width       = screenFrame.width
      height      = screenFrame.height * 0.1

      @viewContainer.frame =
        x: screenFrame.x
        y: screenFrame.y + screenFrame.height - height
        width:  width
        height: height

      @viewContainer.backgroundColor =
        red:   0.0
        blue:  0.0
        green: 0.0
        alpha: 0.0

      @viewContainer.alpha = 1

      topPadding        = @viewContainer.frame.height * 0.35
      horizontalPadding = @viewContainer.frame.width  * 0.05

      @message.frame =
        x: horizontalPadding
        y: 0
        width:  @viewContainer.frame.width - (2 * horizontalPadding)
        height: @viewContainer.frame.height - topPadding

      @viewContainer.subviews = [@message]

    container: -> @viewContainer

    setText: (text) ->
      @message.attributedString =
        string: text
        attributes:
          pointSize: 36.0
          color:
            red:   1
            blue:  1
            green: 1

    showView: ->
      return if @visible
      animation =
        type:      "BasicAnimation"
        keyPath:   "opacity"
        fromValue: 0
        toValue:   1
        duration:  0.5
        removedOnCompletion: false
        fillMode:  "forwards"

      @viewContainer.addAnimation(animation, 'a')
      @visible = true


    hideView: ->
      return unless @visible
      animation =
        type:      "BasicAnimation"
        keyPath:   "opacity"
        fromValue: 1
        toValue:   0
        duration:  0.5
        removedOnCompletion: false
        fillMode:  "forwards"

      @viewContainer.addAnimation(animation, 'a')
      @visible = false

