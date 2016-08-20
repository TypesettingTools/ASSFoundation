return (ASS, ASSFInst, yutilsMissingMsg, createASSClass, Functional, LineCollection, Line, logger, SubInspector, Yutils) ->
  {:list, :math, :string, :table, :unicode, :util, :re } = Functional

  class Sections
    tagMatchPattern = re.compile "\\\\[^\\\\\\(]+(?:\\([^\\)]+\\)[^\\\\]*)?|[^\\\\]+"

    @getTagOrCommentSection = (rawTags) =>
      tagSection = ASS.Section.Tag!
      return tagSection if #rawTags == 0
      tags, t = tagSection.tags, 1

      for match in tagMatchPattern\gfind rawTags
        tag, _, last = ASS\getTagFromString match
        tags[t], tag.parent = tag, tagSection
        t += 1

        -- comments inside tag sections are read into ASS.Tag.Unknowns
        if last < #match
          afterStr = match\sub last + 1
          tags[t] = ASS\createTag afterStr\sub(1,1)=="\\" and "unknown" or "junk", afterStr
          tags[t].parent = tagSection
          t += 1

      -- no tags found means we have a comment section
      return #tags > 0 and tagSection or ASS.Section.Comment tags