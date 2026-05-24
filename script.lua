-- Script Cốt lõi "Luxumi Enterprise" - Tích hợp AimLock, ESP (Hiển thị người chơi), và Target HUD
-- Tối ưu hóa UI theo tiêu chuẩn giao diện cao cấp (Đen/Vàng Gold)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Config = {
    AimEnabled = false,
    ESPEnabled = false,
    AimPart = "Head",
    Smoothness = 0.08,
    Prediction = 0.12,
    FOV = 200
}

-- [DRAWING API] Khởi tạo các thành phần đồ họa (Visuals)
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 215, 0) -- Vàng Gold
FOVCircle.Thickness = 1
FOVCircle.Filled = false
FOVCircle.Visible = false

local ESPBoxes = {} -- Bảng lưu trữ Box ESP

local function CreateBox()
    local Box = Drawing.new("Square")
    Box.Color = Color3.fromRGB(255, 215, 0)
    Box.Thickness = 1.5
    Box.Filled = false
    Box.Visible = false
    return Box
end

-- [LUXURY UI MENU] Giao diện điều khiển trung tâm
local Gui = Instance.new("ScreenGui", game.CoreGui)
local MenuFrame = Instance.new("Frame", Gui)
MenuFrame.Size = UDim2.new(0, 200, 0, 120)
MenuFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
MenuFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MenuFrame.BorderSizePixel = 2
MenuFrame.BorderColor3 = Color3.fromRGB(255, 215, 0)
MenuFrame.Active = true
MenuFrame.Draggable = true

local Title = Instance.new("TextLabel", MenuFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.TextColor3 = Color3.fromRGB(255, 215, 0)
Title.Text = "LUXUMI ENTERPRISE"
Title.Font = Enum.Font.Code
Title.TextSize = 14

local AimBtn = Instance.new("TextButton", MenuFrame)
AimBtn.Size = UDim2.new(0.9, 0, 0, 30)
AimBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AimBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
AimBtn.Text = "AIMLOCK: OFF"

local ESPBtn = Instance.new("TextButton", MenuFrame)
ESPBtn.Size = UDim2.new(0.9, 0, 0, 30)
ESPBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ESPBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ESPBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
ESPBtn.Text = "ESP BOX: OFF"

AimBtn.MouseButton1Click:Connect(function()
    Config.AimEnabled = not Config.AimEnabled
    AimBtn.Text = Config.AimEnabled and "AIMLOCK: ON" or "AIMLOCK: OFF"
    AimBtn.TextColor3 = Config.AimEnabled and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
    FOVCircle.Visible = Config.AimEnabled
end)

ESPBtn.MouseButton1Click:Connect(function()
    Config.ESPEnabled = not Config.ESPEnabled
    ESPBtn.Text = Config.ESPEnabled and "ESP BOX: ON" or "ESP BOX: OFF"
    ESPBtn.TextColor3 = Config.ESPEnabled and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
end)

-- [TARGET HUD] Hiển thị thông tin mục tiêu đang khóa
local TargetHUD = Instance.new("TextLabel", Gui)
TargetHUD.Size = UDim2.new(0, 200, 0, 30)
TargetHUD.Position = UDim2.new(0.5, -100, 0.85, 0)
TargetHUD.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TargetHUD.TextColor3 = Color3.fromRGB(255, 215, 0)
TargetHUD.BorderColor3 = Color3.fromRGB(255, 215, 0)
TargetHUD.Visible = false

-- [LOGIC CỐT LÕI & VÒNG LẶP]
RunService.RenderStepped:Connect(function()
    -- Cập nhật FOV Circle
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = Config.FOV

    local ClosestTarget = nil
    local MinDist = Config.FOV

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local Char = Player.Character
            local HRP = Char.HumanoidRootPart
            local Head = Char:FindFirstChild(Config.AimPart)
            local Humanoid = Char:FindFirstChild("Humanoid")

            -- [XỬ LÝ ESP BOX]
            if Config.ESPEnabled and Humanoid and Humanoid.Health > 0 then
                if not ESPBoxes[Player] then ESPBoxes[Player] = CreateBox() end
                
                local Pos, OnScreen = Camera:WorldToViewportPoint(HRP.Position)
                if OnScreen then
                    local Size = Vector2.new(2000 / Pos.Z, 3000 / Pos.Z)
                    ESPBoxes[Player].Size = Size
                    ESPBoxes[Player].Position = Vector2.new(Pos.X - Size.X / 2, Pos.Y - Size.Y / 2)
                    ESPBoxes[Player].Visible = true
                else
                    ESPBoxes[Player].Visible = false
                end
            elseif ESPBoxes[Player] then
                ESPBoxes[Player].Visible = false
            end

            -- [XỬ LÝ AIMLOCK]
            if Config.AimEnabled and Head and Humanoid and Humanoid.Health > 0 then
                local Pos, OnScreen = Camera:WorldToViewportPoint(Head.Position)
                local MousePos = UserInputService.TouchEnabled and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UserInputService:GetMouseLocation()
                local Dist = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude

                if OnScreen and Dist < MinDist then
                    MinDist = Dist
                    ClosestTarget = {Player = Player, Part = Head, Dist = Dist}
                end
            end
        end
    end

    -- Xóa ESP của người chơi đã thoát
    for Player, Box in pairs(ESPBoxes) do
        if not Players:FindFirstChild(Player.Name) then
            Box:Remove()
            ESPBoxes[Player] = nil
        end
    end

    -- Thực thi Aim và hiển thị HUD
    if Config.AimEnabled and ClosestTarget then
        -- Interpolation & Prediction
        local TargetPos = ClosestTarget.Part.Position + (ClosestTarget.Part.Velocity * Config.Prediction)
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, TargetPos), Config.Smoothness)
        
        -- Cập nhật Target HUD
        TargetHUD.Text = string.format("TARGET: %s | DIST: %d", ClosestTarget.Player.Name, ClosestTarget.Dist)
        TargetHUD.Visible = true
    else
        TargetHUD.Visible = false
    end
end)
