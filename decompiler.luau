local function decompilescript(scr)
    local last = 0

    local HttpService = cloneref and cloneref(game:GetService("HttpService"))
        or game:GetService("HttpService")

    local function safe_b64(data)
        if base64_encode then
            return base64_encode(data)
        end

        -- fallback encoder
        local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        return ((data:gsub('.', function(x)
            local r,byte='',x:byte()
            for i=8,1,-1 do
                r = r .. (byte % 2^i - byte % 2^(i-1) > 0 and '1' or '0')
            end
            return r
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if #x < 6 then return '' end
            local c = 0
            for i=1,6 do
                c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
            end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data % 3 + 1])
    end

    -- get bytecode
    local ok, bytecode = pcall(getscriptbytecode, scr)
    if not ok then
        return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
    end

    -- rate limit
    local elapsed = time() - last
    if elapsed < 0.12 then
        task.wait(0.12 - elapsed)
    end

    -- encode
    local encoded = safe_b64(bytecode)

    -- send request
    local res = request({
        Url = "https://api.lua.expert/decompile",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode({
            script = encoded
        })
    })

    last = time()

    if not res or res.StatusCode ~= 200 then
        return "-- api request error\n--[[\n" .. (res and res.Body or "no response") .. "\n--]]"
    end

    return res.Body
end

return decompilescript