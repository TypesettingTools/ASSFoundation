return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  Move = createASSClass "Tag.Move", ASS.Tag.Base, {"startPos", "endPos", "startTime", "endTime"}, {ASS.Point, ASS.Point, ASS.Time, ASS.Time}

  msgs = {
    new: {
      endsBeforeStart: "argument #4 (endTime) to %s may not be smaller than argument #3 (startTime), got %d>=%d."
    }
    getTagParams: {
      endsBeforeStart: "move times must evaluate to t1 <= t2, got %d<=%d."
    }
  }

  Move.new = (args) =>
    startX, startY, endX, endY, startTime, endTime = unpack @getArgs args, 0, true

    logger\assert startTime <= endTime, msgs.new.endsBeforeStart, @typeName, endTime, startTime

    @readProps args
    @startPos = ASS.Point {startX, startY}
    @endPos = ASS.Point {endX, endY}
    @startTime = ASS.Time {startTime}
    @endTime = ASS.Time {endTime}

    return @


  Move.getSignature = =>
    @__tag.signature = if @startTime\equal(0) and @endTime\equal(0) -- TODO: remove legacy property
      "simple"
    else "default"
    return @__tag.signature


  Move.getTagParams = =>
    startX, startY = @startPos\getTagParams!
    endX, endY = @endPos\getTagParams!

    if @__tag.signature == "simple"
      return startX, startY, endX, endY

    t1, t2 = @startTime\getTagParams!, @endTime\getTagParams!
    logger\assert t1 <= t2, msgs.getTagParams, t1, t2
    return startX, startY, endX, endY, math.min(t1, t2), math.max(t2, t1)

  return Move
