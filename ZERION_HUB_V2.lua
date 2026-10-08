-- ==============================================================================
-- ZERION HUB V2 - Renamed edition
-- Giữ nguyên script/chức năng/giao diện gốc; chỉ đổi tên hiển thị Chilli Hub
-- thành ZERION HUB V2.
-- ==============================================================================

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Nạp bản gốc
task.spawn(function()
    pcall(function()
        loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/robvxs24/freemium/refs/heads/main/chillihubv2.lua"
        ))()
    end)
end)

-- Đổi tên hiển thị sau khi giao diện gốc được tạo.
task.delay(3, function()
    local roots = {
        (gethui and gethui()) or nil,
        CoreGui,
        LocalPlayer:FindFirstChild("PlayerGui")
    }

    local function rename(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            return
        end

        local ok, text = pcall(function()
            return obj.Text
        end)

        if ok and type(text) == "string" then
            local newText = text
                :gsub("CHILLI HUB V2", "ZERION HUB V2")
                :gsub("Chilli Hub V2", "ZERION HUB V2")
                :gsub("Chilli Hub", "ZERION HUB V2")
                :gsub("CHILLI HUB", "ZERION HUB V2")

            if newText ~= text then
                pcall(function()
                    obj.Text = newText
                end)
            end
        end
    end

    local function scan(root)
        if not root then return end
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                rename(obj)
            end
            root.DescendantAdded:Connect(function(obj)
                task.defer(function()
                    rename(obj)
                end)
            end)
        end)
    end

    for _, root in ipairs(roots) do
        scan(root)
    end
end)
