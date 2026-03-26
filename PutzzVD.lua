local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local guiName = "GuiViolenceDistrict"
local killerNames = {["abysswalker"]=true,["hidden"]=true,["jason"]=true,["jeff"]=true,["masked"]=true,["myers"]=true}
local DEV_ONLY = (RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId))

-- ================== ESP SYSTEM (ON/OFF) ==================
local espEnabled = false
local espLineEnabled = false
local espBoxes = {}
local espTexts = {}
local espLines = {}
local espBoxColor = Color3.fromRGB(0, 255, 0) -- Hijau

-- Fungsi ESP
local function createESP(plr)
    if plr == player then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Color = espBoxColor
    box.Filled = false
    box.Visible = false
    
    local name = Drawing.new("Text")
    name.Size = 14
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0)
    name.Visible = false
    
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(255, 100, 0)
    line.Visible = false
    
    espBoxes[plr] = {box, name, line}
end

local function updateESP()
    for pl, esp in pairs(espBoxes) do
        local box, name, line = unpack(esp)
        local char = pl.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local pos, visible = camera:WorldToViewportPoint(hrp.Position)
            
            if visible then
                local top = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                
                if espEnabled then
                    -- Box
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(pos.X - width/2, top.Y)
                    box.Visible = true
                    
                    -- Name
                    name.Position = Vector2.new(pos.X, top.Y - 16)
                    name.Text = pl.Name
                    name.Visible = true
                    
                    -- Line (dari bawah ke target)
                    if espLineEnabled then
                        line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    box.Visible = false
                    name.Visible = false
                    line.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
                line.Visible = false
            end
        end
    end
end

-- Render untuk ESP
RunService.RenderStepped:Connect(updateESP)

-- Inisialisasi ESP untuk semua player
for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
end

Players.PlayerAdded:Connect(function(p)
    createESP(p)
end)

Players.PlayerRemoving:Connect(function(p)
    if espBoxes[p] then
        for _, drawing in pairs(espBoxes[p]) do
            pcall(function() drawing:Remove() end)
        end
        espBoxes[p] = nil
    end
end)

-- ================== ANTI DAMAGE (SUPER FIXED DARI DRIP) ==================
local antiDamageEnabled = false
local antiDamageConnection = nil
local antiDamageThread = nil
local antiDamageHeartbeat = nil
local lastHealth = nil

local function setupAntiDamage()
    -- Matikan semua koneksi lama
    if antiDamageConnection then
        antiDamageConnection:Disconnect()
        antiDamageConnection = nil
    end
    
    if antiDamageHeartbeat then
        antiDamageHeartbeat:Disconnect()
        antiDamageHeartbeat = nil
    end
    
    if antiDamageThread then
        antiDamageThread = nil
    end
    
    -- 1. Heartbeat loop (sangat cepat)
    antiDamageHeartbeat = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                -- Paksa health ke max setiap saat
                if humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
                -- Cegah death
                if humanoid.Health <= 0 then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end
    end)
    
    -- 2. Thread terpisah dengan delay lebih cepat (0.001 detik)
    antiDamageThread = task.spawn(function()
        while antiDamageEnabled do
            task.wait(0.001) -- Super cepat!
            pcall(function()
                if player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end)
        end
    end)
    
    -- 3. HealthChanged event (responsif terhadap perubahan health)
    local function onHealthChanged()
        if antiDamageEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.HealthChanged:Connect(function(newHealth)
                    if antiDamageEnabled and newHealth < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end)
            end
        end
    end
    
    -- Panggil saat karakter ada
    if player.Character then
        onHealthChanged()
    end
    
    -- 4. Saat karakter berganti
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if antiDamageEnabled then
            onHealthChanged()
        end
    end)
    
    print("✅ GOD MODE AKTIF - Anti one-hit kill!")
end

local function disableAntiDamage()
    if antiDamageHeartbeat then
        antiDamageHeartbeat:Disconnect()
        antiDamageHeartbeat = nil
    end
    if antiDamageConnection then
        antiDamageConnection:Disconnect()
        antiDamageConnection = nil
    end
    if antiDamageThread then
        antiDamageThread = nil
    end
    print("❌ GOD MODE OFF - Proteksi dimatikan")
end

-- ================== FITUR LAIN (TETAP SAMA) ==================
local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild(guiName) then pg[guiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = pg
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 210, 0, 500)
main.Position = UDim2.new(0.5, -105, 0.5, -250)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Parent = screenGui
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

main.BackgroundTransparency = 1
main.Position = UDim2.new(0.5, -105, 0.5, -270)
TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0,
	Position = UDim2.new(0.5, -105, 0.5, -250)
}):Play()

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(28,28,28)
title.Text = "VD Putzzdev"
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local scroll = Instance.new("ScrollingFrame", main)
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, -12, 1, -58)
scroll.Position = UDim2.new(0, 6, 0, 42)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,0)
local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
end)

local function makeButton(text, parent)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -12, 0, 32)
	b.BackgroundColor3 = Color3.fromRGB(44,44,44)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 13
	b.TextColor3 = Color3.fromRGB(240,240,240)
	b.AutoButtonColor = false
	b.Text = text
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	b.Parent = parent
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(66,66,66)}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(44,44,44)}):Play()
	end)
	return b
end

-- ================== TOGGLE ESP ==================
local espToggleState = false
makeButton("ESP ON/OFF", scroll).MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    print("ESP " .. (espEnabled and "ON" or "OFF"))
end)

-- ================== TOGGLE ESP LINE ==================
local espLineToggleState = false
makeButton("ESP Line ON/OFF", scroll).MouseButton1Click:Connect(function()
    espLineEnabled = not espLineEnabled
    print("ESP Line " .. (espLineEnabled and "ON" or "OFF"))
end)

-- ================== TOGGLE ANTI DAMAGE (DARI DRIP) ==================
makeButton("AntiDamage (GodMode)", scroll).MouseButton1Click:Connect(function()
    antiDamageEnabled = not antiDamageEnabled
    if antiDamageEnabled then
        setupAntiDamage()
        print("✅ GOD MODE AKTIF - Anti one-hit kill!")
    else
        disableAntiDamage()
        print("❌ GOD MODE OFF - Proteksi dimatikan")
    end
end)

-- ================== FITUR ASLI (TIDAK DIUBAH) ==================
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

local highlights = {}
local smartProxies = {}
local noclipConn = nil
local antiConn = nil

-- Nama-nama generator dan hook yang valid
local generatorNames = {
	["generator"] = true,
	["generator_old"] = true,
	["gene"] = true
}
local hookNames = {
	["hookpoint"] = true,
	["hook"] = true,
	["hookmeat"] = true
}

-- Prefix tambahan
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

local gens = collectGenerators()
print("Generators found:", #gens)

local hooks = collectHooks()
print("Hooks found:", #hooks)

local function safeTeleportTo(part)
	local char = player.Character
	if not char or not part then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
end

makeButton("ESP Generator", scroll).MouseButton1Click:Connect(function()
	for _,root in ipairs(collectGenerators()) do
		highlights[root] = createHighlight(root, Color3.fromRGB(255,200,0))
	end
end)

makeButton("ESP Players", scroll).MouseButton1Click:Connect(function()
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and pl.Character then
			highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0,150,255))
		end
	end
end)

makeButton("ESP Killer", scroll).MouseButton1Click:Connect(function()
	for _,pl in ipairs(Players:GetPlayers()) do
		local nm = string.lower(pl.Name or "")
		if pl.Character and (killerNames[nm] or string.find(nm, "killer")) then
			highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255,0,0))
		end
	end
end)

makeButton("ESP Hook", scroll).MouseButton1Click:Connect(function()
	for _,hook in ipairs(collectHooks()) do
		highlights[hook] = createHighlight(hook, Color3.fromRGB(255,255,0))
	end
end)

makeButton("To Generator (Random)", scroll).MouseButton1Click:Connect(function()
	local matches = collectGenerators()
	if #matches > 0 then safeTeleportTo(matches[math.random(1,#matches)]) end
end)

makeButton("To Hook (Random)", scroll).MouseButton1Click:Connect(function()
	local matches = collectHooks()
	if #matches > 0 then safeTeleportTo(matches[math.random(1,#matches)]) end
end)

makeButton("To Player (Random)", scroll).MouseButton1Click:Connect(function()
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
end)

makeButton("Heal", scroll).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = hum.MaxHealth end
end)

makeButton("Speed50", scroll).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 50 end
end)

makeButton("Animx2", scroll).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum:FindFirstChild("Animator") then
		for _,t in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
			t:AdjustSpeed(2)
		end
	end
end)

makeButton("ShiftLock", scroll).MouseButton1Click:Connect(function()
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = false
	local conn = RunService.RenderStepped:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp and camera then
			local look = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
			if look.Magnitude>0.001 then hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look) end
		end
	end)
	delay(8,function()
		if conn and conn.Connected then conn:Disconnect() end
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)
end)

makeButton("Noclip", scroll).MouseButton1Click:Connect(function()
	if noclipConn then 
        noclipConn:Disconnect()
        noclipConn = nil
        print("Noclip OFF")
        return 
    end
	noclipConn = RunService.Stepped:Connect(function()
		if player.Character then
			for _,p in ipairs(player.Character:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end)
    print("Noclip ON")
end)

makeButton("NoHitbox", scroll).MouseButton1Click:Connect(function()
	local c = player.Character
	if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.CanTouch = false end
	end
end)

makeButton("SmartHitbox", scroll).MouseButton1Click:Connect(function()
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
end)

makeButton("AntiStun", scroll).MouseButton1Click:Connect(function()
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
	delay(5,function() if conn and conn.Connected then conn:Disconnect() end end)
end)

makeButton("NoShadow", scroll).MouseButton1Click:Connect(function()
	for _,v in ipairs(Lighting:GetDescendants()) do
		if v:IsA("ShadowMapLight") or v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("DirectionalLight") then
			v.Shadows=false
		end
	end
	Lighting.GlobalShadows=false
end)

makeButton("Morning", scroll).MouseButton1Click:Connect(function()
	Lighting.ClockTime=7
end)

makeButton("Afternoon", scroll).MouseButton1Click:Connect(function()
	Lighting.ClockTime=17
end)

makeButton("SpawnJump", scroll).MouseButton1Click:Connect(function()
	if screenGui:FindFirstChild("JumpButton") then return end
	local jb = Instance.new("TextButton", screenGui)
	jb.Name="JumpButton"
	jb.Size=UDim2.new(0,80,0,44)
	jb.Position=UDim2.new(1,-98,1,-68)
	jb.AnchorPoint=Vector2.new(1,1)
	jb.BackgroundColor3=Color3.fromRGB(48,48,48)
	jb.Font=Enum.Font.GothamBold
	jb.Text="Jump"
	jb.TextColor3=Color3.fromRGB(240,240,240)
	Instance.new("UICorner", jb).CornerRadius=UDim.new(0,8)
	jb.MouseButton1Click:Connect(function()
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Jump=true end
	end)
end)

local invisibleMapEnabled = false

-- Tombol FastCooldown
makeButton("FastCooldown", scroll).MouseButton1Click:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			local cds = plr.Character:FindFirstChild("Cooldowns")
			if cds then
				for _,v in ipairs(cds:GetChildren()) do
					if v:IsA("NumberValue") then
						v.Value = 0
					end
				end
			end
		end
	end
end)

-- Tombol Get Off Sling
makeButton("Get Off Sling", scroll).MouseButton1Click:Connect(function()
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
end)

local noFogEnabled = false

makeButton("No Fog", scroll).MouseButton1Click:Connect(function()
	noFogEnabled = not noFogEnabled
	if noFogEnabled then
		Lighting.FogStart = 0
		Lighting.FogEnd = 100000
	else
		Lighting.FogStart = 0
		Lighting.FogEnd = 1000
	end
end)

-- Tombol Invisible Map ON/OFF
makeButton("Invisible Map", scroll).MouseButton1Click:Connect(function()
	invisibleMapEnabled = not invisibleMapEnabled
	for _,v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			v.LocalTransparencyModifier = invisibleMapEnabled and 1 or 0
		end
	end
end)

makeButton("ClearHL", scroll).MouseButton1Click:Connect(function()
	for k,v in pairs(highlights) do if v and v.Parent then v:Destroy() end end
	highlights={}
end)

local minimizeBtn = Instance.new("TextButton", main)
minimizeBtn.Size = UDim2.new(0,28,0,24)
minimizeBtn.Position = UDim2.new(1,-34,0,6)
minimizeBtn.BackgroundColor3=Color3.fromRGB(55,55,55)
minimizeBtn.Text="—"
minimizeBtn.Font=Enum.Font.GothamBold
minimizeBtn.TextSize=14
minimizeBtn.TextColor3=Color3.fromRGB(230,230,230)
Instance.new("UICorner", minimizeBtn).CornerRadius=UDim.new(0,6)

local isMin=false
minimizeBtn.MouseButton1Click:Connect(function()
	isMin=not isMin
	if isMin then
		TweenService:Create(main,TweenInfo.new(0.25),{Size=UDim2.new(0,140,0,40)}):Play()
		scroll.Visible=false
		title.Text="VD PZ"
	else
		TweenService:Create(main,TweenInfo.new(0.25),{Size=UDim2.new(0,210,0,500)}):Play()
		scroll.Visible=true
		title.Text="VD Putzzdev"
	end
end)

player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) and screenGui then screenGui:Destroy() end
end)

player.CharacterRemoving:Connect(function()
	for _,p in pairs(smartProxies) do if p and p.Parent then p:Destroy() end end
	smartProxies={}
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if antiDamageHeartbeat then
        antiDamageHeartbeat:Disconnect()
        antiDamageHeartbeat = nil
    end
    if antiDamageThread then
        antiDamageThread = nil
    end
end)

print("✅ VD Putzzdev")