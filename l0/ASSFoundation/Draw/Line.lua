return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, Yutils)
    local DrawLine = createASSClass("Draw.Line", ASS.Draw.CommandBase, {"x", "y"}, {ASS.Number, ASS.Number},
                                    {name="l", ords=2}, {ASS.Point, ASS.Draw.Move, ASS.Draw.MoveNc})
    function DrawLine:ScaleToLength(len,noUpdate)
        assert(Yutils, yutilsMissingMsg)
        if not (self.length and self.cursor and noUpdate) then self.parent:getLength() end
        self:sub(self.cursor)
        self:set(self.cursor:copy():add(Yutils.math.stretch(self.x.value, self.y.value, 0, len)))
        return self
    end

    function DrawLine:getAngle(ref, vectAngle, noUpdate)
        if not ref then
            if not (self.cursor and noUpdate) then self.parent:getLength() end
            ref = self.cursor
        end
        return ASS.Point.getAngle(self, ref, vectAngle)
    end

    return DrawLine
end