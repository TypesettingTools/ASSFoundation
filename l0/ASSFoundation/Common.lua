local DependencyControl = require("l0.DependencyControl")
local version = DependencyControl{
    name = "ASSFoundation Common Components",
    version = "0.2.0",
    description = "Collection of commonly used functions",
    author = "line0",
    moduleName = "l0.ASSFoundation.Common",
    url = "https://github.com/TypesettingCartel/ASSFoundation",
    feed = "https://raw.githubusercontent.com/TypesettingCartel/ASSFoundation/master/DependencyControl.json",
    {"aegisub.util", "aegisub.unicode", "a-mo.Log"},
}
local util, unicode, Log = version:requireModules()

function string:split(sep)
    local sep, fields = sep or "", {}
    self:gsub(string.format("([^%s]+)", sep), function(field)
        fields[#fields+1] = field
    end)
    return fields
end

table.reverseArray = function(tbl)
    local length, rTbl = #tbl, {}
    for i,val in ipairs(tbl) do
        rTbl[length-i+1] = val
    end
    return rTbl
end

-- TODO: move into functional
unicode.reverse = function(s)
    return table.concat(table.reverseArray(unicode.toCharTable(s)))
end

util.getScriptInfo = function(sub)
    local infoBlockFound, scriptInfo = false, {}
    for i=1,#sub do
        if sub[i].class=="info" then
            infoBlockFound = true
            scriptInfo[sub[i].key] = sub[i].value
        elseif infoBlockFound then break end
    end
    return scriptInfo
end

util.timecode2ms = function(tc)
    local split, num = {tc:match("^(%d):(%d%d):(%d%d)%.(%d%d)$")}, tonumber
    assert(#split==4, "invalid timecode")
    return ((num(split[1])*60 + num(split[2]))*60 + num(split[3]))*1000 + num(split[4])*10
end

util.ms2timecode = function(num)
    local ms = num%1000
    num = (num-ms)/1000
    local s = num % 60
    num = (num-s)/60
    local m = num % 60
    local h = (num-m)/60
    assert(h<=9, "value too large to create an ASS timecode")
    return string.format("%01d:%02d:%02d.%02d", h, m, s, ms/10)
end

return version:register({version=version})
