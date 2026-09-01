local host = "https://soliton-api.duckdns.org"

local get = cloneref or function(o) return o end
local HttpService = get(game:GetService("HttpService"))
local Players = get(game:GetService("Players"))
local lp = Players.LocalPlayer

local function kick(msg)
    pcall(function()
        if lp and lp.Kick then
            lp:Kick("\n[Soliton]\n" .. tostring(msg))
        end
    end)
    task.delay(1, function() while true do end end)
end

local hw = (gethwid and gethwid())
    or (get_hwid and get_hwid())
    or (syn and syn.get_hwid and syn.get_hwid())
    or tostring(lp.UserId)

local key = _G.SolitonKey
if not key or key == "" then
    key = "SOLITON_USER_" .. tostring(lp.UserId)
end

local http_req = (syn and syn.request) or (http and http.request) or http_request or request

local function req(opt)
    if http_req then
        return http_req(opt)
    end
    if opt.Method == "POST" then
        return { StatusCode = 200, Body = game:HttpPost(opt.Url, opt.Body or "", opt.Headers and opt.Headers["Content-Type"] or "application/json") }
    end
    return { StatusCode = 200, Body = game:HttpGet(opt.Url) }
end

local body = HttpService:JSONEncode({
    key = key,
    hwid = hw,
    roblox_user_id = tostring(lp.UserId),
    roblox_username = tostring(lp.Name),
    roblox_display_name = tostring(lp.DisplayName),
    nonce = os.time()
})

local ok, res = pcall(req, {
    Url = host .. "/api/v1/auth",
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = body
})

if not ok or not res or not res.Body then
    return kick("Failed to connect to auth server")
end

local s, data = pcall(function()
    return HttpService:JSONDecode(res.Body)
end)

if not s or not data or data.status ~= "success" then
    local code = data and data.code or "AUTH_ERROR"
    local msg = data and data.message or "Authentication rejected."
    return kick("[" .. code .. "] " .. msg)
end

local ok2, res2 = pcall(req, {
    Url = host .. "/api/v1/payload",
    Method = "GET",
    Headers = {
        ["Authorization"] = "Bearer " .. tostring(data.token)
    }
})

if not ok2 or not res2 or not res2.Body or #res2.Body == 0 then
    return kick("Failed to load script payload")
end

local f, err = loadstring(res2.Body)
if not f then
    return kick("Init error: " .. tostring(err))
end

_G.SolitonKey = key
_G.SolitonRelayUrl = string.gsub(host, "^http", "ws") .. "/ws"
task.spawn(f)
