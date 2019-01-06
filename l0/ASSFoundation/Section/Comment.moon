return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  CommentSection = createASSClass "Section.Comment", ASS.Section.Text, {"value"}, {"string"}
  return CommentSection
