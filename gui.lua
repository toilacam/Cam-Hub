-- CamHub.client.lua
-- Place in: StarterPlayer > StarterPlayerScripts
-- Builds the whole "Cam Hub" GUI from code. Native Roblox GUI objects only.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local nguoichoi = Players.LocalPlayer
local pgui = nguoichoi:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Config / design tokens
---------------------------------------------------------------------
local CH = {
	ten = "Cam Hub",
	phu = "Nothing here yet. This space is ready for what comes next.",
	cuasoMax = Vector2.new(892, 700),
	cuasoTile = 0.9, -- fraction of the viewport the window may fill
	benRong = 0.303, -- sidebar width (270 / 892)
	benThu = 0.085, -- collapsed sidebar width (~76 px)
	nguongThu = 600, -- auto-collapse below this viewport width

	mauNen = Color3.fromRGB(24, 22, 20),
	mauBen = Color3.fromRGB(32, 31, 30),
	mauKinh = Color3.fromRGB(44, 43, 42),
	mauChu = Color3.fromRGB(242, 241, 238),
	mauChu2 = Color3.fromRGB(143, 141, 137),
	mauVien = Color3.fromRGB(255, 255, 255),

	trongNen = 0.12,
	trongBen = 0.35,
	trongKinh = 0.5,
	trongVien = 0.9,
	trongVienHi = 0.8,
	trongBong = 0.93,

	goc = { cuaso = 20, panel = 20, ctl = 12, icon = 10 },
	le = { nd = UDim.new(0, 22), ndPhai = UDim.new(0, 26) },
	tg = 0.2, -- tween seconds
	font = Enum.Font.Gotham,
	fontDam = Enum.Font.GothamBold,
	fontVua = Enum.Font.GothamMedium,
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function tao(lop: string, thuoctinh: { [string]: any }, cha: Instance?): any
	local o = Instance.new(lop)
	for k, v in pairs(thuoctinh) do
		(o :: any)[k] = v
	end
	if cha then
		o.Parent = cha
	end
	return o
end

local function tweenTo(o: Instance, thuoctinh: { [string]: any })
	local tw = TweenService:Create(o, TweenInfo.new(CH.tg, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), thuoctinh)
	tw:Play()
	return tw
end

local function goc(cha: Instance, r: number)
	return tao("UICorner", { CornerRadius = UDim.new(0, r) }, cha)
end

-- Border: bright at the top edge, fading toward the bottom (layered border feel)
local function vien(cha: Instance, trong: number)
	local s = tao("UIStroke", {
		Color = CH.mauVien,
		Transparency = trong,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, cha)
	tao("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0.55),
			NumberSequenceKeypoint.new(1, 0.8),
		}),
	}, s)
	return s
end

-- Soft top sheen layered over a surface
local function anhsang(cha: Instance, r: number, cuong: number)
	local f = tao("Frame", {
		Name = "Sheen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Active = false,
		ZIndex = cha.ZIndex,
	}, cha)
	goc(f, r)
	tao("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - cuong),
			NumberSequenceKeypoint.new(0.3, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, f)
	return f
end

local function kinh(cha: Instance, props: { [string]: any }, r: number, mau: Color3, trong: number)
	props.BackgroundColor3 = mau
	props.BackgroundTransparency = trong
	props.BorderSizePixel = 0
	local f = tao("Frame", props, cha)
	goc(f, r)
	vien(f, CH.trongVien)
	anhsang(f, r, 0.06)
	return f
end

local function nhan(cha: Instance, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.TextColor3 = props.TextColor3 or CH.mauChu
	props.Font = props.Font or CH.font
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return tao("TextLabel", props, cha)
end

---------------------------------------------------------------------
-- Build GUI (never duplicate)
---------------------------------------------------------------------
local cu = pgui:FindFirstChild("CamHubGui")
if cu then
	cu:Destroy()
end

local gui = tao("ScreenGui", {
	Name = "CamHubGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, pgui)

-- Root keeps the 892:700 shape and never exceeds the viewport
local root = tao("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(CH.cuasoTile, CH.cuasoTile),
	BackgroundTransparency = 1,
}, gui)
tao("UIAspectRatioConstraint", { AspectRatio = CH.cuasoMax.X / CH.cuasoMax.Y }, root)
tao("UISizeConstraint", { MaxSize = CH.cuasoMax }, root)

-- Layered ambient shadow (stacked, increasingly faint frames)
for i = 1, 4 do
	local bong = tao("Frame", {
		Name = "Shadow" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 6 + i * 2),
		Size = UDim2.new(1, i * 8, 1, i * 8),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = CH.trongBong + (i - 1) * 0.015,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, root)
	goc(bong, CH.goc.cuaso + i * 4)
end

local cuaso = tao("Frame", {
	Name = "MainWindow",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = CH.mauNen,
	BackgroundTransparency = CH.trongNen,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 1,
}, root)
goc(cuaso, CH.goc.cuaso)
tao("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 196, 190)),
}, cuaso)
vien(cuaso, CH.trongVien - 0.04)
anhsang(cuaso, CH.goc.cuaso, 0.07)

-- Sidebar ------------------------------------------------------------
local ben = tao("Frame", {
	Name = "Sidebar",
	Size = UDim2.fromScale(CH.benRong, 1),
	BackgroundColor3 = CH.mauBen,
	BackgroundTransparency = CH.trongBen,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 2,
}, cuaso)
tao("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 208, 205)),
}, ben)

tao("Frame", { -- vertical divider
	Name = "Divider",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = CH.mauVien,
	BackgroundTransparency = CH.trongVien + 0.02,
	BorderSizePixel = 0,
	ZIndex = 3,
}, ben)

local dau = tao("Frame", {
	Name = "Header",
	Position = UDim2.new(0, 14, 0, 16),
	Size = UDim2.new(1, -28, 0, 44),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, ben)

local tenhieu = nhan(dau, {
	Name = "BrandText",
	Text = CH.ten,
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.fromOffset(6, 0),
	TextSize = 20,
	Font = CH.fontDam,
	TextTruncate = Enum.TextTruncate.AtEnd,
	ZIndex = 3,
})

local nutthu = tao("TextButton", {
	Name = "CollapseButton",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(1, 0.5),
	Size = UDim2.fromOffset(38, 38),
	BackgroundColor3 = CH.mauVien,
	BackgroundTransparency = 0.93,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 4,
}, dau)
goc(nutthu, CH.goc.icon)
local vienNut = tao("UIStroke", {
	Color = CH.mauVien,
	Transparency = CH.trongVien,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, nutthu)
local bieutuong = nhan(nutthu, { -- text glyph avoids needing any image asset
	Name = "Icon",
	Text = "‹",
	Size = UDim2.fromScale(1, 1),
	TextSize = 26,
	TextColor3 = CH.mauChu2,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = CH.fontVua,
	ZIndex = 5,
})

-- Content ------------------------------------------------------------
local noidung = tao("Frame", {
	Name = "ContentArea",
	Position = UDim2.fromScale(CH.benRong, 0),
	Size = UDim2.fromScale(1 - CH.benRong, 1),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 2,
}, cuaso)
tao("UIPadding", {
	PaddingTop = CH.le.nd,
	PaddingBottom = CH.le.ndPhai,
	PaddingLeft = CH.le.ndPhai,
	PaddingRight = CH.le.ndPhai,
}, noidung)

nhan(noidung, {
	Name = "Heading",
	Text = CH.ten,
	Size = UDim2.new(1, 0, 0, 40),
	TextSize = 26,
	Font = CH.fontDam,
	ZIndex = 3,
})
tao("Frame", {
	Name = "HeadingDivider",
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = CH.mauVien,
	BackgroundTransparency = CH.trongVien,
	BorderSizePixel = 0,
	ZIndex = 3,
}, noidung)

local trangchu = kinh(noidung, {
	Name = "HomePanel",
	Position = UDim2.fromOffset(0, 72),
	Size = UDim2.new(1, 0, 1, -72),
	ZIndex = 3,
}, CH.goc.panel, CH.mauKinh, CH.trongKinh)

local khoichu = tao("Frame", {
	Name = "Text",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.8, 0, 0, 70),
	BackgroundTransparency = 1,
	ZIndex = 5,
}, trangchu)
tao("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
}, khoichu)
nhan(khoichu, {
	Text = "Welcome to Cam Hub",
	Size = UDim2.new(1, 0, 0, 28),
	TextSize = 22,
	Font = CH.fontVua,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 1,
	ZIndex = 5,
})
nhan(khoichu, {
	Text = CH.phu,
	Size = UDim2.new(1, 0, 0, 36),
	TextSize = 14,
	TextColor3 = CH.mauChu2,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 2,
	ZIndex = 5,
})

---------------------------------------------------------------------
-- Interaction
---------------------------------------------------------------------
local dathu = false

local function datThu(thu: boolean)
	if dathu == thu then
		return
	end
	dathu = thu
	local rong = thu and CH.benThu or CH.benRong
	tweenTo(ben, { Size = UDim2.fromScale(rong, 1) })
	tweenTo(noidung, { Position = UDim2.fromScale(rong, 0), Size = UDim2.fromScale(1 - rong, 1) })
	tweenTo(tenhieu, { TextTransparency = thu and 1 or 0 })
	bieutuong.Text = thu and "›" or "‹"
end

nutthu.Activated:Connect(function()
	datThu(not dathu)
end)

nutthu.MouseEnter:Connect(function()
	tweenTo(nutthu, { BackgroundTransparency = 0.88 })
	tweenTo(vienNut, { Transparency = CH.trongVienHi })
	tweenTo(bieutuong, { TextColor3 = CH.mauChu })
end)
nutthu.MouseLeave:Connect(function()
	tweenTo(nutthu, { BackgroundTransparency = 0.93 })
	tweenTo(vienNut, { Transparency = CH.trongVien })
	tweenTo(bieutuong, { TextColor3 = CH.mauChu2 })
end)

-- Auto-collapse on narrow viewports (single connection, cleaned up with the GUI)
local cam = workspace.CurrentCamera
local function kiemtra()
	if cam and cam.ViewportSize.X < CH.nguongThu then
		datThu(true)
	end
end
if cam then
	local kn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(kiemtra)
	gui.Destroying:Connect(function()
		kn:Disconnect()
	end)
end
kiemtra()
