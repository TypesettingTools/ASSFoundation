return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, YUtils)
    local CommentSection = createASSClass("Section.Comment", ASS.Section.Text, {"value"}, {"string"})
    return CommentSection
end