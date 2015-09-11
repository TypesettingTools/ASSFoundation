return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, Yutils)
    local TextSection = createASSClass("Section.Text", ASS.String, {"value"}, {"string"}, nil, nil, function(tbl, key)
        if key == "len" then
            return unicode.len(tbl.value)
        else return getmetatable(tbl)[key] end
    end)

    function TextSection:new(value)
        self.value = self:typeCheck(self:getArgs({value},"",true))
        return self
    end

    function TextSection:getString(coerce)
        if coerce then return tostring(self.value)
        else return self:typeCheck(self.value) end
    end

    function TextSection:getEffectiveTags(includeDefault, includePrevious, copyTags)
        includePrevious, copyTags = default(includePrevious, true), default(copyTags, true)
        -- previous and default tag lists
        local effTags
        if includeDefault then
            effTags = self.parent:getDefaultTags(nil, copyTags)
        end

        if includePrevious and self.prevSection then
            local prevTagList = self.prevSection:getEffectiveTags(false, true, copyTags)
            effTags = includeDefault and effTags:merge(prevTagList, false, false, true) or prevTagList
        end

        return effTags or ASS.TagList(nil, self.parent)
    end

    function TextSection:getStyleTable(name, coerce)
        return self:getEffectiveTags(false,true,false):getStyleTable(self.parent.line.styleRef, name, coerce)
    end

    function TextSection:getTextExtents(coerce)
        return aegisub.text_extents(self:getStyleTable(nil,coerce),self.value)
    end

    function TextSection:getTextMetrics(calculateBounds, coerce)
        assert(Yutils, yutilsMissingMsg)
        local fontObj, tagList, shape = self:getYutilsFont()
        extents, metrics = fontObj.text_extents(self.value), fontObj.metrics()
        -- make sure we convert uint64 (returned from ffi) to lua numbers here
        -- in order to not ruin everything
        metrics.width, metrics.height = tonumber(extents.width), tonumber(extents.height)

        if calculateBounds then
            shape = fontObj.text_to_shape(self.value)
            metrics.bounds = {Yutils.shape.bounding(shape)}
            metrics.bounds.w = (metrics.bounds[3] or 0)-(metrics.bounds[1] or 0)
            metrics.bounds.h = (metrics.bounds[4] or 0)-(metrics.bounds[2] or 0)
        end

        return metrics, tagList, shape
    end

    function TextSection:getShape(applyRotation, coerce)
        applyRotation = default(applyRotation, false)
        local metr, tagList, shape = self:getTextMetrics(true)
        local drawing, an = ASS.Draw.DrawingBase{str=shape}, tagList.tags.align:getSet()
        -- fix position based on aligment
        drawing:sub(not an.left and (metr.width-metr.bounds.width)   / (an.centerH and 2 or 1) or 0,
                    not an.top  and (metr.height-metr.bounds.height) / (an.centerV and 2 or 1) or 0
        )

        -- rotate shape
        if applyRotation then
            local angle = tagList.tags.angle:getTagParams(coerce)
            drawing:rotate(angle)
        end
        return drawing
    end

    function TextSection:convertToDrawing(applyRotation, coerce)
        local shape = self:getShape(applyRotation, coerce)
        self.value, self.contours, self.scale = nil, shape.contours, shape.scale
        setmetatable(self, ASS.Section.Drawing)
        return self
    end

    function TextSection:expand(x,y)
        self:convertToDrawing()
        return self:expand(x,y)
    end

    function TextSection:getYutilsFont(coerce)
        assert(Yutils, yutilsMissingMsg)
        local tagList = self:getEffectiveTags(true,true,false)
        local tags = tagList.tags
        return Yutils.decode.create_font(tags.fontname:getTagParams(coerce), tags.bold:getTagParams(coerce)>0,
                                         tags.italic:getTagParams(coerce)>0, tags.underline:getTagParams(coerce)>0, tags.strikeout:getTagParams(coerce)>0,
                                         tags.fontsize:getTagParams(coerce), tags.scale_x:getTagParams(coerce)/100, tags.scale_y:getTagParams(coerce)/100,
                                         tags.spacing:getTagParams(coerce)
        ), tagList
    end
    return TextSection
end