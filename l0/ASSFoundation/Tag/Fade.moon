return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  {:list, :math, :string, :table, :unicode, :util, :re} = Functional

  Fade = createASSClass "Tag.Fade", ASS.Tag.Base,
    {"inDuration", "outDuration", "inStartTime", "outStartTime", "inAlpha", "midAlpha", "outAlpha"},
    {ASS.Duration, ASS.Duration, ASS.Time, ASS.Time, ASS.Hex, ASS.Hex, ASS.Hex}

  Fade.new = (args) =>
    @readProps args
    if args.raw and @__tag.name == "fade" -- \fade(<a1>,<a2>,<a3>,<t1>,<t2>,<t3>,<t4>)
      a, r, num = {}, args.raw, tonumber
      a[1], a[2], a[3], a[4] = num(r[5])-num(r[4]), num(r[7])-num(r[6]), r[4], r[6]
      -- avoid having alpha values automatically parsed as hex strings
      a[5], a[6], a[7] = num(r[1]), num(r[2]), num(r[3])
      args.raw = a

    inDuration, outDuration, inStartTime, outStartTime, inAlpha, midAlpha, outAlpha = unpack @getArgs args,
      {0, 0, math.nan, math.nan, 255, 0, 255}, true

    @inDuration = ASS.Duration {inDuration}
    @outDuration = ASS.Duration {outDuration}
    @inStartTime = ASS.Time {inStartTime}
    @outStartTime = ASS.Time {outStartTime}
    @inAlpha = ASS.Hex {inAlpha}
    @midAlpha = ASS.Hex {midAlpha}
    @outAlpha = ASS.Hex {outAlpha}

    return @

  Fade.getTagParams = =>
    if @__tag.name == "fade_simple"
      return @inDuration\getTagParams!, @outDuration\getTagParams!

    t1, t3 = @inStartTime\getTagParams!, @outStartTime\getTagParams!
    inDuration, outDuration = @inDuration\getTagParams!, @outDuration\getTagParams!
    t2 = t1 + inDuration
    t4 = t3 + outDuration
    @checkPositive inDuration, outDuration
    return @inAlpha\getTagParams!, @midAlpha\getTagParams!, @outAlpha\getTagParams!, t1, math.max(t2, t1), t3, math.max(t4, t3)

  --- Interpolate the fade for any given time
  -- @param time time at which fade must be interpolated of
  -- @param lineDuration duration of the current line
  -- @param alpha alpha in the first tag block if it exists
  -- @return the interpolated alpha value
  Fade.interpolate = (time, lineDuration, alpha) =>
    local a1, a2, a3, t1, t2, t3 , t4, finalAlpha
    if @__tag.name == "fade_simple"
      a1, a2, a3, t1, t4  = 255, 0, 255, 0, lineDuration
      t2, t3 = @inDuration\getTagParams!, @outDuration\getTagParams!
      t3 = t4 - t3
    else
      a1, a2, a3, t1, t2, t3 , t4 = @getTagParams!

    a2 = alpha if alpha
    currAlpha = a3
    if time < t1
      currAlpha = a1
    elseif time < t2
      cf = (time - t1)/(t2 - t1)
      currAlpha = a1 * (1 - cf) + a2 * cf
    elseif time < t3
      currAlpha = a2
    elseif time < t4
      cf = (time - t3)/(t4 - t3)
      currAlpha = a2 * (1 - cf)+ a3 * cf
    return currAlpha

  -- TODO: add method to convert between fades by supplying a line duration

  return Fade
