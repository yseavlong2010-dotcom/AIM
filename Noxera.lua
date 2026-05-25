--=============================================================================
-- [HỆ THỐNG]: NOXERA V18 APEX - MOBILE FPS OPTIMIZED & BUG FIXES
-- [MÔ TẢ KỸ THUẬT]: 
-- 1. Sửa lỗi kẹt Menu: Viết lại thuật toán Drag UI mượt mà 100% trên cảm ứng.
-- 2. Hệ thống ESP Mới: Tự động đo Bounding Box thực tế (Sửa lỗi khung bị móp/dính).
-- 3. TriggerBot Raycast: Tự bắn chuẩn 100% theo tâm thật của game (Xóa bỏ tâm ảo gây lệch).
-- 4. Entity Updater: Quét liên tục người chơi mới vào/chết để cập nhật.
--=============================================================================

local CustomConfig = {
    ToggleIcon      = "rbxassetid://93621646420054", 
    ToggleText      = "Open Noxera",             
    MenuImage       = "rbxassetid://87125517934058", 
    MenuTitle       = "NOXERA APEX V18",
    CreatorName     = "Noxera",
    DiscordLink     = "https://discord.gg/wb3VRK5eup",
    DiscordContact  = "Discord ID: @_noxera.",
    UpdateLog       = "Phiên bản V18 APEX:\n+ Fix kéo thả UI 100%\n+ Fix ESP móp khung/bị dính\n+ Thêm TriggerBot (Tự bắn khi tâm thật trúng địch)\n+ Xóa tâm ảo gây lag",

    -- Thông số
    AimPart         = "Head", 
    Smoothness      = 0.65, 
    Prediction      = 0.145,
    AimFOV          = 150,
    CamFOV          = 70,
    MaxRender       = 2500,
    ShootDelay      = 0.05,
    HitboxSize      = 10,
    WalkSpeed       = 16,
    JumpPower       = 50,
    SpinSpeed       = 50
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Runtime = {
    AimEnabled = false,
    AutoShoot = false, -- Sử dụng TriggerBot
    WallCheck = true,
    TeamCheck = false,
    HitboxExpander = false,
    ESPBox = false,
    ESPName = false,
    ESPHP = false,
    ESPTracer = false,
    SpeedHack = false,
    JumpHack = false,
    InfJump = false,
    Spinbot = false,
    NoClip = false,
    Fullbright = false
}

local LockedTarget = nil
local LastShootTick = 0
local ESP_Cache = {}

-- ============================================================================
-- [QUẢN LÝ ĐỒ HỌA ESP & ANTI-GHOST]
-- ============================================================================
local function GetESP(Player)
    if not ESP_Cache[Player] then
        ESP_Cache[Player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            HP = Drawing.new("Square"),
            Tracer = Drawing.new("Line")
        }
        ESP_Cache[Player].Box.Color = Color3.fromRGB(255, 255, 255)
        ESP_Cache[Player].Box.Thickness = 1.5
        ESP_Cache[Player].Box.Filled = false
        ESP_Cache[Player].Name.Color = Color3.fromRGB(255, 255, 255)
        ESP_Cache[Player].Name.Size = 13
        ESP_Cache[Player].Name.Center = true
        ESP_Cache[Player].Name.Outline = true
        ESP_Cache[Player].HP.Color = Color3.fromRGB(0, 255, 0)
        ESP_Cache[Player].HP.Filled = true
        ESP_Cache[Player].Tracer.Color = Color3.fromRGB(80, 150, 255)
        ESP_Cache[Player].Tracer.Thickness = 1.5
    end
    return ESP_Cache[Player]
end

local function HideESP(Player)
    if ESP_Cache[Player] then
        ESP_Cache[Player].Box.Visible = false
        ESP_Cache[Player].Name.Visible = false
        ESP_Cache[Player].HP.Visible = false
        ESP_Cache[Player].Tracer.Visible = false
    end
end

local function ClearESP(Player)
    pcall(function()
        if ESP_Cache[Player] then
            for _, obj in pairs(ESP_Cache[Player]) do 
                if typeof(obj) == "table" and obj.Remove then obj:Remove() end
            end
            ESP_Cache[Player] = nil
        end
    end)
end
Players.PlayerRemoving:Connect(ClearESP)

-- ============================================================================
-- [HỆ THỐNG GIAO DIỆN (UI) V18]
-- ============================================================================
if CoreGui:FindFirstChild("NoxeraUI_V18") then CoreGui.NoxeraUI_V18:Destroy() end

local Gui = Instance.new("ScreenGui", CoreGui)
Gui.Name = "NoxeraUI_V18"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- NÚT TOGGLE (MỞ MENU)
local ToggleFrame = Instance.new("Frame", Gui)
ToggleFrame.Size, ToggleFrame.Position = UDim2.new(0, 150, 0, 40), UDim2.new(0.5, -75, 0, 15)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleFrame.Active = true
Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleFrame)
ToggleStroke.Color, ToggleStroke.Thickness = Color3.fromRGB(80, 150, 255), 2

local ToggleBtn = Instance.new("TextButton", ToggleFrame)
ToggleBtn.Size, ToggleBtn.BackgroundTransparency, ToggleBtn.Text = UDim2.new(1, 0, 1, 0), 1, ""

local ToggleIcon = Instance.new("ImageLabel", ToggleFrame)
ToggleIcon.Size, ToggleIcon.Position, ToggleIcon.BackgroundTransparency = UDim2.new(0, 22, 0, 22), UDim2.new(0, 10, 0.5, -11), 1
ToggleIcon.Image = CustomConfig.ToggleIcon
Instance.new("UICorner", ToggleIcon).CornerRadius = UDim.new(1, 0)

local ToggleLabel = Instance.new("TextLabel", ToggleFrame)
ToggleLabel.Size, ToggleLabel.Position, ToggleLabel.BackgroundTransparency = UDim2.new(1, -40, 1, 0), UDim2.new(0, 38, 0, 0), 1
ToggleLabel.Text, ToggleLabel.TextColor3, ToggleLabel.Font, ToggleLabel.TextSize = CustomConfig.ToggleText, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 12
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- THUẬT TOÁN KÉO THẢ (DRAG) HOÀN HẢO CHO MOBILE
local function MakeDraggable(UIElement)
    local dragToggle, dragStart, startPos
    UIElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true
            dragStart = input.Position
            startPos = UIElement.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            -- Dùng tọa độ Offset tuyệt đối để không bị giật
            UIElement.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = false
        end
    end)
end

MakeDraggable(ToggleFrame)

-- KHUNG MENU CHÍNH
local MainMenu = Instance.new("Frame", Gui)
MainMenu.Size, MainMenu.Position = UDim2.new(0, 500, 0, 320), UDim2.new(0.5, -250, 0.5, -160)
MainMenu.BackgroundColor3, MainMenu.ClipsDescendants, MainMenu.Visible = Color3.fromRGB(10, 10, 15), true, false
MainMenu.Active = true
Instance.new("UICorner", MainMenu).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainMenu)
MainStroke.Color, MainStroke.Thickness = Color3.fromRGB(80, 150, 255), 1

local BackgroundImage = Instance.new("ImageLabel", MainMenu)
BackgroundImage.Size, BackgroundImage.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
BackgroundImage.Image, BackgroundImage.ScaleType, BackgroundImage.ImageTransparency = CustomConfig.MenuImage, Enum.ScaleType.Crop, 0.6

MakeDraggable(MainMenu)

-- ANIMATION MỞ/ĐÓNG
local MenuOpen = false
ToggleBtn.MouseButton1Click:Connect(function()
    MenuOpen = not MenuOpen
    if MenuOpen then
        MainMenu.Size = UDim2.new(0, 0, 0, 0)
        MainMenu.Visible = true
        TweenService:Create(MainMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 500, 0, 320)}):Play()
    else
        local T = TweenService:Create(MainMenu, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        T:Play(); T.Completed:Wait(); if not MenuOpen then MainMenu.Visible = false end
    end
end)

-- BỐ CỤC UI
local Sidebar = Instance.new("Frame", MainMenu)
Sidebar.Size, Sidebar.BackgroundColor3, Sidebar.BackgroundTransparency = UDim2.new(0, 130, 1, 0), Color3.fromRGB(5, 5, 10), 0.5
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local SidebarTitle = Instance.new("TextLabel", Sidebar)
SidebarTitle.Size, SidebarTitle.Position, SidebarTitle.BackgroundTransparency = UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 10), 1
SidebarTitle.Text, SidebarTitle.TextColor3, SidebarTitle.Font, SidebarTitle.TextSize = CustomConfig.MenuTitle, Color3.fromRGB(80, 150, 255), Enum.Font.GothamBold, 11

local SidebarList = Instance.new("UIListLayout", Sidebar)
SidebarList.Padding, SidebarList.HorizontalAlignment = UDim.new(0, 5), Enum.HorizontalAlignment.Center
Instance.new("UIPadding", Sidebar).PaddingTop = UDim.new(0, 50)

local ContentArea = Instance.new("Frame", MainMenu)
ContentArea.Size, ContentArea.Position, ContentArea.BackgroundTransparency = UDim2.new(1, -140, 1, -20), UDim2.new(0, 140, 0, 10), 1

local Tabs, TabButtons = {}, {}

local function CreateTab(Name, IsDefault)
    local TabBtn = Instance.new("TextButton", Sidebar)
    TabBtn.Size, TabBtn.BackgroundColor3, TabBtn.BorderSizePixel = UDim2.new(0.9, 0, 0, 30), Color3.fromRGB(20, 20, 25), 0
    TabBtn.BackgroundTransparency = IsDefault and 0.2 or 0.8
    TabBtn.Text, TabBtn.TextColor3, TabBtn.Font, TabBtn.TextSize = Name, IsDefault and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150), Enum.Font.GothamSemibold, 12
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)

    local TabContent = Instance.new("ScrollingFrame", ContentArea)
    TabContent.Size, TabContent.BackgroundTransparency, TabContent.ScrollBarThickness = UDim2.new(1, 0, 1, 0), 1, 2
    TabContent.Visible = IsDefault
    local CList = Instance.new("UIListLayout", TabContent)
    CList.Padding = UDim.new(0, 6)

    table.insert(TabButtons, TabBtn)
    Tabs[Name] = TabContent

    TabBtn.MouseButton1Click:Connect(function()
        for _, btn in pairs(TabButtons) do btn.BackgroundTransparency = 0.8; btn.TextColor3 = Color3.fromRGB(150, 150, 150) end
        for _, content in pairs(Tabs) do content.Visible = false end
        TabBtn.BackgroundTransparency = 0.2; TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        TabContent.Visible = true
    end)
    return TabContent
end

local function CreateToggleUI(Tab, Text, Key, Callback)
    local Btn = Instance.new("TextButton", Tab)
    Btn.Size, Btn.BackgroundColor3, Btn.BackgroundTransparency, Btn.Text = UDim2.new(1, -10, 0, 35), Color3.fromRGB(20, 20, 25), 0.4, ""
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    local Label = Instance.new("TextLabel", Btn)
    Label.Size, Label.Position, Label.BackgroundTransparency = UDim2.new(1, -50, 1, 0), UDim2.new(0, 15, 0, 0), 1
    Label.Text, Label.TextColor3, Label.Font, Label.TextSize, Label.TextXAlignment = Text, Color3.fromRGB(200, 200, 200), Enum.Font.Gotham, 13, Enum.TextXAlignment.Left

    local Indicator = Instance.new("Frame", Btn)
    Indicator.Size, Indicator.Position, Indicator.BackgroundColor3 = UDim2.new(0, 24, 0, 12), UDim2.new(1, -35, 0.5, -6), Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

    Btn.MouseButton1Click:Connect(function()
        Runtime[Key] = not Runtime[Key]
        TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundColor3 = Runtime[Key] and Color3.fromRGB(80, 150, 255) or Color3.fromRGB(50, 50, 50)}):Play()
        Label.TextColor3 = Runtime[Key] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        if Callback then Callback(Runtime[Key]) end
    end)
end

local function CreateSliderUI(Tab, Text, Key, Min, Max, Step)
    local Frame = Instance.new("Frame", Tab)
    Frame.Size, Frame.BackgroundColor3, Frame.BackgroundTransparency = UDim2.new(1, -10, 0, 50), Color3.fromRGB(20, 20, 25), 0.4
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 4)
    local Label = Instance.new("TextLabel", Frame)
    Label.Size, Label.Position, Label.BackgroundTransparency = UDim2.new(1, -30, 0, 20), UDim2.new(0, 15, 0, 5), 1
    Label.Text, Label.TextColor3, Label.Font, Label.TextSize, Label.TextXAlignment = Text .. ": " .. CustomConfig[Key], Color3.fromRGB(200, 200, 200), Enum.Font.Gotham, 12, Enum.TextXAlignment.Left

    local SliderBG = Instance.new("TextButton", Frame)
    SliderBG.Size, SliderBG.Position, SliderBG.BackgroundColor3, SliderBG.Text = UDim2.new(1, -30, 0, 6), UDim2.new(0, 15, 0, 32), Color3.fromRGB(50, 50, 50), ""
    Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", SliderBG)
    Fill.Size, Fill.BackgroundColor3 = UDim2.new((CustomConfig[Key] - Min) / (Max - Min), 0, 1, 0), Color3.fromRGB(80, 150, 255)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local draggingSlider = false
    local function Update(Input)
        local X = math.clamp((Input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
        local Value = math.floor((Min + (Max - Min) * X) / Step) * Step
        CustomConfig[Key] = Value
        Fill.Size = UDim2.new(X, 0, 1, 0)
        Label.Text = Text .. ": " .. Value
    end

    SliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; Update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then Update(input) end
    end)
end

local function CreateTextInfo(Tab, Text, Highlight)
    local Lbl = Instance.new("TextLabel", Tab)
    Lbl.Size, Lbl.BackgroundTransparency = UDim2.new(1, -10, 0, 25), 1
    Lbl.Text, Lbl.TextColor3, Lbl.Font, Lbl.TextSize, Lbl.TextXAlignment = Text, Highlight and Color3.fromRGB(80, 150, 255) or Color3.fromRGB(200, 200, 200), Enum.Font.Gotham, 12, Enum.TextXAlignment.Left
end

-- KHỞI TẠO TABS
local TabCombat = CreateTab("Combat", true)
local TabVisuals = CreateTab("Visuals", false)
local TabMovement = CreateTab("Movement", false)
local TabMisc = CreateTab("Misc", false)
local TabInfo = CreateTab("Info", false)

-- TAB COMBAT
CreateToggleUI(TabCombat, "Sticky AimLock", "AimEnabled")
CreateToggleUI(TabCombat, "Auto-Shoot (TriggerBot)", "AutoShoot")
CreateToggleUI(TabCombat, "Wall Check", "WallCheck")
CreateToggleUI(TabCombat, "Team Check", "TeamCheck")
CreateSliderUI(TabCombat, "Aim FOV", "AimFOV", 10, 500, 10)
CreateSliderUI(TabCombat, "Aim Smoothness", "Smoothness", 0.05, 1, 0.05)

-- TAB VISUALS
CreateToggleUI(TabVisuals, "ESP Box", "ESPBox")
CreateToggleUI(TabVisuals, "ESP Name", "ESPName")
CreateToggleUI(TabVisuals, "ESP Health Bar", "ESPHP")
CreateToggleUI(TabVisuals, "ESP Tracers", "ESPTracer")

-- TAB MOVEMENT & MISC
CreateToggleUI(TabMovement, "WalkSpeed Hack", "SpeedHack")
CreateSliderUI(TabMovement, "Speed Value", "WalkSpeed", 16, 200, 1)
CreateToggleUI(TabMovement, "JumpPower Hack", "JumpHack")
CreateToggleUI(TabMovement, "Infinite Jump", "InfJump")
CreateToggleUI(TabMisc, "NoClip (Đi Xuyên Tường)", "NoClip")
CreateToggleUI(TabMisc, "Fullbright", "Fullbright", function(state)
    if state then
        Lighting.Ambient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127); Lighting.GlobalShadows = true
    end
end)

-- TAB INFO
CreateTextInfo(TabInfo, "Tác giả: " .. CustomConfig.CreatorName, false)
CreateTextInfo(TabInfo, "Cộng đồng: " .. CustomConfig.DiscordLink, false)
CreateTextInfo(TabInfo, CustomConfig.DiscordContact, true)
CreateTextInfo(TabInfo, "----------------------", false)
CreateTextInfo(TabInfo, CustomConfig.UpdateLog, false)

-- ============================================================================
-- [CƠ CHẾ LÕI HỆ THỐNG - FPS TRIGGERBOT & ĐO BỘ ESP MỚI]
-- ============================================================================
local FOVCircleRender = Drawing.new("Circle")
FOVCircleRender.Color = Color3.fromRGB(255, 255, 255)
FOVCircleRender.Thickness = 1.2
FOVCircleRender.Filled = false

local function IsVisible(TargetPart)
    local Origin = Camera.CFrame.Position
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {Camera, LocalPlayer.Character, Workspace:FindFirstChild("Ignored")}
    local Result = Workspace:Raycast(Origin, TargetPart.Position - Origin, Params)
    return not Result or Result.Instance:IsDescendantOf(TargetPart.Parent)
end

local function SafeMobileAutoShoot()
    if tick() - LastShootTick >= CustomConfig.ShootDelay then
        pcall(function()
            local Char = LocalPlayer.Character
            if Char then
                local Tool = Char:FindFirstChildOfClass("Tool")
                if Tool then Tool:Activate() end
            end
        end)
        LastShootTick = tick()
    end
end

-- THUẬT TOÁN TRIGGERBOT BẰNG RAYCAST (CHUẨN 100% TÂM GAME)
local function HandleTriggerBot()
    if not Runtime.AutoShoot then return end
    
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = Camera.CFrame.LookVector * 1000 -- Bắn tia thẳng từ giữa Camera
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera, Workspace:FindFirstChild("Ignored")}
    
    local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    if result and result.Instance then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel:FindFirstChild("Humanoid") and hitModel.Humanoid.Health > 0 then
            local targetPlayer = Players:GetPlayerFromCharacter(hitModel)
            if targetPlayer and targetPlayer ~= LocalPlayer then
                if not Runtime.TeamCheck or targetPlayer.Team ~= LocalPlayer.Team then
                    SafeMobileAutoShoot() -- Nếu tia laser trúng địch -> Bắn
                end
            end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if Runtime.InfJump and LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local Char = LocalPlayer.Character
        local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
        if Hum then
            if Runtime.SpeedHack then Hum.WalkSpeed = CustomConfig.WalkSpeed else Hum.WalkSpeed = 16 end
            if Runtime.JumpHack then Hum.JumpPower = CustomConfig.JumpPower; Hum.UseJumpPower = true end
        end
        if Runtime.NoClip and Char then
            for _, v in pairs(Char:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
        end
        
        -- Gọi TriggerBot mỗi khung hình
        HandleTriggerBot()
    end)
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        Camera = Workspace.CurrentCamera
        local ScreenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local ScreenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        
        FOVCircleRender.Position = ScreenCenter
        FOVCircleRender.Radius = CustomConfig.AimFOV
        FOVCircleRender.Visible = Runtime.AimEnabled

        -- AIMLOCK BREAKAWAY
        if LockedTarget then
            local isAlive = LockedTarget:IsDescendantOf(Workspace) and LockedTarget.Parent and LockedTarget.Parent:FindFirstChild("Humanoid") and LockedTarget.Parent.Humanoid.Health > 0
            if not isAlive then LockedTarget = nil else
                local Pos, OnScreen = Camera:WorldToViewportPoint(LockedTarget.Position)
                if OnScreen then
                    local DistToCenter = (Vector2.new(Pos.X, Pos.Y) - ScreenCenter).Magnitude
                    if DistToCenter > (CustomConfig.AimFOV * 1.5) or (Runtime.WallCheck and not IsVisible(LockedTarget)) then
                        LockedTarget = nil
                    end
                else LockedTarget = nil end
            end
        end

        local MinDist = CustomConfig.AimFOV 

        -- VÒNG QUÉT NGƯỜI CHƠI
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player == LocalPlayer then continue end
            if Runtime.TeamCheck and Player.Team == LocalPlayer.Team then HideESP(Player); continue end

            local Char = Player.Character
            local Hum = Char and Char:FindFirstChild("Humanoid")
            local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
            local Head = Char and Char:FindFirstChild("Head")

            -- Nếu người chơi không có đủ bộ phận hoặc đã chết -> Tắt bóng ma ESP
            if not Char or not Hum or Hum.Health <= 0 or not HRP or not Head then 
                HideESP(Player)
                continue 
            end

            local Pos, OnScreen = Camera:WorldToViewportPoint(HRP.Position)

            -- [THUẬT TOÁN VẼ ESP CHUẨN 3D -> 2D MỚI NHẤT]
            if OnScreen and (Runtime.ESPBox or Runtime.ESPName or Runtime.ESPHP or Runtime.ESPTracer) then
                -- Tính toán kích thước từ đỉnh đầu xuống chân
                local TopPos, TopVis = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
                local BotPos, BotVis = Camera:WorldToViewportPoint(HRP.Position - Vector3.new(0, 3, 0))

                if TopVis and BotVis then
                    local BoxH = math.abs(TopPos.Y - BotPos.Y)
                    local BoxW = BoxH * 0.55 -- Tỉ lệ khung hình người
                    local BoxPos = Vector2.new(TopPos.X - BoxW / 2, TopPos.Y)

                    local ESP = GetESP(Player)
                    ESP.Box.Size = Vector2.new(BoxW, BoxH)
                    ESP.Box.Position = BoxPos
                    ESP.Box.Visible = Runtime.ESPBox
                    
                    ESP.Name.Text = Player.Name
                    ESP.Name.Position = Vector2.new(TopPos.X, TopPos.Y - 15)
                    ESP.Name.Visible = Runtime.ESPName
                    
                    local HPRatio = math.clamp(Hum.Health / Hum.MaxHealth, 0, 1)
                    ESP.HP.Size = Vector2.new(2, BoxH * HPRatio)
                    ESP.HP.Position = Vector2.new(BoxPos.X - 5, TopPos.Y + BoxH - (BoxH * HPRatio))
                    ESP.HP.Color = Color3.fromRGB(255 - (255 * HPRatio), 255 * HPRatio, 0)
                    ESP.HP.Visible = Runtime.ESPHP

                    ESP.Tracer.From = ScreenBottom
                    ESP.Tracer.To = Vector2.new(BotPos.X, BotPos.Y)
                    ESP.Tracer.Visible = Runtime.ESPTracer
                else
                    HideESP(Player)
                end
            else 
                HideESP(Player) 
            end

            -- TÌM MỤC TIÊU AIMLOCK
            local AimPart = Char:FindFirstChild(CustomConfig.AimPart)
            if AimPart and Runtime.AimEnabled and not LockedTarget and OnScreen then
                local AimPos = Camera:WorldToViewportPoint(AimPart.Position)
                local DistToCenter = (Vector2.new(AimPos.X, AimPos.Y) - ScreenCenter).Magnitude
                if DistToCenter < MinDist then
                    if not Runtime.WallCheck or IsVisible(AimPart) then
                        MinDist = DistToCenter
                        LockedTarget = AimPart
                    end
                end
            end
        end

        -- THỰC THI KIỂM SOÁT CAMERA (AIMLOCK)
        if Runtime.AimEnabled and LockedTarget then
            local TargetPos = LockedTarget.Position + (LockedTarget.Velocity * CustomConfig.Prediction)
            local TargetCFrame = CFrame.lookAt(Camera.CFrame.Position, TargetPos)
            Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, CustomConfig.Smoothness)
        end
    end)
end)
