local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local LocalPlayer      = Players.LocalPlayer

local function getContainer()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Theme = {
    Background    = Color3.fromRGB(0, 0, 0),
    Accent        = Color3.fromRGB(255, 0, 5),
    AccentOn      = Color3.fromRGB(255, 50, 50),
    Text          = Color3.fromRGB(255, 255, 255),
    TextDim       = Color3.fromRGB(140, 140, 140),
    TextMid       = Color3.fromRGB(190, 190, 190),
    Element       = Color3.fromRGB(18, 18, 18),
    ElementHover  = Color3.fromRGB(28, 28, 28),
    ElementActive = Color3.fromRGB(36, 36, 36),
    Font          = Enum.Font.SourceSans,
    FontBold      = Enum.Font.SourceSansBold,
}

local CHECK_IMG = "rbxassetid://14189590169"

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in next, (props or {}) do i[k] = v end
    if parent then i.Parent = parent end
    return i
end

local function tween(i, props, t)
    if typeof(i) ~= "Instance" then return end
    TweenService:Create(i, TweenInfo.new(t or 0.15), props):Play()
end

local function call(fn, ...)
    if type(fn) == "function" then task.spawn(fn, ...) end
end

local function isMouse(inp)
    return inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch
end

local Library = {}
Library.Version = "5.2.0"
Library.Theme   = Theme

function Library:Window(cfg)
    cfg = cfg or {}

    local win = {
        Tabs       = {},
        Flags      = {},
        Elements   = {},
        _conns     = {},
        _destroyed = false,
        _activeTab = nil,
    }

    local accent    = cfg.Accent or Theme.Accent
    local toggleKey = cfg.ToggleKey or Enum.KeyCode.Delete
    local size      = cfg.Size or UDim2.new(0, 568, 0, 445)
    local pos       = cfg.Position or UDim2.new(
        0.5, -size.X.Offset / 2,
        0.5, -size.Y.Offset / 2
    )

    local gui = new("ScreenGui", {
        Name = "Memesense",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
    }, getContainer())
    win.Gui = gui

    local main = new("Frame", {
        Size = size,
        Position = pos,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
    }, gui)
    win.Frame = main

    local rgbLine = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, main)

    local rgbGradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255)),
        }),
    }, rgbLine)

    table.insert(win._conns, RunService.RenderStepped:Connect(function()
        if win._destroyed then return end
        local t = os.clock() * 0.3 % 1
        rgbGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(t, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV((t + 0.35) % 1, 1, 1)),
        })
    end))

    new("TextLabel", {
        Size = UDim2.new(0, 97, 0, 50),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = cfg.Title or "Meme",
        TextColor3 = Theme.Accent,
        TextSize = 25,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)

    new("TextLabel", {
        Size = UDim2.new(0, 97, 0, 50),
        Position = UDim2.new(0, 64, 0, 0),
        BackgroundTransparency = 1,
        Text = cfg.Subtitle or "Sense",
        TextColor3 = Theme.Text,
        TextSize = 25,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)

    local saveBtn = new("TextButton", {
        Size = UDim2.new(0, 70, 0, 26),
        Position = UDim2.new(1, -82, 0, 12),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Text = "Save",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Theme.FontBold,
        AutoButtonColor = false,
    }, main)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, saveBtn)

    local themeBtn = new("TextButton", {
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(1, -46, 0, 12),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0,
        Text = "...",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Theme.FontBold,
        AutoButtonColor = false,
    }, main)
    new("UICorner", { CornerRadius = UDim.new(0, 4) }, themeBtn)

    table.insert(win._conns, saveBtn.MouseEnter:Connect(function()
        tween(saveBtn, { BackgroundColor3 = Theme.ElementHover })
    end))
    table.insert(win._conns, saveBtn.MouseLeave:Connect(function()
        tween(saveBtn, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) })
    end))
    table.insert(win._conns, themeBtn.MouseEnter:Connect(function()
        tween(themeBtn, { BackgroundColor3 = Theme.ElementHover })
    end))
    table.insert(win._conns, themeBtn.MouseLeave:Connect(function()
        tween(themeBtn, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) })
    end))

    local sidebar = new("Frame", {
        Size = UDim2.new(0, 151, 1, -60),
        Position = UDim2.new(0, 5, 0, 55),
        BackgroundTransparency = 1,
    }, main)

    new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, sidebar)

    local pages = new("Frame", {
        Size = UDim2.new(1, -171, 1, -60),
        Position = UDim2.new(0, 161, 0, 55),
        BackgroundTransparency = 1,
    }, main)
    win.Pages   = pages
    win.Sidebar = sidebar

    local dragging, dragStart, startPos
    table.insert(win._conns, main.InputBegan:Connect(function(inp)
        if isMouse(inp) and (inp.Position.Y - main.AbsolutePosition.Y) < 50 then
            dragging = true
            dragStart = inp.Position
            startPos = main.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    table.insert(win._conns, UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end))

    table.insert(win._conns, UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == toggleKey then
            gui.Enabled = not gui.Enabled
        end
    end))

    function win:Tab(name)
        local tab = {}
        tab.Name     = name
        tab.Window   = win
        tab._current = nil

        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, sidebar)

        local btnLabel = new("TextLabel", {
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Theme.Text,
            TextSize = 14,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })

        tab._btn      = btn
        tab._btnLabel = btnLabel

        local page = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
        }, pages)
        new("UIListLayout", {
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, page)
        new("UIPadding", {
            PaddingTop    = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
        }, page)

        tab._frame = page

        function tab:Select()
            for _, t in ipairs(win.Tabs) do
                t._frame.Visible       = false
                t._btnLabel.TextColor3 = Theme.Text
            end
            page.Visible         = true
            btnLabel.TextColor3  = Theme.Accent
            win._activeTab       = tab
        end

        table.insert(win._conns, btn.MouseButton1Click:Connect(function()
            tab:Select()
        end))

        function tab:Section(title, columns)
            columns = columns or 1

            local sect = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = #page:GetChildren(),
            }, page)
            new("UIListLayout", {
                Padding = UDim.new(0, 4),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, sect)

            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = title or "",
                TextColor3 = Theme.TextMid,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = 1,
                Parent = sect,
            })

            local items = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                Parent = sect,
            })

            if columns > 1 then
                new("UIGridLayout", {
                    CellSize = UDim2.new(1 / columns, -4, 0, 26),
                    CellPadding = UDim2.new(0, 8, 0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, items)
            else
                new("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, items)
            end

            tab._current = items
            return sect
        end

        local function getParent()
            if tab._current then return tab._current end
            return page
        end

        function tab:Toggle(label, default, callback, bindKey)
            local state     = default and true or false
            local bind      = bindKey
            local listening = false

            local cell = new("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
            }, getParent())

            local box = new("TextButton", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 0, 0.5, -9),
                BackgroundColor3 = state and Theme.AccentOn or Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = cell,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 5) }, box)

            local img = new("ImageLabel", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 2, 0, 2),
                BackgroundTransparency = 1,
                Image = CHECK_IMG,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                ImageTransparency = state and 0 or 1,
                Parent = box,
            })

            local labelLbl = new("TextLabel", {
                Size = UDim2.new(1, bindKey and -100 or -30, 1, 0),
                Position = UDim2.new(0, 26, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = cell,
            })

            local keyBtn
            if bindKey ~= nil then
                keyBtn = new("TextButton", {
                    Size = UDim2.new(0, 60, 0, 20),
                    Position = UDim2.new(1, -62, 0.5, -10),
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                    BorderSizePixel = 0,
                    Text = bindKey.Name,
                    TextColor3 = Theme.TextDim,
                    TextSize = 11,
                    Font = Theme.Font,
                    AutoButtonColor = false,
                    Parent = cell,
                })
                new("UICorner", { CornerRadius = UDim.new(0, 4) }, keyBtn)

                table.insert(win._conns, keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                    keyBtn.TextColor3 = Theme.Accent
                end))
            end

            local function set(v, fire)
                state = v and true or false
                box.BackgroundColor3 = state and Theme.AccentOn or Color3.fromRGB(255, 255, 255)
                img.ImageTransparency = state and 0 or 1
                win.Flags[label] = state
                if fire ~= false then call(callback, state) end
            end

            table.insert(win._conns, box.MouseButton1Click:Connect(function()
                set(not state)
            end))

            if bindKey ~= nil then
                table.insert(win._conns, UserInputService.InputBegan:Connect(function(inp, gp)
                    if gp then return end
                    if listening then
                        listening = false
                        bind = (inp.KeyCode == Enum.KeyCode.Backspace) and nil or inp.KeyCode
                        keyBtn.Text = bind and bind.Name or "None"
                        keyBtn.TextColor3 = Theme.TextDim
                        win.Flags[label .. "_key"] = bind
                        return
                    end
                    if bind and inp.KeyCode == bind then
                        set(not state)
                    end
                end))
            end

            set(state, false)

            local obj = {}
            function obj:Set(v) set(v, true) end
            function obj:Get() return state end
            function obj:SetKey(k) bind = k end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() cell:Destroy() end

            table.insert(win.Elements, { Type = "Toggle", Label = label, Object = obj })
            return obj
        end

        function tab:Button(label, callback)
            local row = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                AutoButtonColor = false,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)
            new("UIPadding", { PaddingLeft = UDim.new(0, 10) }, row)
            row.TextXAlignment = Enum.TextXAlignment.Left

            table.insert(win._conns, row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = Theme.ElementHover })
            end))
            table.insert(win._conns, row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) })
            end))
            table.insert(win._conns, row.MouseButton1Click:Connect(function()
                call(callback)
            end))

            local obj = {}
            function obj:Destroy() row:Destroy() end
            return obj
        end

        function tab:Slider(label, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            local value = math.clamp(default, min, max)

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            new("TextLabel", {
                Size = UDim2.new(1, -70, 0, 18),
                Position = UDim2.new(0, 10, 0, 5),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local valueLbl = new("TextLabel", {
                Size = UDim2.new(0, 50, 0, 18),
                Position = UDim2.new(1, -60, 0, 5),
                BackgroundTransparency = 1,
                Text = tostring(value),
                TextColor3 = Theme.TextDim,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = row,
            })

            local trackBg = new("Frame", {
                Size = UDim2.new(1, -20, 0, 3),
                Position = UDim2.new(0, 10, 0, 32),
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderSizePixel = 0,
                Parent = row,
            })

            local fill = new("Frame", {
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = trackBg,
            })

            local dragging = false
            local function updateFromX(x)
                local p = math.clamp((x - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
                value = min + (max - min) * p
                value = math.floor(value * 100 + 0.5) / 100
                fill.Size = UDim2.new(p, 0, 1, 0)
                valueLbl.Text = tostring(value)
                win.Flags[label] = value
                call(callback, value)
            end

            table.insert(win._conns, trackBg.InputBegan:Connect(function(inp)
                if isMouse(inp) then
                    dragging = true
                    updateFromX(inp.Position.X)
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                    updateFromX(inp.Position.X)
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(inp)
                if isMouse(inp) then dragging = false end
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

        function tab:Textbox(label, default, callback)
            default = default or ""
            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            new("TextLabel", {
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local box = new("TextBox", {
                Size = UDim2.new(0.5, -20, 0, 22),
                Position = UDim2.new(0.5, 0, 0.5, -11),
                BackgroundColor3 = Color3.fromRGB(15, 15, 15),
                BorderSizePixel = 0,
                Text = default,
                TextColor3 = Theme.Text,
                PlaceholderText = "...",
                PlaceholderColor3 = Theme.TextDim,
                TextSize = 12,
                Font = Theme.Font,
                ClearTextOnFocus = false,
                Parent = row,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
            new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)

            table.insert(win._conns, box.FocusLost:Connect(function()
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

        function tab:Dropdown(label, options, default, callback)
            options = options or {}
            local selected = default or options[1]
            local open = false

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            local headerBtn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })

            new("TextLabel", {
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn,
            })

            local selectedLbl = new("TextLabel", {
                Size = UDim2.new(0.5, -20, 1, 0),
                Position = UDim2.new(0.5, 0, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(selected),
                TextColor3 = Theme.TextDim,
                TextSize = 12,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = headerBtn,
            })

            local list = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1,
                Parent = row,
            })
            new("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, list)
            new("UIPadding", {
                PaddingLeft   = UDim.new(0, 5),
                PaddingRight  = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
            }, list)

            for i, opt in ipairs(options) do
                local ob = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    LayoutOrder = i,
                    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                    BorderSizePixel = 0,
                    Text = tostring(opt),
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    Font = Theme.Font,
                    AutoButtonColor = false,
                    Parent = list,
                })
                new("UICorner", { CornerRadius = UDim.new(0, 4) }, ob)

                table.insert(win._conns, ob.MouseButton1Click:Connect(function()
                    selected = opt
                    selectedLbl.Text = tostring(opt)
                    win.Flags[label] = opt
                    call(callback, opt)
                    open = false
                    list.Size = UDim2.new(1, 0, 0, 0)
                    row.Size  = UDim2.new(1, 0, 0, 30)
                end))
                table.insert(win._conns, ob.MouseEnter:Connect(function()
                    tween(ob, { BackgroundColor3 = Color3.fromRGB(50, 50, 50) })
                end))
                table.insert(win._conns, ob.MouseLeave:Connect(function()
                    tween(ob, { BackgroundColor3 = Color3.fromRGB(35, 35, 35) })
                end))
            end

            table.insert(win._conns, headerBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local h = #options * 26 + 5
                    list.Size = UDim2.new(1, 0, 0, h)
                    row.Size  = UDim2.new(1, 0, 0, 30 + h)
                else
                    list.Size = UDim2.new(1, 0, 0, 0)
                    row.Size  = UDim2.new(1, 0, 0, 30)
                end
            end))

            win.Flags[label] = selected

            local obj = {}
            function obj:Set(v)
                selected = v
                selectedLbl.Text = tostring(v)
                win.Flags[label] = v
                call(callback, v)
            end
            function obj:Get() return selected end
            function obj:SetCallback(fn) callback = fn end
            function obj:Destroy() row:Destroy() end

            table.insert(win.Elements, { Type = "Dropdown", Label = label, Object = obj })
            return obj
        end

        function tab:Keybind(label, default, callback)
            local current   = default or Enum.KeyCode.Unknown
            local listening = false

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            new("TextLabel", {
                Size = UDim2.new(1, -110, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = row,
            })

            local btn = new("TextButton", {
                Size = UDim2.new(0, 80, 0, 22),
                Position = UDim2.new(1, -88, 0.5, -11),
                BackgroundColor3 = Color3.fromRGB(35, 35, 35),
                BorderSizePixel = 0,
                Text = current.Name,
                TextColor3 = Theme.TextDim,
                TextSize = 12,
                Font = Theme.Font,
                AutoButtonColor = false,
                Parent = row,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

            table.insert(win._conns, btn.MouseButton1Click:Connect(function()
                listening = true
                btn.Text = "..."
                btn.TextColor3 = Theme.Accent
            end))

            table.insert(win._conns, UserInputService.InputBegan:Connect(function(inp, gp)
                if gp then return end
                if listening then
                    listening = false
                    current = (inp.KeyCode == Enum.KeyCode.Backspace)
                        and Enum.KeyCode.Unknown or inp.KeyCode
                    btn.Text = current.Name
                    btn.TextColor3 = Theme.TextDim
                    win.Flags[label] = current
                    call(callback, current)
                elseif current ~= Enum.KeyCode.Unknown and inp.KeyCode == current then
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

        function tab:ColorPicker(label, default, callback)
            local color = default or Color3.fromRGB(255, 0, 0)
            local open = false

            local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = Color3.fromRGB(25, 25, 25),
                BorderSizePixel = 0,
                ClipsDescendants = true,
            }, getParent())
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

            local headerBtn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                Parent = row,
            })

            new("TextLabel", {
                Size = UDim2.new(0.5, -10, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = label,
                TextColor3 = Theme.Text,
                TextSize = 13,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn,
            })

            local swatch = new("Frame", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(1, -26, 0.5, -9),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Parent = headerBtn,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, swatch)

            local panel = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Parent = row,
            })

            local hueBg = new("Frame", {
                Size = UDim2.new(1, -20, 0, 10),
                Position = UDim2.new(0, 10, 0, 8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = panel,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, hueBg)
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
            }, hueBg)

            local svBg = new("Frame", {
                Size = UDim2.new(1, -20, 0, 70),
                Position = UDim2.new(0, 10, 0, 26),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Parent = panel,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 4) }, svBg)

            new("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }, svBg)
            new("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            }, svBg)

            local function updateColor(c)
                color = c
                swatch.BackgroundColor3 = c
                win.Flags[label] = c
                call(callback, c)
            end

            local hueDrag = false
            table.insert(win._conns, hueBg.InputBegan:Connect(function(inp)
                if isMouse(inp) then
                    hueDrag = true
                    local p = math.clamp((inp.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1)
                    local _, s, v = Color3.toHSV(color)
                    updateColor(Color3.fromHSV(p, s, v))
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(inp)
                if hueDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                    local p = math.clamp((inp.Position.X - hueBg.AbsolutePosition.X) / hueBg.AbsoluteSize.X, 0, 1)
                    local _, s, v = Color3.toHSV(color)
                    updateColor(Color3.fromHSV(p, s, v))
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(inp)
                if isMouse(inp) then hueDrag = false end
            end))

            local svDrag = false
            table.insert(win._conns, svBg.InputBegan:Connect(function(inp)
                if isMouse(inp) then
                    svDrag = true
                    local rx = math.clamp((inp.Position.X - svBg.AbsolutePosition.X) / svBg.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((inp.Position.Y - svBg.AbsolutePosition.Y) / svBg.AbsoluteSize.Y, 0, 1)
                    local h = select(1, Color3.toHSV(color))
                    updateColor(Color3.fromHSV(h, rx, 1 - ry))
                end
            end))
            table.insert(win._conns, UserInputService.InputChanged:Connect(function(inp)
                if svDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                    local rx = math.clamp((inp.Position.X - svBg.AbsolutePosition.X) / svBg.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((inp.Position.Y - svBg.AbsolutePosition.Y) / svBg.AbsoluteSize.Y, 0, 1)
                    local h = select(1, Color3.toHSV(color))
                    updateColor(Color3.fromHSV(h, rx, 1 - ry))
                end
            end))
            table.insert(win._conns, UserInputService.InputEnded:Connect(function(inp)
                if isMouse(inp) then svDrag = false end
            end))

            table.insert(win._conns, headerBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    panel.Size = UDim2.new(1, 0, 0, 106)
                    row.Size   = UDim2.new(1, 0, 0, 30 + 106)
                else
                    panel.Size = UDim2.new(1, 0, 0, 0)
                    row.Size   = UDim2.new(1, 0, 0, 30)
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

        function tab:Label(text)
            local lbl = new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = text,
                TextColor3 = Theme.TextDim,
                TextSize = 12,
                Font = Theme.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = getParent(),
            })
            local obj = {}
            function obj:Set(v) lbl.Text = v end
            function obj:Destroy() lbl:Destroy() end
            return obj
        end

        function tab:Divider()
            local f = new("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BorderSizePixel = 0,
                Parent = getParent(),
            })
            local obj = {}
            function obj:Destroy() f:Destroy() end
            return obj
        end

        table.insert(win.Tabs, tab)
        if #win.Tabs == 1 then tab:Select() end
        return tab
    end

    function win:SelectTab(name)
        for _, t in ipairs(win.Tabs) do
            if t.Name == name then t:Select() return end
        end
    end

    function win:GetFlag(name) return win.Flags[name] end
    function win:SetFlag(name, v) win.Flags[name] = v end
    function win:Toggle() gui.Enabled = not gui.Enabled end

    function win:SaveConfig(name)
        if not writefile then return false end
        local data = { flags = win.Flags, version = Library.Version }
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not ok then return false end
        writefile("memesense_" .. (name or "default") .. ".json", encoded)
        return true
    end

    function win:LoadConfig(name)
        if not isfile or not readfile then return false end
        local path = "memesense_" .. (name or "default") .. ".json"
        if not isfile(path) then return false end
        local ok, raw = pcall(readfile, path)
        if not ok then return false end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 or type(data) ~= "table" then return false end
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

    table.insert(win._conns, saveBtn.MouseButton1Click:Connect(function()
        if win:SaveConfig("default") then
            Library:Notify("Config saved")
        else
            Library:Notify("Save failed")
        end
    end))

    table.insert(win._conns, themeBtn.MouseButton1Click:Connect(function()
        local popup = new("Frame", {
            Size = UDim2.new(0, 220, 0, 60),
            Position = UDim2.new(0.5, -110, 0.5, -30),
            BackgroundColor3 = Color3.fromRGB(25, 25, 25),
            BorderSizePixel = 0,
            Parent = gui,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 6) }, popup)

        new("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Text = "Accent Color",
            TextColor3 = Theme.Text,
            TextSize = 13,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = popup,
        })

        local close = new("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -26, 0, 8),
            BackgroundTransparency = 1,
            Text = "X",
            TextColor3 = Theme.TextDim,
            TextSize = 12,
            Font = Theme.FontBold,
            Parent = popup,
        })
        table.insert(win._conns, close.MouseButton1Click:Connect(function()
            popup:Destroy()
        end))

        local hue = new("Frame", {
            Size = UDim2.new(1, -20, 0, 10),
            Position = UDim2.new(0, 10, 0, 34),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = popup,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 4) }, hue)
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

        local hueDrag = false
        table.insert(win._conns, hue.InputBegan:Connect(function(inp)
            if isMouse(inp) then
                hueDrag = true
                local p = math.clamp((inp.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                accent = Color3.fromHSV(p, 1, 1)
                rgbLine.BackgroundColor3 = accent
            end
        end))
        table.insert(win._conns, UserInputService.InputChanged:Connect(function(inp)
            if hueDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch) then
                local p = math.clamp((inp.Position.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                accent = Color3.fromHSV(p, 1, 1)
                rgbLine.BackgroundColor3 = accent
            end
        end))
        table.insert(win._conns, UserInputService.InputEnded:Connect(function(inp)
            if isMouse(inp) then hueDrag = false end
        end))
    end))

    return win
end

function Library:Notify(text, duration)
    duration = duration or 3

    local pg = getContainer()
    local nGui = pg:FindFirstChild("MemesenseNotifications")
    if not nGui then
        nGui = new("ScreenGui", {
            Name = "MemesenseNotifications",
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, pg)
        new("Frame", {
            Name = "Container",
            Size = UDim2.new(0, 260, 1, -40),
            Position = UDim2.new(1, -280, 0, 20),
            BackgroundTransparency = 1,
        }, nGui)
        new("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment   = Enum.VerticalAlignment.Top,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, nGui:FindFirstChild("Container"))
    end

    local container = nGui:FindFirstChild("Container")
    if not container then return end

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 0,
    }, container)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, frame)

    new("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
    })

    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = frame,
    })

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
