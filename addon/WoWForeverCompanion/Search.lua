local addonName, ns = ...

ns.Search = ns.Search or {}
local Search = ns.Search

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function tokenize(query)
    local tokens = {}
    query = lower(trim(query or ""))
    for token in string.gmatch(query, "%S+") do
        tokens[#tokens + 1] = token
    end
    return tokens
end

local function scoreEntry(entry, tokens)
    local title = lower(entry.title)
    local subtitle = lower(entry.subtitle)
    local keywords = lower(entry.keywords)
    local kind = lower(entry.type)
    local haystack = table.concat({ title, subtitle, keywords, kind }, " ")
    local score = 0

    for i = 1, #tokens do
        local token = tokens[i]
        local found = string.find(haystack, token, 1, true)
        if not found then
            return nil
        end

        if title == token then
            score = score + 100
        elseif string.sub(title, 1, #token) == token then
            score = score + 50
        elseif string.find(title, token, 1, true) then
            score = score + 25
        elseif string.find(subtitle, token, 1, true) then
            score = score + 10
        else
            score = score + 5
        end
    end

    return score
end

local function resultSort(a, b)
    if a.score ~= b.score then
        return a.score > b.score
    end
    if a.title ~= b.title then
        return a.title < b.title
    end
    return a.id < b.id
end

function Search:Find(query, options)
    options = options or {}
    local tokens = tokenize(query)
    if #tokens == 0 then return {} end

    local maxResults = tonumber(options.limit) or 25
    if maxResults < 1 then maxResults = 1 end
    if maxResults > 100 then maxResults = 100 end

    local typeFilter = options.type and lower(options.type) or nil
    local entries = ns.Data:GetSearchEntries()
    local results = {}

    for i = 1, #entries do
        local entry = entries[i]
        if not typeFilter or lower(entry.type) == typeFilter then
            local score = scoreEntry(entry, tokens)
            if score then
                results[#results + 1] = {
                    id = entry.id,
                    type = entry.type or "record",
                    title = entry.title,
                    subtitle = entry.subtitle or "",
                    dataset = entry.dataset,
                    recordId = entry.recordId,
                    pack = entry.pack,
                    score = score,
                }
            end
        end
    end

    table.sort(results, resultSort)
    while #results > maxResults do
        table.remove(results)
    end
    return results
end

function Search:FormatResults(query, options)
    local results = self:Find(query, options)
    local lines = {}
    for i = 1, #results do
        local row = results[i]
        local context = row.subtitle ~= "" and (" — " .. row.subtitle) or ""
        lines[#lines + 1] = string.format("%d. %s%s [%s]", i, row.title, context, row.type or "record")
    end
    return lines, results
end

Search._tokenize = tokenize
Search._scoreEntry = scoreEntry
