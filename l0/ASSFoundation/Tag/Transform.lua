return function(ASS, ASSFInst, yutilsMissingMsg, createASSClass, re, util, unicode, Common, LineCollection, Line, Log, SubInspector, YUtils)
    local Transform = createASSClass("Transform", ASS.Tag.Base, {"tags", "startTime", "endTime", "accel"},
                                     {ASS.Section.Tag, ASS.Time, ASS.Time, ASS.Number})

    function Transform:new(args)
        self:readProps(args)
        local signature = self.__tag.signature
        if args.raw then
            local r = {}
            if signature == "accel" then        -- \t(<accel>,<style modifiers>)
                r[1], r[4] = args.raw[1], args.raw[2]
            elseif signature == "default" then    -- \t(<t1>,<t2>,<accel>,<style modifiers>)
                r[1], r[2], r[3], r[4] = args.raw[4], args.raw[1], args.raw[2], args.raw[3]
            elseif signature == "time" then    -- \t(<t1>,<t2>,<style modifiers>)
                r[1], r[2], r[3] = args.raw[3], args.raw[1], args.raw[2]
            else r = args.raw end
            args.raw = r
        end
        tags, startTime, endTime, accel = self:getArgs(args,{"",0,0,1},true)

        self.tags, self.accel = ASS.Section.Tag(tags,args.transformableOnly), ASS.Number{accel, tagProps={positive=true}}
        self.startTime, self.endTime = ASS.Time{startTime}, ASS.Time{endTime}
        return self
    end

    function Transform:changeTagType(type_)
        if not type_ then
            local noTime = self.startTime:equal(0) and self.endTime:equal(0)
            self.__tag.signature = self.accel:equal(1) and (noTime and "simple" or "time") or noTime and "accel" or "default"
            self.__tag.typeLocked = false
        else
            assertEx(ASS.tagMap.transform.signatures[type], "invalid transform type '%s'.", tostring(type))
            self.__tag.signature, self.__tag.typeLocked = type_, true
        end
        return self.__tag.signature, self.__tag.typeLocked
    end

    function Transform:getTagParams(coerce)
        if not self.__tag.typeLocked then
            self:changeTagType()
        end

        local signature = self.__tag.signature
        local t1, t2 = self.startTime:getTagParams(coerce), self.endTime:getTagParams(coerce)

        if coerce then
            t2 = util.max(t1, t2)
        else assertEx(t1<=t2, "transform start time must not be greater than the end time, got %d <= %d.", t1, t2) end

        if signature == "simple" then
            return self.tags:getString(coerce)
        elseif signature == "accel" then                                         -- \t(<accel>,<style modifiers>)
            return self.accel:getTagParams(coerce), self.tags:getString(coerce)
        elseif signature == "time" then                                         -- \t(<t1>,<t2>,<style modifiers>)
            return t1, t2, self.tags:getString(coerce)
        elseif signature == "default" then                                         -- \t(<t1>,<t2>,<accel>,<style modifiers>)
            return t1, t2, self.accel:getTagParams(coerce), self.tags:getString(coerce)
        else error("Error: invalid transform type: " .. tostring(type)) end

    end
    return Transform
end