-- CamHub.client.lua  (Update #2)
-- Place in: StarterPlayer > StarterPlayerScripts   (delete any older Cam Hub script first)
-- Adds: Lucide-style icon system, 5-section sidebar navigation with pages.
-- Keeps: logo, subtitle, close/reopen, four-corner resize, collapse, glass style.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local nguoichoi = Players.LocalPlayer
local pgui = nguoichoi:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Icon assets (CENTRALIZED). Paste your uploaded Roblox image IDs here,
-- e.g. x = "rbxassetid://123456789". Empty "" = use built-in drawn icon.
-- Upload transparent white/gray PNGs exported from lucide.dev (24px or 64px).
---------------------------------------------------------------------
local IconAssets = {
	["x"] = "",
	["panel-left-close"] = "",
	["panel-left-open"] = "",
	["house"] = "",
	["eye"] = "",
	["swords"] = "",
	["sport-shoe"] = "",
	["layout-grid-circles"] = "",
}

---------------------------------------------------------------------
-- Config / design tokens
---------------------------------------------------------------------
local CH = {
	ten = "Cam Hub",
	phuGame = "Blox Fruits",
	phu = "Nothing here yet. This space is ready for what comes next.",
	logo = "rbxassetid://73919882310822",

	cuasoMax = Vector2.new(892, 700),
	cuasoTile = 0.9,
	rs = { minW = 560, minH = 400, maxW = 1200, maxH = 900, le = 8, hit = 18 },

	benMo = 270,
	benThu = 76,
	nguongThu = 600,

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
	trongChon = 0.9, -- selected nav item
	trongBong = 0.93,

	goc = { cuaso = 20, panel = 20, ctl = 12, icon = 10 },
	le = { nd = UDim.new(0, 22), ndPhai = UDim.new(0, 26) },
	tg = 0.2,
	tgNut = 0.15,
	font = Enum.Font.Gotham,
	fontDam = Enum.Font.GothamBold,
	fontVua = Enum.Font.GothamMedium,

	muc = { -- navigation, exact order
		{ "Home", "house" },
		{ "Visual", "eye" },
		{ "Combat", "swords" },
		{ "Movement", "sport-shoe" },
		{ "Misc", "layout-grid-circles" },
	},
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

local function hieuUngNut(nut: GuiButton, vienUI: UIStroke)
	local trongNut = nut.BackgroundTransparency
	local ben = false
	nut.MouseEnter:Connect(function()
		ben = true
		tweenTo(nut, { BackgroundTransparency = CH.trongNutHi }, CH.tgNut)
		tweenTo(vienUI, { Transparency = CH.trongVienHi }, CH.tgNut)
	end)
	nut.MouseLeave:Connect(function()
		ben = false
		tweenTo(nut, { BackgroundTransparency = trongNut }, CH.tgNut)
		tweenTo(vienUI, { Transparency = CH.trongVien }, CH.tgNut)
	end)
	nut.MouseButton1Down:Connect(function()
		tweenTo(nut, { BackgroundTransparency = CH.trongNutAn }, 0.1)
	end)
	nut.MouseButton1Up:Connect(function()
		tweenTo(nut, { BackgroundTransparency = ben and CH.trongNutHi or trongNut }, CH.tgNut)
	end)
end

---------------------------------------------------------------------
-- Icon system: image asset if configured + loaded, else drawn fallback.
-- Fallback shapes follow the Lucide 24x24 grid, 2px outline strokes.
---------------------------------------------------------------------
local function duong(cha: Instance, x1: number, y1: number, x2: number, y2: number, ds: { any })
	local dx, dy = x2 - x1, y2 - y1
	local f = tao("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2),
		Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1.5, 2),
		Rotation = math.deg(math.atan2(dy, dx)),
		BackgroundColor3 = CH.mauChu2,
		BorderSizePixel = 0,
		ZIndex = cha.ZIndex + 1,
	}, cha)
	goc(f, 1)
	table.insert(ds, function(m: Color3)
		f.BackgroundColor3 = m
	end)
end

local function hop(cha: Instance, x: number, y: number, w: number, h: number, r: number, ds: { any })
	local f = tao("Frame", {
		Position = UDim2.fromOffset(x + 1, y + 1),
		Size = UDim2.fromOffset(w - 2, h - 2),
		BackgroundTransparency = 1,
		ZIndex = cha.ZIndex + 1,
	}, cha)
	goc(f, r)
	local s = tao("UIStroke", { Color = CH.mauChu2, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	table.insert(ds, function(m: Color3)
		s.Color = m
	end)
end

local ve: { [string]: (Instance, { any }) -> () } = {
	["x"] = function(c, d)
		duong(c, 6, 6, 18, 18, d)
		duong(c, 18, 6, 6, 18, d)
	end,
	["panel-left-close"] = function(c, d)
		hop(c, 3, 3, 18, 18, 4, d)
		duong(c, 9, 4, 9, 20, d)
		duong(c, 16, 9, 13, 12, d)
		duong(c, 13, 12, 16, 15, d)
	end,
	["panel-left-open"] = function(c, d)
		hop(c, 3, 3, 18, 18, 4, d)
		duong(c, 9, 4, 9, 20, d)
		duong(c, 13, 9, 16, 12, d)
		duong(c, 16, 12, 13, 15, d)
	end,
	["house"] = function(c, d)
		duong(c, 3, 11, 12, 4, d)
		duong(c, 12, 4, 21, 11, d)
		hop(c, 6, 10, 12, 11, 2, d)
	end,
	["eye"] = function(c, d)
		hop(c, 2, 6, 20, 12, 6, d)
		hop(c, 9, 9, 6, 6, 3, d)
	end,
	["swords"] = function(c, d)
		duong(c, 4, 4, 15, 15, d)
		duong(c, 12, 18, 18, 12, d)
		duong(c, 15, 15, 20, 20, d)
		duong(c, 20, 4, 9, 15, d)
		duong(c, 12, 18, 6, 12, d)
		duong(c, 9, 15, 4, 20, d)
	end,
	["sport-shoe"] = function(c, d)
		hop(c, 3, 13, 18, 7, 3, d)
		duong(c, 5, 13, 5, 5, d)
		duong(c, 5, 5, 10, 6, d)
		duong(c, 10, 6, 14, 11, d)
	end,
	["layout-grid-circles"] = function(c, d)
		hop(c, 3, 3, 7, 7, 4, d)
		hop(c, 14, 3, 7, 7, 4, d)
		hop(c, 3, 14, 7, 7, 4, d)
		hop(c, 14, 14, 7, 7, 4, d)
	end,
}

local function taoIcon(cha: Instance, ten: string, z: number)
	local gc = tao("Frame", {
		Name = "Icon_" .. ten,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24),
		BackgroundTransparency = 1,
		ZIndex = z,
	}, cha)
	local ds = {}
	local hinh = tao("Frame", { Name = "Shapes", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z }, gc)
	if ve[ten] then
		ve[ten](hinh, ds)
	end
	local img: ImageLabel? = nil
	local id = IconAssets[ten]
	if id and id ~= "" then
		hinh.Visible = false
		local anh = tao("ImageLabel", {
			Name = "Image",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = id,
			ImageColor3 = CH.mauChu2,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = z,
		}, gc)
		img = anh
		task.delay(4, function() -- asset failed to load -> fall back to drawn icon
			if anh.Parent and not anh.IsLoaded then
				anh.Visible = false
				hinh.Visible = true
			end
		end)
	end
	local function datMau(m: Color3)
		for _, f in ipairs(ds) do
			f(m)
		end
		if img then
			img.ImageColor3 = m
		end
	end
	return { gc = gc, datMau = datMau }
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

local khoiTen = tao("Frame", {
	Name = "BrandBlock",
	Position = UDim2.fromOffset(56, 0),
	Size = UDim2.new(1, -56 - 46, 1, 0),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, dau)
tao("UIListLayout", {
	VerticalAlignment = Enum.VerticalAlignment.Center,
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
local icDong = taoIcon(nutthu, "panel-left-close", 5) -- shown while sidebar is expanded
local icMo = taoIcon(nutthu, "panel-left-open", 5) -- shown while collapsed
icMo.gc.Visible = false
hieuUngNut(nutthu, vienNut)

-- Navigation -----------------------------------------------------------
local nav = tao("Frame", {
	Name = "Nav",
	Position = UDim2.new(0, 14, 0, 78),
	Size = UDim2.new(1, -28, 1, -92),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, ben)
tao("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, nav)

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

local tde = nhan(noidung, {
	Name = "Heading",
	Text = CH.muc[1][1],
	Size = UDim2.new(1, -56, 0, 40),
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

-- One page per section (placeholder panel); only the active one is visible
local function taoTrang(ten: string, tieu: string, phu: string)
	local p = kinh(noidung, {
		Name = "Page_" .. ten,
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 1, -72),
		Visible = false,
		ZIndex = 3,
	}, CH.goc.panel, CH.mauKinh, CH.trongKinh)
	local kc = tao("Frame", {
		Name = "Text",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.8, 0, 0, 70),
		BackgroundTransparency = 1,
		ZIndex = 5,
	}, p)
	tao("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
	}, kc)
	nhan(kc, {
		Text = tieu,
		Size = UDim2.new(1, 0, 0, 28),
		TextSize = 22,
		Font = CH.fontVua,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		ZIndex = 5,
	})
	nhan(kc, {
		Text = phu,
		Size = UDim2.new(1, 0, 0, 36),
		TextSize = 14,
		TextColor3 = CH.mauChu2,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		ZIndex = 5,
	})
	return p
end

local mucUI = {}
local chon = 0

local function chonMuc(i: number)
	if chon == i then
		return
	end
	chon = i
	for j, u in ipairs(mucUI) do
		local sel = j == i
		tweenTo(u.nut, { BackgroundTransparency = sel and CH.trongChon or 1 }, CH.tgNut)
		tweenTo(u.vien, { Transparency = sel and CH.trongVienHi or 1 }, CH.tgNut)
		tweenTo(u.nhan, { TextColor3 = sel and CH.mauChu or CH.mauChu2 }, CH.tgNut)
		u.ic.datMau(sel and CH.mauChu or CH.mauChu2)
		u.trang.Visible = sel
	end
	tde.Text = CH.muc[i][1]
end

for i, m in ipairs(CH.muc) do
	local nut = tao("TextButton", {
		Name = "Nav_" .. m[1],
		LayoutOrder = i,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = CH.mauVien,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ClipsDescendants = true,
		ZIndex = 4,
	}, nav)
	goc(nut, CH.goc.ctl)
	local v = tao("UIStroke", {
		Color = CH.mauVien,
		Transparency = 1,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, nut)
	local ic = taoIcon(nut, m[2], 5)
	ic.gc.Position = UDim2.new(0, 24, 0.5, 0) -- centered when collapsed (48 px item)
	local nh = nhan(nut, {
		Name = "Label",
		Text = m[1],
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.new(1, -56, 1, 0),
		TextSize = 15,
		Font = CH.fontVua,
		TextColor3 = CH.mauChu2,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 5,
	})
	local trang = taoTrang(m[1], i == 1 and "Welcome to Cam Hub" or m[1], i == 1 and CH.phu or "Nothing here yet.")
	mucUI[i] = { nut = nut, vien = v, ic = ic, nhan = nh, trang = trang }

	nut.MouseEnter:Connect(function()
		if chon ~= i then
			tweenTo(nut, { BackgroundTransparency = 0.95 }, CH.tgNut)
		end
	end)
	nut.MouseLeave:Connect(function()
		if chon ~= i then
			tweenTo(nut, { BackgroundTransparency = 1 }, CH.tgNut)
		end
	end)
	nut.Activated:Connect(function()
		chonMuc(i)
	end)
end
chonMuc(1)

-- Close (X) button -------------------------------------------------------
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
taoIcon(nutdong, "x", 9)
hieuUngNut(nutdong, vienDong)

-- Reopen button (outside Root) -------------------------------------------
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
-- Sidebar collapse (icons + labels follow the state)
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
	for _, u in ipairs(mucUI) do
		tweenTo(u.nhan, { TextTransparency = trong })
	end
	icDong.gc.Visible = not thu
	icMo.gc.Visible = thu
end
nutthu.Activated:Connect(function()
	datThu(not dathu)
end)

---------------------------------------------------------------------
-- Four-corner resizing (one centralized handler)
---------------------------------------------------------------------
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
	local w = p.w + p.g.hx * dx
	local h = p.h + p.g.vy * dy
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
	local x = p.g.hx == -1 and (p.x + p.w - w) or p.x
	local y = p.g.vy == -1 and (p.y + p.h - h) or p.y
	datKT(x, y, w, h)
end

local function finRS()
	phien = nil
end

for ten, g in pairs(gocRS) do
	local h = tao("Frame", {
		Name = ten,
		AnchorPoint = g.anchor,
		Position = UDim2.fromScale(g.anchor.X, g.anchor.Y),
		Size = UDim2.fromOffset(CH.rs.hit, CH.rs.hit),
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
-- Hide / reopen whole GUI (separate from sidebar collapse)
---------------------------------------------------------------------
nutdong.Activated:Connect(function()
	finRS()
	root.Visible = false
	nutmo.Visible = true
end)
nutmo.Activated:Connect(function()
	root.Visible = true
	nutmo.Visible = false
end)

---------------------------------------------------------------------
-- Viewport changes
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
