--[[
    UnSky GUI Library  •  v3.0
    Memesense-styled Roblox UI library with Lucide icons, color picker,
    integrated keybinds, and config save/load.

    Load:
        local Library = loadstring(game:HttpGet("URL"))()

    Use:
        local Win = Library:Window({
            Title     = "Meme",
            Subtitle  = "Sense",
            ToggleKey = Enum.KeyCode.Delete,
        })

        local Main = Win:Tab("Main", "gamepad-2")
        Main:Section("Visuals")
        Main:Toggle("Enemy Glow", false, function(v) print(v) end, Enum.KeyCode.G)
        Main:Button("Print Hi", function() print("hi") end)
        Main:Slider("FOV", 0, 180, 90, function(v) end)
        Main:Textbox("Name", "", function(v) end)
        Main:Dropdown("Hitbox", {"Head","Chest","Pelvis"}, "Head", function(v) end)
        Main:ColorPicker("Accent", Color3.fromRGB(255, 0, 5), function(c) end)
        Main:Keybind("Aim Key", Enum.KeyCode.E, function(k) end)

        Library:Notify("loaded.", 4)
]]

-- ==========================================================================
-- SERVICES
-- ==========================================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

-- ==========================================================================
-- LUCIDE ICONS
-- sprite sheet, no asset uploading needed.
-- ==========================================================================
local LUCIDE_SHEET = "rbxassetid://15269177520"

-- name -> {offsetX, offsetY, size}
-- using 48px icons from the 48x48 grid
local LucideIcons = {
    ["keyboard"]      = Vector2.new(0, 0),
    ["settings"]      = Vector2.new(48, 0),
    ["palette"]       = Vector2.new(96, 0),
    ["save"]          = Vector2.new(144, 0),
    ["gamepad-2"]     = Vector2.new(192, 0),
    ["crosshair"]     = Vector2.new(240, 0),
    ["eye"]           = Vector2.new(288, 0),
    ["eye-off"]       = Vector2.new(336, 0),
    ["shield"]        = Vector2.new(384, 0),
    ["sword"]         = Vector2.new(432, 0),
    ["user"]          = Vector2.new(480, 0),
    ["users"]         = Vector2.new(528, 0),
    ["map"]           = Vector2.new(576, 0),
    ["boxes"]         = Vector2.new(624, 0),
    ["mouse-pointer"] = Vector2.new(672, 0),
    ["list"]          = Vector2.new(720, 0),
    ["folder"]        = Vector2.new(768, 0),
    ["home"]          = Vector2.new(816, 0),
    ["zap"]           = Vector2.new(864, 0),
    ["activity"]      = Vector2.new(912, 0),
}

local function getIcon(name)
    local pos = LucideIcons[name]
    if not pos then return nil end
    return {
        Image = LUCIDE_SHEET,
        ImageRectOffset = pos,
        ImageRectSize = Vector2.new(48, 48),
    }
end

-- ==========================================================================
-- LIBRARY TABLE
-- ==========================================================================
local Library = {}
Library.Version = "3.0.0"
Library.SaveManager = nil

Library.Theme = {
    Background    = Color3.fromRGB(0, 0, 0),
    Surface       = Color3.fromRGB(14, 14, 14),
    Element       = Color3.fromRGB(20, 20, 20),
    ElementHover  = Color3.fromRGB(30, 30, 30),
    ElementActive = Color3.fromRGB(38, 38, 38),
    Accent        = Color3.fromRGB(255, 0, 5),
    Text          = Color3.fromRGB(240, 240, 240),
    TextDim       = Color3.fromRGB(140, 140, 140),
    Outline       = Color3.fromRGB(30, 30, 30),
    Font          = Enum.Font.SourceSans,
    FontBold      = Enum.Font.SourceSansBold,
    Corner        = 6,
}

local Theme = Library.Theme

-- ==========================================================================
-- HELPERS
-- ==========================================================================
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in next, (props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(p, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or Theme.Corner) }, p)
end

local function stroke(p, col, thick, trans)
    return new("UIStroke", {
        Color = col or Theme.Outline,
        Thickness = thick or 1,
        Transparency = trans or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function pad(p, all)
    all = all or 0
    return new("UIPadding", {
        PaddingTop    = UDim.new(0, all),
        PaddingBottom = UDim.new(0, all),
        PaddingLeft   = UDim.new(0, all),
        PaddingRight  = UDim.new(0, all),
    }, p)
end

local function tween(o, props, t, style)
    if typeof(o) ~= "Instance" then return end
    TweenService:Create(o, TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ), props):Play()
end

local function call(fn, ...)
    if type(fn) == "function" then
        task.spawn(fn, ...)
    end
end

local function isMouse(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

-- ==========================================================================
-- WINDOW
-- ==========================================================================
function Library:Window(cfg)
    cfg = cfg or {}

    local win = {}
    win.Tabs        = {}
    win.Flags       = {}
    win.Elements    = {}
    win._conns      = {}
    win._destroyed  = false
    win._activeTab  = nil

    local accent    = cfg.Accent or Theme.Accent
    local title     = cfg.Title or "Meme"
    local subtitle  = cfg.Subtitle or "Sense"
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.Delete
    local size      = cfg.Size or UDim2.new(0, 568, 0, 445)
    local pos       = cfg.Position or UDim2.new(
        0.5, -size.X.Offset / 2,
        0.5, -size.Y.Offset / 2
    )

    -- === ScreenGui ===
    local gui = new("ScreenGui", {
        Name = "UnSkyGUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, LocalPlayer:WaitForChild("PlayerGui"))
    win.Gui = gui

    -- === Main frame ===
    local main = new("Frame", {
        Name = "Main",
        Size = size,
        Position = pos,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    }, gui)
    corner(main, 8)
    stroke(main, Theme.Outline, 1, 0.3)
    win.Frame = main

    -- === Header ===
    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
    }, main)

    local titleRow = new("Frame", {
        Size = UDim2.new(1, -130, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
    }, header)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, titleRow)

    new("TextLabel", {
        LayoutOrder = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = accent,
        TextSize = 25,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleRow)

    new("TextLabel", {
        LayoutOrder = 2,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = Theme.Text,
        TextSize = 25,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, titleRow)

    -- === Header buttons (config / settings) ===
    local headerBtns = new("Frame", {
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(1, -110, 0, 0),
        BackgroundTransparency = 1,
    }, header)
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, headerBtns)

    -- Save button
    local saveBtn = new("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 1,
    }, headerBtns)
    corner(saveBtn, 6)
    local saveIcon = getIcon("save")
    if saveIcon then
        new("ImageLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0.5, -8, 0.5, -8),
            BackgroundTransparency = 1,
            Image = saveIcon.Image,
            ImageRectOffset = saveIcon.ImageRectOffset,
            ImageRectSize = saveIcon.ImageRectSize,
            ImageColor3 = Theme.TextDim,
            Parent = saveBtn,
        })
    end

    -- Settings button (color picker for accent)
    local settingsBtn = new("TextButton", {
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 2,
    }, headerBtns)
    corner(settingsBtn, 6)
    local settingsIcon = getIcon("palette")
    if settingsIcon then
        new("ImageLabel", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0.5, -8, 0.5, -8),
            BackgroundTransparency = 1,
            Image = settingsIcon.Image,
            ImageRectOffset = settingsIcon.ImageRectOffset,
            ImageRectSize = settingsIcon.ImageRectSize,
            ImageColor3 = Theme.TextDim,
            Parent = settingsBtn,
        })
    end

    -- === RGB divider ===
    local divider = new("Frame", {
        Name = "RGB",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, main)

    local gradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
        }),
    }, divider)

    table.insert(win._conns, RunService.RenderStepped:Connect(function()
        if win._destroyed then return end
        local t = os.clock() * 0.3 % 1
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(t, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV((t + 0.35) % 1, 1, 1)),
        })
    end))

    -- === Content ===
    local content = new("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -51),
        Position = UDim2.new(0, 0, 0, 51),
        BackgroundTransparency = 1,
    }, main)

    -- Sidebar
    local sidebar = new("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 150, 1, -8),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundTransparency = 1,
    }, content)
    new("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)
    new("UIPadding", {
        PaddingTop   = UDim.new(0, 6),
        PaddingLeft  = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }, sidebar)

    -- Pages
    local pages = new("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -160, 1, -8),
        Position = UDim2.new(0, 156, 0, 4),
        BackgroundTransparency = 1,
    }, content)
    win.Pages   = pages
    win.Sidebar = sidebar

    -- === Drag ===
    local dragging, dragStart, startPos
    local function updateDrag(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    table.insert(win._conns, header.InputBegan:Connect(function(input)
        if isMouse(input) then
            dragging  = true
            dragStart = input.Position
            startPos  = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    table.insert(win._conns, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end))

    -- === Toggle key ===
    table.insert(win._conns, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end))

    -- === Accent color updater ===
    local accentUpdaters = {}
    function win:SetAccent(color)
        Theme.Accent = color
        accent = color
        for _, fn in ipairs(accentUpdaters) do fn(color) end
    end

    -- ======================================================================
    -- TAB
    -- ======================================================================
    function win:Tab(name, iconName)
        local tab = {}
        tab.Name      = name
        tab.Window    = win
        tab._elements = {}

        -- Sidebar button
        local btn = new("TextButton", {
            Name = "Tab_" .. name,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, sidebar)
        corner(btn, 6)

        -- Icon
        local iconOffset = 14
        if iconName then
            local ico = getIcon(iconName)
            if ico then
                new("ImageLabel", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 12, 0.5, -8),
                    BackgroundTransparency = 1,
                    Image = ico.Image,
                    ImageRectOffset = ico.ImageRectOffset,
                    ImageRectSize = ico.ImageRectSize,
                    ImageColor3 = Theme.TextDim,
                    Parent = btn,
                })
                iconOffset = 34
            end
        end

        local btnLabel = new("TextLabel", {
            Size = UDim2.new(1, -iconOffset - 10, 1, 0),
            Position = UDim2.new(0, iconOffset, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })

        local indicator = new("Frame", {
            Size = UDim2.new(0, 3, 0, 16),
            Position = UDim2.new(0, 0, 0.5, -8),
            BackgroundColor3 = accent,
            BorderSizePixel = 0,
            Visible = false,
        }, btn)
        corner(indicator, 2)
        table.insert(accentUpdaters, function(c) indicator.BackgroundColor3 = c end)

        -- Page
        local page = new("ScrollingFrame", {
            Name = "Page_" .. name,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = accent,
            Visible = false,
        }, pages)
        new("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        new("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
        }, page)

        tab._frame     = page
        tab._btn       = btn
        tab._indicator = indicator
        tab._btnLabel  = btnLabel

        -- Select
        function tab:Select()
            for _, t in ipairs(win.Tabs) do
                t._frame.Visible       = false
                t._indicator.Visible   = false
                t._btnLabel.TextColor3 = Theme.TextDim
                tween(t._btn, { BackgroundTransparency = 1 }, 0.12)
                if t._icon then t._icon.ImageColor3 = Theme.TextDim end
            end
            page.Visible         = true
            indicator.Visible    = true
            btnLabel.TextColor3  = Theme.Text
            win._activeTab       = tab
            if tab._icon then tab._icon.ImageColor3 = accent end
        end

        -- Hover
        table.insert(win._conns, btn.MouseEnter:Connect(function()
            if win._activeTab ~= tab then
                tween(btn, { BackgroundTransparency = 0.5 })
            end
        end))
        table.insert(win._conns, btn.MouseLeave:Connect(function()
            if win._activeTab ~= tab then
                tween(btn, { BackgroundTransparency = 1 })
            end
        end))
        table.insert(win._conns, btn.MouseButton1Click:Connect(function()
            tab:Select()
        end))

        -- ------------------------------------------------------------------
        -- ROW FACTORY
        -- ------------------------------------------------------------------
        local function makeRow(height)
            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, height or 34),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel = 0,
            }, page)
            corner(row, 6)
            stroke(row, Theme.Outline, 1, 0.4)
            table.insert(win._conns, row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = Theme.ElementHover })
            end))
            table.insert(win._conns, row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = Theme.Element })
            end))
            return row
        end

        -- ------------------------------------------------------------------
        -- TOGGLE (with integrated keybind button)
        -- ------------------------------------------------------------------
        function tab:Toggle(label, default, callback, bindKey)
            local state = default and true or false
            local currentBind = bindKey
            local listening = false

            local row = makeRow(34)

            -- Keybind button (keyboard icon) — only if bindKey provided
            local keyBtn
            if bindKey then
                keyBtn = new("TextButton", {
                    Size = UDim2.new(0, 24, 0, 24),
                    Position = UDim2.new(1, -84, 0.5, -12),
                    BackgroundColor3 = Theme.ElementActive,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = row,
                })
                corner(keyBtn, 4)

                local kbIcon = getIcon("keyboard")
                local kbImg
                if kbIcon then
                    kbImg = new("ImageLabel", {
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0.5, -6, 0.5, -6),
                        BackgroundTransparency = 1,
                        Image = kbIcon.Image,
                        ImageRectOffset = kbIcon.ImageRectOffset,
                        ImageRectSize = kbIcon.ImageRectSize,
                        ImageColor3 = Theme.TextDim,
                        Parent = keyBtn,
                    })
                end

                table.insert(win._conns, keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    if kbImg then kbImg.ImageColor3 = accent end
                end))
            end

            -- Label
            new("TextLabel", {
                Size = UDim2.new(1, bindKey and -110 or -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            -- Toggle track
            local track = new("Frame", {
                Size = UDim2.new(0, 42, 0, 20),
                Position = UDim2.new(1, -54, 0.5, -10),
                BackgroundColor3 = state and accent or Theme.ElementActive,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(track, 10)
            table.insert(accentUpdaters, function(c)
                if state then track.BackgroundColor3 = c end
            end)

            local knob = new("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = state
                    and UDim2.new(1, -18, 0.5, -8)
                    or  UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
                Parent = track,
            })
            corner(knob, 8)

            local function set(v, fire)
                state = v and true or false
                tween(track, {
                    BackgroundColor3 = state and accent or Theme.ElementActive
                }, 0.15)
                tween(knob, {
                    Position = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8)
                }, 0.15)
                win.Flags[label] = state
                if fire ~= false then call(callback, state) end
            end

            table.insert(win._conns, row.InputBegan:Connect(function(input)
                if isMouse(input) then
                    if keyBtn and input.Position.X >= keyBtn.AbsolutePosition.X then return end
                    set(not state)
                end
            end))

            -- Keybind listener
            if bindKey then
                table.insert(win._conns, UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if listening then
                        listening = false
                        if input.KeyCode == Enum.KeyCode.Backspace then
                            currentBind = nil
                        else
                            currentBind = input.KeyCode
                        end
                        if kbImg then kbImg.ImageColor3 = Theme.TextDim end
                        win.Flags[label .. "_key"] = currentBind
                        return
                    end
                    if currentBind and input.KeyCode == currentBind then
                        set(not state)
                    end
                end))
            end

            set(state, false)

            local obj = {}
            function obj:Set(v) set(v, true) end
            function obj:Get() return state end
            function obj:SetKey(k) currentBind = k end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "Toggle", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- BUTTON
        -- ------------------------------------------------------------------
        function tab:Button(label, callback)
            local row = makeRow(34)

            local btn = new("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })

            new("TextLabel", {
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = btn,
            })

            table.insert(win._conns, btn.MouseButton1Click:Connect(function()
                call(callback)
            end))

            local obj = {}
            function obj:Destroy() row:Destroy() end
            return obj
        end

        -- ------------------------------------------------------------------
        -- SLIDER
        -- ------------------------------------------------------------------
        function tab:Slider(label, min, max, default, callback)
            min     = min or 0
            max     = max or 100
            default = default or min
            local value = math.clamp(default, min, max)

            local row = makeRow(48)

            new("TextLabel", {
                Size = UDim2.new(1, -60, 0, 20),
                Position = UDim2.new(0, 12, 0, 4),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local valueLbl = new("TextLabel", {
                Size = UDim2.new(0, 50, 0, 20),
                Position = UDim2.new(1, -58, 0, 4),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Theme.TextDim,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })

            local trackBg = new("Frame", {
                Size = UDim2.new(1, -24, 0, 6),
                Position = UDim2.new(0, 12, 0, 32),
                BackgroundColor3 = Theme.ElementActive,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(trackBg, 3)

            local fill = new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = accent,
                BorderSizePixel = 0,
                Parent = trackBg,
            })
            corner(fill, 3)
            table.insert(accentUpdaters, function(c) fill.BackgroundColor3 = c end)

            local dragging = false
            local function updateFromX(x)
                local pos = math.clamp(
                    (x - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1
                )
                value = min + (max - min) * pos
                value = math.floor(value * 100 + 0.5) / 100
                fill.Size = UDim2.new(pos, 0, 1, 0)
                valueLbl.Text = tostring(value)
                win.Flags[label] = value
                call(callback, value)
            end

            table.insert(win._conns, trackBg.InputBegan:Connect(function(input)
                if isMouse(input) then
                    dragging = true
                    updateFromX(input.Position.X)
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(input.Position.X)
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(input)
                if isMouse(input) then dragging = false end
            end))

            win.Flags[label] = value

            local obj = {}
            function obj:Set(v)
                v = math.clamp(v, min, max)
                value = v
                fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
                valueLbl.Text = tostring(v)
                win.Flags[label] = v
                call(callback, v)
            end
            function obj:Get() return value end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "Slider", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- TEXTBOX
        -- ------------------------------------------------------------------
        function tab:Textbox(label, default, callback)
            default = default or ""
            local row = makeRow(34)

            new("TextLabel", {
                Size = UDim2.new(0.5, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local box = new("TextBox", {
                Size = UDim2.new(0.5, -24, 0, 22),
                Position = UDim2.new(0.5, 0, 0.5, -11),
                BackgroundColor3 = Theme.ElementActive,
                BorderSizePixel = 0,
                Text = default,
                TextColor3 = Theme.Text,
                PlaceholderText = "...",
                PlaceholderColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                ClearTextOnFocus = false,
                Parent = row,
            })
            corner(box, 4)
            pad(box, 6)

            table.insert(win._conns, box.Focused:Connect(function()
                tween(box, { BackgroundColor3 = Theme.Surface })
            end))
            table.insert(win._conns, box.FocusLost:Connect(function()
                tween(box, { BackgroundColor3 = Theme.ElementActive })
                win.Flags[label] = box.Text
                call(callback, box.Text)
            end))

            win.Flags[label] = default

            local obj = {}
            function obj:Set(v) box.Text = tostring(v); win.Flags[label] = box.Text end
            function obj:Get() return box.Text end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "Textbox", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- DROPDOWN
        -- ------------------------------------------------------------------
        function tab:Dropdown(label, options, default, callback)
            options = options or {}
            local selected = default or options[1]
            local open = false

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, page)
            corner(row, 6)
            stroke(row, Theme.Outline, 1, 0.4)

            local headerBtn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })

            new("TextLabel", {
                Size = UDim2.new(0.5, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn,
            })

            local selectedLbl = new("TextLabel", {
                Size = UDim2.new(0.5, -24, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(selected) .. " v",
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = headerBtn,
            })

            local list = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 34),
                BackgroundTransparency = 1,
                Parent = row,
            })
            new("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, list)
            new("UIPadding", {
                PaddingLeft  = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
            }, list)

            for i, opt in ipairs(options) do
                local ob = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    LayoutOrder = i,
                    BackgroundColor3 = Theme.ElementActive,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Text = tostring(opt),
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    Font = Theme.Font,
                    AutoButtonColor = false,
                    Parent = list,
                })
                corner(ob, 4)

                table.insert(win._conns, ob.MouseButton1Click:Connect(function()
                    selected = opt
                    selectedLbl.Text = tostring(opt) .. " v"
                    win.Flags[label] = opt
                    call(callback, opt)
                    open = false
                    list.Size = UDim2.new(1, 0, 0, 0)
                    row.Size  = UDim2.new(1, 0, 0, 34)
                end))
                table.insert(win._conns, ob.MouseEnter:Connect(function()
                    tween(ob, { BackgroundTransparency = 0 })
                end))
                table.insert(win._conns, ob.MouseLeave:Connect(function()
                    tween(ob, { BackgroundTransparency = 0.5 })
                end))
            end

            table.insert(win._conns, headerBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local h = #options * 28
                    list.Size = UDim2.new(1, 0, 0, h)
                    row.Size  = UDim2.new(1, 0, 0, 34 + h)
                else
                    list.Size = UDim2.new(1, 0, 0, 0)
                    row.Size  = UDim2.new(1, 0, 0, 34)
                end
            end))

            win.Flags[label] = selected

            local obj = {}
            function obj:Set(v)
                selected = v
                selectedLbl.Text = tostring(v) .. " v"
                win.Flags[label] = v
                call(callback, v)
            end
            function obj:Get() return selected end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "Dropdown", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- COLOR PICKER
        -- ------------------------------------------------------------------
        function tab:ColorPicker(label, default, callback)
            local color = default or Color3.fromRGB(255, 0, 0)
            local open = false

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = Theme.Element,
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, page)
            corner(row, 6)
            stroke(row, Theme.Outline, 1, 0.4)

            local headerBtn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })

            new("TextLabel", {
                Size = UDim2.new(0.5, -12, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn,
            })

            local swatch = new("Frame", {
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -32, 0.5, -10),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Parent = headerBtn,
            })
            corner(swatch, 4)
            stroke(swatch, Theme.Outline, 1, 0.5)

            -- Picker panel
            local panel = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 34),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = row,
            })

            -- Hue slider
            local hueBg = new("Frame", {
                Size = UDim2.new(1, -20, 0, 12),
                Position = UDim2.new(0, 10, 0, 10),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = panel,
            })
            corner(hueBg, 6)

            local hueGradient = new("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
            }, hueBg)

            local hueKnob = new("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, -7, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = hueBg,
            })
            corner(hueKnob, 7)
            stroke(hueKnob, Color3.fromRGB(0, 0, 0), 2, 0.3)

            -- Sat/Val square
            local svBg = new("Frame", {
                Size = UDim2.new(1, -20, 0, 80),
                Position = UDim2.new(0, 10, 0, 30),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Parent = panel,
            })
            corner(svBg, 4)

            local svGradientX = new("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0)),
                }),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, svBg)

            local svGradientY = new("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
                }),
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, svBg)

            local svKnob = new("Frame", {
                Size = UDim2.new(0, 10, 0, 10),
                Position = UDim2.new(1, -5, 0, -5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = svBg,
            })
            corner(svKnob, 5)
            stroke(svKnob, Color3.fromRGB(0, 0, 0), 1, 0.3)

            -- Hex input
            local hexBox = new("TextBox", {
                Size = UDim2.new(1, -20, 0, 22),
                Position = UDim2.new(0, 10, 0, 120),
                BackgroundColor3 = Theme.ElementActive,
                BorderSizePixel = 0,
                Text = color:ToHex(),
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Theme.Font,
                ClearTextOnFocus = false,
                Parent = panel,
            })
            corner(hexBox, 4)
            pad(hexBox, 6)

            local function updateColor(c, skipHex)
                color = c
                swatch.BackgroundColor3 = c
                svBg.BackgroundColor3 = Color3.fromHSV(
                    Color3.toHSV(c)
                )
                if not skipHex then hexBox.Text = c:ToHex() end
                win.Flags[label] = c
                call(callback, c)
            end

            -- Hue drag
            local hueDrag = false
            table.insert(win._conns, hueBg.InputBegan:Connect(function(input)
                if isMouse(input) then
                    hueDrag = true
                    local pos = math.clamp(
                        (input.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1
                    )
                    hueKnob.Position = UDim2.new(pos, -7, 0.5, -7)
                    local h, s, v = Color3.toHSV(color)
                    local nc = Color3.fromHSV(pos, s, v)
                    updateColor(nc)
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(input)
                if hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    local pos = math.clamp(
                        (input.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1
                    )
                    hueKnob.Position = UDim2.new(pos, -7, 0.5, -7)
                    local h, s, v = Color3.toHSV(color)
                    local nc = Color3.fromHSV(pos, s, v)
                    updateColor(nc)
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(input)
                if isMouse(input) then hueDrag = false end
            end))

            -- SV drag
            local svDrag = false
            table.insert(win._conns, svBg.InputBegan:Connect(function(input)
                if isMouse(input) then
                    svDrag = true
                    local rx = math.clamp(
                        (input.Position.X - svBg.AbsolutePosition.X) / svBg.AbsoluteSize.X, 0, 1
                    )
                    local ry = math.clamp(
                        (input.Position.Y - svBg.AbsolutePosition.Y) / svBg.AbsoluteSize.Y, 0, 1
                    )
                    svKnob.Position = UDim2.new(rx, -5, ry, -5)
                    local h = select(1, Color3.toHSV(color))
                    local nc = Color3.fromHSV(h, rx, 1 - ry)
                    updateColor(nc)
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(input)
                if svDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    local rx = math.clamp(
                        (input.Position.X - svBg.AbsolutePosition.X) / svBg.AbsoluteSize.X, 0, 1
                    )
                    local ry = math.clamp(
                        (input.Position.Y - svBg.AbsolutePosition.Y) / svBg.AbsoluteSize.Y, 0, 1
                    )
                    svKnob.Position = UDim2.new(rx, -5, ry, -5)
                    local h = select(1, Color3.toHSV(color))
                    local nc = Color3.fromHSV(h, rx, 1 - ry)
                    updateColor(nc)
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(input)
                if isMouse(input) then svDrag = false end
            end))

            -- Hex input
            table.insert(win._conns, hexBox.FocusLost:Connect(function()
                local ok, c = pcall(Color3.fromHex, hexBox.Text)
                if ok then
                    updateColor(c, true)
                else
                    hexBox.Text = color:ToHex()
                end
            end))

            -- Toggle panel
            table.insert(win._conns, headerBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    panel.Size = UDim2.new(1, 0, 0, 152)
                    row.Size   = UDim2.new(1, 0, 0, 34 + 152)
                else
                    panel.Size = UDim2.new(1, 0, 0, 0)
                    row.Size   = UDim2.new(1, 0, 0, 34)
                end
            end))

            win.Flags[label] = color

            local obj = {}
            function obj:Set(c) updateColor(c) end
            function obj:Get() return color end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "ColorPicker", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- KEYBIND (standalone)
        -- ------------------------------------------------------------------
        function tab:Keybind(label, default, callback)
            local current   = default or Enum.KeyCode.Unknown
            local listening = false

            local row = makeRow(34)

            new("TextLabel", {
                Size = UDim2.new(1, -100, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local btn = new("TextButton", {
                Size = UDim2.new(0, 80, 0, 22),
                Position = UDim2.new(1, -92, 0.5, -11),
                BackgroundColor3 = Theme.ElementActive,
                BorderSizePixel = 0,
                Text = current.Name,
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                AutoButtonColor = false,
                Parent = row,
            })
            corner(btn, 4)

            table.insert(win._conns, btn.MouseButton1Click:Connect(function()
                listening = true
                btn.Text = "..."
                btn.TextColor3 = accent
            end))

            table.insert(win._conns, UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if listening then
                    listening = false
                    current = (input.KeyCode == Enum.KeyCode.Backspace)
                        and Enum.KeyCode.Unknown
                        or  input.KeyCode
                    btn.Text = current.Name
                    btn.TextColor3 = Theme.TextDim
                    win.Flags[label] = current
                    call(callback, current)
                elseif current ~= Enum.KeyCode.Unknown and input.KeyCode == current then
                    call(callback, current)
                end
            end))

            win.Flags[label] = current

            local obj = {}
            function obj:Set(v)
                current = v
                btn.Text = v.Name
                win.Flags[label] = v
                call(callback, v)
            end
            function obj:Get() return current end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
            table.insert(win.Elements, { Type = "Keybind", Label = label, Object = obj })
            return obj
        end

        -- ------------------------------------------------------------------
        -- LABEL / DIVIDER / SECTION
        -- ------------------------------------------------------------------
        function tab:Label(text)
            local lbl = new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
            local obj = {}
            function obj:Set(v) lbl.Text = v end
            function obj:Destroy() lbl:Destroy() end
            return obj
        end

        function tab:Divider()
            local f = new("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Theme.Outline,
                BorderSizePixel = 0,
                Parent = page,
            })
            local obj = {}
            function obj:Destroy() f:Destroy() end
            return obj
        end

        function tab:Section(text)
            local f = new("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                Parent = page,
            })
            new("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = string.upper(text),
                TextColor3 = accent,
                TextSize = 12,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = f,
            })
            local obj = {}
            function obj:Destroy() f:Destroy() end
            table.insert(accentUpdaters, function(c)
                f:FindFirstChildOfClass("TextLabel").TextColor3 = c
            end)
            return obj
        end

        table.insert(win.Tabs, tab)
        if #win.Tabs == 1 then
            tab:Select()
        end
        return tab
    end

    -- ======================================================================
    -- WINDOW METHODS
    -- ======================================================================
    function win:SelectTab(name)
        for _, t in ipairs(win.Tabs) do
            if t.Name == name then t:Select() return end
        end
    end

    function win:GetFlag(name) return win.Flags[name] end
    function win:SetFlag(name, v) win.Flags[name] = v end
    function win:Toggle() gui.Enabled = not gui.Enabled end
    function win:SetToggleKey(key) toggleKey = key end

    -- === Save config ===
    function win:SaveConfig(name)
        local data = { flags = win.Flags, version = Library.Version }
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not ok then return false, "encode failed" end
        if writefile then
            writefile("unsky_" .. (name or "default") .. ".json", encoded)
            return true
        end
        return false, "no filesystem"
    end

    -- === Load config ===
    function win:LoadConfig(name)
        if not isfile or not readfile then return false, "no filesystem" end
        local path = "unsky_" .. (name or "default") .. ".json"
        if not isfile(path) then return false, "file not found" end
        local ok, raw = pcall(readfile, path)
        if not ok then return false, "read failed" end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 or type(data) ~= "table" then return false, "decode failed" end
        for k, v in next, (data.flags or {}) do
            win.Flags[k] = v
            for _, el in ipairs(win.Elements) do
                if el.Label == k and el.Object.Set then
                    pcall(function() el.Object:Set(v) end)
                end
            end
        end
        return true
    end

    function win:Destroy()
        win._destroyed = true
        for _, c in ipairs(win._conns) do
            pcall(function() c:Disconnect() end)
        end
        win._conns = {}
        gui:Destroy()
    end

    -- === Wire up save button ===
    table.insert(win._conns, saveBtn.MouseButton1Click:Connect(function()
        local ok, err = win:SaveConfig("default")
        if ok then
            Library:Notify("config saved.", 2)
        else
            Library:Notify("save failed: " .. tostring(err), 3)
        end
    end))

    -- === Wire up settings button (accent color picker) ===
    table.insert(win._conns, settingsBtn.MouseButton1Click:Connect(function()
        -- quick accent picker in a notification-style popup
        local popup = new("Frame", {
            Size = UDim2.new(0, 200, 0, 100),
            Position = UDim2.new(0.5, -100, 0.5, -50),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Parent = gui,
        })
        corner(popup, 8)
        stroke(popup, Theme.Outline, 1, 0.2)

        new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Text = "accent color",
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = popup,
        })

        local close = new("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -28, 0, 8),
            BackgroundTransparency = 1,
            Text = "x",
            TextColor3 = Theme.TextDim,
            TextSize = 14,
            Font = Theme.FontBold,
            Parent = popup,
        })
        table.insert(win._conns, close.MouseButton1Click:Connect(function()
            popup:Destroy()
        end))

        local hue = new("Frame", {
            Size = UDim2.new(1, -20, 0, 12),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = popup,
        })
        corner(hue, 6)

        new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
        }, hue)

        local hueKnob = new("Frame", {
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, -8, 0.5, -8),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = hue,
        })
        corner(hueKnob, 8)
        stroke(hueKnob, Color3.fromRGB(0, 0, 0), 2, 0.3)

        local hueDrag = false
        local function updateHue(x)
            local p = math.clamp((x - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
            hueKnob.Position = UDim2.new(p, -8, 0.5, -8)
            local c = Color3.fromHSV(p, 1, 1)
            win:SetAccent(c)
        end

        table.insert(win._conns, hue.InputBegan:Connect(function(input)
            if isMouse(input) then
                hueDrag = true
                updateHue(input.Position.X)
            end
        end))
        table.insert(win._conns, UserInputService.InputChanged:Connect(function(input)
            if hueDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                updateHue(input.Position.X)
            end
        end))
        table.insert(win._conns, UserInputService.InputEnded:Connect(function(input)
            if isMouse(input) then hueDrag = false end
        end))
    end))

    return win
end

-- ==========================================================================
-- NOTIFICATIONS
-- ==========================================================================
function Library:Notify(text, duration)
    duration = duration or 4

    local pg = LocalPlayer:WaitForChild("PlayerGui")
    local notifGui = pg:FindFirstChild("UnSkyNotifications")
    if not notifGui then
        notifGui = new("ScreenGui", {
            Name = "UnSkyNotifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, pg)
        new("Frame", {
            Name = "Container",
            Size = UDim2.new(0, 260, 1, -40),
            Position = UDim2.new(1, -280, 0, 20),
            BackgroundTransparency = 1,
        }, notifGui)
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment   = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, notifGui:FindFirstChild("Container"))
    end

    local container = notifGui:FindFirstChild("Container")
    if not container then return end

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
    }, container)
    corner(frame, 6)
    stroke(frame, Theme.Outline, 1, 0.3)

    new("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = frame,
    })

    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = frame,
    })
    corner(bar, 2)

    task.delay(duration, function()
        tween(frame, { BackgroundTransparency = 1 }, 0.3)
        for _, d in ipairs(frame:GetDescendants()) do
            if d:IsA("TextLabel") then tween(d, { TextTransparency = 1 }, 0.3) end
            if d:IsA("Frame")     then tween(d, { BackgroundTransparency = 1 }, 0.3) end
        end
        task.wait(0.4)
        frame:Destroy()
    end)
end

return Library
