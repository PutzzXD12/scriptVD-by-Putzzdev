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
local ANTI_DAMAGE_DISTANCE = 40
local DEV_ONLY = (RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId))

local pg = player:WaitForChild("PlayerGui")
if pg:FindFirstChild(guiName) then pg[guiName]:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = pg
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 190, 0, 400)
main.Position = UDim2.new(0.5, -95, 0.5, -200)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Parent = screenGui
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

main.BackgroundTransparency = 1
main.Position = UDim2.new(0.5, -95, 0.5, -220)
TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0,
	Position = UDim2.new(0.5, -95, 0.5, -200)
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

-- ==================== ESP LANE (LINE ESP) ====================
local lineESPObjects = {}
local lineESPEnabled = false
local lineESPColor = Color3.fromRGB(0, 255, 150) -- Hijau muda

local function createLineESP(target)
	if not target or not target.Parent then return nil end
	local hrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
	if not hrp then return nil end
	
	-- Buat garis dari kamera ke target
	local line = Instance.new("SelectionBox")
	line.Adornee = hrp
	line.LineThickness = 2
	line.Color3 = lineESPColor
	line.Transparency = 0.5
	line.Parent = hrp
	
	return line
end

local function updateLineESP()
	while lineESPEnabled do
		task.wait(0.1)
		-- Hapus garis lama
		for _, obj in pairs(lineESPObjects) do
			pcall(function() if obj and obj.Parent then obj:Destroy() end end)
		end
		lineESPObjects = {}
		
		-- Buat garis ke setiap player (kecuali diri sendiri)
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and pl.Character then
				local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local line = createLineESP(pl.Character)
					if line then table.insert(lineESPObjects, line) end
				end
			end
		end
	end
end

-- ==================== VARIABEL ESP TOGGLE ====================
local highlights = {}
local espStates = {
	generator = false,
	players = false,
	killer = false,
	hook = false,
	lane = false,  -- ESP Lane (Line ESP)
}

local function clearHighlights()
	for k,v in pairs(highlights) do 
		if v and v.Parent then v:Destroy() end 
	end
	highlights = {}
end

local function refreshESP()
	clearHighlights()
	
	-- ESP Generator
	if espStates.generator then
		for _,root in ipairs(collectGenerators()) do
			highlights[root] = createHighlight(root, Color3.fromRGB(255,200,0))
		end
	end
	
	-- ESP Players (Highlight biasa)
	if espStates.players then
		for _,pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and pl.Character then
				highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0,150,255))
			end
		end
	end
	
	-- ESP Killer
	if espStates.killer then
		for _,pl in ipairs(Players:GetPlayers()) do
			local nm = string.lower(pl.Name or "")
			if pl.Character and (killerNames[nm] or string.find(nm, "killer")) then
				highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255,0,0))
			end
		end
	end
	
	-- ESP Hook
	if espStates.hook then
		for _,hook in ipairs(collectHooks()) do
			highlights[hook] = createHighlight(hook, Color3.fromRGB(255,255,0))
		end
	end
end

-- ==================== GENERATOR & HOOK COLLECTION ====================
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

-- ==================== BUTTON FITUR ====================
-- ESP Generator (Toggle style)
local espGenBtn = makeButton("ESP Generator: OFF", scroll)
espGenBtn.MouseButton1Click:Connect(function()
	espStates.generator = not espStates.generator
	espGenBtn.Text = espStates.generator and "ESP Generator: ON" or "ESP Generator: OFF"
	espGenBtn.BackgroundColor3 = espStates.generator and Color3.fromRGB(0,100,0) or Color3.fromRGB(44,44,44)
	refreshESP()
end)

-- ESP Players (Toggle style)
local espPlayerBtn = makeButton("ESP Players: OFF", scroll)
espPlayerBtn.MouseButton1Click:Connect(function()
	espStates.players = not espStates.players
	espPlayerBtn.Text = espStates.players and "ESP Players: ON" or "ESP Players: OFF"
	espPlayerBtn.BackgroundColor3 = espStates.players and Color3.fromRGB(0,100,0) or Color3.fromRGB(44,44,44)
	refreshESP()
end)

-- ESP LANE (Line ESP) - Toggle style, bisa aktif BERSAMAAN dengan ESP Players
local espLaneBtn = makeButton("ESP Lane (Line): OFF", scroll)
espLaneBtn.MouseButton1Click:Connect(function()
	espStates.lane = not espStates.lane
	espLaneBtn.Text = espStates.lane and "ESP Lane (Line): ON" or "ESP Lane (Line): OFF"
	espLaneBtn.BackgroundColor3 = espStates.lane and Color3.fromRGB(0,100,0) or Color3.fromRGB(44,44,44)
	
	if espStates.lane then
		lineESPEnabled = true
		coroutine.wrap(updateLineESP)()
	else
		lineESPEnabled = false
		for _, obj in pairs(lineESPObjects) do
			pcall(function() if obj and obj.Parent then obj:Destroy() end end)
		end
		lineESPObjects = {}
	end
end)

-- ESP Killer (Toggle style)
local espKillerBtn = makeButton("ESP Killer: OFF", scroll)
espKillerBtn.MouseButton1Click:Connect(function()
	espStates.killer = not espStates.killer
	espKillerBtn.Text = espStates.killer and "ESP Killer: ON" or "ESP Killer: OFF"
	espKillerBtn.BackgroundColor3 = espStates.killer and Color3.fromRGB(0,100,0) or Color3.fromRGB(44,44,44)
	refreshESP()
end)

-- ESP Hook (Toggle style)
local espHookBtn = makeButton("ESP Hook: OFF", scroll)
espHookBtn.MouseButton1Click:Connect(function()
	espStates.hook = not espStates.hook
	espHookBtn.Text = espStates.hook and "ESP Hook: ON" or "ESP Hook: OFF"
	espHookBtn.BackgroundColor3 = espStates.hook and Color3.fromRGB(0,100,0) or Color3.fromRGB(44,44,44)
	refreshESP()
end)

-- Clear All ESP
makeButton("Clear All ESP", scroll, Color3.fromRGB(80,50,50)).MouseButton1Click:Connect(function()
	-- Matikan semua toggle
	espStates.generator = false
	espStates.players = false
	espStates.killer = false
	espStates.hook = false
	espStates.lane = false
	
	-- Update tampilan tombol
	espGenBtn.Text = "ESP Generator: OFF"
	espGenBtn.BackgroundColor3 = Color3.fromRGB(44,44,44)
	espPlayerBtn.Text = "ESP Players: OFF"
	espPlayerBtn.BackgroundColor3 = Color3.fromRGB(44,44,44)
	espLaneBtn.Text = "ESP Lane (Line): OFF"
	espLaneBtn.BackgroundColor3 = Color3.fromRGB(44,44,44)
	espKillerBtn.Text = "ESP Killer: OFF"
	espKillerBtn.BackgroundColor3 = Color3.fromRGB(44,44,44)
	espHookBtn.Text = "ESP Hook: OFF"
	espHookBtn.BackgroundColor3 = Color3.fromRGB(44,44,44)
	
	-- Hapus semua ESP
	clearHighlights()
	lineESPEnabled = false
	for _, obj in pairs(lineESPObjects) do
		pcall(function() if obj and obj.Parent then obj:Destroy() end end)
	end
	lineESPObjects = {}
end)

-- ==================== FITUR LAINNYA (Tetap sama) ====================
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

-- Noclip
local noclipConn = nil
makeButton("Noclip", scroll).MouseButton1Click:Connect(function()
	if noclipConn then 
		noclipConn:Disconnect()
		noclipConn = nil
	else
		noclipConn = RunService.Stepped:Connect(function()
			if player.Character then
				for _,p in ipairs(player.Character:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end)

makeButton("NoHitbox", scroll).MouseButton1Click:Connect(function()
	local c = player.Character
	if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.CanTouch = false end
	end
end)

-- SmartHitbox
local smartProxies = {}
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

-- AntiDamage
local antiDamageEnabled = false
local lastHealth = nil
local antiConn = nil
makeButton("AntiDamage", scroll).MouseButton1Click:Connect(function()
	antiDamageEnabled = not antiDamageEnabled
	if antiDamageEnabled and not antiConn then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then lastHealth = hum.Health end
		antiConn = RunService.Heartbeat:Connect(function()
			local hum2 = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not hum2 then return end
			if lastHealth == nil then lastHealth = hum2.Health; return end
			if hum2.Health < lastHealth then
				local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local nearestKiller, kd = nil, math.huge
					for _, pl in ipairs(Players:GetPlayers()) do
						if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
							local nm = string.lower(pl.Name or "")
							if killerNames[nm] or string.find(nm,"killer") then
								local otherHRP = pl.Character:FindFirstChild("HumanoidRootPart")
								if otherHRP then
									local d = (otherHRP.Position - hrp.Position).Magnitude
									if d < kd then kd = d; nearestKiller = otherHRP end
								end
							end
						end
					end
					local escapeCFrame
					if nearestKiller then
						local dir = (hrp.Position - nearestKiller.Position)
						if dir.Magnitude < 1 then dir = Vector3.new(0,0,1) end
						dir = dir.Unit
						escapeCFrame = CFrame.new(hrp.Position + dir*ANTI_DAMAGE_DISTANCE, hrp.Position + dir*ANTI_DAMAGE_DISTANCE + Vector3.new(0,1,0))
					else
						local look = camera and Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z) or Vector3.new(0,0,-1)
						if look.Magnitude<0.001 then look = Vector3.new(0,0,-1) end
						escapeCFrame = CFrame.new(hrp.Position - look.Unit*ANTI_DAMAGE_DISTANCE, hrp.Position - look.Unit*ANTI_DAMAGE_DISTANCE + Vector3.new(0,1,0))
					end
					if hrp then hrp.CFrame = escapeCFrame + Vector3.new(0,3,0) end
				end
			end
			lastHealth = hum2.Health
		end)
	else
		if antiConn then antiConn:Disconnect(); antiConn=nil end
		antiDamageEnabled=false
	end
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

makeButton("Invisible Map", scroll).MouseButton1Click:Connect(function()
	invisibleMapEnabled = not invisibleMapEnabled
	for _,v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			v.LocalTransparencyModifier = invisibleMapEnabled and 1 or 0
		end
	end
end)

makeButton("ClearHL", scroll).MouseButton1Click:Connect(function()
	clearHighlights()
end)

-- Minimize Button
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
		TweenService:Create(main,TweenInfo.new(0.25),{Size=UDim2.new(0,190,0,400)}):Play()
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
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
	if antiConn then antiConn:Disconnect() antiConn = nil end
	lineESPEnabled = false
	for _, obj in pairs(lineESPObjects) do
		pcall(function() if obj and obj.Parent then obj:Destroy() end end)
	end
	lineESPObjects = {}
end)

print("VD Putzzdev + ESP Lane (Line ESP) Loaded!")