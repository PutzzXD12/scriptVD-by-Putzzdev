-- ============================================
-- ANCH HAX V2.0 | Violence District Script Hub
-- HP FRIENDLY | GUI Langsung Muncul
-- Auto Repair Generator WORK!
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ==================== LOAD RAYFIELD ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== VARIABEL ====================
local highlights = {}
local noclipConn = nil
local flyConn = nil
local flyBodyVel = nil
local antiDamageConn = nil
local autoRepairRunning = false
local selectedTarget = nil

local killerKeywords = {
    ["abysswalker"] = true, ["hidden"] = true, ["jason"] = true,
    ["jeff"] = true, ["masked"] = true, ["myers"] = true,
    ["killer"] = true, ["slasher"] = true
}

-- ==================== FUNGSI UTILITY ====================
local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local h = target:FindFirstChildOfClass("Highlight")
    if h then
        h.FillColor = color
        return h
    end
    h = Instance.new("Highlight")
    h.FillColor = color
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.Parent = target
    return h
end

local function clearHighlights()
    for _, v in pairs(highlights) do
        if v and v.Parent then v:Destroy() end
    end
    highlights = {}
end

local function collectGenerators()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name or "")
        if (nameLower:find("generator") or nameLower:find("gen") or nameLower:find("gene")) then
            if obj:IsA("BasePart") then
                table.insert(matches, obj)
            elseif obj:IsA("Model") and obj.PrimaryPart then
                table.insert(matches, obj.PrimaryPart)
            end
        end
    end
    return matches
end

local function getNearestGenerator()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest, minDist = nil, math.huge
    for _, gen in ipairs(collectGenerators()) do
        local dist = (hrp.Position - gen.Position).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = gen
        end
    end
    return nearest
end

local function safeTeleportTo(part)
    local char = player.Character
    if not char or not part then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
end

-- ==================== AUTO REPAIR (3 METODE) ====================
local function tryRepairMethod1(genPart)
    local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or 
                   ReplicatedStorage:FindFirstChild("Interact") or
                   ReplicatedStorage:FindFirstChild("Repair") or
                   ReplicatedStorage:FindFirstChild("Generator")
    if remote then
        pcall(function() 
            remote:FireServer("Interact", genPart)
            remote:FireServer(genPart)
            remote:FireServer("Repair", genPart)
        end)
        return true
    end
    return false
end

local function tryRepairMethod2(genPart)
    local prompt = genPart.Parent and genPart.Parent:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then
        for _, child in ipairs(genPart:GetDescendants()) do
            if child:IsA("ProximityPrompt") then
                prompt = child
                break
            end
        end
    end
    if prompt then
        pcall(function() prompt:InputHoldBegin() end)
        return true
    end
    return false
end

local function tryRepairMethod3(genPart)
    local click = genPart:FindFirstChildWhichIsA("ClickDetector")
    if click then
        pcall(function() click:Click() end)
        return true
    end
    return false
end

local function startAutoRepair()
    if autoRepairRunning then return end
    autoRepairRunning = true
    
    coroutine.wrap(function()
        while autoRepairRunning do
            task.wait(0.3)
            local char = player.Character
            if not char then continue end
            local nearest = getNearestGenerator()
            if not nearest then continue end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            if (hrp.Position - nearest.Position).Magnitude > 15 then
                safeTeleportTo(nearest)
                task.wait(0.3)
            end
            
            tryRepairMethod1(nearest)
            tryRepairMethod2(nearest)
            tryRepairMethod3(nearest)
            task.wait(0.8)
        end
    end)()
end

local function stopAutoRepair()
    autoRepairRunning = false
end

-- ==================== UPDATE PLAYER LIST ====================
local function updatePlayerList()
    local list = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player then
            table.insert(list, pl.Name)
        end
    end
    return list
end

-- ==================== GUI WINDOW (HP FRIENDLY) ====================
local Window = Rayfield:CreateWindow({
    Name = "ANCH HAX | V2.0",
    Icon = 0,
    LoadingTitle = "ANCH HAX",
    LoadingSubtitle = "by ANCH",
    Theme = "Dark",
    -- HAPUS ToggleUIKeybind biar gak perlu tekan K
})

-- ==================== TAB INFO ====================
local InfoTab = Window:CreateTab("INFO", nil)

InfoTab:CreateParagraph({
    Title = "ANCH HAX V2.0",
    Content = "Script for Violence District\n\nCreated by: ANCH\nCredits: Kraftz47, dahuku_yk, lommn1234\n\nTekan tombol di layar untuk menggunakan fitur",
})

-- ==================== TAB GENERAL ====================
local GeneralTab = Window:CreateTab("GENERAL", nil)

GeneralTab:CreateDropdown({
    Name = "Select Target",
    Options = updatePlayerList(),
    CurrentOption = "None",
    Callback = function(Option)
        selectedTarget = Option
        Rayfield:Notify({Title = "ANCH", Content = "Target: " .. (selectedTarget or "None"), Duration = 2})
    end,
})

GeneralTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        local newList = updatePlayerList()
        Rayfield:Notify({Title = "ANCH", Content = "Found " .. #newList .. " players", Duration = 2})
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then
                -- Refresh dropdown logic
            end
        end
    end,
})

GeneralTab:CreateButton({
    Name = "Teleport to Survivor",
    Callback = function()
        if not selectedTarget or selectedTarget == "None" then
            Rayfield:Notify({Title = "Error", Content = "Select target first!", Duration = 2})
            return
        end
        local target = Players:FindFirstChild(selectedTarget)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            safeTeleportTo(target.Character.HumanoidRootPart)
            Rayfield:Notify({Title = "ANCH", Content = "Teleported to " .. selectedTarget, Duration = 2})
        end
    end,
})

GeneralTab:CreateButton({
    Name = "Teleport to Killer",
    Callback = function()
        for _, pl in ipairs(Players:GetPlayers()) do
            local nameLower = string.lower(pl.Name or "")
            if pl ~= player and pl.Character and (killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")]) then
                local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    safeTeleportTo(hrp)
                    Rayfield:Notify({Title = "ANCH", Content = "Teleported to Killer: " .. pl.Name, Duration = 2})
                    return
                end
            end
        end
        Rayfield:Notify({Title = "Error", Content = "Killer not found!", Duration = 2})
    end,
})

GeneralTab:CreateButton({
    Name = "Body Lock",
    Callback = function()
        if not selectedTarget or selectedTarget == "None" then
            Rayfield:Notify({Title = "Error", Content = "Select target first!", Duration = 2})
            return
        end
        local target = Players:FindFirstChild(selectedTarget)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local char = player.Character
                local playerHrp = char and char:FindFirstChild("HumanoidRootPart")
                if playerHrp then
                    playerHrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
                    Rayfield:Notify({Title = "ANCH", Content = "Body Lock on " .. selectedTarget, Duration = 2})
                end
            end
        end
    end,
})

-- ==================== TAB VISUALS ====================
local VisualsTab = Window:CreateTab("VISUALS", nil)

VisualsTab:CreateButton({
    Name = "ESP Generator",
    Callback = function()
        clearHighlights()
        for _, gen in ipairs(collectGenerators()) do
            highlights[gen] = createHighlight(gen, Color3.fromRGB(255, 200, 0))
        end
        Rayfield:Notify({Title = "ANCH", Content = "ESP Generator ON", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "ESP Survivor",
    Callback = function()
        clearHighlights()
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character then
                local nameLower = string.lower(pl.Name or "")
                if not (killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")]) then
                    highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
        Rayfield:Notify({Title = "ANCH", Content = "ESP Survivor ON", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "ESP Killer",
    Callback = function()
        clearHighlights()
        for _, pl in ipairs(Players:GetPlayers()) do
            local nameLower = string.lower(pl.Name or "")
            if pl ~= player and pl.Character and (killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")]) then
                highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255, 0, 0))
            end
        end
        Rayfield:Notify({Title = "ANCH", Content = "ESP Killer ON", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "ESP All",
    Callback = function()
        clearHighlights()
        for _, gen in ipairs(collectGenerators()) do
            highlights[gen] = createHighlight(gen, Color3.fromRGB(255, 200, 0))
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character then
                local nameLower = string.lower(pl.Name or "")
                if killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")] then
                    highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255, 0, 0))
                else
                    highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0, 150, 255))
                end
            end
        end
        Rayfield:Notify({Title = "ANCH", Content = "ESP All ON", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "Clear ESP",
    Callback = function()
        clearHighlights()
        Rayfield:Notify({Title = "ANCH", Content = "ESP Cleared", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "No Fog",
    Callback = function()
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Rayfield:Notify({Title = "ANCH", Content = "No Fog ON", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "Morning",
    Callback = function()
        Lighting.ClockTime = 7
        Rayfield:Notify({Title = "ANCH", Content = "Morning", Duration = 2})
    end,
})

VisualsTab:CreateButton({
    Name = "Afternoon",
    Callback = function()
        Lighting.ClockTime = 17
        Rayfield:Notify({Title = "ANCH", Content = "Afternoon", Duration = 2})
    end,
})

-- ==================== TAB SETTINGS ====================
local SettingsTab = Window:CreateTab("SETTINGS", nil)

-- Auto Repair (WORK!)
local autoRepairEnabled = false
SettingsTab:CreateButton({
    Name = "START AUTO REPAIR",
    Callback = function()
        if not autoRepairEnabled then
            autoRepairEnabled = true
            startAutoRepair()
            Rayfield:Notify({Title = "ANCH", Content = "Auto Repair: ON (WORKING)", Duration = 3})
        else
            autoRepairEnabled = false
            stopAutoRepair()
            Rayfield:Notify({Title = "ANCH", Content = "Auto Repair: OFF", Duration = 2})
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Teleport to Generator",
    Callback = function()
        local nearest = getNearestGenerator()
        if nearest then
            safeTeleportTo(nearest)
            Rayfield:Notify({Title = "ANCH", Content = "Teleported to Generator", Duration = 2})
        else
            Rayfield:Notify({Title = "Error", Content = "No generator found", Duration = 2})
        end
    end,
})

SettingsTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 350},
    Increment = 1,
    Suffix = "Studs/s",
    CurrentValue = 16,
    Callback = function(Value)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Value end
    end,
})

-- Noclip Toggle
local noclipEnabled = false
SettingsTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        if noclipEnabled then
            if not noclipConn then
                noclipConn = RunService.Stepped:Connect(function()
                    if player.Character then
                        for _, part in ipairs(player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end
            Rayfield:Notify({Title = "ANCH", Content = "Noclip ON", Duration = 2})
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
            Rayfield:Notify({Title = "ANCH", Content = "Noclip OFF", Duration = 2})
        end
    end,
})

-- Fly Toggle
local flyEnabled = false
SettingsTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        flyEnabled = Value
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if flyEnabled then
            if not hrp or not hum then return end
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBodyVel.Velocity = Vector3.new(0, 0, 0)
            flyBodyVel.Parent = hrp
            hum.PlatformStand = true
            
            flyConn = RunService.RenderStepped:Connect(function()
                if not flyEnabled or not flyBodyVel.Parent then return end
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    moveDir = moveDir + Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    moveDir = moveDir - Vector3.new(0, 1, 0)
                end
                if moveDir.Magnitude > 0 then
                    flyBodyVel.Velocity = moveDir.Unit * 70
                else
                    flyBodyVel.Velocity = Vector3.new(0, 0, 0)
                end
            end)
            Rayfield:Notify({Title = "ANCH", Content = "Fly ON (WASD + Space/Shift)", Duration = 2})
        else
            if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
            if flyConn then flyConn:Disconnect() flyConn = nil end
            if hum then hum.PlatformStand = false end
            Rayfield:Notify({Title = "ANCH", Content = "Fly OFF", Duration = 2})
        end
    end,
})

-- Anti Damage Toggle
local antiDamageEnabled = false
SettingsTab:CreateToggle({
    Name = "Anti Damage",
    CurrentValue = false,
    Callback = function(Value)
        antiDamageEnabled = Value
        if antiDamageEnabled and not antiDamageConn then
            antiDamageConn = RunService.Heartbeat:Connect(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.Health = hum.MaxHealth end
            end)
            Rayfield:Notify({Title = "ANCH", Content = "Anti Damage ON", Duration = 2})
        elseif not antiDamageEnabled and antiDamageConn then
            antiDamageConn:Disconnect()
            antiDamageConn = nil
            Rayfield:Notify({Title = "ANCH", Content = "Anti Damage OFF", Duration = 2})
        end
    end,
})

SettingsTab:CreateButton({
    Name = "Heal Full",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
        Rayfield:Notify({Title = "ANCH", Content = "Healed!", Duration = 2})
    end,
})

SettingsTab:CreateButton({
    Name = "Fast Cooldown",
    Callback = function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local cds = plr.Character:FindFirstChild("Cooldowns")
                if cds then
                    for _, v in ipairs(cds:GetChildren()) do
                        if v:IsA("NumberValue") then
                            v.Value = 0
                        end
                    end
                end
            end
        end
        Rayfield:Notify({Title = "ANCH", Content = "Cooldowns reset", Duration = 2})
    end,
})

SettingsTab:CreateButton({
    Name = "Rejoin Game",
    Callback = function()
        TeleportService:Teleport(game.PlaceId)
    end,
})

-- ==================== NOTIFIKASI LOAD ====================
Rayfield:Notify({
    Title = "ANCH HAX V2.0",
    Content = "Script Loaded! GUI langsung muncul",
    Duration = 4,
})