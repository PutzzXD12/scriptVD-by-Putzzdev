-- ============================================
-- VD PUTZZDEV V3 - CLASSIC EDITION
-- Tampilan GUI kayak awal (semua tombol)
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==================== SETUP GUI ====================
local guiName = "VD_Putzzdev_V3"
local pg = player:WaitForChild("PlayerGui")

if pg:FindFirstChild(guiName) then pg[guiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = pg
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 200, 0, 450)
main.Position = UDim2.new(0.5, -100, 0.5, -225)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.Parent = screenGui
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

main.BackgroundTransparency = 1
main.Position = UDim2.new(0.5, -100, 0.5, -245)
TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0,
    Position = UDim2.new(0.5, -100, 0.5, -225)
}):Play()

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
title.Text = "VD PUTZZDEV"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame", main)
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, -12, 1, -58)
scroll.Position = UDim2.new(0, 6, 0, 42)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
end)

-- ==================== FUNGSI BUTTON ====================
local function makeButton(text, parent, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 34)
    b.BackgroundColor3 = color or Color3.fromRGB(44, 44, 44)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(240, 240, 240)
    b.AutoButtonColor = false
    b.Text = text
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.Parent = parent
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(66, 66, 66)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundColor3 = color or Color3.fromRGB(44, 44, 44)}):Play()
    end)
    return b
end

-- ==================== VARIABEL ====================
local highlights = {}
local noclipConn = nil
local noclipEnabled = false
local flyConn = nil
local flyBodyVel = nil
local flyEnabled = false
local antiDamageConn = nil
local antiDamageEnabled = false
local noFogEnabled = false
local invisibleMapEnabled = false
local smartHitboxEnabled = false
local smartProxies = {}
local autoRepairRunning = false

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
        if (nameLower:find("generator") or nameLower:find("gen") or nameLower:find("gene")) and obj:IsA("BasePart") then
            table.insert(matches, obj)
        end
    end
    return matches
end

local function collectHooks()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name or "")
        if (nameLower:find("hook") or nameLower:find("hookpoint")) and obj:IsA("BasePart") then
            table.insert(matches, obj)
        end
    end
    return matches
end

local function collectGates()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name or "")
        if (nameLower:find("gate") or nameLower:find("door") or nameLower:find("exit")) and obj:IsA("BasePart") then
            table.insert(matches, obj)
        end
    end
    return matches
end

local function collectPallets()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local nameLower = string.lower(obj.Name or "")
        if (nameLower:find("pallet") or nameLower:find("barrier")) and obj:IsA("BasePart") then
            table.insert(matches, obj)
        end
    end
    return matches
end

local function safeTeleportTo(part)
    local char = player.Character
    if not char or not part then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
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

-- ==================== BUTTON FITUR ====================
-- SECTION ESP
makeButton("━━━ ESP ━━━", scroll, Color3.fromRGB(80, 80, 100))

makeButton("ESP Generator", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, gen in ipairs(collectGenerators()) do
        highlights[gen] = createHighlight(gen, Color3.fromRGB(255, 200, 0))
    end
end)

makeButton("ESP Player", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character then
            highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0, 150, 255))
        end
    end
end)

makeButton("ESP Killer", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, pl in ipairs(Players:GetPlayers()) do
        local nameLower = string.lower(pl.Name or "")
        if pl ~= player and pl.Character and (killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")]) then
            highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255, 0, 0))
        end
    end
end)

makeButton("ESP Hook", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, hook in ipairs(collectHooks()) do
        highlights[hook] = createHighlight(hook, Color3.fromRGB(255, 255, 0))
    end
end)

makeButton("ESP Gate", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, gate in ipairs(collectGates()) do
        highlights[gate] = createHighlight(gate, Color3.fromRGB(255, 255, 255))
    end
end)

makeButton("ESP Pallet", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, pallet in ipairs(collectPallets()) do
        highlights[pallet] = createHighlight(pallet, Color3.fromRGB(0, 255, 255))
    end
end)

makeButton("ESP All", scroll).MouseButton1Click:Connect(function()
    clearHighlights()
    for _, gen in ipairs(collectGenerators()) do
        highlights[gen] = createHighlight(gen, Color3.fromRGB(255, 200, 0))
    end
    for _, hook in ipairs(collectHooks()) do
        highlights[hook] = createHighlight(hook, Color3.fromRGB(255, 255, 0))
    end
    for _, gate in ipairs(collectGates()) do
        highlights[gate] = createHighlight(gate, Color3.fromRGB(255, 255, 255))
    end
    for _, pallet in ipairs(collectPallets()) do
        highlights[pallet] = createHighlight(pallet, Color3.fromRGB(0, 255, 255))
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character then
            highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0, 150, 255))
        end
    end
end)

makeButton("Clear ESP", scroll, Color3.fromRGB(80, 50, 50)).MouseButton1Click:Connect(function()
    clearHighlights()
end)

-- SECTION TELEPORT
makeButton("━━━ TELEPORT ━━━", scroll, Color3.fromRGB(80, 80, 100))

makeButton("Teleport ke Generator (Random)", scroll).MouseButton1Click:Connect(function()
    local gens = collectGenerators()
    if #gens > 0 then safeTeleportTo(gens[math.random(1, #gens)]) end
end)

makeButton("Teleport ke Generator Terdekat", scroll).MouseButton1Click:Connect(function()
    local nearest = getNearestGenerator()
    if nearest then safeTeleportTo(nearest) end
end)

makeButton("Teleport ke Hook (Random)", scroll).MouseButton1Click:Connect(function()
    local hooks = collectHooks()
    if #hooks > 0 then safeTeleportTo(hooks[math.random(1, #hooks)]) end
end)

makeButton("Teleport ke Gate (Random)", scroll).MouseButton1Click:Connect(function()
    local gates = collectGates()
    if #gates > 0 then safeTeleportTo(gates[math.random(1, #gates)]) end
end)

makeButton("Teleport ke Player (Random)", scroll).MouseButton1Click:Connect(function()
    local pool = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(pool, pl)
        end
    end
    if #pool > 0 then
        local target = pool[math.random(1, #pool)]
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then safeTeleportTo(hrp) end
    end
end)

-- SECTION AUTO
makeButton("━━━ AUTO ━━━", scroll, Color3.fromRGB(80, 80, 100))

-- Auto Repair (toggle style tapi tombol)
local autoRepairEnabled = false
local autoRepairBtn = makeButton("Auto Repair: OFF", scroll)
autoRepairBtn.MouseButton1Click:Connect(function()
    autoRepairEnabled = not autoRepairEnabled
    autoRepairBtn.Text = autoRepairEnabled and "Auto Repair: ON" or "Auto Repair: OFF"
    autoRepairBtn.BackgroundColor3 = autoRepairEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
    if autoRepairEnabled then
        coroutine.wrap(function()
            while autoRepairEnabled do
                task.wait(0.3)
                local char = player.Character
                if not char then continue end
                local nearest = getNearestGenerator()
                if nearest then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - nearest.Position).Magnitude > 15 then
                        safeTeleportTo(nearest)
                        task.wait(0.5)
                    end
                    local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or 
                                  ReplicatedStorage:FindFirstChild("Interact") or
                                  ReplicatedStorage:FindFirstChild("Repair")
                    if remote then
                        pcall(function() remote:FireServer("Interact", nearest) end)
                    end
                    task.wait(1)
                end
            end
        end)()
    end
end)

-- SECTION MOVEMENT
makeButton("━━━ MOVEMENT ━━━", scroll, Color3.fromRGB(80, 80, 100))

-- WalkSpeed Slider
local speedContainer = Instance.new("Frame", scroll)
speedContainer.Size = UDim2.new(1, -12, 0, 50)
speedContainer.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
Instance.new("UICorner", speedContainer).CornerRadius = UDim.new(0, 6)

local speedLabel = Instance.new("TextLabel", speedContainer)
speedLabel.Size = UDim2.new(1, -16, 0, 20)
speedLabel.Position = UDim2.new(0, 8, 0, 4)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "WalkSpeed: 16"
speedLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left

local speedSlider = Instance.new("TextButton", speedContainer)
speedSlider.Size = UDim2.new(1, -16, 0, 20)
speedSlider.Position = UDim2.new(0, 8, 0, 26)
speedSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedSlider.Text = "───────────"
speedSlider.TextColor3 = Color3.fromRGB(200, 200, 200)
Instance.new("UICorner", speedSlider).CornerRadius = UDim.new(0, 4)

local currentSpeed = 16
local draggingSpeed = false
speedSlider.MouseButton1Down:Connect(function() draggingSpeed = true end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSpeed = false end
end)
RunService.RenderStepped:Connect(function()
    if draggingSpeed and speedSlider.AbsolutePosition then
        local mousePos = UserInputService:GetMouseLocation()
        local percent = math.clamp((mousePos.X - speedSlider.AbsolutePosition.X) / speedSlider.AbsoluteSize.X, 0, 1)
        currentSpeed = math.floor(16 + (percent * 334))
        speedLabel.Text = "WalkSpeed: " .. currentSpeed
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = currentSpeed end
    end
end)

-- Noclip (toggle style)
local noclipBtn = makeButton("Noclip: OFF", scroll)
noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
    noclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
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
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    end
end)

-- Fly (toggle style)
local flyBtn = makeButton("Fly: OFF", scroll)
flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    flyBtn.Text = flyEnabled and "Fly: ON" or "Fly: OFF"
    flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
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
    else
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if hum then hum.PlatformStand = false end
    end
end)

-- SECTION ANTI
makeButton("━━━ ANTI ━━━", scroll, Color3.fromRGB(80, 80, 100))

-- Anti Damage (toggle style)
local antiDamageBtn = makeButton("Anti Damage: OFF", scroll)
antiDamageBtn.MouseButton1Click:Connect(function()
    antiDamageEnabled = not antiDamageEnabled
    antiDamageBtn.Text = antiDamageEnabled and "Anti Damage: ON" or "Anti Damage: OFF"
    antiDamageBtn.BackgroundColor3 = antiDamageEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
    if antiDamageEnabled and not antiDamageConn then
        antiDamageConn = RunService.Heartbeat:Connect(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end)
    elseif not antiDamageEnabled and antiDamageConn then
        antiDamageConn:Disconnect()
        antiDamageConn = nil
    end
end)

makeButton("Anti Stun (Tahan)", scroll).MouseButton1Click:Connect(function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local conn = hum.StateChanged:Connect(function(_, new)
        if new == Enum.HumanoidStateType.PlatformStanding or new == Enum.HumanoidStateType.Physics then
            hum.Sit = false
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    task.wait(8)
    if conn and conn.Connected then conn:Disconnect() end
end)

makeButton("Heal Full", scroll).MouseButton1Click:Connect(function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = hum.MaxHealth end
end)

-- SECTION UTILITY
makeButton("━━━ UTILITY ━━━", scroll, Color3.fromRGB(80, 80, 100))

makeButton("Fast Cooldown", scroll).MouseButton1Click:Connect(function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local cds = plr.Character:FindFirstChild("Cooldowns")
            if cds then
                for _, v in ipairs(cds:GetChildren()) do
                    if v:IsA("NumberValue") then v.Value = 0 end
                end
            end
        end
    end
end)

makeButton("Get Off Sling", scroll).MouseButton1Click:Connect(function()
    local char = player.Character
    if not char then return end
    for _, joint in ipairs(char:GetDescendants()) do
        if joint:IsA("HingeConstraint") or joint:IsA("RodConstraint") then
            joint.Enabled = false
        end
    end
    local seat = char:FindFirstChildWhichIsA("VehicleSeat", true)
    if seat then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Sit = false end
    end
end)

-- No Fog (toggle style)
local noFogBtn = makeButton("No Fog: OFF", scroll)
noFogBtn.MouseButton1Click:Connect(function()
    noFogEnabled = not noFogEnabled
    noFogBtn.Text = noFogEnabled and "No Fog: ON" or "No Fog: OFF"
    noFogBtn.BackgroundColor3 = noFogEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
    if noFogEnabled then
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
    else
        Lighting.FogStart = 0
        Lighting.FogEnd = 1000
    end
end)

-- Invisible Map (toggle style)
local invMapBtn = makeButton("Invisible Map: OFF", scroll)
invMapBtn.MouseButton1Click:Connect(function()
    invisibleMapEnabled = not invisibleMapEnabled
    invMapBtn.Text = invisibleMapEnabled and "Invisible Map: ON" or "Invisible Map: OFF"
    invMapBtn.BackgroundColor3 = invisibleMapEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
            v.LocalTransparencyModifier = invisibleMapEnabled and 1 or 0
        end
    end
end)

makeButton("No Shadow", scroll).MouseButton1Click:Connect(function()
    Lighting.GlobalShadows = false
    for _, v in ipairs(Lighting:GetDescendants()) do
        if v:IsA("ShadowMapLight") or v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("DirectionalLight") then
            v.Shadows = false
        end
    end
end)

makeButton("Morning", scroll).MouseButton1Click:Connect(function()
    Lighting.ClockTime = 7
end)

makeButton("Afternoon", scroll).MouseButton1Click:Connect(function()
    Lighting.ClockTime = 17
end)

makeButton("No Hitbox", scroll).MouseButton1Click:Connect(function()
    local char = player.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanTouch = false end
    end
end)

-- Smart Hitbox (toggle style)
local smartHitboxBtn = makeButton("Smart Hitbox: OFF", scroll)
smartHitboxBtn.MouseButton1Click:Connect(function()
    smartHitboxEnabled = not smartHitboxEnabled
    smartHitboxBtn.Text = smartHitboxEnabled and "Smart Hitbox: ON" or "Smart Hitbox: OFF"
    smartHitboxBtn.BackgroundColor3 = smartHitboxEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(44, 44, 44)
    
    if smartHitboxEnabled then
        for _, pl in ipairs(Players:GetPlayers()) do
            local nameLower = string.lower(pl.Name or "")
            if pl ~= player and pl.Character and (killerKeywords[nameLower] or killerKeywords[string.lower(pl.DisplayName or "")]) then
                local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not smartProxies[pl] then
                    local proxy = Instance.new("Part")
                    proxy.Name = "SmartHitboxProxy"
                    proxy.Size = Vector3.new(4, 4, 4)
                    proxy.Transparency = 1
                    proxy.CanCollide = false
                    proxy.Anchored = false
                    proxy.Massless = true
                    proxy.CFrame = hrp.CFrame
                    proxy.Parent = Workspace
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = proxy
                    weld.Part1 = hrp
                    weld.Parent = proxy
                    smartProxies[pl] = proxy
                end
            end
        end
    else
        for _, proxy in pairs(smartProxies) do
            if proxy and proxy.Parent then proxy:Destroy() end
        end
        smartProxies = {}
    end
end)

makeButton("Spawn Jump Button", scroll).MouseButton1Click:Connect(function()
    if screenGui:FindFirstChild("JumpButton") then return end
    local jb = Instance.new("TextButton", screenGui)
    jb.Name = "JumpButton"
    jb.Size = UDim2.new(0, 80, 0, 44)
    jb.Position = UDim2.new(1, -98, 1, -68)
    jb.AnchorPoint = Vector2.new(1, 1)
    jb.BackgroundColor3 = Color3.fromRGB(48, 48, 48)
    jb.Font = Enum.Font.GothamBold
    jb.Text = "Jump"
    jb.TextColor3 = Color3.fromRGB(240, 240, 240)
    Instance.new("UICorner", jb).CornerRadius = UDim.new(0, 8)
    jb.MouseButton1Click:Connect(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Jump = true end
    end)
end)

makeButton("Shift Lock (8s)", scroll).MouseButton1Click:Connect(function()
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    local conn = RunService.RenderStepped:Connect(function()
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and camera then
            local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
            if look.Magnitude > 0.001 then
                hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
            end
        end
    end)
    task.wait(8)
    if conn and conn.Connected then conn:Disconnect() end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end)

makeButton("Rejoin Game", scroll, Color3.fromRGB(80, 50, 50)).MouseButton1Click:Connect(function()
    TeleportService:Teleport(game.PlaceId)
end)

makeButton("Server Hop", scroll, Color3.fromRGB(80, 50, 50)).MouseButton1Click:Connect(function()
    local Http = game:GetService("HttpService")
    pcall(function()
        local response = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
        local data = Http:JSONDecode(response)
        local servers = {}
        for _, server in pairs(data.data) do
            if server.playing < server.maxPlayers then
                table.insert(servers, server.id)
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
        end
    end)
end)

-- ==================== MINIMIZE BUTTON ====================
local minimizeBtn = Instance.new("TextButton", main)
minimizeBtn.Size = UDim2.new(0, 28, 0, 24)
minimizeBtn.Position = UDim2.new(1, -34, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local isMin = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0, 140, 0, 40)}):Play()
        scroll.Visible = false
        title.Text = "VD"
    else
        TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0, 200, 0, 450)}):Play()
        scroll.Visible = true
        title.Text = "VD PUTZZDEV"
    end
end)

-- ==================== CLEANUP ====================
player.CharacterRemoving:Connect(function()
    for _, p in pairs(smartProxies) do
        if p and p.Parent then p:Destroy() end
    end
    smartProxies = {}
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if antiDamageConn then antiDamageConn:Disconnect() antiDamageConn = nil end
end)

print("VD PUTZZDEV - Script Loaded!")