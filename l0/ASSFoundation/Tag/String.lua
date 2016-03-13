return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, Yutils)
    local String = createASSClass("Tag.String", {ASS.Tag.Base, ASS.String}, {"value"}, {"string"})
    String.add, String.mul, String.div, String.pow, String.mod = String.append, nil, nil, nil, nil

    function String:getTagParams()
        self:typeCheck{self.value}
        return self.value
    end

    return String
end