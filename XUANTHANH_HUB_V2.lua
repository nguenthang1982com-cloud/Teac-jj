-- =========================================================================
--   🌶️ XUANTHANH HUB V2 - STEAL AN EGG 🥚
--   KEY + HWID LOCK - 1 KEY = 1 MÁY
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================================
--   CẤU HÌNH
-- =========================================================================

local CONFIG = {
    Title = "XUANTHANH HUB V2",
    Version = "v2.0",
    TargetScriptUrl = "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua",

    ValidKeys = {
        ["XUANTHANH2026"] = { type = "vip",      duration = 86400 },
        ["XUANTHANHVIP"]   = { type = "vip",      duration = 2592000 },
        ["XUANTHANHFREE"]  = { type = "free",     duration = 1800 },
        ["TOKUDA2026"]     = { type = "vip",      duration = 2592000 },
        ["CHILLIV2VIP"]    = { type = "vip",      duration = 86400 },
    },

    TrialDuration = 300,
    KeyFileName = "XuanThanhV2_Key.json",
    TrialFileName = "XuanThanhV2_Trial.json",
    HWIDFileName = "XuanThanhV2_HWID.json",

    WarnLevels = {
        {time = 300, text = "⚠️ KEY CÒN 5 PHÚT",  color = "warn"},
        {time = 60,  text = "⚠️ KEY CÒN 1 PHÚT",  color = "warn"},
        {time = 30,  text = "⚠️ KEY CÒN 30 GIÂY", color = "danger"},
        {time = 10,  text = "❌ SẮP HẾT KEY",      color = "danger"},
    },

    KickMessage = "🔒 [XUANTHANH HUB] Key đã hết hạn!\n\nVui lòng nhập key mới để tiếp tục sử dụng.",
    HWIDMismatchMsg = "🔒 [XUANTHANH HUB] Key này đã khóa cho máy khác!\n\nMỗi key chỉ dùng được 1 máy.",
}

local C = {
    bg       = Color3.fromRGB(15, 6, 9),
    bg2      = Color3.fromRGB(24, 7, 12),
    card     = Color3.fromRGB(30, 10, 16),
    cardHi   = Color3.fromRGB(40, 14, 22),
    line     = Color3.fromRGB(60, 18, 28),
    accent   = Color3.fromRGB(220, 68, 98),
    accent2  = Color3.fromRGB(235, 148, 170),
    text     = Color3.fromRGB(250, 240, 243),
    textMid  = Color3.fromRGB(200, 150, 165),
    textDim  = Color3.fromRGB(130, 75, 95),
    danger   = Color3.fromRGB(239, 68, 68),
    success  = Color3.fromRGB(52, 211, 153),
    warn     = Color3.fromRGB(255, 190, 60),
}

-- =========================================================================
--   🔒 HWID GENERATOR
-- =========================================================================

local HWID = {}

-- Hash djb2
local function _hash(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 4294967296
    end
    return h
end

-- Seed máy (lưu cố định 1 lần)
local function _getSeed()
    local SEED_FILE = "XuanThanhV2_Seed.dat"
    if isfile and readfile and isfile(SEED_FILE) then
        local ok, seed = pcall(readfile, SEED_FILE)
        if ok and seed and #seed > 0 then return seed end
    end

    local raw = ""
    raw = raw .. tostring(LocalPlayer.UserId) .. "-"
    raw = raw .. tostring(os.time()) .. "-"
    raw = raw .. tostring(math.random(100000, 999999)) .. "-"
    raw = raw .. tostring(game.PlaceId) .. "-"
    raw = raw .. tostring(tick()) .. "-"

    local hashed = string.format("%08X", _hash(raw))
    if writefile then pcall(writefile, SEED_FILE, hashed) end
    return hashed
end

-- Tạo HWID cuối
function HWID.Generate()
    local info = {}

    info.UserId = tostring(LocalPlayer.UserId)
    info.PlaceId = tostring(game.PlaceId)
    info.Seed = _getSeed()

    if identifyexecutor then
        pcall(function() info.Executor = identifyexecutor() end)
    end

    local cam = workspace.CurrentCamera
    if cam then
        info.ScreenX = tostring(cam.ViewportSize.X)
        info.ScreenY = tostring(cam.ViewportSize.Y)
    end

    info.TimeZone = tostring(os.date("%z"))

    -- Sắp xếp key alphabet
    local keys = {}
    for k in pairs(info) do table.insert(keys, k) end
    table.sort(keys)

    local raw = ""
    for _, k in ipairs(keys) do
        raw = raw .. k .. "=" .. tostring(info[k]) .. "|"
    end

    local final = string.format("%08X", _hash(raw))

    -- Format: XXXX-XXXX-XXXX-XXXX
    return string.format("%s-%s-%s-%s",
        final:sub(1, 4),
        final:sub(5, 8),
        final:sub(1, 4),
        final:sub(5, 8)
    )
end

-- =========================================================================
--   🔒 HWID LOCK SYSTEM
-- =========================================================================

local HWIDLock = {}

local function _loadHWIDDB()
    if not isfile or not readfile then return {} end
    if not isfile(CONFIG.HWIDFileName) then return {} end
    local ok, raw = pcall(readfile, CONFIG.HWIDFileName)
    if not ok or not raw then return {} end
    local pOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not pOk or type(data) ~= "table" then return {} end
    return data
end

local function _saveHWIDDB(data)
    if not writefile then return end
    pcall(function()
        writefile(CONFIG.HWIDFileName, HttpService:JSONEncode(data))
    end)
end

-- Kiểm tra key có khớp HWID máy này không
-- Trả về: ok, reason
function HWIDLock.Check(keyValue)
    local currentHWID = HWID.Generate()
    local db = _loadHWIDDB()

    if not db[keyValue] then
        -- Key chưa dùng lần nào → đăng ký cho máy này
        db[keyValue] = currentHWID
        _saveHWIDDB(db)
        return true, "first_use"
    end

    if db[keyValue] == currentHWID then
        -- Key đã đăng ký cho đúng máy này
        return true, "match"
    end

    -- Key đã đăng ký cho máy khác
    return false, "mismatch"
end

-- Reset khóa (chỉ dùng khi test)
function HWIDLock.Reset()
    if delfile then
        pcall(delfile, CONFIG.HWIDFileName)
    end
end

-- =========================================================================
--   KEY SYSTEM
-- =========================================================================

local KeySystem = {}
local XOR_KEY = 137

function KeySystem.Encrypt(str)
    local r = {}
    for i = 1, #str do
        table.insert(r, string.format("%02X", bit32.bxor(string.byte(str, i), XOR_KEY)))
    end
    return table.concat(r)
end

function KeySystem.Decrypt(hex)
    local r = {}
    for i = 1, #hex, 2 do
        local b = tonumber(hex:sub(i, i+1), 16)
        if not b then return nil end
        table.insert(r, string.char(bit32.bxor(b, XOR_KEY)))
    end
    return table.concat(r)
end

function KeySystem.SaveKey(keyValue, keyInfo)
    if not writefile then return end
    pcall(function()
        local data = {
            Key = keyValue,
            Type = keyInfo.type,
            HWID = HWID.Generate(),
            StartTime = os.time(),
            ExpireTime = os.time() + keyInfo.duration,
        }
        writefile(CONFIG.KeyFileName, KeySystem.Encrypt(HttpService:JSONEncode(data)))
    end)
end

function KeySystem.LoadKey()
    if not isfile or not readfile then return nil end
    if not isfile(CONFIG.KeyFileName) then return nil end
    local ok, raw = pcall(readfile, CONFIG.KeyFileName)
    if not ok or not raw or raw == "" then return nil end
    local dec = KeySystem.Decrypt(raw)
    if not dec then return nil end
    local pOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
    if not pOk or type(data) ~= "table" then return nil end
    if not data.ExpireTime then return nil end
    if os.time() > data.ExpireTime then return nil end

    -- 🔒 Kiểm tra HWID
    local currentHWID = HWID.Generate()
    if data.HWID and data.HWID ~= currentHWID then
        print("[HWID] Key đã khóa cho máy khác!")
        return nil
    end

    return data
end

function KeySystem.ClearKey()
    if not delfile then return end
    pcall(delfile, CONFIG.KeyFileName)
end

function KeySystem.SaveTrial()
    if not writefile then return end
    pcall(function()
        local data = {
            StartTime = os.time(),
            EndTime = os.time() + CONFIG.TrialDuration,
            HWID = HWID.Generate(),
        }
        writefile(CONFIG.TrialFileName, KeySystem.Encrypt(HttpService:JSONEncode(data)))
    end)
end

function KeySystem.LoadTrial()
    local def = { StartTime = os.time(), EndTime = os.time() + CONFIG.TrialDuration }
    if not isfile or not readfile then return def end
    if not isfile(CONFIG.TrialFileName) then
        KeySystem.SaveTrial()
        return def
    end
    local ok, raw = pcall(readfile, CONFIG.TrialFileName)
    if not ok or not raw then return def end
    local dec = KeySystem.Decrypt(raw)
    if not dec then return def end
    local pOk, data = pcall(function() return HttpService:JSONDecode(dec) end)
    if not pOk or type(data) ~= "table" then return def end

    -- Trial cũng lock theo HWID
    if data.HWID and data.HWID ~= HWID.Generate() then
        return { StartTime = os.time(), EndTime = 0 }
    end

    return data
end

function KeySystem.ValidateKey(input)
    if not input or input == "" then return nil end
    local clean = input:gsub("%s", ""):upper()
    local info = CONFIG.ValidKeys[clean]
    if info then
        return info, clean
    end
    return nil
end

-- =========================================================================
--   HELPERS
-- =========================================================================

local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function Corner(o, r)
    return New("UICorner", {CornerRadius = UDim.new(0, r)}, o)
end

local function Stroke(o, c, t, tr)
    return New("UIStroke", {Color = c, Thickness = t or 1, Transparency = tr or 0.5}, o)
end

local function Tween(o, p, d)
    local t = TweenService:Create(o, TweenInfo.new(d or 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p)
    t:Play()
    return t
end

local function FormatFull(sec)
    sec = math.max(0, math.floor(sec))
    local d = math.floor(sec / 86400)
    local h = math.floor((sec % 86400) / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if d > 0 then
        return string.format("%dd %02dh %02dm", d, h, m)
    elseif h > 0 then
        return string.format("%02dh %02dm %02ds", h, m, s)
    else
        return string.format("%02d:%02d", m, s)
    end
end

local function ShortDuration(sec)
    if sec >= 2592000 then return math.floor(sec / 2592000) .. " tháng"
    elseif sec >= 604800 then return math.floor(sec / 604800) .. " tuần"
    elseif sec >= 86400 then return math.floor(sec / 86400) .. " ngày"
    elseif sec >= 3600 then return math.floor(sec / 3600) .. " giờ"
    elseif sec >= 60 then return math.floor(sec / 60) .. " phút"
    else return sec .. " giây"
    end
end

-- =========================================================================
--   ⏰ EXPIRY CHECKER
-- =========================================================================

local Expiry = {
    Gui = nil, TimeLabel = nil, BarFill = nil,
    FrameStroke = nil, Warned = {}, Running = false,
}

local function CreateCountdownUI(keyData)
    if Expiry.Gui then Expiry.Gui:Destroy() end

    Expiry.Gui = New("ScreenGui", {
        Name = "XuanThanhV2_Countdown",
        ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 998,
    }, PlayerGui)

    local Frame = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Size = UDim2.fromOffset(240, 82),
        Position = UDim2.new(1, -20, 0, 20),
        BackgroundColor3 = C.bg, BorderSizePixel = 0,
        BackgroundTransparency = 0.05,
    }, Expiry.Gui)
    Corner(Frame, 12)

    local typeColor = C.accent
    if keyData and keyData.Type == "vip" then typeColor = C.accent
    elseif keyData and keyData.Type == "free" then typeColor = C.textMid end

    Expiry.FrameStroke = Stroke(Frame, typeColor, 1.2, 0.3)

    New("TextLabel", {
        Size = UDim2.fromOffset(80, 14), Position = UDim2.fromOffset(12, 8),
        BackgroundColor3 = typeColor, BackgroundTransparency = 0.85,
        Text = keyData and string.upper(keyData.Type) or "KEY",
        TextColor3 = typeColor,
        Font = Enum.Font.GothamBold, TextSize = 8,
    }, Frame)

    New("TextLabel", {
        Size = UDim2.new(1, -100, 0, 14), Position = UDim2.fromOffset(98, 8),
        BackgroundTransparency = 1,
        Text = keyData and keyData.Key or "KEY",
        TextColor3 = C.textMid, Font = Enum.Font.GothamMedium,
        TextSize = 9, TextXAlignment = Enum.TextXAlignment.Right,
    }, Frame)

    Expiry.TimeLabel = New("TextLabel", {
        Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 26),
        BackgroundTransparency = 1, Text = "00:00:00",
        TextColor3 = typeColor, Font = Enum.Font.Code,
        TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left,
    }, Frame)

    New("TextLabel", {
        Size = UDim2.new(1, -24, 0, 12), Position = UDim2.fromOffset(12, 52),
        BackgroundTransparency = 1, Text = "⏱ KEY CÒN LẠI",
        TextColor3 = C.textDim, Font = Enum.Font.GothamBold,
        TextSize = 8, TextXAlignment = Enum.TextXAlignment.Left,
    }, Frame)

    local BarBg = New("Frame", {
        Size = UDim2.new(1, -24, 0, 3), Position = UDim2.fromOffset(12, 70),
        BackgroundColor3 = C.bg2, BorderSizePixel = 0,
    }, Frame)
    Corner(BarBg, 1.5)

    Expiry.BarFill = New("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = typeColor, BorderSizePixel = 0,
    }, BarBg)
    Corner(Expiry.BarFill, 1.5)

    Frame.Position = UDim2.new(1, 20, 0, 20)
    Tween(Frame, {Position = UDim2.new(1, -20, 0, 20)}, 0.4)
end

local function ShowBigWarning(text, colorName, duration)
    duration = duration or 3
    local color = C[colorName] or C.warn

    local WG = New("ScreenGui", {
        Name = "XuanThanhV2_Warn", ResetOnSpawn = false,
        IgnoreGuiInset = true, DisplayOrder = 1000,
    }, PlayerGui)

    local WF = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(520, 80),
        Position = UDim2.new(0.5, 0, -0.2, 0),
        BackgroundColor3 = C.bg, BorderSizePixel = 0,
        BackgroundTransparency = 0.05,
    }, WG)
    Corner(WF, 14)
    Stroke(WF, color, 2, 0.15)

    New("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = color, Font = Enum.Font.GothamBold, TextSize = 18,
    }, WF)

    Tween(WF, {Position = UDim2.new(0.5, 0, 0.15, 0)}, 0.4)

    task.delay(duration, function()
        Tween(WF, {Position = UDim2.new(0.5, 0, -0.2, 0)}, 0.3)
        task.wait(0.35)
        WG:Destroy()
    end)
end

local function KickPlayer(reason)
    reason = reason or CONFIG.KickMessage
    ShowBigWarning("❌ KEY HẾT HẠN - ĐANG KICK", "danger", 2.5)
    KeySystem.ClearKey()
    if Expiry.Gui then Expiry.Gui:Destroy() Expiry.Gui = nil end
    task.wait(2)
    pcall(function() LocalPlayer:Kick(reason) end)
    task.wait(1)
    pcall(function() LocalPlayer.Character:BreakJoints() end)
end

function Expiry.Start()
    if Expiry.Running then return end
    Expiry.Running = true
    Expiry.Warned = {}

    task.spawn(function()
        while Expiry.Running do
            task.wait(1)
            local keyData = KeySystem.LoadKey()
            if not keyData then
                Expiry.Running = false
                if Expiry.Gui then Expiry.Gui:Destroy() Expiry.Gui = nil end
                break
            end

            if not Expiry.Gui then CreateCountdownUI(keyData) end

            local now = os.time()
            local remaining = keyData.ExpireTime - now
            local totalDuration = keyData.Duration or 86400
            local typeColor = C.accent
            if keyData.Type == "free" then typeColor = C.textMid end

            if Expiry.TimeLabel and Expiry.TimeLabel.Parent then
                Expiry.TimeLabel.Text = FormatFull(remaining)
                if remaining <= 60 then
                    Expiry.TimeLabel.TextColor3 = C.danger
                    Expiry.FrameStroke.Color = C.danger
                    Expiry.BarFill.BackgroundColor3 = C.danger
                elseif remaining <= 300 then
                    Expiry.TimeLabel.TextColor3 = C.warn
                    Expiry.FrameStroke.Color = C.warn
                    Expiry.BarFill.BackgroundColor3 = C.warn
                else
                    Expiry.TimeLabel.TextColor3 = typeColor
                    Expiry.FrameStroke.Color = typeColor
                    Expiry.BarFill.BackgroundColor3 = typeColor
                end
                local ratio = math.clamp(remaining / (totalDuration or 86400), 0, 1)
                Expiry.BarFill.Size = UDim2.new(ratio, 0, 1, 0)
            end

            for _, w in ipairs(CONFIG.WarnLevels) do
                if remaining <= w.time and not Expiry.Warned[w.time] then
                    Expiry.Warned[w.time] = true
                    local txt = w.text
                    if w.time <= 10 then txt = w.text .. " - " .. remaining .. "s" end
                    ShowBigWarning(txt, w.color, 3)
                end
            end

            if remaining <= 0 then
                Expiry.Running = false
                KickPlayer()
                break
            end
        end
    end)
end

function Expiry.Reset()
    Expiry.Warned = {}
    if Expiry.Gui then Expiry.Gui:Destroy() Expiry.Gui = nil end
end

-- =========================================================================
--   KEY GUI
-- =========================================================================

local KeyGui = New("ScreenGui", {
    Name = "XuanThanhV2_KeyUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset = true, DisplayOrder = 999,
}, PlayerGui)

local Blur = New("BlurEffect", {Size = 24}, Lighting)

local KeyFrame = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.new(0, 420, 0, 420),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundColor3 = C.bg, BorderSizePixel = 0,
}, KeyGui)
Corner(KeyFrame, 20)
Stroke(KeyFrame, C.accent, 1.4, 0.2)

local KeyScale = New("UIScale", {Scale = 0.5}, KeyFrame)

task.spawn(function()
    while KeyFrame.Parent do
        local v = (math.sin(tick() * 1.8) + 1) / 2
        local s = KeyFrame:FindFirstChildOfClass("UIStroke")
        if s then
            s.Color = Color3.new(
                (190 + math.floor(v * 35)) / 255,
                (45 + math.floor(v * 25)) / 255,
                (75 + math.floor(v * 30)) / 255
            )
        end
        task.wait(0.05)
    end
end)

local Header = New("Frame", {
    Size = UDim2.new(1, -40, 0, 60),
    Position = UDim2.fromOffset(20, 20),
    BackgroundTransparency = 1,
}, KeyFrame)

local LogoBox = New("Frame", {
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.fromOffset(0, 6),
    BackgroundColor3 = C.bg2,
}, Header)
Corner(LogoBox, 14)
Stroke(LogoBox, C.accent, 1.2)
New("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "🔒", TextSize = 22,
}, LogoBox)

New("TextLabel", {
    Size = UDim2.new(1, -60, 0, 20), Position = UDim2.fromOffset(60, 6),
    BackgroundTransparency = 1, Text = CONFIG.Title .. " · " .. CONFIG.Version,
    TextColor3 = C.text, Font = Enum.Font.GothamBold,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

New("TextLabel", {
    Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(60, 28),
    BackgroundTransparency = 1, Text = "Steal An Egg 🥚 · HWID-LOCKED (1 KEY = 1 MÁY)",
    TextColor3 = C.accent2, Font = Enum.Font.GothamMedium,
    TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, He= "Bán một lần các trứng khớp điều kiện",
    ["Sell Egg Rule"] = "Quy Tắc Bán Trứng",
    ["Egg Max Rarity"] = "Độ Hiếm Trứng Max Cần Bán",
    ["Sell eggs at or below this rarity"] = "Bán trứng từ độ hiếm này trở xuống",
    ["Egg Sell Value"] = "Giá Trị Bán Trứng Min",
    ["Keep Mutated Eggs"] = "Giữ Lại Trứng Đột Biến",
    ["Never sell mutated eggs"] = "Không bao giờ bán trứng có đột biến",
    ["Blacklist Sell Eggs"] = "Danh Sách Đen Bán Trứng",
    ["These eggs are never sold"] = "Những trứng này sẽ không bao giờ bị bán",
    ["Sell eggs traded from Dr Scramble that match the filters below"] = "Bán trứng đổi từ Dr Scramble khớp bộ lọc dưới",
    ["Sell Lab Eggs Now"] = "Bán Trứng Lab Ngay",
    ["Sell matching Lab eggs once"] = "Bán một lần các trứng Lab khớp điều kiện",
    ["Sell Lab Egg Rule"] = "Quy Tắc Bán Trứng Lab",
    ["Lab Egg Max Rarity"] = "Độ Hiếm Trứng Lab Max Cần Bán",
    ["Sell Lab eggs at or below this rarity (Off = none by rarity)"] = "Bán trứng Lab từ độ hiếm này trở xuống (Off = tắt)",
    ["Lab Egg Sell Value"] = "Giá Trị Bán Trứng Lab Min",
    ["Sell Lab eggs worth less than this (0 = off)"] = "Bán trứng Lab giá trị thấp hơn mức này (0 = tắt)",
    ["Keep Mutated Lab Eggs"] = "Giữ Lại Trứng Lab Đột Biến",
    ["Never sell mutated Lab eggs"] = "Không bao giờ bán trứng Lab có đột biến",
    ["Keep Lab Pets"] = "Giữ Lại Pet Lab",
    ["Lab eggs of these pets are never sold"] = "Trứng Lab của những pet này sẽ không bao giờ bị bán",

    ["No three matching pets"] = "Không đủ 3 pet trùng khớp",
    ["Fuse 3 same pets into an egg, nonstop"] = "Ghép 3 pet cùng loại thành 1 trứng liên tục",
    ["Fuse Priority Mode"] = "Chế Độ Ưu Tiên Dung Hợp",
    ["Pets To Use"] = "Loại Pet Sử Dụng",
    ["Max Rarity to Fuse"] = "Độ Hiếm Dung Hợp Max",
    ["Specific Species to Fuse"] = "Chỉ Định Loài Cần Dung Hợp",
    ["Only fuse these species (empty = all)"] = "Chỉ ghép loài này (trống = tất cả)",
    ["Skip Mutated Pets"] = "Bỏ Qua Pet Đột Biến",
    ["Eject Incomplete Slots"] = "Nhả Các Ô Chưa Đủ Bộ",
    ["Take out pets that can't make a set"] = "Đẩy ra các pet không thể ghép đủ bộ 3",

    ["Auto Favorite Pet"] = "Tự Động Khóa Pet",
    ["Favorite pets matching the rules below"] = "Khóa các pet khớp quy tắc bên dưới",
    ["Favorite Pets Now"] = "Khóa Pet Ngay",
    ["Favorite matching pets once"] = "Khóa các pet khớp điều kiện một lần",
    ["Favorite Rule"] = "Quy Tắc Khóa",
    ["Pass any check or all checks"] = "Thỏa mãn một hoặc tất cả điều kiện",
    ["Favorite Min Rarity"] = "Độ Hiếm Khóa Min",
    ["Favorite pets of the chosen rarity and every rarity above it (Off = skip)"] = "Khóa pet từ độ hiếm đã chọn trở lên (Off = bỏ qua)",
    ["Favorite Mutations"] = "Đột Biến Cần Khóa",
    ["Mutation check (empty = skip)"] = "Kiểm tra đột biến (trống = bỏ qua)",
    ["Min Favorite Value"] = "Giá Trị Khóa Min",
    ["Value check (0 = skip)"] = "Kiểm tra giá trị (0 = bỏ qua)",
    ["Always Favorite Species"] = "Luôn Khóa Các Loài Này",
    ["Always favorite these species"] = "Luôn luôn khóa những loài này",
    ["Auto Favorite Equipped"] = "Tự Khóa Pet Đang Dùng",
    ["Keep equipped pets favorited"] = "Luôn giữ pet đang trang bị được khóa",
    ["Auto Unfavorite Equipped"] = "Tự Bỏ Khóa Pet Đang Dùng",
    ["Unfavorite equipped pets not in the rules"] = "Mở khóa pet đang trang bị nếu không đúng quy tắc",
    ["Favorite Equipped Now"] = "Khóa Pet Đang Dùng Ngay",
    ["Favorite all equipped pets once"] = "Khóa tất cả pet đang trang bị một lần",
    ["Unfavorite Equipped Now"] = "Bỏ Khóa Pet Đang Dùng Ngay",
    ["Unfavorite all equipped pets once"] = "Mở khóa tất cả pet đang trang bị một lần",

    ["Auto Mech Boss"] = "Tự Động Đánh Boss Robot",
    ["Mech Tween Speed"] = "Tốc Độ Bay Đánh Boss",
    ["Main Weapon Hold"] = "Thời Gian Giữ Vũ Khí Chính",
    ["Scrambler Hold"] = "Thời Gian Giữ Súng Biến Đổi",
    ["Swap Two Weapons"] = "Tự Đổi Qua Lại 2 Vũ Khí",
    ["Boss Server Hop"] = "Tự Đổi Server Săn Boss",
    ["After each boss, hops to a less crowded server to fight again"] = "Sau mỗi boss, đổi sang server vắng hơn để đánh tiếp",
    ["Keep Hopping For"] = "Thời Gian Đổi Server Liên Tục",
    ["Keeps fighting every boss it finds and hopping for this long"] = "Liên tục săn boss tìm được và đổi server trong thời gian này",
    ["Auto Claim Mastery"] = "Tự Nhận Thưởng Tinh Thông Boss",
    ["Claims Boss Mastery rewards as soon as they unlock"] = "Tự nhận thưởng Tinh Thông Boss ngay khi mở khóa",
    ["Lab Banners"] = "Biểu Ngữ Phòng Lab",
    ["Only trade and steal for these banners (empty = all)"] = "Chỉ đổi và cướp các biểu ngữ này (trống = tất cả)",
    ["Auto Lab Trade-In"] = "Tự Đổi Đồ Phòng Thí Nghiệm",
    ["Auto Reroll Lab Recipe"] = "Tự Đổi Công Thức Phòng Lab",
    ["Auto Place Lab Reward Eggs"] = "Tự Đặt Trứng Thưởng Lab",
    ["Places the reward eggs from Lab trades"] = "Tự động đặt trứng thưởng nhận từ đổi đồ phòng lab",
    ["Auto Buy Scramble Shop"] = "Tự Mua Shop Dr. Scramble",
    ["Buy the picked items with Samples"] = "Dùng Mẫu Vật (Samples) mua các vật phẩm đã chọn",
    ["Scramble Shop Items"] = "Vật Phẩm Cửa Hàng Scramble",
    ["Keep Samples"] = "Giữ Lại Mẫu Vật Tối Thiểu",
    ["Never spend below this many Samples"] = "Không bao giờ tiêu hao dưới mức mẫu vật này",
    ["Auto Use Scrambled"] = "Tự Dùng Thuốc Biến Đổi Scrambled",
    ["Turn it on to start applying Scrambled"] = "Bật lên để bắt đầu áp dụng thuốc Scrambled",
    ["Auto Buy Scrambled"] = "Tự Mua Thêm Scrambled Khi Hết",
    ["Buy another Scrambled from the event shop when you run out"] = "Tự mua thêm Scrambled từ shop sự kiện khi dùng hết",
    ["Mutation Min Rarity"] = "Độ Hiếm Đột Biến Min",
    ["Only eggs of this rarity and above are used"] = "Chỉ dùng trứng từ độ hiếm này trở lên",
    ["Min Mutation Value"] = "Giá Trị Đột Biến Min",
    ["Mutation Priority"] = "Ưu Tiên Đột Biến",
    ["Which egg gets the consumable first"] = "Trứng nào được ưu tiên dùng thuốc trước",
    ["Mutation Target Eggs"] = "Mục Tiêu Trứng Đột Biến",
    ["Only use the consumable on these eggs (empty = all)"] = "Chỉ dùng thuốc lên các trứng này (trống = tất cả)",
    ["Auto Wisp"] = "Tự Động Nhặt Wisp",
    ["Auto Banjo Cricket"] = "Tự Động Bắt Dế Banjo",

    ["Chase Settings"] = "Cài Đặt Đuổi Đánh",
    ["Chase Cài Đặt"] = "Cài Đặt Đuổi Đánh",
    ["Hit Tween Speed"] = "Tốc Độ Bay Đánh",
    ["Hit Max Speed"] = "Tốc Độ Đánh Tối Đa",
    ["Hit Lead"] = "Đón Đầu Đòn Đánh (Hit Lead)",
    ["Stand further ahead of the target (i.e. or closer to them)"] = "Đứng đón đầu mục tiêu xa hơn (hoặc áp sát gần hơn)",
    ["Hit Sweep"] = "Góc Quét Đòn Đánh (Hit Sweep)",
    ["How far you swipe back and forth in front of the target"] = "Khoảng cách vung vũ khí quét qua lại trước mục tiêu",
    ["Add/Remove Hits On Quick Bar 2"] = "Thêm/Bỏ Nút Đánh Vào Quick Bar 2",
    ["Pin or unpin the hit toggles on Quick Bar 2"] = "Ghim hoặc bỏ ghim các nút đánh trên Quick Bar 2",
    ["Auto Hit Nearest Player"] = "Tự Đánh Người Gần Nhất",
    ["Auto Hit Egg Holders"] = "Tự Đánh Người Đang Bê Trứng",
    ["Auto Hit Specific Player"] = "Tự Đánh Người Chỉ Định",
    ["Hit Player"] = "Chọn Người Cần Đánh",
    ["Hit Aura"] = "Vòng Đánh Tự Động (Hit Aura)",
    ["Instant Prompts"] = "Tương Tác Phím Nhanh (Instant E)",
    ["Speed Boost"] = "Tăng Tốc Chạy",
    ["Boost Speed"] = "Tốc Độ Tăng Tốc",
    ["Infinite Jump"] = "Nhảy Vô Hạn",
    ["Invisibility"] = "Tàng Hình (Invisibility)",
    ["Makes you invisible to other players"] = "Làm bạn vô hình trước người chơi khác",
    ["Anti Ragdoll"] = "Chống Ngã (Anti Ragdoll)",
    ["Anti Trap"] = "Chống Bẫy (Anti Trap)",
    ["Traps from other players cannot catch you"] = "Bẫy của người khác không thể bắt được bạn",

    ["ESP Eggs"] = "ESP Trứng",
    ["ESP Fixed Size"] = "Cỡ ESP Cố Định",
    ["ESP Own Base Eggs"] = "Hiện Trứng Căn Cứ Mình",
    ["Also show the eggs placed in your own base"] = "Hiển thị cả trứng đã đặt tại căn cứ của bạn",
    ["ESP Min Rarity"] = "Độ Hiếm ESP Min",
    ["Show eggs of the chosen rarity and every rarity above it"] = "Hiện trứng từ độ hiếm đã chọn trở lên",
    ["ESP Show Info"] = "Hiện Thông Tin ESP",
    ["Min ESP Value"] = "Giá Trị ESP Min",
    ["ESP Egg Size"] = "Cỡ ESP Trứng",
    ["ESP Guards"] = "ESP Vệ Sĩ",
    ["ESP Guard Size"] = "Cỡ ESP Vệ Sĩ",
    ["ESP Lost Parts"] = "ESP Phụ Tùng Rơi",
    ["ESP Players"] = "ESP Người Chơi",
    ["ESP Player Info"] = "Thông Tin ESP Người Chơi",
    ["ESP Player Size"] = "Cỡ ESP Người Chơi",

    ["Search eggs..."] = "Tìm kiếm trứng...",
    ["FLY TO EGG"] = "BAY ĐẾN TRỨNG",
    ["Biohazard Pets"] = "Pet Phóng Xạ (Biohazard)",
    ["CURRENT RECIPE"] = "CÔNG THỨC HIỆN TẠI",
    ["REWARD ODDS - BIOHAZARD PETS"] = "TỈ LỆ THƯỞNG - PET PHÓNG XẠ",
    ["Chase pet"] = "Đuổi bắt pet",
    ["Machine is empty"] = "Máy đang trống",
    ["Load 3 pets of the same species to see the result odds"] = "Đặt 3 pet cùng loài vào máy để xem tỉ lệ kết quả",
    ["Sort By"] = "Sắp Xếp Theo",
    ["Preview Card"] = "Thẻ Xem Trước",

    ["Auto Buy Trail"] = "Tự Mua Vệt Sáng (Trail)",
    ["Automatically buy available trails when affordable"] = "Tự động mua vệt sáng có sẵn khi đủ tiền",
    ["Auto Upgrade Base"] = "Tự Nâng Cấp Căn Cứ",
    ["Automatically upgrade base when money is available"] = "Tự động nâng cấp căn cứ khi đủ tiền",
    ["Auto Upgrade Treadmill"] = "Tự Nâng Cấp Máy Tập",
    ["Automatically upgrade treadmill when money is available"] = "Tự động nâng cấp máy tập khi đủ tiền",
    ["Auto Claim"] = "Tự Nhận Thưởng",
    ["Claim offline money & index rewards"] = "Nhận tiền tích lũy offline & thưởng sách pet",
    ["Auto Claim Index"] = "Tự Nhận Thưởng Sách Pet",
    ["Claim index rewards as soon as they unlock"] = "Tự động nhận thưởng sách ngay khi mở khóa",

    ["Auto Load Script"] = "Tự Động Nạp Script",
    ["Server Hop Mode"] = "Chế Độ Đổi Server",
    ["Server Hop"] = "Đổi Server",
    ["Job ID"] = "Mã Phòng (Job ID)",
    ["Paste a server Job ID..."] = "Dán mã Job ID của server...",
    ["Join Job ID"] = "Vào Bằng Job ID",
    ["Copy Current Job ID"] = "Chép Job ID Hiện Tại",
    ["Rejoin Server"] = "Vào Lại Server",
    ["Auto Rejoin When Disconnect"] = "Tự Kết Nối Lại Khi Mất Mạng",

    ["FPS Cap"] = "Giới Hạn FPS",
    ["Optimizer"] = "Tối Ưu Hóa (Giảm Lag)",
    ["Strip shadows, textures and effects for the highest FPS"] = "Xóa bóng, bề mặt và hiệu ứng để đạt FPS tối đa",
    ["FPS and Ping"] = "Hiện FPS & Ping",
    ["FPS and Ping Size"] = "Kích Cỡ FPS & Ping",
    ["Disable 3D Render"] = "Tắt Đồ Họa 3D",
    ["Farm HUD"] = "Bảng Cày Cuốc (Farm HUD)",
    ["Drag any panel to place it where you like"] = "Kéo bất kỳ bảng nào đến vị trí bạn muốn",
    ["Anti AFK"] = "Chống Treo Máy (Anti AFK)",

    ["Joins new servers to find eggs that match the filters below"] = "Tự đổi server để tìm trứng khớp bộ lọc bên dưới",
    ["Turn on Auto Hop to start hunting"] = "Bật Tự Đổi Server để bắt đầu săn trứng",
    ["Hop Mode"] = "Chế Độ Đổi Server",
    ["Rarity To Wait For"] = "Độ Hiếm Cần Giữ Chân",
    ["For After A Rare Spawns this rarity or higher"] = "Chờ nếu xuất hiện trứng từ độ hiếm này trở lên",
    ["Sync With Auto Steal Filters"] = "Đồng Bộ Bộ Lọc Cướp",
    ["Changing a filter here also changes it in Auto Steal, and back"] = "Thay đổi bộ lọc tại đây sẽ đồng bộ với mục Tự Động Cướp",
    ["Find eggs of the chosen rarity and every rarity above it"] = "Tìm trứng thuộc độ hiếm đã chọn và cao hơn",
    ["Min Value To Find"] = "Giá Trị Trứng Min Cần Tìm",
    ["Skip eggs worth less than this. Drag or type 350k, 50m, 10b"] = "Bỏ qua trứng giá nhỏ hơn mức này. Kéo hoặc nhập 350k, 50m, 10b",
    ["First Hop Delay"] = "Độ Trễ Lần Đổi Server Đầu",
    ["Wait after the script loads before the first hop"] = "Chờ sau khi nạp script hoàn tất trước khi đổi server",
    ["Webhook URL"] = "Đường Dẫn Webhook",
    ["Ping @everyone"] = "Tag @everyone",
    ["Notify Stolen Eggs"] = "Báo Cáo Cướp Trứng",
    ["Post every egg you bring home"] = "Gửi thông báo mỗi quả trứng mang về thành công",
    ["selected"] = "đã chọn"
}

local DYNAMIC_PATTERNS = {
    {
        pattern = "ALL (%d+)",
        format = function(lang, c) return lang == "VI" and ("TẤT CẢ " .. c) or ("ALL " .. c) end
    },
    {
        pattern = "READY (%d+)",
        format = function(lang, c) return lang == "VI" and ("SẴN SÀNG " .. c) or ("READY " .. c) end
    },
    {
        pattern = "GROWING (%d+)",
        format = function(lang, c) return lang == "VI" and ("ĐANG LỚN " .. c) or ("GROWING " .. c) end
    },
    {
        pattern = "IN BAG (%d+)",
        format = function(lang, c) return lang == "VI" and ("TRONG TÚI " .. c) or ("IN BAG " .. c) end
    },
    {
        pattern = "#(%d+) of (%d+) eggs by value",
        format = function(lang, r, total) return lang == "VI" and string.format("Hạng #%s/%s trứng theo giá trị", r, total) or string.format("#%s of %s eggs by value", r, total) end
    },
    {
        pattern = "1 in ([%d%.]+)",
        format = function(lang, val) return lang == "VI" and ("Tỉ lệ 1/" .. val) or ("1 in " .. val) end
    },
    {
        pattern = "Ends in (%d+h %d+m %d+s)",
        format = function(lang, tStr) return lang == "VI" and ("Kết thúc sau " .. tStr) or ("Ends in " .. tStr) end
    },
    {
        pattern = "in (%d+h %d+m)",
        format = function(lang, tStr) return lang == "VI" and ("sau " .. tStr) or ("in " .. tStr) end
    },
    {
        pattern = "Banner chance (%d+%.?%d*%%)",
        format = function(lang, cStr) return lang == "VI" and ("Tỉ lệ Banner " .. cStr) or ("Banner chance " .. cStr) end
    },
    {
        pattern = "Pity (%d+)/(%d+)",
        format = function(lang, p1, p2) return lang == "VI" and string.format("Bảo hiểm %s/%s", p1, p2) or string.format("Pity %s/%s", p1, p2) end
    },
    {
        pattern = "Free rerolls (%d+)",
        format = function(lang, rStr) return lang == "VI" and ("Đổi miễn phí " .. rStr) or ("Free rerolls " .. rStr) end
    },
    {
        pattern = "rotates in (%d+:%d+)",
        format = function(lang, timeStr) return lang == "VI" and ("xoay vòng sau " .. timeStr) or ("rotates in " .. timeStr) end
    },
    {
        pattern = "Eggs placed (%d+)/(%d+) %- (%d+)/(%d+) pets equipped, (%d+) in bag",
        format = function(lang, p1, p2, p3, p4, p5)
            if lang == "VI" then
                return string.format("Trứng đã đặt %s/%s - %s/%s pet trang bị, %s trong túi", p1, p2, p3, p4, p5)
            end
            return string.format("Eggs placed %s/%s - %s/%s pets equipped, %s in bag", p1, p2, p3, p4, p5)
        end
    },
    {
        pattern = "Pet matches %- (%d+) pets? for %$(.+)",
        format = function(lang, count, val)
            if lang == "VI" then return string.format("Khớp pet - %s pet giá $%s", count, val) end
            return string.format("Pet matches - %s pets for $%s", count, val)
        end
    },
    {
        pattern = "Egg matches %- (%d+) eggs? for %$(.+)",
        format = function(lang, count, val)
            if lang == "VI" then return string.format("Khớp trứng - %s trứng giá $%s", count, val) end
            return string.format("Egg matches - %s eggs for $%s", count, val)
        end
    },
    {
        pattern = "Lab egg matches %- (%d+) eggs? for %$(.+)",
        format = function(lang, count, val)
            if lang == "VI" then return string.format("Khớp trứng Lab - %s trứng giá $%s", count, val) end
            return string.format("Lab egg matches - %s eggs for $%s", count, val)
        end
    },
    {
        pattern = "Favorite matches %- (%d+) pets?, (%d+) to mark %| (%d+) favorited",
        format = function(lang, c1, c2, c3)
            if lang == "VI" then return string.format("Khớp yêu thích - %s pet, %s cần lưu | %s đã khóa", c1, c2, c3) end
            return string.format("Favorite matches - %s pets, %s to mark | %s favorited", c1, c2, c3)
        end
    },
    {
        pattern = "Charges (%d+) Eggs (%d+)/(%d+) Tries (%d+) Applied (%d+)",
        format = function(lang, c, e1, e2, t, a)
            if lang == "VI" then return string.format("Số lần sạc %s Trứng %s/%s Thử %s Đã dùng %s", c, e1, e2, t, a) end
            return string.format("Charges %s Eggs %s/%s Tries %s Applied %s", c, e1, e2, t, a)
        end
    },
    {
        pattern = "Players (%d+)/(%d+)",
        format = function(lang, p1, p2) return lang == "VI" and string.format("Người chơi %s/%s", p1, p2) or string.format("Players %s/%s", p1, p2) end
    },
    {
        pattern = "Next Mech portal in (%d+:%d+)",
        format = function(lang, timeStr) return lang == "VI" and ("Cổng Robot mở sau " .. timeStr) or ("Next Mech portal in " .. timeStr) end
    },
    {
        pattern = "Next Butterfly Bloom in (%d+:%d+)",
        format = function(lang, timeStr) return lang == "VI" and ("Sự kiện Bướm nở sau " .. timeStr) or ("Next Butterfly Bloom in " .. timeStr) end
    },
    {
        pattern = "Butterfly Bloom live, (%d+:%d+) left",
        format = function(lang, timeStr) return lang == "VI" and ("Sự kiện Bướm đang diễn ra, còn " .. timeStr) or ("Butterfly Bloom live, " .. timeStr .. " left") end
    },
    {
        pattern = "Caught (.+)! %((%d+) owned%)",
        format = function(lang, name, count) return lang == "VI" and string.format("Đã bắt %s! (Đang có %s con)", name, count) or string.format("Caught %s! (%s owned)", name, count) end
    }
}

local SortedVI = {}
for en, vi in pairs(MAP_VI) do table.insert(SortedVI, {en = en, out = vi, len = #en}) end
table.sort(SortedVI, function(a, b) return a.len > b.len end)

-- ==================== 3. LÕI DỊCH THUẬT SIÊU TỐC O(1) ====================
local function translateText(raw)
    local cacheKey = currentLanguage .. "|" .. raw
    if FastCache[cacheKey] then return FastCache[cacheKey] end

    if currentLanguage == "EN" then
        local res = replaceAll(raw, "XUANTHANH HUB V2", "XUANTHANH HUB V2")
        FastCache[cacheKey] = res
        return res
    end

    local trimmed = raw:match("^%s*(.-)%s*$") or raw

    if EXACT_MATCH_VI[trimmed] then
        local res = raw:gsub(trimmed, EXACT_MATCH_VI[trimmed], 1)
        FastCache[cacheKey] = res
        return res
    end

    local result = raw
    local matched = false

    for _, item in ipairs(DYNAMIC_PATTERNS) do
        if result:find(item.pattern) then
            result = result:gsub(item.pattern, function(...)
                return item.format(currentLanguage, ...)
            end)
            matched = true
        end
    end

    for _, item in ipairs(SortedVI) do
        if result:find(item.en, 1, true) then
            result = replaceAll(result, item.en, item.out)
            matched = true
        end
    end

    FastCache[cacheKey] = matched and result or raw
    return FastCache[cacheKey]
end

local TrackedElements = {}

local function applyTranslation(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then return end
    if inst:FindFirstAncestor("XUANTHANH_Liquid_Capsule") then return end
    if inst:GetAttribute("__IsTranslating") then return end

    local original = inst:GetAttribute("OriginalRawText")
    if not original then
        original = inst.Text
        inst:SetAttribute("OriginalRawText", original)
    end

    local mappedText = translateText(original)
    if inst.Text ~= mappedText then
        inst:SetAttribute("__IsTranslating", true)
        inst:SetAttribute("__LastTranslatedText", mappedText)
        pcall(function() inst.Text = mappedText end)
        inst:SetAttribute("__IsTranslating", false)
    end
end

local function hookElement(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then return end
    if inst:GetAttribute("HasTranslateHook") then return end
    inst:SetAttribute("HasTranslateHook", true)

    table.insert(TrackedElements, inst)
    task.defer(function() applyTranslation(inst) end)

    inst:GetPropertyChangedSignal("Text"):Connect(function()
        if inst:GetAttribute("__IsTranslating") then return end
        local current = inst.Text
        if current == inst:GetAttribute("__LastTranslatedText") then return end
        inst:SetAttribute("OriginalRawText", current)
        applyTranslation(inst)
    end)
end

local function updateAllActive()
    for i = #TrackedElements, 1, -1 do
        local el = TrackedElements[i]
        if el and el.Parent then
            applyTranslation(el)
        else
            table.remove(TrackedElements, i)
        end
    end
end

-- ==================== 4. LÕI CÔ LẬP ĐỔI MÀU ĐÚNG 3 PHẦN (SOFT PASTEL BLUE) ====================
-- Bảng màu Soft Pastel Sky Blue (Dịu mắt, không đậm, không chói)
local COLOR_FACE_TOP    = Color3.fromRGB(140, 195, 245) -- Xanh nhạt sáng dịu
local COLOR_FACE_BOTTOM = Color3.fromRGB(95, 155, 225)  -- Xanh biển nhạt
local COLOR_BEVEL_SHADOW= Color3.fromRGB(55, 110, 180)  -- Bóng đổ chân nút 3D

-- DANH SÁCH TỪ KHÓA CHỈ ĐỊNH CỦA ĐÚNG 2 HÀNG NÚT (ẢNH 1 & ẢNH 2)
local TARGET_BUTTON_KEYWORDS = {
    -- Hàng nút Tab bên trái (Ảnh 2)
    ["cày cuốc"] = true, ["farm"] = true,
    ["người chơi"] = true, ["player"] = true,
    ["dự đoán"] = true, ["predictor"] = true,
    ["tiến trình"] = true, ["progress"] = true,
    ["máy chủ"] = true, ["server"] = true,
    ["khác"] = true, ["misc"] = true,
    ["tự đổi máy chủ"] = true, ["tự đổi server"] = true, ["auto hop"] = true,
    -- Hàng nút điều hướng bên phải (Ảnh 1)
    ["discord"] = true,
    ["phím tắt & key"] = true, ["quick & keys"] = true,
    ["cài đặt"] = true, ["settings"] = true,
    ["cấu hình"] = true, ["config"] = true
}

-- Hàm áp màu xanh nhạt lên duy nhất một nút cụ thể
local function recolorSingleButton(btnContainer, labelObj)
    if not btnContainer then return end
    
    -- 1. Đổi UIGradient bề mặt nếu có
    local grad = btnContainer:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = btnContainer
    end
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLOR_FACE_TOP),
        ColorSequenceKeypoint.new(1, COLOR_FACE_BOTTOM)
    })

    btnContainer.BackgroundColor3 = COLOR_FACE_BOTTOM

    -- 2. Đổi chân bóng 3D (Frame viền chân nếu có)
    if btnContainer.Parent and btnContainer.Parent:IsA("Frame") and btnContainer.Parent ~= btnContainer then
        local p = btnContainer.Parent
        local pCol = p.BackgroundColor3
        if pCol and (pCol.R > 0.4 and pCol.G < 0.35) then
            p.BackgroundColor3 = COLOR_BEVEL_SHADOW
        end
    end

    -- 3. KHÓA CỨNG MÀU CHỮ: Luôn luôn giữ màu TRẮNG tinh
    if labelObj and labelObj:IsA("TextLabel") or labelObj:IsA("TextButton") then
        labelObj.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

-- Hàm áp màu xanh nhạt lên Thanh Header TopBar (Ảnh 3)
local function recolorHeaderBar(headerFrame, titleObj)
    if not headerFrame then return end

    local grad = headerFrame:FindFirstChildOfClass("UIGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = headerFrame
    end
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLOR_FACE_TOP),
        ColorSequenceKeypoint.new(1, COLOR_FACE_BOTTOM)
    })

    headerFrame.BackgroundColor3 = COLOR_FACE_BOTTOM

    -- Chân bóng viền dưới header (nếu có frame shadow)
    if headerFrame.Parent and headerFrame.Parent:IsA("Frame") then
        local p = headerFrame.Parent
        if p.BackgroundColor3.R > 0.4 and p.BackgroundColor3.G < 0.35 then
            p.BackgroundColor3 = COLOR_BEVEL_SHADOW
        end
    end

    -- Khóa cứng chữ tiêu đề màu trắng
    if titleObj and (titleObj:IsA("TextLabel") or titleObj:IsA("TextButton")) then
        titleObj.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    -- Đổi nút tắt [X] sang màu xanh pastel đồng bộ
    for _, item in ipairs(headerFrame:GetDescendants()) do
        if item:IsA("TextButton") or item:IsA("ImageButton") then
            item.BackgroundColor3 = COLOR_FACE_BOTTOM
            local xGrad = item:FindFirstChildOfClass("UIGradient")
            if xGrad then
                xGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, COLOR_FACE_TOP),
                    ColorSequenceKeypoint.new(1, COLOR_FACE_BOTTOM)
                })
            end
            if item:IsA("TextButton") then
                item.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
    end
end

-- Bộ kiểm soát chỉ định (Chỉ duyệt đúng 3 đối tượng, tuyệt đối không duyệt lan man)
local function inspectAndApplySoftBlue(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton")) then return end
    if inst:FindFirstAncestor("XUANTHANH_Liquid_Capsule") then return end

    local textRaw = inst.Text:lower():match("^%s*(.-)%s*$") or ""

    -- 1. Nhận diện Thanh Header (Ảnh 3)
    if textRaw:find("XUANTHANH HUB V2") then
        local headerFrame = inst:FindFirstAncestorOfClass("Frame")
        if headerFrame then
            recolorHeaderBar(headerFrame, inst)
        end
        return
    end

    -- 2. Nhận diện Đúng 2 hàng nút Tab trái & phải (Ảnh 1 & Ảnh 2)
    if TARGET_BUTTON_KEYWORDS[textRaw] then
        -- Tìm Container của nút bấm
        local btnTarget = inst:IsA("TextButton") and inst or inst:FindFirstAncestorOfClass("TextButton") or inst:FindFirstAncestorOfClass("Frame")
        if btnTarget then
            recolorSingleButton(btnTarget, inst)
        end
        return
    end
end

-- ==================== 5. NÚT ĐỔI NGÔN NGỮ LIQUID CYBER (SOFT BLUE THEME) ====================
local function createLiquidCapsuleUI()
    local parentTarget = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    local old = parentTarget:FindFirstChild("XUANTHANH_Liquid_Capsule")
    if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "XUANTHANH_Liquid_Capsule"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 2147483647
    ScreenGui.Parent = parentTarget

    -- Vỏ Viên Nang
    local Capsule = Instance.new("Frame")
    Capsule.Name = "Capsule"
    Capsule.Size = UDim2.new(0, 176, 0, 36)
    Capsule.AnchorPoint = Vector2.new(0.5, 0)
    Capsule.Position = UDim2.new(0.5, 0, 0, 12)
    Capsule.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    Capsule.BackgroundTransparency = 0.15
    Capsule.BorderSizePixel = 0
    Capsule.Parent = ScreenGui

    local CapsuleCorner = Instance.new("UICorner")
    CapsuleCorner.CornerRadius = UDim.new(1, 0)
    CapsuleCorner.Parent = Capsule

    local CapsuleStroke = Instance.new("UIStroke")
    CapsuleStroke.Thickness = 1.4
    CapsuleStroke.Color = COLOR_FACE_TOP
    CapsuleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    CapsuleStroke.Parent = Capsule

    -- Con trượt Active Slider (Soft Sky Blue)
    local Slider = Instance.new("Frame")
    Slider.Name = "Slider"
    Slider.Size = UDim2.new(0, 84, 0, 28)
    Slider.Position = UDim2.new(0, 4, 0.5, -14)
    Slider.BackgroundColor3 = COLOR_FACE_BOTTOM
    Slider.BorderSizePixel = 0
    Slider.Parent = Capsule

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = Slider

    local SliderGradient = Instance.new("UIGradient")
    SliderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLOR_FACE_TOP),
        ColorSequenceKeypoint.new(1, COLOR_FACE_BOTTOM)
    })
    SliderGradient.Rotation = 90
    SliderGradient.Parent = Slider

    local SliderGlow = Instance.new("UIStroke")
    SliderGlow.Thickness = 1
    SliderGlow.Color = Color3.fromRGB(175, 215, 255)
    SliderGlow.Transparency = 0.4
    SliderGlow.Parent = Slider

    -- Nút Tiếng Việt
    local BtnVI = Instance.new("TextButton")
    BtnVI.Name = "BtnVI"
    BtnVI.Size = UDim2.new(0, 84, 1, 0)
    BtnVI.Position = UDim2.new(0, 4, 0, 0)
    BtnVI.BackgroundTransparency = 1
    BtnVI.Text = "🇻🇳 TIẾNG VIỆT"
    BtnVI.Font = Enum.Font.GothamBold
    BtnVI.TextSize = 10
    BtnVI.TextColor3 = Color3.fromRGB(255, 255, 255)
    BtnVI.ZIndex = 5
    BtnVI.Parent = Capsule

    -- Nút English
    local BtnEN = Instance.new("TextButton")
    BtnEN.Name = "BtnEN"
    BtnEN.Size = UDim2.new(0, 84, 1, 0)
    BtnEN.Position = UDim2.new(1, -88, 0, 0)
    BtnEN.BackgroundTransparency = 1
    BtnEN.Text = "🌐 ENGLISH"
    BtnEN.Font = Enum.Font.GothamBold
    BtnEN.TextSize = 10
    BtnEN.TextColor3 = Color3.fromRGB(145, 160, 185)
    BtnEN.ZIndex = 5
    BtnEN.Parent = Capsule

    local function switchMode(target)
        if currentLanguage == target then return end
        currentLanguage = target

        TweenService:Create(Capsule, TweenInfo.new(0.08), {Size = UDim2.new(0, 170, 0, 34)}):Play()
        task.delay(0.08, function()
            TweenService:Create(Capsule, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 176, 0, 36)}):Play()
        end)

        if target == "VI" then
            TweenService:Create(Slider, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 4, 0.5, -14),
                BackgroundColor3 = COLOR_FACE_BOTTOM
            }):Play()
            TweenService:Create(CapsuleStroke, TweenInfo.new(0.3), {Color = COLOR_FACE_TOP}):Play()
            TweenService:Create(BtnVI, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(BtnEN, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(145, 160, 185)}):Play()
        else
            TweenService:Create(Slider, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -88, 0.5, -14),
                BackgroundColor3 = Color3.fromRGB(55, 70, 95)
            }):Play()
            TweenService:Create(CapsuleStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(90, 120, 165)}):Play()
            TweenService:Create(BtnEN, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            TweenService:Create(BtnVI, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(145, 160, 185)}):Play()
        end

        updateAllActive()
    end

    BtnVI.MouseButton1Click:Connect(function() switchMode("VI") end)
    BtnEN.MouseButton1Click:Connect(function() switchMode("EN") end)

    -- Kéo thả tự do kèm kẹp mép Viewport
    local dragging, dragStart, startPos = false, nil, nil
    Capsule.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Capsule.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    Capsule.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            local cam = workspace.CurrentCamera
            local maxX = cam and cam.ViewportSize.X - 180 or 800
            local maxY = cam and cam.ViewportSize.Y - 45 or 600

            local newX = math.clamp(startPos.X.Offset + delta.X, -maxX / 2, maxX / 2)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, maxY)

            Capsule.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
end

-- ==================== 6. BỘ QUÉT TẢI TRÌ HOÃN (DEFER SCANNER) ====================
task.delay(2.5, function()
    createLiquidCapsuleUI()

    local searchRoots = {
        gethui and gethui(),
        CoreGui,
        LocalPlayer:FindFirstChild("PlayerGui")
    }

    local function scanUIChunked(parent)
        local children = parent:GetChildren()
        for i, desc in ipairs(children) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                hookElement(desc)
                inspectAndApplySoftBlue(desc)
            end
            if i % 30 == 0 then RunService.RenderStepped:Wait() end
            scanUIChunked(desc)
        end
    end

    for _, root in ipairs(searchRoots) do
        if root then pcall(function() scanUIChunked(root) end) end
    end

    for _, root in ipairs(searchRoots) do
        if root then
            root.DescendantAdded:Connect(function(desc)
                task.defer(function()
                    if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                        hookElement(desc)
                        inspectAndApplySoftBlue(desc)
                    end
                end)
            end)
        end
    end
end)
