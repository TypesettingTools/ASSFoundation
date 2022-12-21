return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  {:list, :math, :string, :table, :unicode, :util, :re } = Functional

  msgs = {
    insertTagsAtChar: {
      badTags: "Argument #2 (tags) to insertTagsAtChar() must be a %s, a %s or a list of Tag objects, got a %s."
    }
  }

  TextSection = createASSClass "Section.Text", ASS.String, {"value"}, {"string"}, nil, nil, (tbl, key) ->
    if key == "len"
      return unicode.len tbl.value
    else return getmetatable(tbl)[key]

  TextSection.new = (value) =>
    @value = @getArgs({value},"",true)[1]
    @typeCheck {@value}
    return @

  TextSection.getString = =>
    @typeCheck {@value}
    return @value

  TextSection.getEffectiveTags = (includeDefault, includePrevious = true, copyTags = true) =>
    -- previous and default tag lists
    effTags = if includeDefault
      @parent\getDefaultTags nil, copyTags

    if includePrevious and @prevSection
      prevTagList = @prevSection\getEffectiveTags false, true, copyTags
      effTags = includeDefault and effTags\merge(prevTagList, false, false, true) or prevTagList

    return effTags or ASS.TagList nil, @parent

  TextSection.getStyleTable = (name) =>
    return @getEffectiveTags(false,true,false)\getStyleTable @parent.line.styleRef, name

  TextSection.getTextExtents = =>
    return aegisub.text_extents @getStyleTable!, @value

  TextSection.getTextMetrics = (calculateBounds, text = @value) =>
    logger\assert Yutils, yutilsMissingMsg
    fontObj, tagList = @getYutilsFont!
    extents = fontObj.text_extents text
    metrics = fontObj.metrics!

    -- make sure we convert uint64 (returned from ffi) to lua numbers here
    -- in order to not ruin everything
    metrics.width, metrics.height = tonumber(extents.width), tonumber(extents.height)

    local shape
    if calculateBounds
      shape = fontObj.text_to_shape text
      metrics.bounds = {Yutils.shape.bounding shape}
      metrics.bounds.w = (metrics.bounds[3] or 0) - (metrics.bounds[1] or 0)
      metrics.bounds.h = (metrics.bounds[4] or 0) - (metrics.bounds[2] or 0)

    return metrics, tagList, shape

  TextSection.getShape = (applyRotation = false, applyScale = false) =>
    tagList = @getEffectiveTags true, true, false
    fs = tagList.tags.fontsize\getTagParams!
    fscy = tagList.tags.scale_y\getTagParams!
    align = tagList.tags.align\getSet!

    -- Calculate the vertical offset for each line seperated by linebreak
    _, breakCount = @value\gsub "\\N", ""
    breakCount += 1
    verticalOffset = (fs * fscy) / 100
    offsetTable = [ (i-1)*verticalOffset for i = 1, breakCount ]

    shape, longestWidth, xAlignOffset,  metrics = "", 0, 0
    sec = Functional.string.split @value, "\\N"
    for i, text in ipairs sec
      metrics, _, tempShape = @getTextMetrics true, text
      drawing = ASS.Draw.DrawingBase{str: tempShape}

      local xOffset, yOffset
      -- Reconstruct the shape with proper vertical offset for each line
      if align.bottom
        yOffset = offsetTable[breakCount - i + 1] 
      elseif align.top
        yOffset = offsetTable[i] * (-1)
      else
        yOffset = (offsetTable[breakCount - i + 1] - offsetTable[i])/2

      -- Reconstruct the shape with proper horizontal offset for each line
      -- However, this constructed shape will be offseted by the width or half of width (depending on alignment) of the longest line
      -- So the whole shape will later have to be offseted by that amount
      if align.left
        xOffset = 0
        longestWidth = 0
      elseif align.right
        xOffset = metrics.width
        if xOffset > longestWidth
          longestWidth = xOffset
          xAlignOffset = metrics.bounds.w
      else
        xOffset = (metrics.width)/2
        if xOffset > longestWidth
          longestWidth = xOffset
          xAlignOffset = metrics.bounds.w/2
      drawing\sub xOffset, yOffset
      shape ..= "#{drawing\getTagParams!} "

    drawing = ASS.Draw.DrawingBase{str: shape}
    with metrics
      .bounds = { Yutils.shape.bounding shape}
      .bounds.h = (.bounds[4] or 0) - (.bounds[2] or 0)
      drawing\sub  (-1) * xAlignOffset, not align.top and (.height - .bounds.h) / (align.centerV and 2 or 1) or 0

    -- Scale the drawings based on fscx and fscy values
    if applyScale
      facX = 100/tagList.tags.scale_x\getTagParams!
      facY = 100/tagList.tags.scale_y\getTagParams!
      drawing\mul facX, facY

    -- rotate shape
    if applyRotation
      angle = tagList.tags.angle\getTagParams!
      drawing\rotate angle

    return drawing

  TextSection.convertToDrawing = =>
    shape = @getShape false, true
    @value, @contours, @scale = nil, shape.contours, shape.scale
    setmetatable @, ASS.Section.Drawing
    return @

  TextSection.expand = (x, y) =>
    @convertToDrawing!
    return @expand x, y

  TextSection.getYutilsFont = =>
    logger\assert Yutils, yutilsMissingMsg
    tagList = @getEffectiveTags true, true, false
    local font
    with tagList.tags
      font = Yutils.decode.create_font .fontname\getTagParams!,
        .bold\getTagParams! > 0, .italic\getTagParams! > 0, .underline\getTagParams! > 0,
        .strikeout\getTagParams! > 0, .fontsize\getTagParams!, .scale_x\getTagParams! / 100,
        .scale_y\getTagParams! / 100, .spacing\getTagParams!

    return font, tagList

  TextSection.splitAtChar = (index, mutate) =>
    index = unicode.len @value + index + 1 if index < 0
    right = ASS.Section.Text unicode.sub @value, index, -1

    leftText = unicode.sub @value, 1, index - 1
    left = if mutate
      @value = leftText
      @
    else ASS.Section.Text leftText

    return left, right

  TextSection.insertTagsAtChar = (index, tags) =>
    logger\error msgs.insertTagsAtChar.badTags, ASS.Section.Tag.typeName,
      ASS.TagList.typeName, type tags if "table" != type tags

    tags = if tags.class != ASS.Section.Tag
      ASS.Section.Tag tags

    -- insert a new tag section before index, split

  TextSection.trimLeft = =>
    @value = string.trimLeft @value

  TextSection.trimRight = =>
    @value = string.trimRight @value

  TextSection.trim = =>
    @value = string.trim @value

  return TextSection
