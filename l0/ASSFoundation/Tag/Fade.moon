return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  {:list, :math, :string, :table, :unicode, :util, :re} = Functional

  Fade = createASSClass "Tag.Fade", ASS.Tag.Base,
    {"startDuration", "endDuration", "startTime", "endTime", "startAlpha", "midAlpha", "endAlpha"},
    {ASS.Duration, ASS.Duration, ASS.Time, ASS.Time, ASS.Hex, ASS.Hex, ASS.Hex}

  msgs = {
    getTagParams: {
      badFadeTimes: "fade times must evaluate to t1<=t2<=t3<=t4, got %d<=%d<=%d<=%d."
    }
  }

  Fade.new = (args) =>
    @readProps args
    if args.raw and @__tag.name == "fade"
      a, r, num = {}, args.raw, tonumber
      a[1], a[2], a[3], a[4] = num(r[5])-num(r[4]), num(r[7])-num(r[6]), r[4], r[7]
      -- avoid having alpha values automatically parsed as hex strings
      a[5], a[6], a[7] = num(r[1]), num(r[2]), num(r[3])
      args.raw = a
    startDuration, endDuration, startTime, endTime, startAlpha, midAlpha, endAlpha = unpack @getArgs args,
      {0, 0, 0, 0, 255, 0, 255}, true

    @startDuration = ASS.Duration {startDuration}
    @endDuration = ASS.Duration {endDuration}
    @startTime = ASS.Time {startTime}
    @endTime = ASS.Time {endTime}
    @startAlpha = ASS.Hex {startAlpha}
    @midAlpha = ASS.Hex {midAlpha}
    @endAlpha = ASS.Hex {endAlpha}

    if @__tag.simple == nil
      @__tag.simple = @setSimple args.simple

    return @

  Fade.getTagParams = =>
    if @__tag.simple 
      return @startDuration\getTagParams!, @endDuration\getTagParams!

    t1, t4 = @startTime\getTagParams!, @endTime\getTagParams!
    startDuration, endDuration = @startDuration\getTagParams!, @endDuration\getTagParams!
    t2 = t1 + startDuration
    t3 = t4 - endDuration
    @checkPositive startDuration, endDuration
    logger\assert t1 <= t2 and t2 <= t3 and t3 <= t4, msgs.getTagParams.badFadeTimes, t1, t2, t3, t4

    return @startAlpha\getTagParams! @midAlpha\getTagParams!, @endAlpha\getTagParams!, math.min(t1, t2), util.clamp(t2,t1,t3), util.clamp(t3, t2, t4), math.max(t4, t3)

  Fade.setSimple = (state) =>
    if state == nil
      state = @startTime\equal(0) and @endTime\equal(0) and @startAlpha\equal(255) and @midAlpha\equal(0) and @endAlpha\equal 255

    @__tag.simple, @__tag.name = state, state and "fade_simple" or "fade"
    return state

  return Fade
