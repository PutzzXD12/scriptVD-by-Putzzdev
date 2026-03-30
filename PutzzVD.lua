-- ============================================
-- VD PUTZZDEV | RAYFIELD EDITION (FIX AUTO REPAIR)
-- Fitur: Auto Repair sampai semua generator selesai
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ==================== LOAD RAYFIELD ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ==================== VARIABEL GLOBAL ====================
local killerNames = {["abysswalker"]=true,["hidden"]=true,["jason"]=true,["jeff"]=true,["masked"]=true,["myers"]=true}
local ANTI_DAMAGE_DISTANCE = 40
local DEV_ONLY = (RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId))

local highlights = {}
local smartProxies = {}
local noclipConn = nil
local antiDamageEnabled = false
local lastHealth = nil
local antiConn = nil

-- ESP Line (Drip)
local espLineEnabled = false
local espLines = {}
local espLineColor = Color3.fromRGB(255,255,255)

-- Auto Repair
local autoRepairEnabled = false
local autoRepairThread = nil
local autoSkillCheckEnabled = false

-- ==================== FUNGSI UTILITY ====================
local function findRootForDesc(desc)
    if not desc then return nil end
    if desc:IsA("BasePart") then return desc end
    if desc:IsA("Model") then
        return desc.PrimaryPart or desc:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

local function createHighlight(target, color)
    if not target or not target.Parent then return nil end
    local h = target:FindFirstChildOfClass("Highlight")
    if h then
        h.FillColor = color
        h.OutlineColor = Color3.fromRGB(255,255,255)
        return h
    end
    h = Instance.new("Highlight")
    h.FillColor = color
    h.OutlineColor = Color3.fromRGB(255,255,255)
    h.Parent = target
    return h
end

local function clearHighlights()
    for _, v in pairs(highlights) do
        if v and v.Parent then v:Destroy() end
    end
    highlights = {}
end

-- Generator & Hook collection
local generatorNames = {["generator"]=true,["generator_old"]=true,["gene"]=true}
local hookNames = {["hookpoint"]=true,["hook"]=true,["hookmeat"]=true}
local generatorPrefix = "ge"
local hookPrefix = "ho"

local function collectGenerators()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if generatorNames[nameLower] or string.sub(nameLower, 1, #generatorPrefix) == generatorPrefix then
                local root = findRootForDesc(obj) or obj
                if root and root.Parent then
                    table.insert(matches, root)
                end
            end
        end
    end
    return matches
end

local function collectHooks()
    local matches = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local nameLower = string.lower(obj.Name)
            if hookNames[nameLower] or string.sub(nameLower, 1, #hookPrefix) == hookPrefix then
                local root = findRootForDesc(obj) or obj
                if root and root.Parent then
                    table.insert(matches, root)
                end
            end
        end
    end
    return matches
end

local function safeTeleportTo(part)
    local char = player.Character
    if not char or not part then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
end

-- ==================== ESP LINE (DRIP) ====================
local function createESPLine(plr)
    if plr == player then return end
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = espLineColor
    line.Visible = false
    espLines[plr] = line
end

local function updateESPLine()
    if not espLineEnabled then
        for _, line in pairs(espLines) do
            if line then line.Visible = false end
        end
        return
    end
    for pl, line in pairs(espLines) do
        local char = pl.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local pos, visible = camera:WorldToViewportPoint(hrp.Position)
            if visible then
                line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
end

for _, p in pairs(Players:GetPlayers()) do createESPLine(p) end
Players.PlayerAdded:Connect(createESPLine)
Players.PlayerRemoving:Connect(function(p)
    if espLines[p] then
        pcall(function() espLines[p]:Remove() end)
        espLines[p] = nil
    end
end)
RunService.RenderStepped:Connect(updateESPLine)

-- ==================== ANTI DAMAGE ==================
local function setupAntiDamage()
    if antiConn then antiConn:Disconnect() end
    antiConn = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                if hum.Health <= 0 then hum.Health = hum.MaxHealth end
            end
        end
    end)
end

local function disableAntiDamage()
    if antiConn then antiConn:Disconnect() antiConn = nil end
end

-- ==================== AUTO SKILL CHECK (Biar GAGAL PROOF) ==================
local function setupAutoSkillCheck()
    -- Hook ke remote event skill check (jika ada)
    local remote = ReplicatedStorage:FindFirstChild("SkillCheck") or ReplicatedStorage:FindFirstChild("GeneratorSkillCheck")
    if remote then
        local oldFunction
        oldFunction = remote.OnClientEvent
        remote.OnClientEvent = function(...)
            local args = {...}
            -- Otomatis sukses dengan mengirim respon sukses
            local successRemote = ReplicatedStorage:FindFirstChild("SkillCheckResult")
            if successRemote then
                successRemote:FireServer(true) -- true = sukses
            end
            if oldFunction then oldFunction(...) end
        end
    end
end

-- ==================== AUTO REPAIR GENERATOR (SAMPAI SELESAI) ==================
local function repairGenerator(genPart)
    if not genPart then return false end
    -- Coba berbagai metode interaksi
    local success = false
    -- 1. Remote event
    local remote = ReplicatedStorage:FindFirstChild("RemoteEvent") or
                   ReplicatedStorage:FindFirstChild("Interact") or
                   ReplicatedStorage:FindFirstChild("Repair")
    if remote then
        pcall(function() remote:FireServer("Interact", genPart) end)
        pcall(function() remote:FireServer(genPart) end)
        success = true
    end
    -- 2. ProximityPrompt
    local prompt = genPart:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt and genPart.Parent then prompt = genPart.Parent:FindFirstChildWhichIsA("ProximityPrompt") end
    if prompt then
        pcall(function() 
            prompt:InputHoldBegin()
            -- Simulasi hold selama 2 detik (agar repair jalan)
            task.wait(2)
            prompt:InputHoldEnd()
        end)
        success = true
    end
    -- 3. ClickDetector
    local click = genPart:FindFirstChildWhichIsA("ClickDetector")
    if click then
        pcall(function() click:Click() end)
        success = true
    end
    return success
end

-- Fungsi untuk mengecek apakah generator masih ada / belum selesai
local function isGeneratorActive(genPart)
    if not genPart or not genPart.Parent then return false end
    -- Cek apakah masih memiliki prompt atau partikel (indikator belum selesai)
    local prompt = genPart:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt and genPart.Parent then prompt = genPart.Parent:FindFirstChildWhichIsA("ProximityPrompt") end
    if prompt and prompt.Enabled then
        return true
    end
    -- Jika tidak ada prompt, mungkin sudah selesai
    return false
end

local function autoRepairLoop()
    while autoRepairEnabled do
        -- Kumpulkan generator yang masih aktif
        local allGens = collectGenerators()
        local activeGens = {}
        for _, gen in ipairs(allGens) do
            if isGeneratorActive(gen) then
                table.insert(activeGens, gen)
            end
        end
        
        if #activeGens == 0 then
            Rayfield:Notify({Title = "Auto Repair", Content = "Semua generator selesai!", Duration = 3})
            autoRepairEnabled = false
            break
        end
        
        -- Proses satu per satu
        for _, gen in ipairs(activeGens) do
            if not autoRepairEnabled then break end
            
            -- Teleport ke generator
            safeTeleportTo(gen)
            task.wait(0.5)
            
            -- Mulai repair
            repairGenerator(gen)
            
            -- Tunggu sampai generator ini selesai (atau maksimal 30 detik)
            local startTime = tick()
            while isGeneratorActive(gen) and (tick() - startTime) < 30 do
                task.wait(1)
                -- Ulangi repair setiap 2 detik agar tetap interaksi
                if (tick() - startTime) % 2 < 0.5 then
                    repairGenerator(gen)
                end
            end
            
            -- Notifikasi jika selesai
            if not isGeneratorActive(gen) then
                Rayfield:Notify({Title = "Auto Repair", Content = "Generator selesai!", Duration = 2})
            end
            task.wait(0.5)
        end
    end
    autoRepairThread = nil
end

-- ==================== GUI RAYFIELD ==================
local Window = Rayfield:CreateWindow({
    Name = "VD Putzzdev",
    Icon = 0,
    LoadingTitle = "Violence District",
    LoadingSubtitle = "Rayfield",
    Theme = "Dark",
    ToggleUIKeybind = "K",
})

-- Tab: ESP
local ESPTab = Window:CreateTab("ESP", nil)
ESPTab:CreateSection("Highlight ESP")

local espGen = false
ESPTab:CreateToggle({
    Name = "ESP Generator",
    CurrentValue = false,
    Callback = function(v)
        espGen = v
        if v then
            for _,root in ipairs(collectGenerators()) do
                highlights[root] = createHighlight(root, Color3.fromRGB(255,200,0))
            end
        else
            for k,v in pairs(highlights) do
                if v and v.Parent and (k:IsA("BasePart") or k:IsA("Model")) and (k.Name:lower():find("generator") or k.Name:lower():find("gen")) then
                    v:Destroy()
                    highlights[k]=nil
                end
            end
        end
    end
})

local espPlayers = false
ESPTab:CreateToggle({
    Name = "ESP Players",
    CurrentValue = false,
    Callback = function(v)
        espPlayers = v
        if v then
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl ~= player and pl.Character then
                    highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0,150,255))
                end
            end
        else
            for k,v in pairs(highlights) do
                if v and v.Parent and k:IsA("Player") then v:Destroy() highlights[k]=nil end
            end
        end
    end
})

local espKiller = false
ESPTab:CreateToggle({
    Name = "ESP Killer",
    CurrentValue = false,
    Callback = function(v)
        espKiller = v
        if v then
            for _,pl in ipairs(Players:GetPlayers()) do
                local nm = string.lower(pl.Name or "")
                if pl.Character and (killerNames[nm] or string.find(nm, "killer")) then
                    highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255,0,0))
                end
            end
        else
            for k,v in pairs(highlights) do
                if v and v.Parent and k:IsA("Player") and (killerNames[string.lower(k.Name)] or string.find(k.Name:lower(),"killer")) then
                    v:Destroy() highlights[k]=nil
                end
            end
        end
    end
})

local espHook = false
ESPTab:CreateToggle({
    Name = "ESP Hook",
    CurrentValue = false,
    Callback = function(v)
        espHook = v
        if v then
            for _,hook in ipairs(collectHooks()) do
                highlights[hook] = createHighlight(hook, Color3.fromRGB(255,255,0))
            end
        else
            for k,v in pairs(highlights) do
                if v and v.Parent and k:IsA("BasePart") and (k.Name:lower():find("hook") or k.Name:lower():find("hookpoint")) then
                    v:Destroy() highlights[k]=nil
                end
            end
        end
    end
})

ESPTab:CreateToggle({
    Name = "ESP Lane (Line Drip)",
    CurrentValue = false,
    Callback = function(v)
        espLineEnabled = v
    end
})

ESPTab:CreateButton({
    Name = "Clear All ESP",
    Callback = function()
        clearHighlights()
        espGen = false; espPlayers = false; espKiller = false; espHook = false
        espLineEnabled = false
        Rayfield:Notify({Title = "ESP", Content = "All ESP cleared", Duration = 2})
    end
})

-- Tab: Teleport
local TeleTab = Window:CreateTab("Teleport", nil)
TeleTab:CreateButton({
    Name = "To Generator (Random)",
    Callback = function()
        local gens = collectGenerators()
        if #gens > 0 then safeTeleportTo(gens[math.random(1,#gens)]) end
    end
})
TeleTab:CreateButton({
    Name = "To Hook (Random)",
    Callback = function()
        local hooks = collectHooks()
        if #hooks > 0 then safeTeleportTo(hooks[math.random(1,#hooks)]) end
    end
})
TeleTab:CreateButton({
    Name = "To Player (Random)",
    Callback = function()
        local pool = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(pool, pl)
            end
        end
        if #pool > 0 then
            local target = pool[math.random(1,#pool)]
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then safeTeleportTo(hrp) end
        end
    end
})

-- Tab: Auto
local AutoTab = Window:CreateTab("Auto", nil)
AutoTab:CreateToggle({
    Name = "Auto Repair Generator (Sampai Selesai)",
    CurrentValue = false,
    Callback = function(v)
        autoRepairEnabled = v
        if v then
            if autoRepairThread then task.cancel(autoRepairThread) end
            autoRepairThread = task.spawn(autoRepairLoop)
        else
            if autoRepairThread then task.cancel(autoRepairThread) end
            autoRepairThread = nil
        end
    end
})
AutoTab:CreateToggle({
    Name = "Auto Skill Check (No Fail)",
    CurrentValue = false,
    Callback = function(v)
        autoSkillCheckEnabled = v
        if v then
            setupAutoSkillCheck()
            Rayfield:Notify({Title = "Auto Skill Check", Content = "Aktif, repair tidak akan gagal", Duration = 3})
        end
    end
})

-- Tab: Combat
local CombatTab = Window:CreateTab("Combat", nil)
CombatTab:CreateButton({
    Name = "Heal",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = hum.MaxHealth end
    end
})
CombatTab:CreateButton({
    Name = "Speed50",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 50 end
    end
})
CombatTab:CreateButton({
    Name = "Animx2",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum:FindFirstChild("Animator") then
            for _,t in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
                t:AdjustSpeed(2)
            end
        end
    end
})
CombatTab:CreateButton({
    Name = "ShiftLock (8s)",
    Callback = function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        local conn = RunService.RenderStepped:Connect(function()
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and camera then
                local look = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
                if look.Magnitude>0.001 then hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look) end
            end
        end)
        task.delay(8, function()
            if conn and conn.Connected then conn:Disconnect() end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    end
})
CombatTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v)
        if v then
            if noclipConn then return end
            noclipConn = RunService.Stepped:Connect(function()
                if player.Character then
                    for _,p in ipairs(player.Character:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
        end
    end
})
CombatTab:CreateButton({
    Name = "NoHitbox",
    Callback = function()
        local c = player.Character
        if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanTouch = false end
        end
    end
})
CombatTab:CreateButton({
    Name = "SmartHitbox",
    Callback = function()
        for _,pl in ipairs(Players:GetPlayers()) do
            local nm = string.lower(pl.Name or "")
            if pl ~= player and pl.Character and (killerNames[nm] or string.find(nm,"killer")) then
                local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not smartProxies[pl] then
                    local proxy = Instance.new("Part")
                    proxy.Name = "SmartHitboxProxy"
                    proxy.Size = Vector3.new(3,3,3)
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
    end
})
CombatTab:CreateButton({
    Name = "AntiStun (5s)",
    Callback = function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        local conn
        conn = hum.StateChanged:Connect(function(_, new)
            if new == Enum.HumanoidStateType.PlatformStanding or new == Enum.HumanoidStateType.Physics then
                hum.Sit = false
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
        task.delay(5, function() if conn and conn.Connected then conn:Disconnect() end end)
    end
})
CombatTab:CreateToggle({
    Name = "Anti Damage",
    CurrentValue = false,
    Callback = function(v)
        antiDamageEnabled = v
        if v then setupAntiDamage() else disableAntiDamage() end
    end
})

-- Tab: Visual
local VisualTab = Window:CreateTab("Visual", nil)
VisualTab:CreateButton({
    Name = "NoShadow",
    Callback = function()
        for _,v in ipairs(Lighting:GetDescendants()) do
            if v:IsA("ShadowMapLight") or v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("DirectionalLight") then
                v.Shadows=false
            end
        end
        Lighting.GlobalShadows=false
    end
})
VisualTab:CreateButton({
    Name = "Morning",
    Callback = function() Lighting.ClockTime=7 end
})
VisualTab:CreateButton({
    Name = "Afternoon",
    Callback = function() Lighting.ClockTime=17 end
})
VisualTab:CreateButton({
    Name = "Spawn Jump Button",
    Callback = function()
        local pg = player:WaitForChild("PlayerGui")
        if pg:FindFirstChild("JumpButton") then return end
        local jb = Instance.new("TextButton")
        jb.Name="JumpButton"
        jb.Size=UDim2.new(0,80,0,44)
        jb.Position=UDim2.new(1,-98,1,-68)
        jb.AnchorPoint=Vector2.new(1,1)
        jb.BackgroundColor3=Color3.fromRGB(48,48,48)
        jb.Font=Enum.Font.GothamBold
        jb.Text="Jump"
        jb.TextColor3=Color3.fromRGB(240,240,240)
        jb.Parent = pg
        Instance.new("UICorner", jb).CornerRadius=UDim.new(0,8)
        jb.MouseButton1Click:Connect(function()
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump=true end
        end)
    end
})
VisualTab:CreateToggle({
    Name = "Invisible Map",
    CurrentValue = false,
    Callback = function(v)
        for _,obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj:IsDescendantOf(player.Character) then
                obj.LocalTransparencyModifier = v and 1 or 0
            end
        end
    end
})
VisualTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Callback = function(v)
        if v then
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
        else
            Lighting.FogStart = 0
            Lighting.FogEnd = 1000
        end
    end
})

-- Tab: Utility
local UtilTab = Window:CreateTab("Utility", nil)
UtilTab:CreateButton({
    Name = "Fast Cooldown",
    Callback = function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local cds = plr.Character:FindFirstChild("Cooldowns")
                if cds then
                    for _,v in ipairs(cds:GetChildren()) do
                        if v:IsA("NumberValue") then v.Value = 0 end
                    end
                end
            end
        end
    end
})
UtilTab:CreateButton({
    Name = "Get Off Sling",
    Callback = function()
        local char = player.Character
        if not char then return end
        for _,joint in ipairs(char:GetDescendants()) do
            if joint:IsA("HingeConstraint") or joint:IsA("RodConstraint") then
                joint.Enabled = false
            end
        end
        local seat = char:FindFirstChildWhichIsA("VehicleSeat", true)
        if seat then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = false end
        end
    end
})
UtilTab:CreateButton({
    Name = "Rejoin Game",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

-- Notifikasi siap
Rayfield:Notify({
    Title = "VD Putzzdev",
    Content = "mes",
    Duration = 5
})

print("VD Putzzdev Rayfield")