-- ============================================
-- VD PUTZZDEV
-- Mobile Version - No Keyboard Required
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "VD PUTZZDEV",
    Icon = 0,
    LoadingTitle = "Violence District",
    LoadingSubtitle = "Mobile Script Hub",
    Theme = "Dark",
})

-- ==================== TAB ESP ====================
local ESPTab = Window:CreateTab("ESP", nil)

ESPTab:CreateSection("ESP Settings")

local espEnabled = false
local espObjects = {}
local killerESP = false
local playerESP = false
local generatorESP = false
local gateESP = false
local hookESP = false
local palletESP = false

local function createESP(part, color, text)
    if not espEnabled then return nil end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Putzzdev"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 150, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = color
    frame.BorderSize = 0
    frame.Parent = billboard
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Text = text or ""
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = frame
    
    billboard.Parent = part
    return billboard
end

local function updateESP()
    while espEnabled do
        task.wait(0.15)
        for _, obj in pairs(espObjects) do
            pcall(function() if obj and obj.Parent then obj:Destroy() end end)
        end
        espObjects = {}
        
        if killerESP then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local esp = createESP(hrp, Color3.new(1, 0, 0), "KILLER")
                        if esp then table.insert(espObjects, esp) end
                    end
                end
            end
        end
        
        if playerESP then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local esp = createESP(hrp, Color3.new(0, 1, 0), "SURVIVOR")
                        if esp then table.insert(espObjects, esp) end
                    end
                end
            end
        end
        
        if generatorESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) and obj:IsA("BasePart") then
                    local esp = createESP(obj, Color3.new(1, 0.5, 0), "GENERATOR")
                    if esp then table.insert(espObjects, esp) end
                end
            end
        end
        
        if gateESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj.Name:lower():find("gate") or obj.Name:lower():find("door") or obj.Name:lower():find("exit")) and obj:IsA("BasePart") then
                    local esp = createESP(obj, Color3.new(1, 1, 1), "GATE")
                    if esp then table.insert(espObjects, esp) end
                end
            end
        end
        
        if hookESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("hook") and obj:IsA("BasePart") then
                    local esp = createESP(obj, Color3.new(0.8, 0, 0), "HOOK")
                    if esp then table.insert(espObjects, esp) end
                end
            end
        end
        
        if palletESP then
            for _, obj in pairs(workspace:GetDescendants()) do
                if (obj.Name:lower():find("pallet") or obj.Name:lower():find("barrier")) and obj:IsA("BasePart") then
                    local esp = createESP(obj, Color3.new(1, 1, 0), "PALLET")
                    if esp then table.insert(espObjects, esp) end
                end
            end
        end
    end
end

ESPTab:CreateToggle({
    Name = "ESP Killer",
    CurrentValue = false,
    Callback = function(Value)
        killerESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Player",
    CurrentValue = false,
    Callback = function(Value)
        playerESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Generator",
    CurrentValue = false,
    Callback = function(Value)
        generatorESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Gate",
    CurrentValue = false,
    Callback = function(Value)
        gateESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Hook",
    CurrentValue = false,
    Callback = function(Value)
        hookESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "ESP Pallet",
    CurrentValue = false,
    Callback = function(Value)
        palletESP = Value
        if Value and not espEnabled then
            espEnabled = true
            coroutine.wrap(updateESP)()
        end
    end,
})

-- ==================== TAB AUTO ====================
local AutoTab = Window:CreateTab("AUTO", nil)

local autoRepairEnabled = false

local function autoRepairLoop()
    while autoRepairEnabled do
        task.wait(0.3)
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character then continue end
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
                local genPart = obj:IsA("Model") and obj.PrimaryPart or (obj:IsA("BasePart") and obj)
                if genPart and character:FindFirstChild("HumanoidRootPart") then
                    local distance = (character.HumanoidRootPart.Position - genPart.Position).Magnitude
                    if distance < 15 then
                        pcall(function()
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvent") or 
                                         game:GetService("ReplicatedStorage"):FindFirstChild("Interact") or
                                         game:GetService("ReplicatedStorage"):FindFirstChild("Repair")
                            if remote then
                                remote:FireServer("Interact", obj)
                            end
                        end)
                        task.wait(1)
                    end
                end
            end
        end
    end
end

AutoTab:CreateToggle({
    Name = "Auto Repair Generator",
    CurrentValue = false,
    Callback = function(Value)
        autoRepairEnabled = Value
        if Value then
            coroutine.wrap(autoRepairLoop)()
        end
        Rayfield:Notify({Title = "VD PUTZZDEV", Content = Value and "Auto Repair ON" or "Auto Repair OFF", Duration = 2})
    end,
})

AutoTab:CreateButton({
    Name = "Teleport ke Generator Terdekat",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character then return end
        
        local nearest = nil
        local minDist = math.huge
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if (obj.Name:lower():find("generator") or obj.Name:lower():find("gen")) then
                local genPart = obj:IsA("Model") and obj.PrimaryPart or (obj:IsA("BasePart") and obj)
                if genPart then
                    local dist = (character.HumanoidRootPart.Position - genPart.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = genPart
                    end
                end
            end
        end
        
        if nearest then
            character.HumanoidRootPart.CFrame = nearest.CFrame + Vector3.new(0, 2, 0)
            Rayfield:Notify({Title = "VD PUTZZDEV", Content = "Teleport ke Generator", Duration = 2})
        else
            Rayfield:Notify({Title = "VD PUTZZDEV", Content = "Generator tidak ditemukan", Duration = 2})
        end
    end,
})

-- ==================== TAB MOVEMENT ====================
local MoveTab = Window:CreateTab("MOVEMENT", nil)

MoveTab:CreateSection("Movement Settings")

MoveTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 350},
    Increment = 1,
    Suffix = "Studs/s",
    CurrentValue = 16,
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Value end
        end
    end,
})

local flying = false
local bodyVel = nil
local UserInputService = game:GetService("UserInputService")

MoveTab:CreateButton({
    Name = "Toggle Fly",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not hum then return end
        
        flying = not flying
        
        if flying then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            bodyVel.Velocity = Vector3.new(0, 0, 0)
            bodyVel.Parent = hrp
            hum.PlatformStand = true
            
            local runService = game:GetService("RunService")
            local camera = workspace.CurrentCamera
            
            runService.RenderStepped:Connect(function()
                if not flying or not bodyVel.Parent then 
                    if bodyVel then bodyVel:Destroy() end
                    return 
                end
                
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
                
                bodyVel.Velocity = moveDir.Unit * 70
            end)
            Rayfield:Notify({Title = "VD PUTZZDEV", Content = "Fly ON", Duration = 2})
        else
            if bodyVel then bodyVel:Destroy() end
            hum.PlatformStand = false
            Rayfield:Notify({Title = "VD PUTZZDEV", Content = "Fly OFF", Duration = 2})
        end
    end,
})

local noclipEnabled = false
MoveTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
        Rayfield:Notify({Title = "VD PUTZZDEV", Content = Value and "Noclip ON" or "Noclip OFF", Duration = 2})
    end,
})

game:GetService("RunService").Stepped:Connect(function()
    if noclipEnabled then
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==================== TAB ANTI ====================
local AntiTab = Window:CreateTab("ANTI", nil)

local antiDamageEnabled = false

AntiTab:CreateToggle({
    Name = "Anti Damage (Invincible)",
    CurrentValue = false,
    Callback = function(Value)
        antiDamageEnabled = Value
        Rayfield:Notify({Title = "VD PUTZZDEV", Content = Value and "Anti Damage ON" or "Anti Damage OFF", Duration = 2})
    end,
})

game:GetService("RunService").Heartbeat:Connect(function()
    if antiDamageEnabled then
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = hum.MaxHealth
                for _, v in pairs(character:GetChildren()) do
                    if v.Name:lower():find("damage") or v.Name:lower():find("hit") then
                        v:Destroy()
                    end
                end
            end
        end
    end
end)

-- ==================== TAB UTILITY ====================
local UtilTab = Window:CreateTab("UTILITY", nil)

UtilTab:CreateButton({
    Name = "Rejoin Game",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end,
})

UtilTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
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
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
            end
        end)
    end,
})

-- Notifikasi Loaded
Rayfield:Notify({
    Title = "VD PUTZZDEV",
    Content = "Script Loaded!",
    Duration = 3,
})