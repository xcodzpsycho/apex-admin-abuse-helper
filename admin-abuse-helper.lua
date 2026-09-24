-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ApexAdminHelperGui"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- ==========================================
-- 1. DEVICE SELECTOR
-- ==========================================
local DeviceSelectorGui = Instance.new("Frame")
DeviceSelectorGui.Name = "DeviceSelector"
DeviceSelectorGui.Size = UDim2.new(0, 300, 0, 270)
DeviceSelectorGui.Position = UDim2.new(0.5, -150, 0.5, -135)
DeviceSelectorGui.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
DeviceSelectorGui.BorderSizePixel = 0
DeviceSelectorGui.Active = true
DeviceSelectorGui.Draggable = true
DeviceSelectorGui.Parent = ScreenGui

local dsCorner = Instance.new("UICorner", DeviceSelectorGui)
dsCorner.CornerRadius = UDim.new(0, 10)

local dsStroke = Instance.new("UIStroke", DeviceSelectorGui)
dsStroke.Color = Color3.fromRGB(50, 50, 65)
dsStroke.Thickness = 1.5

local dsTitle = Instance.new("TextLabel", DeviceSelectorGui)
dsTitle.Size = UDim2.new(1, 0, 0, 40)
dsTitle.BackgroundTransparency = 1
dsTitle.Text = "Choose Your Device"
dsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
dsTitle.TextSize = 16
dsTitle.Font = Enum.Font.GothamBold

local dsWarning = Instance.new("TextLabel", DeviceSelectorGui)
dsWarning.Size = UDim2.new(1, -20, 0, 60)
dsWarning.Position = UDim2.new(0, 10, 0, 42)
dsWarning.BackgroundTransparency = 1
dsWarning.Text = "Warning: Choosing the wrong device will mess up your menu\nRejoin if you select the wrong device"
dsWarning.TextColor3 = Color3.fromRGB(255, 80, 80)
dsWarning.TextSize = 10
dsWarning.Font = Enum.Font.GothamMedium
dsWarning.TextWrapped = true

local dsListLayout = Instance.new("UIListLayout", DeviceSelectorGui)
dsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
dsListLayout.Padding = UDim.new(0, 6)
dsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local spacer = Instance.new("Frame", DeviceSelectorGui)
spacer.Size = UDim2.new(1, 0, 0, 95)
spacer.BackgroundTransparency = 1
spacer.LayoutOrder = 1

local MainFrame, TopBar, ToggleButton

-- ==========================================
-- LOGIK: ANCHOR, AUTO BUY, AUTO SELL & ANTI RESET
-- ==========================================

-- 1. Anchor Logik
local isAnchored = false
local anchorConnection = nil

local function toggleAnchor(btn)
	isAnchored = not isAnchored
	local char = LocalPlayer.Character
	local rootPart = char and char:FindFirstChild("HumanoidRootPart")

	if isAnchored then
		btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
		btn.Text = "Anchor: ON"
		if rootPart then
			rootPart.Anchored = true
		end
		anchorConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
			local newRoot = newChar:WaitForChild("HumanoidRootPart", 3)
			if newRoot and isAnchored then
				newRoot.Anchored = true
			end
		end)
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		btn.Text = "Anchor: OFF"
		if rootPart then
			rootPart.Anchored = false
		end
		if anchorConnection then
			anchorConnection:Disconnect()
			anchorConnection = nil
		end
	end
end

-- 2. Auto Buy Logik
local autoBuyEnabled = false
local autoBuyConnection = nil
local promptShownConnection = nil

local function toggleAutoBuy(btn)
	autoBuyEnabled = not autoBuyEnabled

	if autoBuyEnabled then
		btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
		btn.Text = "Auto Buy: ON"

		promptShownConnection = ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
			if not autoBuyEnabled then return end
			local actionText = string.lower(prompt.ActionText or "")
			local objectText = string.lower(prompt.ObjectText or "")

			if string.find(actionText, "purchase") or string.find(objectText, "purchase") then
				prompt.HoldDuration = 0
				task.spawn(function()
					pcall(function()
						fireproximityprompt(prompt)
						prompt:InputHoldBegin()
						task.wait(0.05)
						prompt:InputHoldEnd()
					end)
				end)
			end
		end)

		autoBuyConnection = RunService.RenderStepped:Connect(function()
			local char = LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") then
					local parent = descendant.Parent
					if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
						local partPos = parent.Position or (parent:IsA("Model") and parent:GetPivot().Position)
						if partPos then
							local dist = (root.Position - partPos).Magnitude
							if dist <= 35 then
								local actionText = string.lower(descendant.ActionText or "")
								local objectText = string.lower(descendant.ObjectText or "")

								if string.find(actionText, "purchase") or string.find(objectText, "purchase") then
									if descendant.HoldDuration > 0 then
										descendant.HoldDuration = 0
									end
									pcall(function()
										fireproximityprompt(descendant)
									end)
								end
							end
						end
					end
				end
			end
		end)
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		btn.Text = "Auto Buy: OFF"
		if autoBuyConnection then
			autoBuyConnection:Disconnect()
			autoBuyConnection = nil
		end
		if promptShownConnection then
			promptShownConnection:Disconnect()
			promptShownConnection = nil
		end
	end
end

-- 3. Auto Sell Logik
local autoSellEnabled = false
local autoSellConnection = nil
local sellPromptShownConnection = nil

local function toggleAutoSell(btn)
	autoSellEnabled = not autoSellEnabled

	if autoSellEnabled then
		btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
		btn.Text = "Auto Sell: ON"

		sellPromptShownConnection = ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
			if not autoSellEnabled then return end
			local actionText = string.lower(prompt.ActionText or "")
			local objectText = string.lower(prompt.ObjectText or "")

			if string.find(actionText, "sell") or string.find(objectText, "sell") then
				prompt.HoldDuration = 0
				task.spawn(function()
					pcall(function()
						fireproximityprompt(prompt)
						prompt:InputHoldBegin()
						task.wait(0.05)
						prompt:InputHoldEnd()
					end)
				end)
			end
		end)

		autoSellConnection = RunService.RenderStepped:Connect(function()
			local char = LocalPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			for _, descendant in ipairs(workspace:GetDescendants()) do
				if descendant:IsA("ProximityPrompt") then
					local parent = descendant.Parent
					if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
						local partPos = parent.Position or (parent:IsA("Model") and parent:GetPivot().Position)
						if partPos then
							local dist = (root.Position - partPos).Magnitude
							if dist <= 35 then
								local actionText = string.lower(descendant.ActionText or "")
								local objectText = string.lower(descendant.ObjectText or "")

								if string.find(actionText, "sell") or string.find(objectText, "sell") then
									if descendant.HoldDuration > 0 then
										descendant.HoldDuration = 0
									end
									pcall(function()
										fireproximityprompt(descendant)
									end)
								end
							end
						end
					end
				end
			end
		end)
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		btn.Text = "Auto Sell: OFF"
		if autoSellConnection then
			autoSellConnection:Disconnect()
			autoSellConnection = nil
		end
		if sellPromptShownConnection then
			sellPromptShownConnection:Disconnect()
			sellPromptShownConnection = nil
		end
	end
end

-- 4. Anti Reset Logik (Ohne den Chat zu verstecken)
local antiResetEnabled = false
local antiResetConnection = nil
local characterAddedAntiReset = nil

local function setupAntiResetForCharacter(char)
	local humanoid = char:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	antiResetConnection = humanoid.Died:Connect(function()
		if antiResetEnabled then
			humanoid.Health = humanoid.MaxHealth
		end
	end)
end

local function toggleAntiReset(btn)
	antiResetEnabled = not antiResetEnabled

	-- Nur den Reset-Button im Menü blockieren (lässt den Chat in Ruhe)
	pcall(function()
		StarterGui:SetCore("ResetButtonCallback", not antiResetEnabled)
	end)

	if antiResetEnabled then
		btn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
		btn.Text = "Anti Reset: ON"

		if LocalPlayer.Character then
			setupAntiResetForCharacter(LocalPlayer.Character)
		end

		characterAddedAntiReset = LocalPlayer.CharacterAdded:Connect(function(newChar)
			if antiResetEnabled then
				task.wait(0.2)
				setupAntiResetForCharacter(newChar)
			end
		end)
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		btn.Text = "Anti Reset: OFF"
		
		pcall(function()
			StarterGui:SetCore("ResetButtonCallback", true)
		end)

		if antiResetConnection then
			antiResetConnection:Disconnect()
			antiResetConnection = nil
		end
		if characterAddedAntiReset then
			characterAddedAntiReset:Disconnect()
			characterAddedAntiReset = nil
		end
	end
end

-- ==========================================
-- 2. MAIN HUB ERSTELLEN
-- ==========================================
function loadMainHub(scale)
	local uiWidth = 320
	local uiHeight = 235
	local topBarHeight = 35

	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, uiWidth, 0, uiHeight)
	MainFrame.Position = UDim2.new(0.5, -uiWidth/2, 0.5, -uiHeight/2)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local uiScale = Instance.new("UIScale", MainFrame)
	uiScale.Scale = scale

	local mainCorner = Instance.new("UICorner", MainFrame)
	mainCorner.CornerRadius = UDim.new(0, 8)

	local mainStroke = Instance.new("UIStroke", MainFrame)
	mainStroke.Color = Color3.fromRGB(50, 50, 65)
	mainStroke.Thickness = 1.5

	TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, topBarHeight)
	TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	TopBar.BorderSizePixel = 0
	TopBar.ZIndex = 2
	TopBar.Parent = MainFrame

	local topCorner = Instance.new("UICorner", TopBar)
	topCorner.CornerRadius = UDim.new(0, 8)

	local fixFrame = Instance.new("Frame", TopBar)
	fixFrame.Size = UDim2.new(1, 0, 0, 8)
	fixFrame.Position = UDim2.new(0, 0, 1, -8)
	fixFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	fixFrame.BorderSizePixel = 0

	local title = Instance.new("TextLabel", TopBar)
	title.Size = UDim2.new(1, -50, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "APEX HUB | ADMIN ABUSE HELPER"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 11
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 3

	-- ==========================================
	-- RUNDER LOGO TOGGLE-BUTTON (Draggable)
	-- ==========================================
	ToggleButton = Instance.new("ImageButton", ScreenGui)
	ToggleButton.Name = "ApexToggleButton"
	ToggleButton.Size = UDim2.new(0, 45, 0, 45)
	ToggleButton.Position = UDim2.new(0, 20, 0.5, -22)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	ToggleButton.Image = "rbxassetid://123645319057555"
	ToggleButton.Visible = false
	ToggleButton.Active = true

	local tbCorner = Instance.new("UICorner", ToggleButton)
	tbCorner.CornerRadius = UDim.new(1, 0)

	-- ==========================================
	-- X-BUTTON (Schließen)
	-- ==========================================
	local closeBtn = Instance.new("TextButton", TopBar)
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 26, 0, 26)
	closeBtn.Position = UDim2.new(1, -32, 0, 4.5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 13
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.ZIndex = 5
	
	local closeCorner = Instance.new("UICorner", closeBtn)
	closeCorner.CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Down:Connect(function()
		local currentSize = MainFrame.Size
		local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = MainFrame.Position + UDim2.new(0, uiWidth/2, 0, MainFrame.AbsoluteSize.Y/2)
		})
		closeTween:Play()
		closeTween.Completed:Connect(function()
			MainFrame.Visible = false
			MainFrame.Size = currentSize
			MainFrame.Position = UDim2.new(0.5, -uiWidth/2, 0.5, -currentSize.Y.Offset/2)
			ToggleButton.Visible = true
		end)
	end)

	-- Logo Drag & Click Logik
	local isDraggingToggle = false
	local toggleDragStart, toggleStartPos, hasMoved = false, nil, false

	ToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingToggle = true
			toggleDragStart = input.Position
			toggleStartPos = ToggleButton.Position
			hasMoved = false

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					isDraggingToggle = false
					if not hasMoved then
						ToggleButton.Visible = false
						MainFrame.Visible = true
					end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDraggingToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - toggleDragStart
			if delta.Magnitude > 5 then
				hasMoved = true
			end
			ToggleButton.Position = UDim2.new(
				toggleStartPos.X.Scale, 
				toggleStartPos.X.Offset + delta.X, 
				toggleStartPos.Y.Scale, 
				toggleStartPos.Y.Offset + delta.Y
			)
		end
	end)

	-- ==========================================
	-- INHALT (Buttons)
	-- ==========================================
	local contentContainer = Instance.new("Frame", MainFrame)
	contentContainer.Size = UDim2.new(1, -20, 1, -45)
	contentContainer.Position = UDim2.new(0, 10, 0, 40)
	contentContainer.BackgroundTransparency = 1

	local mobLayout = Instance.new("UIListLayout", contentContainer)
	mobLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mobLayout.Padding = UDim.new(0, 7)
	mobLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Anchor Button
	local anchorBtn = Instance.new("TextButton", contentContainer)
	anchorBtn.Size = UDim2.new(1, 0, 0, 32)
	anchorBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	anchorBtn.Text = "Anchor: OFF"
	anchorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	anchorBtn.TextSize, anchorBtn.Font = 12, Enum.Font.GothamBold
	Instance.new("UICorner", anchorBtn).CornerRadius = UDim.new(0, 6)
	anchorBtn.MouseButton1Down:Connect(function()
		toggleAnchor(anchorBtn)
	end)

	-- Auto Buy Button
	local autoBuyBtn = Instance.new("TextButton", contentContainer)
	autoBuyBtn.Size = UDim2.new(1, 0, 0, 32)
	autoBuyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	autoBuyBtn.Text = "Auto Buy: OFF"
	autoBuyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoBuyBtn.TextSize, autoBuyBtn.Font = 12, Enum.Font.GothamBold
	Instance.new("UICorner", autoBuyBtn).CornerRadius = UDim.new(0, 6)
	autoBuyBtn.MouseButton1Down:Connect(function()
		toggleAutoBuy(autoBuyBtn)
	end)

	-- Auto Sell Button
	local autoSellBtn = Instance.new("TextButton", contentContainer)
	autoSellBtn.Size = UDim2.new(1, 0, 0, 32)
	autoSellBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	autoSellBtn.Text = "Auto Sell: OFF"
	autoSellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	autoSellBtn.TextSize, autoSellBtn.Font = 12, Enum.Font.GothamBold
	Instance.new("UICorner", autoSellBtn).CornerRadius = UDim.new(0, 6)
	autoSellBtn.MouseButton1Down:Connect(function()
		toggleAutoSell(autoSellBtn)
	end)

	-- Anti Reset Button
	local antiResetBtn = Instance.new("TextButton", contentContainer)
	antiResetBtn.Size = UDim2.new(1, 0, 0, 32)
	antiResetBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	antiResetBtn.Text = "Anti Reset: OFF"
	antiResetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	antiResetBtn.TextSize, antiResetBtn.Font = 12, Enum.Font.GothamBold
	Instance.new("UICorner", antiResetBtn).CornerRadius = UDim.new(0, 6)
	antiResetBtn.MouseButton1Down:Connect(function()
		toggleAntiReset(antiResetBtn)
	end)

	-- Hauptfenster Drag-Logik
	local dragging, dragInput, dragStart, startPos

	TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	TopBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(
				startPos.X.Scale, 
				startPos.X.Offset + delta.X, 
				startPos.Y.Scale, 
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ==========================================
-- 3. DEVICE SELECTOR BUTTONS ERSTELLEN
-- ==========================================
local function createSelectorButton(name, scaleValue)
	local btn = Instance.new("TextButton", DeviceSelectorGui)
	btn.Size = UDim2.new(0, 260, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(220, 220, 220)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 6)

	btn.MouseButton1Down:Connect(function()
		DeviceSelectorGui:Destroy()
		loadMainHub(scaleValue)
	end)
end

createSelectorButton("Tablet", 0.85)
createSelectorButton("Phone", 0.75)
createSelectorButton("PC/Laptop", 1.0)
