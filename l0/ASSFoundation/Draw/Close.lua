return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, Yutils)
    local DrawClose = createASSClass("Draw.Close", ASS.Draw.CommandBase, {}, {}, {name="c", ords=0})

    function DrawClose:getPoints()
        return {}
    end

    return DrawClose
end