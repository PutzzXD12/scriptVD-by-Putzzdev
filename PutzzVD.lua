local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local guiName = "PutzzdevVD"
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

-- MAIN FRAME
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 210, 0, 420)
main.Position = UDim2.new(0.5, -105, 0.5, -210)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BorderSizePixel = 0
main.Parent = screenGui
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

main.BackgroundTransparency = 1
main.Position = UDim2.new(0.5, -105, 0.5, -230)
TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0,
	Position = UDim2.new(0.5, -105, 0.5, -210)
}):Play()

-- TITLE
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(28,28,28)
title.Text = "Putzzdev VD"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255,255,255)
title.BorderSizePixel = 0
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

-- SCROLLING FRAME
local scroll = Instance.new("ScrollingFrame", main)
scroll.Name = "Scroll"
scroll.Size = UDim2.new(1, -12, 1, -58)
scroll.Position = UDim2.new(0, 6, 0, 42)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 12)
end)

-- TAB BUTTONS
local tabBar = Instance.new("Frame", main)
tabBar.Size = UDim2.new(1, -12, 0, 32)
tabBar.Position = UDim2.new(0, 6, 0, 38)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 2

local tabESP = Instance.new("TextButton", tabBar)
tabESP.Size = UDim2.new(0.5, -4, 1, 0)
tabESP.Position = UDim2.new(0, 0, 0, 0)
tabESP.BackgroundColor3 = Color3.fromRGB(44,44,44)
tabESP.Text = "ESP"
tabESP.Font = Enum.Font.GothamBold
tabESP.TextSize = 13
tabESP.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", tabESP).CornerRadius = UDim.new(0, 6)

local tabMain = Instance.new("TextButton", tabBar)
tabMain.Size = UDim2.new(0.5, -4, 1, 0)
tabMain.Position = UDim2.new(0.5, 4, 0, 0)
tabMain.BackgroundColor3 = Color3.fromRGB(44,44,44)
tabMain.Text = "MAIN"
tabMain.Font = Enum.Font.GothamBold
tabMain.TextSize = 13
tabMain.TextColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", tabMain).CornerRadius = UDim.new(0, 6)

-- CONTENT FRAMES
local espContent = Instance.new("ScrollingFrame", main)
espContent.Name = "ESPContent"
espContent.Size = UDim2.new(1, -12, 1, -98)
espContent.Position = UDim2.new(0, 6, 0, 72)
espContent.BackgroundTransparency = 1
espContent.ScrollBarThickness = 6
espContent.CanvasSize = UDim2.new(0,0,0,0)
espContent.Visible = true

local mainContent = Instance.new("ScrollingFrame", main)
mainContent.Name = "MainContent"
mainContent.Size = UDim2.new(1, -12, 1, -98)
mainContent.Position = UDim2.new(0, 6, 0, 72)
mainContent.BackgroundTransparency = 1
mainContent.ScrollBarThickness = 6
mainContent.CanvasSize = UDim2.new(0,0,0,0)
mainContent.Visible = false

-- Layouts untuk content
local espLayout = Instance.new("UIListLayout", espContent)
espLayout.Padding = UDim.new(0, 6)
espLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
espLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	espContent.CanvasSize = UDim2.new(0,0,0, espLayout.AbsoluteContentSize.Y + 12)
end)

local mainLayout = Instance.new("UIListLayout", mainContent)
mainLayout.Padding = UDim.new(0, 6)
mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	mainContent.CanvasSize = UDim2.new(0,0,0, mainLayout.AbsoluteContentSize.Y + 12)
end)

-- TAB SWITCH
tabESP.MouseButton1Click:Connect(function()
	espContent.Visible = true
	mainContent.Visible = false
	tabESP.BackgroundColor3 = Color3.fromRGB(66,66,66)
	tabMain.BackgroundColor3 = Color3.fromRGB(44,44,44)
end)

tabMain.MouseButton1Click:Connect(function()
	espContent.Visible = false
	mainContent.Visible = true
	tabMain.BackgroundColor3 = Color3.fromRGB(66,66,66)
	tabESP.BackgroundColor3 = Color3.fromRGB(44,44,44)
end)

-- BUTTON MAKER
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

-- ==================== ESP VARIABLES ====================
local espEnabled = false
local espLineEnabled = false
local espBoxEnabled = false
local highlights = {}
local espLineObjects = {}
local espBoxObjects = {}

local function getScreenPos(worldPos)
	local vec, onScreen = camera:WorldToViewportPoint(worldPos)
	return Vector2.new(vec.X, vec.Y), onScreen
end

local function updateESP()
	if not espEnabled then return end
	
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = pl.Character.HumanoidRootPart
			local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
			local rootPart = pl.Character:FindFirstChild("HumanoidRootPart")
			local head = pl.Character:FindFirstChild("Head")
			
			if onScreen and rootPart and head then
				local bottom = getScreenPos(rootPart.Position - Vector3.new(0, 3, 0))
				local top = getScreenPos(head.Position + Vector3.new(0, 0.5, 0))
				local height = math.abs(top.Y - bottom.Y)
				local width = height / 2
				
				-- BOX
				if espBoxEnabled then
					if not espBoxObjects[pl] then
						local box = Drawing.new("Square")
						box.Thickness = 2
						box.Color = Color3.fromRGB(0, 200, 255)
						box.Filled = false
						box.Visible = true
						espBoxObjects[pl] = box
					end
					local box = espBoxObjects[pl]
					box.Size = Vector2.new(width, height)
					box.Position = Vector2.new(pos.X - width/2, top.Y)
					box.Visible = true
				elseif espBoxObjects[pl] then
					espBoxObjects[pl].Visible = false
				end
				
				-- LINE
				if espLineEnabled then
					if not espLineObjects[pl] then
						local line = Drawing.new("Line")
						line.Thickness = 2
						line.Color = Color3.fromRGB(255, 255, 255)
						line.Visible = true
						espLineObjects[pl] = line
					end
					local line = espLineObjects[pl]
					line.From = Vector2.new(camera.ViewportSize.X/2, 0)
					line.To = Vector2.new(pos.X, pos.Y)
					line.Visible = true
				elseif espLineObjects[pl] then
					espLineObjects[pl].Visible = false
				end
			else
				if espBoxObjects[pl] then espBoxObjects[pl].Visible = false end
				if espLineObjects[pl] then espLineObjects[pl].Visible = false end
			end
		end
	end
end

local function clearESP()
	for _,v in pairs(espBoxObjects) do if v then v:Remove() end end
	for _,v in pairs(espLineObjects) do if v then v:Remove() end end
	espBoxObjects = {}
	espLineObjects = {}
end

-- ==================== ESP BUTTONS ====================
makeButton("ESP Line", espContent).MouseButton1Click:Connect(function()
	espLineEnabled = not espLineEnabled
	if not espEnabled then espEnabled = true end
	if not espLineEnabled and not espBoxEnabled then espEnabled = false end
	if not espEnabled then clearESP() end
end)

makeButton("ESP Box", espContent).MouseButton1Click:Connect(function()
	espBoxEnabled = not espBoxEnabled
	if not espEnabled then espEnabled = true end
	if not espLineEnabled and not espBoxEnabled then espEnabled = false end
	if not espEnabled then clearESP() end
end)

makeButton("ESP Generator", espContent).MouseButton1Click:Connect(function()
	for _,root in ipairs(collectGenerators()) do
		highlights[root] = createHighlight(root, Color3.fromRGB(255,200,0))
	end
end)

makeButton("ESP Players", espContent).MouseButton1Click:Connect(function()
	for _,pl in ipairs(Players:GetPlayers()) do
		if pl ~= player and pl.Character then
			highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(0,150,255))
		end
	end
end)

makeButton("ESP Killer", espContent).MouseButton1Click:Connect(function()
	for _,pl in ipairs(Players:GetPlayers()) do
		local nm = string.lower(pl.Name or "")
		if pl.Character and (killerNames[nm] or string.find(nm, "killer")) then
			highlights[pl] = createHighlight(pl.Character, Color3.fromRGB(255,0,0))
		end
	end
end)

makeButton("ESP Hook", espContent).MouseButton1Click:Connect(function()
	for _,hook in ipairs(collectHooks()) do
		highlights[hook] = createHighlight(hook, Color3.fromRGB(255,255,0))
	end
end)

makeButton("Clear HL", espContent).MouseButton1Click:Connect(function()
	for k,v in pairs(highlights) do if v and v.Parent then v:Destroy() end end
	highlights={}
end)

-- ==================== MAIN BUTTONS ====================
makeButton("To Generator (Random)", mainContent).MouseButton1Click:Connect(function()
	local matches = collectGenerators()
	if #matches > 0 then safeTeleportTo(matches[math.random(1,#matches)]) end
end)

makeButton("To Hook (Random)", mainContent).MouseButton1Click:Connect(function()
	local matches = collectHooks()
	if #matches > 0 then safeTeleportTo(matches[math.random(1,#matches)]) end
end)

makeButton("To Player (Random)", mainContent).MouseButton1Click:Connect(function()
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

makeButton("Heal", mainContent).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = hum.MaxHealth end
end)

makeButton("Speed50", mainContent).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = 50 end
end)

makeButton("Animx2", mainContent).MouseButton1Click:Connect(function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum:FindFirstChild("Animator") then
		for _,t in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
			t:AdjustSpeed(2)
		end
	end
end)

makeButton("ShiftLock", mainContent).MouseButton1Click:Connect(function()
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

makeButton("Noclip", mainContent).MouseButton1Click:Connect(function()
	if noclipConn then return end
	noclipConn = RunService.Stepped:Connect(function()
		if player.Character then
			for _,p in ipairs(player.Character:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end)
end)

makeButton("NoHitbox", mainContent).MouseButton1Click:Connect(function()
	local c = player.Character
	if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.CanTouch = false end
	end
end)

makeButton("SmartHitbox", mainContent).MouseButton1Click:Connect(function()
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

makeButton("AntiStun", mainContent).MouseButton1Click:Connect(function()
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

makeButton("AntiDamage", mainContent).MouseButton1Click:Connect(function()
	antiDamageEnabled = not antiDamageEnabled
	if antiDamageEnabled and not antiConn then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then lastHealth = hum.Health end
		antiConn = RunService.Heartbeat:Connect(function()
			local hum2 = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not hum2 then return end
			if lastHealth == nil then lastHealth = hum2.Health; return end
			if hum2.Health < lastHealth then
				if DEV_ONLY then
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
				else
					local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then
						local marker = Instance.new("Part")
						marker.Name = "EscapeMarker"
						marker.Size = Vector3.new(2,2,2)
						marker.Anchored = true
						marker.CanCollide = false
						marker.Transparency = 0.5
						marker.Material = Enum.Material.Neon
						marker.Color = Color3.fromRGB(255,170,0)
						marker.CFrame = hrp.CFrame - camera.CFrame.LookVector.Unit*ANTI_DAMAGE_DISTANCE + Vector3.new(0,3,0)
						marker.Parent = Workspace
						delay(1.2,function() if marker and marker.Parent then marker:Destroy() end end)
					end
				end
			end
			lastHealth = hum2.Health
		end)
	else
		if antiConn then antiConn:Disconnect(); antiConn=nil end
		antiDamageEnabled=false
	end
end)

makeButton("NoShadow", mainContent).MouseButton1Click:Connect(function()
	for _,v in ipairs(Lighting:GetDescendants()) do
		if v:IsA("ShadowMapLight") or v:IsA("SpotLight") or v:IsA("PointLight") or v:IsA("DirectionalLight") then
			v.Shadows=false
		end
	end
	Lighting.GlobalShadows=false
end)

makeButton("Morning", mainContent).MouseButton1Click:Connect(function()
	Lighting.ClockTime=7
end)

makeButton("Afternoon", mainContent).MouseButton1Click:Connect(function()
	Lighting.ClockTime=17
end)

makeButton("SpawnJump", mainContent).MouseButton1Click:Connect(function()
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

makeButton("FastCooldown", mainContent).MouseButton1Click:Connect(function()
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

makeButton("Get Off Sling", mainContent).MouseButton1Click:Connect(function()
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

makeButton("No Fog", mainContent).MouseButton1Click:Connect(function()
	noFogEnabled = not noFogEnabled
	if noFogEnabled then
		Lighting.FogStart = 0
		Lighting.FogEnd = 100000
	else
		Lighting.FogStart = 0
		Lighting.FogEnd = 1000
	end
end)

makeButton("Invisible Map", mainContent).MouseButton1Click:Connect(function()
	invisibleMapEnabled = not invisibleMapEnabled
	for _,v in ipairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") and not v:IsDescendantOf(player.Character) then
			v.LocalTransparencyModifier = invisibleMapEnabled and 1 or 0
		end
	end
end)

-- ==================== HELPER FUNCTIONS (dari script asli) ====================
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

local function safeTeleportTo(part)
	local char = player.Character
	if not char or not part then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = part.CFrame + Vector3.new(0,3,0)
end

-- ESP RENDER LOOP
RunService.RenderStepped:Connect(function()
	updateESP()
end)

-- CLEANUP
player.AncestryChanged:Connect(function()
	if not player:IsDescendantOf(game) and screenGui then screenGui:Destroy() end
end)

player.CharacterRemoving:Connect(function()
	for _,p in pairs(smartProxies) do if p and p.Parent then p:Destroy() end end
	smartProxies={}
	clearESP()
end)

-- MINIMIZE BUTTON
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
		tabBar.Visible=false
		espContent.Visible=false
		mainContent.Visible=false
		title.Text="PZ VD"
	else
		TweenService:Create(main,TweenInfo.new(0.25),{Size=UDim2.new(0,210,0,420)}):Play()
		scroll.Visible=true
		tabBar.Visible=true
		if espContent.Visible then
			espContent.Visible=true
		else
			mainContent.Visible=true
		end
		title.Text="Putzzdev VD"
	end
end)

-- INITIAL TAB SELECTION
tabESP.BackgroundColor3 = Color3.fromRGB(66,66,66)
tabMain.BackgroundColor3 = Color3.fromRGB(44,44,44)