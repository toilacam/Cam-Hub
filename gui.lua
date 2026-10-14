-- CamHub.client.lua  (Update #1)
-- Place in: StarterPlayer > StarterPlayerScripts
-- Adds: orange logo + "Blox Fruits" subtitle, X close button + ReopenButton,
-- and four-corner drag resizing. Native Roblox GUI only.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local nguoichoi = Players.LocalPlayer
local pgui = nguoichoi:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Config / design tokens
---------------------------------------------------------------------
local CH = {
	ten = "Cam Hub",
	phuGame = "Blox Fruits",
	phu = "Nothing here yet. This space is ready for what comes next.",
	logo = "rbxassetid://73919882310822",

	cuasoMax = Vector2.new(892, 700), -- initial size (fits viewport at 90%)
	cuasoTile = 0.9,
	rs = { minW = 560, minH = 400, maxW = 1200, maxH = 900, le = 8, hit = 18 }, -- resize limits

	benMo = 270, -- sidebar width (px), expanded
	benThu = 76, -- collapsed
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
	trongVienHi = 0.78,
	trongNut = 0.93,
	trongNutHi = 0.88,
	trongNutAn = 0.82,
	trongBong = 0.93,

	goc = { cuaso = 20, panel = 20, ctl = 12, icon = 10 },
	le = { nd = UDim.new(0, 22), ndPhai = UDim.new(0, 26) },
	tg = 0.2,
	tgNut = 0.15,
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

local function tweenTo(o: Instance, thuoctinh: { [string]: any }, tg: number?)
	local tw = TweenService:Create(o, TweenInfo.new(tg or CH.tg, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), thuoctinh)
	tw:Play()
	return tw
end

local function goc(cha: Instance, r: number)
	return tao("UICorner", { CornerRadius = UDim.new(0, r) }, cha)
end

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

-- Glass button states: default / hover / press (connected once per button)
local function hieuUngNut(nut: GuiButton, vienUI: UIStroke, mauIcon: { Instance }?)
	local trongaNut = nut.BackgroundTransparency
	local ben = false
	nut.MouseEnter:Connect(function()
		ben = true
		tweenTo(nut, { BackgroundTransparency = CH.trongNutHi }, CH.tgNut)
		tweenTo(vienUI, { Transparency = CH.trongVienHi }, CH.tgNut)
	end)
	nut.MouseLeave:Connect(function()
		ben = false
		tweenTo(nut, { BackgroundTransparency = trongaNut }, CH.tgNut)
		tweenTo(vienUI, { Transparency = CH.trongVien }, CH.tgNut)
	end)
	nut.MouseButton1Down:Connect(function()
		tweenTo(nut, { BackgroundTransparency = CH.trongNutAn }, 0.1)
	end)
	nut.MouseButton1Up:Connect(function()
		tweenTo(nut, { BackgroundTransparency = ben and CH.trongNutHi or trongaNut }, CH.tgNut)
	end)
end

---------------------------------------------------------------------
-- Build GUI (never duplicate)
---------------------------------------------------------------------
local cu = pgui:FindFirstChild("CamHubGui")
if cu then
	cu:Destroy()
end

local cam = workspace.CurrentCamera
local function vpSize(): Vector2
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local gui = tao("ScreenGui", {
	Name = "CamHubGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 10,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, pgui)

-- Root: offset-based so resizing math is exact. State lives in kt.
local vp0 = vpSize()
local kt = {
	w = math.min(CH.cuasoMax.X, math.floor(vp0.X * CH.cuasoTile)),
	h = math.min(CH.cuasoMax.Y, math.floor(vp0.Y * CH.cuasoTile)),
	x = 0,
	y = 0,
}
kt.x = math.floor((vp0.X - kt.w) / 2)
kt.y = math.floor((vp0.Y - kt.h) / 2)

local root = tao("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(kt.x, kt.y),
	Size = UDim2.fromOffset(kt.w, kt.h),
	BackgroundTransparency = 1,
}, gui)

local function datKT(x: number, y: number, w: number, h: number)
	kt.x, kt.y, kt.w, kt.h = x, y, w, h
	root.Position = UDim2.fromOffset(x, y)
	root.Size = UDim2.fromOffset(w, h)
end

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
	Size = UDim2.new(0, CH.benMo, 1, 0),
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

tao("Frame", {
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
	Position = UDim2.new(0, 14, 0, 14),
	Size = UDim2.new(1, -28, 0, 48),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, ben)

-- Logo (left, vertically centered with the title block)
local logo = tao("ImageLabel", {
	Name = "CamHubLogo",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 2, 0.5, 0),
	Size = UDim2.fromOffset(42, 42),
	BackgroundTransparency = 1,
	Image = CH.logo,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 3,
}, dau)

-- Title + subtitle block, offset right of the logo
local khoiTen = tao("Frame", {
	Name = "BrandBlock",
	Position = UDim2.fromOffset(56, 0),
	Size = UDim2.new(1, -56 - 46, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, dau)
tao("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 1),
}, khoiTen)
local tenhieu = nhan(khoiTen, {
	Name = "BrandText",
	Text = CH.ten,
	Size = UDim2.new(1, 0, 0, 24),
	TextSize = 20,
	Font = CH.fontDam,
	TextTruncate = Enum.TextTruncate.AtEnd,
	LayoutOrder = 1,
	ZIndex = 3,
})
local phuhieu = nhan(khoiTen, {
	Name = "BrandSubtitle",
	Text = CH.phuGame,
	Size = UDim2.new(1, 0, 0, 16),
	TextSize = 12,
	TextColor3 = CH.mauChu2,
	Font = CH.font,
	TextTruncate = Enum.TextTruncate.AtEnd,
	LayoutOrder = 2,
	ZIndex = 3,
})

local nutthu = tao("TextButton", {
	Name = "CollapseButton",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(1, 0.5),
	Size = UDim2.fromOffset(38, 38),
	BackgroundColor3 = CH.mauVien,
	BackgroundTransparency = CH.trongNut,
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
local bieutuong = nhan(nutthu, {
	Name = "Icon",
	Text = "‹",
	Size = UDim2.fromScale(1, 1),
	TextSize = 26,
	TextColor3 = CH.mauChu2,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = CH.fontVua,
	ZIndex = 5,
})
hieuUngNut(nutthu, vienNut)

-- Content ------------------------------------------------------------
local noidung = tao("Frame", {
	Name = "ContentArea",
	Position = UDim2.fromOffset(CH.benMo, 0),
	Size = UDim2.new(1, -CH.benMo, 1, 0),
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
	Size = UDim2.new(1, -56, 0, 40), -- leaves room for the close button
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

-- Close (X) button, top-right of the window ---------------------------
local nutdong = tao("TextButton", {
	Name = "CloseButton",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -22, 0, 20),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = CH.mauBen,
	BackgroundTransparency = CH.trongNut - 0.55,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 8,
}, cuaso)
goc(nutdong, CH.goc.ctl)
local vienDong = tao("UIStroke", {
	Color = CH.mauVien,
	Transparency = CH.trongVien,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, nutdong)
for i, rot in ipairs({ 45, -45 }) do
	local net = tao("Frame", {
		Name = "X" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 2),
		Rotation = rot,
		BackgroundColor3 = CH.mauChu2,
		BorderSizePixel = 0,
		ZIndex = 9,
	}, nutdong)
	goc(net, 1)
end
hieuUngNut(nutdong, vienDong)

-- Reopen button: lives OUTSIDE Root so it stays reachable when hidden -
local nutmo = tao("TextButton", {
	Name = "ReopenButton",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 16, 1, -16),
	Size = UDim2.fromOffset(48, 48),
	BackgroundColor3 = CH.mauBen,
	BackgroundTransparency = CH.trongNut - 0.55,
	AutoButtonColor = false,
	Text = "",
	Visible = false,
	ZIndex = 20,
}, gui)
goc(nutmo, 14)
local vienMo = vien(nutmo, CH.trongVien)
anhsang(nutmo, 14, 0.08)
tao("ImageLabel", {
	Name = "ReopenLogo",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(30, 30),
	BackgroundTransparency = 1,
	Image = CH.logo,
	ScaleType = Enum.ScaleType.Fit,
	ZIndex = 21,
}, nutmo)
hieuUngNut(nutmo, vienMo)

---------------------------------------------------------------------
-- Sidebar collapse
---------------------------------------------------------------------
local dathu = false
local function datThu(thu: boolean)
	if dathu == thu then
		return
	end
	dathu = thu
	local rong = thu and CH.benThu or CH.benMo
	tweenTo(ben, { Size = UDim2.new(0, rong, 1, 0) })
	tweenTo(noidung, { Position = UDim2.fromOffset(rong, 0), Size = UDim2.new(1, -rong, 1, 0) })
	local trong = thu and 1 or 0
	tweenTo(tenhieu, { TextTransparency = trong })
	tweenTo(phuhieu, { TextTransparency = trong })
	tweenTo(logo, { ImageTransparency = trong })
	bieutuong.Text = thu and "›" or "‹"
end
nutthu.Activated:Connect(function()
	datThu(not dathu)
end)

---------------------------------------------------------------------
-- Four-corner resizing (one centralized handler)
---------------------------------------------------------------------
-- Each corner: which horizontal edge (-1 = left moves, 1 = right moves) and vertical edge
local gocRS = {
	ResizeTopLeft = { hx = -1, vy = -1, anchor = Vector2.new(0, 0) },
	ResizeTopRight = { hx = 1, vy = -1, anchor = Vector2.new(1, 0) },
	ResizeBottomLeft = { hx = -1, vy = 1, anchor = Vector2.new(0, 1) },
	ResizeBottomRight = { hx = 1, vy = 1, anchor = Vector2.new(1, 1) },
}

local phien: { g: any, bd: Vector2, x: number, y: number, w: number, h: number, input: InputObject }? = nil

local function batdauRS(g: any, input: InputObject)
	phien = {
		g = g,
		bd = Vector2.new(input.Position.X, input.Position.Y),
		x = kt.x, y = kt.y, w = kt.w, h = kt.h,
		input = input,
	}
end

local function capnhatRS(input: InputObject)
	local p = phien
	if not p then
		return
	end
	local vp = vpSize()
	local R = CH.rs
	local dx = input.Position.X - p.bd.X
	local dy = input.Position.Y - p.bd.Y

	-- raw size: right/bottom edges grow with +delta, left/top edges grow with -delta
	local w = p.w + p.g.hx * dx
	local h = p.h + p.g.vy * dy

	-- limits, also bounded by the viewport so the window stays reachable
	local minW = math.min(R.minW, vp.X - 2 * R.le)
	local minH = math.min(R.minH, vp.Y - 2 * R.le)
	local maxW = R.maxW
	local maxH = R.maxH
	if p.g.hx == 1 then
		maxW = math.min(maxW, vp.X - R.le - p.x)
	else
		maxW = math.min(maxW, p.x + p.w - R.le)
	end
	if p.g.vy == 1 then
		maxH = math.min(maxH, vp.Y - R.le - p.y)
	else
		maxH = math.min(maxH, p.y + p.h - R.le)
	end
	w = math.clamp(w, minW, math.max(minW, maxW))
	h = math.clamp(h, minH, math.max(minH, maxH))

	-- keep the opposite corner anchored (no jump)
	local x = p.g.hx == -1 and (p.x + p.w - w) or p.x
	local y = p.g.vy == -1 and (p.y + p.h - h) or p.y
	datKT(x, y, w, h)
end

local function finRS()
	phien = nil
end

for ten, g in pairs(gocRS) do
	local hit = CH.rs.hit
	local h = tao("Frame", {
		Name = ten,
		AnchorPoint = g.anchor,
		Position = UDim2.fromScale(g.anchor.X, g.anchor.Y),
		Size = UDim2.fromOffset(hit, hit),
		BackgroundTransparency = 1,
		Active = true,
		ZIndex = 30,
	}, root)
	h.InputBegan:Connect(function(input: InputObject)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			batdauRS(g, input)
		end
	end)
end

local kn = {}
table.insert(kn, UserInputService.InputChanged:Connect(function(input: InputObject)
	local p = phien
	if not p then
		return
	end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and input == p.input) then
		capnhatRS(input)
	end
end))
table.insert(kn, UserInputService.InputEnded:Connect(function(input: InputObject)
	local p = phien
	if not p then
		return
	end
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or (t == Enum.UserInputType.Touch and input == p.input) then
		finRS()
	end
end))

---------------------------------------------------------------------
-- Hide / reopen (hides Root as one container; handles hide with it)
---------------------------------------------------------------------
local function an()
	finRS()
	root.Visible = false
	nutmo.Visible = true
end
local function hien()
	root.Visible = true
	nutmo.Visible = false
end
nutdong.Activated:Connect(an)
nutmo.Activated:Connect(hien)

---------------------------------------------------------------------
-- Viewport changes: auto-collapse + keep window on screen
---------------------------------------------------------------------
local function khop()
	local vp = vpSize()
	local R = CH.rs
	local w = math.min(kt.w, vp.X - 2 * R.le)
	local h = math.min(kt.h, vp.Y - 2 * R.le)
	local x = math.clamp(kt.x, R.le, math.max(R.le, vp.X - w - R.le))
	local y = math.clamp(kt.y, R.le, math.max(R.le, vp.Y - h - R.le))
	if w ~= kt.w or h ~= kt.h or x ~= kt.x or y ~= kt.y then
		datKT(x, y, w, h)
	end
	if vp.X < CH.nguongThu then
		datThu(true)
	end
end
if cam then
	table.insert(kn, cam:GetPropertyChangedSignal("ViewportSize"):Connect(khop))
end
gui.Destroying:Connect(function()
	for _, c in ipairs(kn) do
		c:Disconnect()
	end
end)
khop()
