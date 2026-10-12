--[================================================================[
    CAM HUB UI - FIXED LOGO DISPLAY & TOP-LEFT ALIGNMENT
    Self-Contained LocalScript Implementation
--]================================================================]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Xóa giao diện cũ nếu đang tải lại
if playerGui:FindFirstChild("CamHubGui") then
    playerGui.CamHubGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CamHubGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Cấu hình Theme giao diện
local Theme = {
    Background = Color3.fromRGB(18, 18, 22),
    SidebarBackground = Color3.fromRGB(22, 22, 26),
    CardBackground = Color3.fromRGB(26, 26, 32),
    CardBackgroundHover = Color3.fromRGB(32, 32, 40),
    Border = Color3.fromRGB(45, 45, 55),
    Accent = Color3.fromRGB(255, 140, 30), -- Màu cam đồng bộ với logo
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(140, 140, 155),
    ToggleOff = Color3.fromRGB(55, 55, 65),
    ToggleOn = Color3.fromRGB(255, 140, 30),
    CornerRadius = UDim.new(0, 8),
    SmallCornerRadius = UDim.new(0, 6),
}

-- Main Window Frame
local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 884, 0, 700)
mainWindow.Position = UDim2.new(0.5, -442, 0.5, -350)
mainWindow.BackgroundColor3 = Theme.Background
mainWindow.BackgroundTransparency = 0.1
mainWindow.BorderSizePixel = 0
mainWindow.ClipsDescendants = true
mainWindow.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = Theme.CornerRadius
mainCorner.Parent = mainWindow

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Theme.Border
mainStroke.Transparency = 0.5
mainStroke.Thickness = 1
mainStroke.Parent = mainWindow

-- Kéo / Di chuyển cửa sổ
local dragging, dragInput, dragStart, startPos
mainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainWindow.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==================== SIDEBAR ====================
local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 260, 1, 0)
sidebar.BackgroundColor3 = Theme.SidebarBackground
sidebar.BackgroundTransparency = 0.2
sidebar.BorderSizePixel = 0
sidebar.Parent = mainWindow

local sidebarStroke = Instance.new("UIStroke")
sidebarStroke.Color = Theme.Border
sidebarStroke.Transparency = 0.6
sidebarStroke.Thickness = 1
sidebarStroke.Parent = sidebar

-- Brand Container (Khung chứa Logo & Text ở góc trên bên trái)
local brandContainer = Instance.new("Frame")
brandContainer.Name = "BrandContainer"
brandContainer.Size = UDim2.new(1, 0, 0, 70)
brandContainer.BackgroundTransparency = 1
brandContainer.Parent = sidebar

-- LOGO CAM HUB (ĐÃ FIX ĐƯỜNG DẪN MỚI & ĐẶT VÀO GÓC TRÊN CÙNG BÊN TRÁI)
local logoImage = Instance.new("ImageLabel")
logoImage.Name = "CamHubLogo"
logoImage.Size = UDim2.new(0, 36, 0, 36)
logoImage.Position = UDim2.new(0, 16, 0, 16)
logoImage.BackgroundTransparency = 1
logoImage.Image = "http://www.roblox.com/asset/?id=73919882310822"
logoImage.ScaleType = Enum.ScaleType.Fit
logoImage.ZIndex = 5
logoImage.Parent = brandContainer

-- Tên "Cam Hub" được đẩy sang phải để không bị chèn lên Logo
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(0, 150, 0, 20)
titleLabel.Position = UDim2.new(0, 60, 0, 16)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Cam Hub"
titleLabel.TextColor3 = Theme.TextPrimary
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = brandContainer

-- Subtitle "Blox Fruit"
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(0, 150, 0, 16)
subtitleLabel.Position = UDim2.new(0, 60, 0, 36)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.Text = "Blox Fruit"
subtitleLabel.TextColor3 = Theme.TextSecondary
subtitleLabel.TextSize = 12
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.Parent = brandContainer

-- Ô Tìm Kiếm (Search Bar)
local searchContainer = Instance.new("Frame")
searchContainer.Size = UDim2.new(1, -32, 0, 36)
searchContainer.Position = UDim2.new(0, 16, 0, 84)
searchContainer.BackgroundColor3 = Theme.CardBackground
searchContainer.BorderSizePixel = 0
searchContainer.Parent = sidebar
Instance.new("UICorner", searchContainer).CornerRadius = Theme.SmallCornerRadius
local searchStroke = Instance.new("UIStroke", searchContainer)
searchStroke.Color = Theme.Border

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -32, 1, 0)
searchBox.Position = UDim2.new(0, 32, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search"
searchBox.PlaceholderColor3 = Theme.TextSecondary
searchBox.Text = ""
searchBox.TextColor3 = Theme.TextPrimary
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Parent = searchContainer

-- Footer Sidebar
local sidebarFooter = Instance.new("Frame")
sidebarFooter.Size = UDim2.new(1, 0, 0, 50)
sidebarFooter.Position = UDim2.new(0, 0, 1, -50)
sidebarFooter.BackgroundTransparency = 1
sidebarFooter.Parent = sidebar

local footerText = Instance.new("TextLabel")
footerText.Size = UDim2.new(0, 150, 1, 0)
footerText.Position = UDim2.new(0, 16, 0, 0)
footerText.BackgroundTransparency = 1
footerText.Font = Enum.Font.Gotham
footerText.Text = "camhub.gg"
footerText.TextColor3 = Theme.TextSecondary
footerText.TextSize = 12
footerText.TextXAlignment = Enum.TextXAlignment.Left
footerText.Parent = sidebarFooter

local lctrlBadge = Instance.new("Frame")
lctrlBadge.Size = UDim2.new(0, 42, 0, 24)
lctrlBadge.Position = UDim2.new(1, -58, 0.5, -12)
lctrlBadge.BackgroundColor3 = Theme.CardBackground
lctrlBadge.BorderSizePixel = 0
lctrlBadge.Parent = sidebarFooter
Instance.new("UICorner", lctrlBadge).CornerRadius = UDim.new(0, 4)
local lctrlStroke = Instance.new("UIStroke", lctrlBadge)
lctrlStroke.Color = Theme.Border

local lctrlText = Instance.new("TextLabel")
lctrlText.Size = UDim2.new(1, 0, 1, 0)
lctrlText.BackgroundTransparency = 1
lctrlText.Font = Enum.Font.GothamBold
lctrlText.Text = "LCtrl"
lctrlText.TextColor3 = Theme.TextSecondary
lctrlText.TextSize = 11
lctrlText.Parent = lctrlBadge

-- ==================== MAIN CONTENT HEADER ====================
local topHeader = Instance.new("Frame")
topHeader.Size = UDim2.new(1, -260, 0, 70)
topHeader.Position = UDim2.new(0, 260, 0, 0)
topHeader.BackgroundTransparency = 1
topHeader.Parent = mainWindow

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(0, 200, 1, 0)
pageTitle.Position = UDim2.new(0, 24, 0, 0)
pageTitle.BackgroundTransparency = 1
pageTitle.Font = Enum.Font.GothamBold
pageTitle.Text = "Blox Fruit"
pageTitle.TextColor3 = Theme.TextPrimary
pageTitle.TextSize = 20
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = topHeader

local closeButton = Instance.new("ImageButton")
closeButton.Size = UDim2.new(0, 32, 0, 32)
closeButton.Position = UDim2.new(1, -48, 0.5, -16)
closeButton.BackgroundColor3 = Theme.CardBackground
closeButton.BorderSizePixel = 0
closeButton.Image = "rbxassetid://6031094678"
closeButton.ImageColor3 = Theme.TextSecondary
closeButton.Parent = topHeader
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)
local closeStroke = Instance.new("UIStroke", closeButton)
closeStroke.Color = Theme.Border

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ==================== CONTENT SCROLLER ====================
local contentScroll = Instance.new("ScrollingFrame")
contentScroll.Size = UDim2.new(1, -260, 1, -70)
contentScroll.Position = UDim2.new(0, 260, 0, 70)
contentScroll.BackgroundTransparency = 1
contentScroll.BorderSizePixel = 0
contentScroll.CanvasSize = UDim2.new(0, 0, 0, 750)
contentScroll.ScrollBarThickness = 4
contentScroll.ScrollBarImageColor3 = Theme.Border
contentScroll.Parent = mainWindow

-- Cột hiển thị nội dung
local leftCol = Instance.new("Frame")
leftCol.Size = UDim2.new(0, 290, 0, 680)
leftCol.Position = UDim2.new(0, 20, 0, 10)
leftCol.BackgroundTransparency = 1
leftCol.Parent = contentScroll

local rightCol = Instance.new("Frame")
rightCol.Size = UDim2.new(0, 290, 0, 680)
rightCol.Position = UDim2.new(0, 325, 0, 10)
rightCol.BackgroundTransparency = 1
rightCol.Parent = contentScroll

-- Helper: Tạo Khung Card
local function createCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Theme.CardBackground
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.Parent = parent
    
    Instance.new("UICorner", card).CornerRadius = Theme.CornerRadius
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Theme.Border
    stroke.Transparency = 0.6
    
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundTransparency = 1
    header.Parent = card
    
    local icon = Instance.new("Frame")
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 14, 0.5, -10)
    icon.BackgroundColor3 = Theme.Accent
    icon.BackgroundTransparency = 0.3
    icon.Parent = header
    Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 4)
    
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -70, 1, 0)
    titleLbl.Position = UDim2.new(0, 44, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = header
    
    local chevron = Instance.new("TextLabel")
    chevron.Size = UDim2.new(0, 20, 0, 20)
    chevron.Position = UDim2.new(1, -30, 0.5, -10)
    chevron.BackgroundTransparency = 1
    chevron.Font = Enum.Font.GothamBold
    chevron.Text = "v"
    chevron.TextColor3 = Theme.TextSecondary
    chevron.TextSize = 12
    chevron.Parent = header
    
    return card
end

-- Helper: Tạo Dropdown
local function createDropdown(parent, labelText, yPos)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -28, 0, 36)
    container.Position = UDim2.new(0, 14, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 120, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(0, 115, 0, 30)
    dropdownBtn.Position = UDim2.new(1, -115, 0.5, -15)
    dropdownBtn.BackgroundColor3 = Theme.Background
    dropdownBtn.AutoButtonColor = false
    dropdownBtn.Font = Enum.Font.GothamMedium
    dropdownBtn.Text = "None   v"
    dropdownBtn.TextColor3 = Theme.TextSecondary
    dropdownBtn.TextSize = 12
    dropdownBtn.Parent = container
    Instance.new("UICorner", dropdownBtn).CornerRadius = Theme.SmallCornerRadius
    local stroke = Instance.new("UIStroke", dropdownBtn)
    stroke.Color = Theme.Border
    
    return container
end

-- Helper: Tạo Nút Toggle
local function createToggle(parent, labelText, yPos, initialState)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -28, 0, 32)
    container.Position = UDim2.new(0, 14, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local toggleBg = Instance.new("TextButton")
    toggleBg.Size = UDim2.new(0, 40, 0, 22)
    toggleBg.Position = UDim2.new(1, -40, 0.5, -11)
    toggleBg.BackgroundColor3 = initialState and Theme.ToggleOn or Theme.ToggleOff
    toggleBg.AutoButtonColor = false
    toggleBg.Text = ""
    toggleBg.Parent = container
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = initialState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    toggleCircle.BackgroundColor3 = Theme.TextPrimary
    toggleCircle.Parent = toggleBg
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    
    local active = initialState
    toggleBg.MouseButton1Click:Connect(function()
        active = not active
        local targetPos = active and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local targetColor = active and Theme.ToggleOn or Theme.ToggleOff
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    end)
    
    return container
end

-- Helper: Tạo Thanh Trượt Slider
local function createSlider(parent, labelText, yPos, min, max, default)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -28, 0, 48)
    container.Position = UDim2.new(0, 14, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = parent
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container
    
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 50, 0, 20)
    valLbl.Position = UDim2.new(1, -50, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamMedium
    valLbl.Text = tostring(default) .. "%"
    valLbl.TextColor3 = Theme.TextSecondary
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 6)
    sliderBg.Position = UDim2.new(0, 0, 0, 30)
    sliderBg.BackgroundColor3 = Theme.ToggleOff
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(1, -7, 0.5, -7)
    knob.BackgroundColor3 = Theme.TextPrimary
    knob.Parent = fill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    return container
end

-- ==================== POPULATE LEFT CARD (Auto Farm) ====================
local autoFarmCard = createCard(leftCol, "Auto Farm", 480)
createDropdown(autoFarmCard, "Quest", 52)
createDropdown(autoFarmCard, "Weapon", 96)
createDropdown(autoFarmCard, "Method", 140)
createDropdown(autoFarmCard, "Target...", 184)
createToggle(autoFarmCard, "Auto Farm Level", 230, false)

local keyContainer = Instance.new("Frame", autoFarmCard)
keyContainer.Size = UDim2.new(1, -28, 0, 32)
keyContainer.Position = UDim2.new(0, 14, 0, 270)
keyContainer.BackgroundTransparency = 1
local keyLbl = Instance.new("TextLabel", keyContainer)
keyLbl.Size = UDim2.new(1, -60, 1, 0)
keyLbl.BackgroundTransparency = 1
keyLbl.Font = Enum.Font.GothamMedium
keyLbl.Text = "Farm toggle key"
keyLbl.TextColor3 = Theme.TextPrimary
keyLbl.TextSize = 13
keyLbl.TextXAlignment = Enum.TextXAlignment.Left

local keyBtn = Instance.new("TextButton", keyContainer)
keyBtn.Size = UDim2.new(0, 50, 0, 24)
keyBtn.Position = UDim2.new(1, -50, 0.5, -12)
keyBtn.BackgroundColor3 = Theme.Background
keyBtn.AutoButtonColor = false
keyBtn.Font = Enum.Font.GothamMedium
keyBtn.Text = "—"
keyBtn.TextColor3 = Theme.TextSecondary
keyBtn.TextSize = 12
Instance.new("UICorner", keyBtn).CornerRadius = Theme.SmallCornerRadius
Instance.new("UIStroke", keyBtn).Color = Theme.Border

createToggle(autoFarmCard, "Fast Attack", 310, false)
createToggle(autoFarmCard, "Bring Mobs", 350, true)
createSlider(autoFarmCard, "Attack Delay", 390, 0, 100, 20)
createToggle(autoFarmCard, "Auto Haki", 440, false)

-- ==================== POPULATE RIGHT CARDS ====================
-- Stats Card
local statsCard = createCard(rightCol, "Stats Upgrade", 280)
local statsInfo = Instance.new("TextLabel", statsCard)
statsInfo.Size = UDim2.new(1, -28, 0, 36)
statsInfo.Position = UDim2.new(0, 14, 0, 48)
statsInfo.BackgroundTransparency = 1
statsInfo.Font = Enum.Font.Gotham
statsInfo.Text = "Level: 2550 | Points: 0\nSelected: Melee"
statsInfo.TextColor3 = Theme.TextSecondary
statsInfo.TextSize = 12
statsInfo.TextXAlignment = Enum.TextXAlignment.Left

createToggle(statsCard, "Auto Stats Melee", 92, false)
createToggle(statsCard, "Auto Stats Defense", 132, false)
createToggle(statsCard, "Auto Stats Sword", 172, false)

local statusLbl = Instance.new("TextLabel", statsCard)
statusLbl.Size = UDim2.new(1, -28, 0, 30)
statusLbl.Position = UDim2.new(0, 14, 0, 214)
statusLbl.BackgroundTransparency = 1
statusLbl.Font = Enum.Font.Gotham
statusLbl.Text = "• Off\nBeli: 14.5M | Fragments: 25.4K"
statusLbl.TextColor3 = Theme.TextSecondary
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Bosses Card
local bossCard = createCard(rightCol, "Boss Farm", 110)
bossCard.Position = UDim2.new(0, 0, 0, 295)
createToggle(bossCard, "Auto Select Boss", 48, false)
local bossStatus = Instance.new("TextLabel", bossCard)
bossStatus.Size = UDim2.new(1, -28, 0, 20)
bossStatus.Position = UDim2.new(0, 14, 0, 82)
bossStatus.BackgroundTransparency = 1
bossStatus.Font = Enum.Font.Gotham
bossStatus.Text = "• Off"
bossStatus.TextColor3 = Theme.TextSecondary
bossStatus.TextSize = 11
bossStatus.TextXAlignment = Enum.TextXAlignment.Left

-- Teleport Card
local tpCard = createCard(rightCol, "World Teleport", 90)
tpCard.Position = UDim2.new(0, 0, 0, 418)

local hopBtn = Instance.new("TextButton", tpCard)
hopBtn.Size = UDim2.new(1, -28, 0, 32)
hopBtn.Position = UDim2.new(0, 14, 0, 46)
hopBtn.BackgroundColor3 = Theme.Background
hopBtn.AutoButtonColor = false
hopBtn.Font = Enum.Font.GothamBold
hopBtn.Text = "Teleport Sea 3"
hopBtn.TextColor3 = Theme.TextPrimary
hopBtn.TextSize = 13
Instance.new("UICorner", hopBtn).CornerRadius = Theme.SmallCornerRadius
Instance.new("UIStroke", hopBtn).Color = Theme.Border

print("Cam Hub UI - Logo đã được sửa lỗi hiển thị và căn chỉnh góc trên bên trái!")
