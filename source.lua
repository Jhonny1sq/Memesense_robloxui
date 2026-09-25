--[[
    UnSky GUI Library  •  v2.0
    Memesense-styled Roblox UI library.

    Load:
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Jhonny1sq/Memesense_robloxui/refs/heads/main/source.lua"))()

    Use:
        local Win = Library:Window({
            Title    = "Meme",
            Subtitle = "Sense",
            ToggleKey = Enum.KeyCode.Delete,
        })

        local Main = Win:Tab("Main")
        Main:Section("Visuals")
        Main:Toggle("Enemy Glow", false, function(v) print(v) end)
        Main:Button("Print Hi", function() print("hi") end)
        Main:Slider("FOV", 0, 180, 90, function(v) end)
        Main:Textbox("Name", "", function(v) end)
        Main:Dropdown("Hitbox", {"Head","Chest","Pelvis"}, "Head", function(v) end)
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
local LocalPlayer      = Players.LocalPlayer

-- ==========================================================================
-- LIBRARY TABLE
-- ==========================================================================
local Library = {}
Library.Version = "2.0.0"

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
    win.Tabs         = {}
    win.Flags        = {}
    win._conns       = {}
    win._destroyed   = false
    win._activeTab   = nil

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
        Size = UDim2.new(1, -30, 1, 0),
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
    win.Pages = pages
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

    -- ======================================================================
    -- TAB
    -- ======================================================================
        -- ======================================================================
    -- TAB
    -- ======================================================================
    function win:Tab(name)
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

        local btnLabel = new("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
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

        tab.Frame     = page
        tab.Button    = btn
        tab.Indicator = indicator
        tab.BtnLabel  = btnLabel   -- renamed from tab.Label

        -- Select
        function tab:Select()
            for _, t in ipairs(win.Tabs) do
                t.Frame.Visible     = false
                t.Indicator.Visible = false
                t.BtnLabel.TextColor3 = Theme.TextDim
                tween(t.Button, { BackgroundTransparency = 1 }, 0.12)
            end
            page.Visible        = true
            indicator.Visible   = true
            btnLabel.TextColor3 = Theme.Text
            win._activeTab      = tab
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
        -- TOGGLE
        -- ------------------------------------------------------------------
        function tab:Toggle(label, default, callback)
            local state = default and true or false
            local row = makeRow(34)

            new("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 14,
                Font = Theme.FontBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local track = new("Frame", {
                Size = UDim2.new(0, 42, 0, 20),
                Position = UDim2.new(1, -54, 0.5, -10),
                BackgroundColor3 = state and accent or Theme.ElementActive,
                BorderSizePixel = 0,
                Parent = row,
            })
            corner(track, 10)

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
                if isMouse(input) then set(not state) end
            end))

            set(state, false)

            local obj = {}
            function obj:Set(v) set(v, true) end
            function obj:Get() return state end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end
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

            local header = new("TextButton", {
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
                Parent = header,
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
                Parent = header,
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

            table.insert(win._conns, header.MouseButton1Click:Connect(function()
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
            return obj
        end

        -- ------------------------------------------------------------------
        -- KEYBIND
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

    function win:Destroy()
        win._destroyed = true
        for _, c in ipairs(win._conns) do
            pcall(function() c:Disconnect() end)
        end
        win._conns = {}
        gui:Destroy()
    end

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
