--[[
    VIOLENCE DISTRICT SCRIPT - SURVIVOR & KILLER FEATURES
    Gunakan hanya untuk pembelajaran di server pribadi.
    Script ini memerlukan executor yang support Drawing & HTTP requests (opsional).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========================== KONFIGURASI ==========================
local Config = {
    -- Survivor
    SpeedBoost = 32,          -- Speed lari (normal 16)
    NoclipEnabled = false,
    AutoGeneEnabled = false,
    AimbotEnabled = false,
    -- Killer
    AutoLockEnabled = false,
    TargetPlayer = nil,
    -- ESP
    ESPEnabled = true,
    ESPColorKiller = Color3.fromRGB(255, 0, 0),
    ESPColorSurvivor = Color3.fromRGB(0, 255, 0),
    ESPColorGene = Color3.fromRGB(255, 255, 0),
}

-- ========================== UTILITY FUNCTIONS ==========================
local function GetCharacter(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character or nil
end

local function GetHumanoid(plr)
    local char = GetCharacter(plr)
    return char and char:FindFirstChild("Humanoid") or nil
end

local function GetRootPart(plr)
    local char = GetCharacter(plr)
    return char and char:FindFirstChild("HumanoidRootPart") or nil
end

-- Detect apakah player adalah Killer (ganti sesuai game)
-- Asumsikan: jika role Killer, namanya mengandung "Killer" atau memiliki atribut tertentu
local function IsKiller(plr)
    if plr == LocalPlayer then return false end
    -- Cek berdasarkan nama atau leaderstats (contoh: jika ada nilai role = "Killer")
    local role = plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Role")
    if role then return role.Value == "Killer" end
    -- Fallback: cek nama karakter
    local char = GetCharacter(plr)
    if char and char.Name:lower():find("killer") then return true end
    return false
end

local function GetAllGenes()
    local genes = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("gene") or obj:IsA("Model") and obj.Name:lower():find("gene") then
            table.insert(genes, obj)
        end
    end
    return genes
end

local function GetAllHooks()
    local hooks = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:lower():find("hook") or obj:IsA("BasePart") and obj.Name:lower():find("hook") then
            table.insert(hooks, obj)
        end
    end
    return hooks
end

-- ========================== ESP SYSTEM ==========================
local ESPObjects = {} -- { [player] = {box, name, health} }

local function CreateESP(player)
    if not Config.ESPEnabled then return end
    if ESPObjects[player] then return end
    local function AddESP()
        local char = GetCharacter(player)
        if not char then return end
        local root = GetRootPart(player)
        if not root then return end
        
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Filled = false
        box.Color = IsKiller(player) and Config.ESPColorKiller or Config.ESPColorSurvivor
        box.Visible = true
        
        local nameTag = Drawing.new("Text")
        nameTag.Text = player.Name
        nameTag.Size = 14
        nameTag.Center = true
        nameTag.Outline = true
        nameTag.Color = Color3.new(1,1,1)
        nameTag.Visible = true
        
        local healthBar = Drawing.new("Line")
        healthBar.Thickness = 3
        healthBar.Color = Color3.fromRGB(0,255,0)
        healthBar.Visible = true
        
        ESPObjects[player] = {box = box, name = nameTag, health = healthBar, root = root}
    end
    
    if GetCharacter(player) then
        AddESP()
    else
        player.CharacterAdded:Connect(AddESP)
    end
end

local function RemoveESP(player)
    local esp = ESPObjects[player]
    if esp then
        esp.box:Remove()
        esp.name:Remove()
        esp.health:Remove()
        ESPObjects[player] = nil
    end
end

-- Update ESP positions setiap frame
RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then return end
    for player, esp in pairs(ESPObjects) do
        local root = esp.root
        if root and root.Parent then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local distance = (Camera.CFrame.Position - root.Position).Magnitude
                local boxSize = 200 / distance * 3
                esp.box.Size = Vector2.new(boxSize, boxSize)
                esp.box.Position = Vector2.new(pos.X - boxSize/2, pos.Y - boxSize/2)
                esp.box.Visible = true
                
                esp.name.Text = player.Name .. " [" .. math.floor(distance) .. "m]"
                esp.name.Position = Vector2.new(pos.X, pos.Y - boxSize/2 - 15)
                esp.name.Visible = true
                
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                if hum then
                    local healthPercent = hum.Health / hum.MaxHealth
                    esp.health.From = Vector2.new(pos.X - boxSize/2, pos.Y + boxSize/2)
                    esp.health.To = Vector2.new(pos.X - boxSize/2 + (boxSize * healthPercent), pos.Y + boxSize/2)
                    esp.health.Visible = true
                else
                    esp.health.Visible = false
                end
            else
                esp.box.Visible = false
                esp.name.Visible = false
                esp.health.Visible = false
            end
        else
            -- Character mati, hapus ESP
            RemoveESP(player)
        end
    end
end)

-- Gene ESP
local GeneESP = {}
local function UpdateGeneESP()
    for _, gene in ipairs(GetAllGenes()) do
        if not GeneESP[gene] then
            local box = Drawing.new("Square")
            box.Thickness = 1
            box.Filled = false
            box.Color = Config.ESPColorGene
            box.Visible = true
            GeneESP[gene] = box
        end
        local pos = gene:IsA("BasePart") and gene.Position or (gene:FindFirstChild("PrimaryPart") and gene.PrimaryPart.Position) or (gene:FindFirstChildWhichIsA("BasePart") and gene:FindFirstChildWhichIsA("BasePart").Position)
        if pos then
            local vp, on = Camera:WorldToViewportPoint(pos)
            if on then
                local size = 100 / (Camera.CFrame.Position - pos).Magnitude * 2
                GeneESP[gene].Size = Vector2.new(size, size)
                GeneESP[gene].Position = Vector2.new(vp.X - size/2, vp.Y - size/2)
                GeneESP[gene].Visible = true
            else
                GeneESP[gene].Visible = false
            end
        end
    end
    -- cleanup
    for gene, draw in pairs(GeneESP) do
        if not gene or not gene.Parent then
            draw:Remove()
            GeneESP[gene] = nil
        end
    end
end

-- Loop ESP Gene
RunService.RenderStepped:Connect(UpdateGeneESP)

-- Detect players masuk/keluar
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then CreateESP(plr) end
end
Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then CreateESP(plr) end
end)
Players.PlayerRemoving:Connect(RemoveESP)

-- ========================== AUTO GENE ==========================
local function CollectGene(gene)
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    -- Teleport ke gene
    local genePos = gene:IsA("BasePart") and gene.Position or (gene:FindFirstChild("PrimaryPart") and gene.PrimaryPart.Position) or (gene:FindFirstChildWhichIsA("BasePart") and gene:FindFirstChildWhichIsA("BasePart").Position)
    if genePos then
        root.CFrame = CFrame.new(genePos)
        task.wait(0.1)
        -- Simulasi collect dengan firetouchinterest
        if gene:IsA("BasePart") then
            firetouchinterest(root, gene, 0)
            task.wait(0.1)
            firetouchinterest(root, gene, 1)
        else
            -- Coba cari bagian yang bisa di-touch
            local touchPart = gene:FindFirstChildWhichIsA("BasePart")
            if touchPart then
                firetouchinterest(root, touchPart, 0)
                task.wait(0.1)
                firetouchinterest(root, touchPart, 1)
            end
        end
    end
end

local function AutoGeneLoop()
    while Config.AutoGeneEnabled and task.wait(0.5) do
        local genes = GetAllGenes()
        if #genes > 0 then
            for _, gene in ipairs(genes) do
                CollectGene(gene)
                task.wait(0.3)
            end
        else
            -- Tidak ada gene, tunggu
            task.wait(1)
        end
    end
end

-- ========================== TP TO GENE ==========================
local function TeleportToNearestGene()
    local genes = GetAllGenes()
    if #genes == 0 then return end
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local nearest = nil
    local dist = math.huge
    for _, gene in ipairs(genes) do
        local pos = gene:IsA("BasePart") and gene.Position or (gene:FindFirstChild("PrimaryPart") and gene.PrimaryPart.Position) or (gene:FindFirstChildWhichIsA("BasePart") and gene:FindFirstChildWhichIsA("BasePart").Position)
        if pos then
            local d = (root.Position - pos).Magnitude
            if d < dist then
                dist = d
                nearest = gene
            end
        end
    end
    if nearest then
        local pos = nearest:IsA("BasePart") and nearest.Position or (nearest:FindFirstChild("PrimaryPart") and nearest.PrimaryPart.Position) or (nearest:FindFirstChildWhichIsA("BasePart") and nearest:FindFirstChildWhichIsA("BasePart").Position)
        if pos then
            root.CFrame = CFrame.new(pos)
        end
    end
end

-- ========================== SPEED & NOCLIP ==========================
local function SetSpeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum and Config.SpeedBoost then
        hum.WalkSpeed = Config.SpeedBoost
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    SetSpeed()
    -- Noclip handler
    if Config.NoclipEnabled then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Noclip loop
RunService.Stepped:Connect(function()
    if Config.NoclipEnabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Speed update setiap detik
task.spawn(function()
    while true do
        task.wait(1)
        SetSpeed()
    end
end)

-- ========================== AIMBOT (Pistol) ==========================
local function GetNearestKiller()
    local nearest = nil
    local minDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and IsKiller(plr) then
            local root = GetRootPart(plr)
            if root then
                local screenPos, on = Camera:WorldToViewportPoint(root.Position)
                if on then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearest = plr
                    end
                end
            end
        end
    end
    return nearest
end

-- Aimbot aktif jika memegang pistol (nama item mengandung "Pistol")
local function IsHoldingPistol()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    return tool and (tool.Name:lower():find("pistol") or tool.Name:lower():find("gun")) or false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Config.AimbotEnabled and input.UserInputType == Enum.UserInputType.MouseButton1 and IsHoldingPistol() then
        local target = GetNearestKiller()
        if target then
            local head = target.Character and target.Character:FindFirstChild("Head")
            if head then
                local pos, on = Camera:WorldToViewportPoint(head.Position)
                if on then
                    mousemoveabs(pos.X, pos.Y)
                end
            end
        end
    end
end)

-- ========================== KILLER FEATURES ==========================
local KillerMode = false  -- toggle manual user

-- List Player GUI
local function CreatePlayerList()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillerGUI"
    screenGui.Parent = LocalPlayer.PlayerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.Text = "KILLER MENU"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-30)
    scroll.Position = UDim2.new(0,0,0,30)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 8
    scroll.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    local function RefreshList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,30)
                btn.Text = plr.Name
                btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
                btn.TextColor3 = Color3.new(1,1,1)
                btn.Parent = scroll
                btn.MouseButton1Click:Connect(function()
                    local targetRoot = GetRootPart(plr)
                    if targetRoot and LocalPlayer.Character then
                        local myRoot = GetRootPart(LocalPlayer)
                        if myRoot then
                            myRoot.CFrame = targetRoot.CFrame + Vector3.new(0,2,0)
                        end
                    end
                end)
            end
        end
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y)
    end
    
    Players.PlayerAdded:Connect(RefreshList)
    Players.PlayerRemoving:Connect(RefreshList)
    RefreshList()
end

-- Auto Lock Body (Killer mengejar survivor)
local function AutoLockLoop()
    while KillerMode and Config.AutoLockEnabled do
        task.wait(0.1)
        if Config.TargetPlayer and GetCharacter(Config.TargetPlayer) then
            local myChar = LocalPlayer.Character
            local targetRoot = GetRootPart(Config.TargetPlayer)
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot and targetRoot then
                -- Bergerak menuju target
                local direction = (targetRoot.Position - myRoot.Position).unit
                myRoot.Velocity = direction * 50
                -- Serang otomatis jika jarak dekat
                if (myRoot.Position - targetRoot.Position).Magnitude < 6 then
                    -- Simulasi attack (tool atau click)
                    local tool = myChar:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    else
                        -- Attack dengan Humanoid
                        local hum = myChar:FindFirstChild("Humanoid")
                        if hum then
                            hum:TakeDamage(20)
                        end
                    end
                end
            end
        end
    end
end

-- TP to Hook
local function TeleportToHook()
    local hooks = GetAllHooks()
    if #hooks == 0 then return end
    local nearest = nil
    local dist = math.huge
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for _, hook in ipairs(hooks) do
        local pos = hook:IsA("BasePart") and hook.Position or (hook:FindFirstChild("PrimaryPart") and hook.PrimaryPart.Position)
        if pos then
            local d = (myRoot.Position - pos).Magnitude
            if d < dist then
                dist = d
                nearest = hook
            end
        end
    end
    if nearest then
        local pos = nearest:IsA("BasePart") and nearest.Position or (nearest:FindFirstChild("PrimaryPart") and nearest.PrimaryPart.Position)
        if pos then
            myRoot.CFrame = CFrame.new(pos)
        end
    end
end

-- ========================== GUI UTAMA ==========================
local function CreateMainGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ViolenceDistrictHack"
    gui.Parent = LocalPlayer.PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,40)
    title.Text = "VIOLENCE DISTRICT HACK"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(100,0,0)
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,-40)
    scroll.Position = UDim2.new(0,0,0,40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 6
    scroll.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll
    
    -- Fungsi bikin tombol toggle
    local function MakeToggle(text, getter, setter)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 35)
        frame.BackgroundTransparency = 1
        frame.Parent = scroll
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7,0,1,0)
        label.Text = text
        label.TextColor3 = Color3.new(1,1,1)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25,0,1,0)
        btn.Position = UDim2.new(0.75,0,0,0)
        btn.Text = getter() and "ON" or "OFF"
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            setter(not getter())
            btn.Text = getter() and "ON" or "OFF"
            btn.BackgroundColor3 = getter() and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        end)
        return frame
    end
    
    local function MakeButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = scroll
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Survivor Section
    local survivorLabel = Instance.new("TextLabel")
    survivorLabel.Size = UDim2.new(1,0,0,30)
    survivorLabel.Text = "=== SURVIVOR MODE ==="
    survivorLabel.TextColor3 = Color3.fromRGB(100,200,255)
    survivorLabel.BackgroundTransparency = 1
    survivorLabel.Parent = scroll
    
    MakeToggle("ESP Killer/Player/Gene", function() return Config.ESPEnabled end, function(v) Config.ESPEnabled = v end)
    MakeToggle("Auto Gene (Selesai Otomatis)", function() return Config.AutoGeneEnabled end, function(v) 
        Config.AutoGeneEnabled = v
        if v then task.spawn(AutoGeneLoop) end
    end)
    MakeButton("TP to Nearest Gene", TeleportToNearestGene)
    MakeToggle("Noclip", function() return Config.NoclipEnabled end, function(v) Config.NoclipEnabled = v end)
    MakeToggle("Speed Hack", function() return Config.SpeedBoost == 32 end, function(v) 
        Config.SpeedBoost = v and 32 or 16
        SetSpeed()
    end)
    MakeToggle("Aimbot (Pistol)", function() return Config.AimbotEnabled end, function(v) Config.AimbotEnabled = v end)
    
    -- Killer Section
    local killerLabel = Instance.new("TextLabel")
    killerLabel.Size = UDim2.new(1,0,0,30)
    killerLabel.Text = "=== KILLER MODE ==="
    killerLabel.TextColor3 = Color3.fromRGB(255,100,100)
    killerLabel.BackgroundTransparency = 1
    killerLabel.Parent = scroll
    
    MakeButton("Buka List Player (TP)", CreatePlayerList)
    MakeToggle("Auto Lock Body (Kejar & Bunuh)", function() return Config.AutoLockEnabled end, function(v)
        Config.AutoLockEnabled = v
        if v and KillerMode then task.spawn(AutoLockLoop) end
    end)
    MakeButton("TP to Hook", TeleportToHook)
    
    -- Mode Switch
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, -10, 0, 40)
    modeBtn.Text = "SWITCH TO KILLER MODE"
    modeBtn.BackgroundColor3 = Color3.fromRGB(150,0,0)
    modeBtn.TextColor3 = Color3.new(1,1,1)
    modeBtn.Parent = scroll
    modeBtn.MouseButton1Click:Connect(function()
        KillerMode = not KillerMode
        modeBtn.Text = KillerMode and "SWITCH TO SURVIVOR MODE" or "SWITCH TO KILLER MODE"
        modeBtn.BackgroundColor3 = KillerMode and Color3.fromRGB(0,100,0) or Color3.fromRGB(150,0,0)
        if KillerMode and Config.AutoLockEnabled then
            task.spawn(AutoLockLoop)
        end
    end)
    
    -- Update CanvasSize
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
    end)
    scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
end

-- Jalankan GUI
task.spawn(CreateMainGUI)

-- Default speed
SetSpeed()

print("Script Violence District loaded. Gunakan GUI untuk mengatur fitur.")