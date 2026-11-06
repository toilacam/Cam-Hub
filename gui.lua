-- CamHub.client.lua  (Update #4: lucide-roblox icons + draggable window)
-- Place in: StarterPlayer > StarterPlayerScripts   (delete any older Cam Hub script first)
-- Adds: icons from latte-soft/lucide-roblox, drag-to-move header zone.
-- Keeps: logo, subtitle, close/reopen, four-corner resize, collapse, glass style.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local nguoichoi = Players.LocalPlayer
local pgui = nguoichoi:WaitForChild("PlayerGui")

---------------------------------------------------------------------
-- Lucide config (CENTRALIZED). Library: https://github.com/latte-soft/lucide-roblox
-- Release asset "lucide-roblox.luau" (Wax bundle). Loaded with loadstring(game:HttpGet(...)).
-- Library v0.1.3 ships Lucide 0.363.0, which predates some newer names, so each icon has an
-- ordered candidate list: the requested name first, then the closest older equivalent.
---------------------------------------------------------------------
local LUCIDE_URL = "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"
local LucideTen = {
	["x"] = { "x" },
	["panel-left-close"] = { "panel-left-close" },
	["panel-left-open"] = { "panel-left-open" },
	["house"] = { "house", "home" }, -- "home" = same icon, old name (renamed to "house" later)
	["eye"] = { "eye" },
	["swords"] = { "swords" },
	["sport-shoe"] = { "sport-shoe", "footprints" }, -- not in 0.363.0 -> nearest: footprints
	["layout-grid-circles"] = { "layout-grid-circles", "layout-grid" }, -- not in 0.363.0 -> nearest: layout-grid
}

---------------------------------------------------------------------
-- Config / design tokens
---------------------------------------------------------------------
local CH = {
	ten = "Cam Hub",
	phuGame = "Blox Fruits",
	phu = "Nothing here yet. This space is ready for what comes next.",
	logo = "http://www.roblox.com/asset/?id=73919882310822",

	cuasoMax = Vector2.new(892, 700),
	cuasoTile = 0.9,
	rs = { minW = 560, minH = 400, maxW = 1200, maxH = 900, le = 8, hit = 18 },

	keoCao = 64, -- height of the drag zone at the top of the window
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
-- Icon system: lucide-roblox via loadstring(game:HttpGet(...)); never breaks the GUI.
-- Failure order: HttpGet/loadstring -> ReplicatedStorage.Lucide module -> text placeholders.
---------------------------------------------------------------------
local Lucide: any = nil
local loiLucide: string? = nil
do
	local ok, kq = pcall(function()
		return loadstring(game:HttpGet(LUCIDE_URL))()
	end)
	if ok and type(kq) == "table" and kq.ImageLabel and kq.IconNames then
		Lucide = kq
	else
		loiLucide = "loadstring/HttpGet failed: " .. tostring(kq)
		local m = game:GetService("ReplicatedStorage"):FindFirstChild("Lucide")
		if m and m:IsA("ModuleScript") then
			local ok2, kq2 = pcall(require, m)
			if ok2 and type(kq2) == "table" and kq2.ImageLabel and kq2.IconNames then
				Lucide = kq2
				loiLucide = nil
			end
		end
	end
end

local tenCoSan: { [string]: boolean } = {}
if Lucide then
	for _, t in ipairs(Lucide.IconNames) do
		tenCoSan[t] = true
	end
end

local FallbackText = {
	["x"] = "x",
	["panel-left-close"] = "<",
	["panel-left-open"] = ">",
	["house"] = "H",
	["eye"] = "V",
	["swords"] = "C",
	["sport-shoe"] = "M",
	["layout-grid-circles"] = "Mi",
}
local iconThayThe = {} -- requested -> substitute actually used
local iconThieu = {} -- no usable Lucide icon at all

local function giaiTen(ten: string): string?
	for i, t in ipairs(LucideTen[ten] or { ten }) do
		if tenCoSan[t] then
			if i > 1 then
				iconThayThe[ten] = t
			end
			return t
		end
	end
	return nil
end

local function taoIcon(cha: Instance, ten: string, z: number)
	local gc = tao("Frame", {
		Name = "Icon_" .. ten,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(24, 24), -- same canvas for every icon
		BackgroundTransparency = 1,
		ZIndex = z,
	}, cha)
	local fb = tao("TextLabel", {
		Name = "Fallback",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = FallbackText[ten] or "?",
		TextColor3 = CH.mauChu2,
		Font = CH.fontVua,
		TextSize = 16,
		Visible = false,
		ZIndex = z,
	}, gc)
	local anh: ImageLabel? = nil
	local ten2 = Lucide and giaiTen(ten)
	if ten2 then
		local ok, kq = pcall(Lucide.ImageLabel, ten2, 24, {
			Name = "Image",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundTransparency = 1,
			ImageColor3 = CH.mauChu2,
			ZIndex = z,
			Parent = gc,
		})
		if ok then
			anh = kq
		else
			warn(("[CamHub] Lucide.ImageLabel('%s') failed: %s"):format(ten2, tostring(kq)))
		end
	end
	if not anh then
		fb.Visible = true
		table.insert(iconThieu, ten)
	end
	local function datMau(m: Color3)
		if anh then
			anh.ImageColor3 = m
		end
		fb.TextColor3 = m
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

-- Drag zone: transparent strip under the header; buttons (higher ZIndex, Active) sink their own clicks
local vungKeo = tao("Frame", {
	Name = "DragZone",
	Size = UDim2.new(1, 0, 0, CH.keoCao),
	BackgroundTransparency = 1,
	Active = true,
	ZIndex = 1,
}, cuaso)

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

local phienKeo: { bd: Vector2, x: number, y: number, input: InputObject }? = nil
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
	phienKeo = nil
end

local function batdauKeo(input: InputObject)
	if phien then
		return
	end
	phienKeo = {
		bd = Vector2.new(input.Position.X, input.Position.Y),
		x = kt.x, y = kt.y,
		input = input,
	}
end

local function capnhatKeo(input: InputObject)
	local p = phienKeo
	if not p then
		return
	end
	local vp = vpSize()
	local le = CH.rs.le
	local x = p.x + (input.Position.X - p.bd.X)
	local y = p.y + (input.Position.Y - p.bd.Y)
	-- keep the whole window on screen
	x = math.clamp(x, le, math.max(le, vp.X - kt.w - le))
	y = math.clamp(y, le, math.max(le, vp.Y - kt.h - le))
	datKT(x, y, kt.w, kt.h)
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

vungKeo.InputBegan:Connect(function(input: InputObject)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
		batdauKeo(input)
	end
end)

local kn = {}
table.insert(kn, UserInputService.InputChanged:Connect(function(input: InputObject)
	local t = input.UserInputType
	if phien then
		if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and input == phien.input) then
			capnhatRS(input)
		end
	elseif phienKeo then
		if t == Enum.UserInputType.MouseMovement or (t == Enum.UserInputType.Touch and input == phienKeo.input) then
			capnhatKeo(input)
		end
	end
end))
table.insert(kn, UserInputService.InputEnded:Connect(function(input: InputObject)
	local t = input.UserInputType
	local cur = (phien and phien.input) or (phienKeo and phienKeo.input)
	if not cur then
		return
	end
	if t == Enum.UserInputType.MouseButton1 or (t == Enum.UserInputType.Touch and input == cur) then
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
---------------------------------------------------------------------
-- COMBAT MODULE — Silent Aim + Tracer + Target Selector
-- Blox Fruits, LocalScript context
-- Drawing API: game:GetService("RunService") Heartbeat loop + Drawing lib
-- Silent aim: weld lại HitPart của skill về phía target gần nhất trước khi
--             hitbox được server xử lý. Hoạt động bằng cách hook
--             RemoteEvent "GameAction" / skill hitbox frame weld.
-- Tracer     : Drawing.new("Line") từ màn hình local char → target mỗi frame.
---------------------------------------------------------------------

local RunService     = game:GetService("RunService")
local cam2           = workspace.CurrentCamera

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local SA = {
	batSA    = false,  -- silent aim on/off
	loaiMT   = "NPC",  -- "NPC" | "Players"
	target   = nil :: Model?,
	tracer   = nil :: any,
	fovR     = 300,    -- pixel radius dùng để lọc target gần crosshair
}

---------------------------------------------------------------------
-- Combat page — lấy frame đã tạo sẵn trong vòng lặp mucUI (index 3)
---------------------------------------------------------------------
local combatPage = mucUI[3].trang  -- Page_Combat

-- Xoá placeholder text mặc định
for _, v in ipairs(combatPage:GetChildren()) do
	if v.Name == "Text" then v:Destroy() end
end

---------------------------------------------------------------------
-- UI helpers (dùng lại helpers từ script gốc)
---------------------------------------------------------------------
local function divider(cha: Instance, posY: number)
	tao("Frame", {
		Name = "Div",
		Position = UDim2.fromOffset(0, posY),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = CH.mauVien,
		BackgroundTransparency = CH.trongVien,
		BorderSizePixel = 0,
		ZIndex = cha.ZIndex + 1,
	}, cha)
end

local function row(cha: Instance, posY: number, ten: string, zIdx: number)
	local f = tao("Frame", {
		Name = "Row_" .. ten,
		Position = UDim2.fromOffset(0, posY),
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		ZIndex = zIdx,
	}, cha)
	nhan(f, {
		Name = "RowLabel",
		Text = ten,
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(0.6, -16, 1, 0),
		TextSize = 14,
		Font = CH.fontVua,
		ZIndex = zIdx + 1,
	})
	return f
end

-- Toggle button (on/off pill)
local function taoToggle(cha: Instance, onChange: (boolean) -> ())
	local bat = false
	local pill = tao("TextButton", {
		Name = "Toggle",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(52, 28),
		BackgroundColor3 = Color3.fromRGB(60, 60, 58),
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		ZIndex = cha.ZIndex + 2,
	}, cha)
	goc(pill, 14)
	local knob = tao("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = CH.mauChu2,
		BorderSizePixel = 0,
		ZIndex = cha.ZIndex + 3,
	}, pill)
	goc(knob, 10)

	local function capNhat(trang: boolean)
		bat = trang
		local offX = trang and 38 or 14
		local mauNen = trang and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(60, 60, 58)
		tweenTo(pill, { BackgroundColor3 = mauNen }, CH.tgNut)
		tweenTo(knob, { Position = UDim2.new(0, offX, 0.5, 0), BackgroundColor3 = Color3.new(1,1,1) }, CH.tgNut)
		onChange(bat)
	end

	pill.Activated:Connect(function() capNhat(not bat) end)
	return { pill = pill, datTrang = capNhat }
end

-- Radio group (2 lựa chọn)
local function taoRadio(cha: Instance, options: { string }, onChange: (string) -> ())
	local chonHien = options[1]
	local nuts = {}
	local pad = tao("Frame", {
		Name = "RadioGroup",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(170, 30),
		BackgroundTransparency = 1,
		ZIndex = cha.ZIndex + 2,
	}, cha)
	tao("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 6),
	}, pad)

	local function capNhat(opt: string)
		chonHien = opt
		for _, d in ipairs(nuts) do
			local sel = d.opt == opt
			tweenTo(d.nut, {
				BackgroundColor3 = sel and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(50, 50, 48),
				BackgroundTransparency = sel and 0 or 0,
			}, CH.tgNut)
			tweenTo(d.lbl, { TextColor3 = sel and Color3.fromRGB(20, 20, 18) or CH.mauChu2 }, CH.tgNut)
		end
		onChange(opt)
	end

	for idx, opt in ipairs(options) do
		local nut = tao("TextButton", {
			Name = "Radio_" .. opt,
			Size = UDim2.fromOffset(78, 30),
			BackgroundColor3 = idx == 1 and Color3.fromRGB(80, 220, 120) or Color3.fromRGB(50, 50, 48),
			BackgroundTransparency = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = cha.ZIndex + 3,
		}, pad)
		goc(nut, 8)
		local lbl = nhan(nut, {
			Text = opt,
			Size = UDim2.fromScale(1, 1),
			TextSize = 13,
			Font = CH.fontVua,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = idx == 1 and Color3.fromRGB(20, 20, 18) or CH.mauChu2,
			ZIndex = cha.ZIndex + 4,
		})
		nuts[idx] = { nut = nut, lbl = lbl, opt = opt }
		nut.Activated:Connect(function() capNhat(opt) end)
	end

	return { datChon = capNhat }
end

---------------------------------------------------------------------
-- Populate Combat page
---------------------------------------------------------------------
local combatZ = combatPage.ZIndex + 1

-- Section header
nhan(combatPage, {
	Name = "SectionAim",
	Text = "AIMBOT",
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.new(1, -32, 0, 18),
	TextSize = 11,
	Font = CH.fontDam,
	TextColor3 = CH.mauChu2,
	ZIndex = combatZ,
})

-- Row 1: Silent Aim toggle
local rowSA = row(combatPage, 32, "Silent Aim", combatZ)
local togSA = taoToggle(rowSA, function(trang)
	SA.batSA = trang
	if not trang then
		-- tắt tracer
		if SA.tracer then
			SA.tracer.Visible = false
		end
		SA.target = nil
	end
end)

divider(combatPage, 76)

-- Row 2: Target selector
local rowTG = row(combatPage, 80, "Target", combatZ)
taoRadio(rowTG, { "NPC", "Players" }, function(opt)
	SA.loaiMT = opt
	SA.target = nil  -- reset target khi đổi loại
end)

divider(combatPage, 124)

-- FOV display label (thông tin)
nhan(combatPage, {
	Name = "FovHint",
	Text = ("FOV Radius: %d px — target gần crosshair nhất trong vòng này."):format(SA.fovR),
	Position = UDim2.fromOffset(16, 132),
	Size = UDim2.new(1, -32, 0, 18),
	TextSize = 11,
	Font = CH.font,
	TextColor3 = CH.mauChu2,
	ZIndex = combatZ,
})

---------------------------------------------------------------------
-- Tracer: Drawing line
---------------------------------------------------------------------
local tracerLine = Drawing.new("Line")
tracerLine.Thickness  = 1.5
tracerLine.Color      = Color3.fromRGB(255, 80, 80)
tracerLine.Transparency = 0.25
tracerLine.Visible    = false
SA.tracer = tracerLine

---------------------------------------------------------------------
-- Helpers: tìm target
---------------------------------------------------------------------
local function layHRP(char: Model): BasePart?
	return (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
end

local function sodiemMH(world: Vector3): (Vector3, boolean)
	return cam2:WorldToViewportPoint(world)
end

local function tiemGan(): Model?
	local nguoichoi2 = Players.LocalPlayer
	local charLocal = nguoichoi2.Character
	if not charLocal then return nil end
	local hrpLocal = layHRP(charLocal)
	if not hrpLocal then return nil end

	-- Crosshair ở giữa viewport
	local vp = cam2.ViewportSize
	local tam = Vector2.new(vp.X / 2, vp.Y / 2)

	local ganNhat: Model? = nil
	local khoangNhat = math.huge

	-- ---- NPC ----
	if SA.loaiMT == "NPC" then
		local folder = workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs")
		local nguon = folder and folder:GetChildren() or workspace:GetChildren()
		for _, v in ipairs(nguon) do
			if v:IsA("Model") and v ~= charLocal then
				local hum = v:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local hrp = layHRP(v)
					if hrp then
						local sp, inVP = sodiemMH(hrp.Position)
						if inVP then
							local dist2D = (Vector2.new(sp.X, sp.Y) - tam).Magnitude
							if dist2D < SA.fovR and dist2D < khoangNhat then
								khoangNhat = dist2D
								ganNhat = v
							end
						end
					end
				end
			end
		end

	-- ---- Players ----
	elseif SA.loaiMT == "Players" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= nguoichoi2 and p.Character then
				local char = p.Character
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					local hrp = layHRP(char)
					if hrp then
						local sp, inVP = sodiemMH(hrp.Position)
						if inVP then
							local dist2D = (Vector2.new(sp.X, sp.Y) - tam).Magnitude
							if dist2D < SA.fovR and dist2D < khoangNhat then
								khoangNhat = dist2D
								ganNhat = char
							end
						end
					end
				end
			end
		end
	end

	return ganNhat
end

---------------------------------------------------------------------
-- Silent Aim: hook toàn bộ RemoteEvent "GameAction" (Blox Fruits)
-- Redirect hướng skill bằng cách đọc / ghi args trước khi fire tới server.
-- Blox Fruits dùng pattern:  Remote:FireServer("UseSkill", dir, ...)
-- Ta thay dir = (hrpTarget.Position - hrpLocal.Position).Unit
---------------------------------------------------------------------
local hookConn: RBXScriptConnection? = nil

local function batHook()
	if hookConn then return end
	-- Tìm RemoteEvent "GameAction" trong ReplicatedStorage / workspace
	local RS2 = game:GetService("ReplicatedStorage")
	local remote: RemoteEvent? = RS2:FindFirstChild("GameAction", true) :: RemoteEvent?
		or RS2:FindFirstChild("Remote", true) :: RemoteEvent?

	if not remote then
		warn("[CamHub/SilentAim] Không tìm thấy RemoteEvent 'GameAction'. Skill redirect sẽ không hoạt động cho đến khi tìm thấy.")
		return
	end

	-- Lưu FireServer gốc
	local fireGoc = remote.FireServer
	local nguoichoi3 = Players.LocalPlayer

	-- Monkey-patch FireServer
	remote.FireServer = function(self, action: string, ...)
		if SA.batSA and SA.target then
			local charLocal = nguoichoi3.Character
			local hrpLocal = charLocal and layHRP(charLocal)
			local hrpTarget = layHRP(SA.target)
			if hrpLocal and hrpTarget then
				local args = { ... }
				-- args[1] thường là direction Vector3 trong Blox Fruits
				if type(args[1]) == "userdata" and typeof(args[1]) == "Vector3" then
					args[1] = (hrpTarget.Position - hrpLocal.Position).Unit
				end
				return fireGoc(self, action, table.unpack(args))
			end
		end
		return fireGoc(self, action, ...)
	end :: any

	hookConn = remote.ChildAdded:Connect(function() end) -- dummy để giữ ref
end

local function thoatHook()
	if hookConn then
		hookConn:Disconnect()
		hookConn = nil
	end
end

---------------------------------------------------------------------
-- Heartbeat loop: scan target + vẽ tracer mỗi frame
---------------------------------------------------------------------
local kn2 = RunService.Heartbeat:Connect(function()
	if not SA.batSA then
		tracerLine.Visible = false
		return
	end

	-- Kích hoạt hook lần đầu khi SA bật
	batHook()

	-- Tìm target gần nhất
	SA.target = tiemGan()

	local nguoichoi4 = Players.LocalPlayer
	local charLocal  = nguoichoi4.Character
	local hrpLocal   = charLocal and layHRP(charLocal)

	if SA.target and hrpLocal then
		local hrpTarget = layHRP(SA.target)
		if hrpTarget then
			-- Vẽ tracer
			local spFrom, inFrom = sodiemMH(hrpLocal.Position)
			local spTo,   inTo   = sodiemMH(hrpTarget.Position)
			if inFrom and inTo then
				tracerLine.From    = Vector2.new(spFrom.X, spFrom.Y)
				tracerLine.To      = Vector2.new(spTo.X, spTo.Y)
				tracerLine.Visible = true
			else
				tracerLine.Visible = false
			end
		else
			tracerLine.Visible = false
		end
	else
		tracerLine.Visible = false
		SA.target = nil
	end
end)

-- Dọn dẹp khi GUI bị destroy
gui.Destroying:Connect(function()
	kn2:Disconnect()
	thoatHook()
	if tracerLine then
		tracerLine.Remove()
	end
end)

---------------------------------------------------------------------
-- Done. Combat tab: Silent Aim + Target Selector + Tracer live.
---------------------------------------------------------------------
if cam then
	table.insert(kn, cam:GetPropertyChangedSignal("ViewportSize"):Connect(khop))
end
gui.Destroying:Connect(function()
	for _, c in ipairs(kn) do
		c:Disconnect()
	end
end)
if loiLucide then
	warn("[CamHub] Lucide library not loaded (" .. loiLucide .. "). Using text placeholders. HttpGet/loadstring only exist in executor-style environments; in normal Studio put the lucide-roblox ModuleScript at ReplicatedStorage.Lucide.")
end
for goc_, dung in pairs(iconThayThe) do
	warn(("[CamHub] Icon '%s' not in this Lucide version -> using '%s'."):format(goc_, dung))
end
if Lucide and #iconThieu > 0 then
	warn("[CamHub] No Lucide icon found for: " .. table.concat(iconThieu, ", "))
end
khop()
