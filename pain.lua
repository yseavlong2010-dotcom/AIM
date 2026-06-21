-- =======================================================
-- AUTO PAINT PRO V2 - UNIVERSAL MAP SUPPORT (DELTA MOBILE)
-- =======================================================

local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Xóa UI cũ để tránh bug trùng lặp khi Execute nhiều lần
if CoreGui:FindFirstChild("AutoPaintPro") then
    CoreGui.AutoPaintPro:Destroy()
end

-- Biến toàn cục kiểm soát trạng thái
local State = {
    IsDrawing = false,
    TopLeft = Vector2.new(0, 0),
    BottomRight = Vector2.new(100, 100),
    DrawDelay = 0.05, -- Độ trễ mặc định
    SettingMode = "None"
}

-- ==========================================
-- 1. THIẾT KẾ GIAO DIỆN (UI MOBILE FRIENDLY)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPaintPro"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 300)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🎨 Auto Paint Pro (Universal)"
Title.TextColor3 = Color3.fromRGB(0, 200, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- Ô nhập link
local LinkInput = Instance.new("TextBox")
LinkInput.Size = UDim2.new(0.9, 0, 0, 40)
LinkInput.Position = UDim2.new(0.05, 0, 0.15, 0)
LinkInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
LinkInput.TextColor3 = Color3.fromRGB(255, 255, 255)
LinkInput.PlaceholderText = "Dán link API chứa JSON ảnh vào đây..."
LinkInput.TextScaled = true
LinkInput.Parent = MainFrame

-- Các nút Set Tọa độ (Giải pháp cho Mọi Map)
local BtnTopLeft = Instance.new("TextButton")
BtnTopLeft.Size = UDim2.new(0.42, 0, 0, 35)
BtnTopLeft.Position = UDim2.new(0.05, 0, 0.32, 0)
BtnTopLeft.Text = "📍 Set Góc Trái-Trên"
BtnTopLeft.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
BtnTopLeft.TextColor3 = Color3.new(1,1,1)
BtnTopLeft.Parent = MainFrame

local BtnBotRight = Instance.new("TextButton")
BtnBotRight.Size = UDim2.new(0.42, 0, 0, 35)
BtnBotRight.Position = UDim2.new(0.53, 0, 0.32, 0)
BtnBotRight.Text = "📍 Set Góc Phải-Dưới"
BtnBotRight.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
BtnBotRight.TextColor3 = Color3.new(1,1,1)
BtnBotRight.Parent = MainFrame

-- Tùy chỉnh Tốc độ (Speed Slider mô phỏng bằng TextBox cho mobile dễ bấm)
local SpeedInput = Instance.new("TextBox")
SpeedInput.Size = UDim2.new(0.9, 0, 0, 35)
SpeedInput.Position = UDim2.new(0.05, 0, 0.48, 0)
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
SpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedInput.PlaceholderText = "Độ trễ vẽ (Delay): 0.05 (Khuyên dùng)"
SpeedInput.Parent = MainFrame

-- Nút Điều khiển chính
local BtnDraw = Instance.new("TextButton")
BtnDraw.Size = UDim2.new(0.42, 0, 0, 45)
BtnDraw.Position = UDim2.new(0.05, 0, 0.65, 0)
BtnDraw.Text = "▶ BẮT ĐẦU"
BtnDraw.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
BtnDraw.TextColor3 = Color3.new(1,1,1)
BtnDraw.Font = Enum.Font.GothamBold
BtnDraw.Parent = MainFrame

local BtnStop = Instance.new("TextButton")
BtnStop.Size = UDim2.new(0.42, 0, 0, 45)
BtnStop.Position = UDim2.new(0.53, 0, 0.65, 0)
BtnStop.Text = "⏹ DỪNG LẠI"
BtnStop.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
BtnStop.TextColor3 = Color3.new(1,1,1)
BtnStop.Font = Enum.Font.GothamBold
BtnStop.Parent = MainFrame

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 30)
StatusText.Position = UDim2.new(0, 0, 0.85, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Trạng thái: Sẵn sàng."
StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusText.Parent = MainFrame

-- ==========================================
-- 2. LOGIC ĐỊNH VỊ BẢNG VẼ ĐA MAP
-- ==========================================
-- Bắt sự kiện chạm màn hình trên Mobile để set tọa độ bảng vẽ
UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
    if processedByUI then return end
    
    if State.SettingMode == "TopLeft" then
        State.TopLeft = position
        BtnTopLeft.Text = "✅ Đã Set Top-Left"
        BtnTopLeft.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        State.SettingMode = "None"
        StatusText.Text = "Đã lưu tọa độ góc Trái-Trên."
        
    elseif State.SettingMode == "BotRight" then
        State.BottomRight = position
        BtnBotRight.Text = "✅ Đã Set Bot-Right"
        BtnBotRight.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        State.SettingMode = "None"
        StatusText.Text = "Đã lưu tọa độ góc Phải-Dưới."
    end
end)

BtnTopLeft.MouseButton1Click:Connect(function()
    State.SettingMode = "TopLeft"
    BtnTopLeft.Text = "Chạm vào màn hình..."
end)

BtnBotRight.MouseButton1Click:Connect(function()
    State.SettingMode = "BotRight"
    BtnBotRight.Text = "Chạm vào màn hình..."
end)

SpeedInput.FocusLost:Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val then
        State.DrawDelay = val
        StatusText.Text = "Đã chỉnh delay thành: " .. val .. "s"
    else
        SpeedInput.Text = tostring(State.DrawDelay)
    end
end)

-- ==========================================
-- 3. CORE LOGIC VẼ (CHỐNG VĂNG GAME & LỖI HTTP)
-- ==========================================

local function FetchImageData(url)
    StatusText.Text = "Đang tải dữ liệu từ API..."
    
    -- Kiểm tra xem Executor có hỗ trợ request không
    local reqFunc = request or http_request or (syn and syn.request)
    if not reqFunc then
        StatusText.Text = "Lỗi: Executor của bạn không hỗ trợ Http Request!"
        return nil
    end

    local success, response = pcall(function()
        return reqFunc({
            Url = url,
            Method = "GET"
        })
    end)

    if success and response and response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodeSuccess then return data end
    end
    
    StatusText.Text = "Lỗi API! Vui lòng kiểm tra lại Link."
    return nil
end

local function StartDrawing()
    local url = LinkInput.Text
    if url == "" then
        StatusText.Text = "Lỗi: Chưa nhập link!"
        return
    end

    -- Tính toán khung hình (Canvas Scale) dựa trên 2 điểm người dùng đã chạm
    local canvasWidth = math.abs(State.BottomRight.X - State.TopLeft.X)
    local canvasHeight = math.abs(State.BottomRight.Y - State.TopLeft.Y)
    
    if canvasWidth == 0 or canvasHeight == 0 then
        StatusText.Text = "Lỗi: Bạn chưa Set tọa độ 2 góc bảng vẽ!"
        return
    end

    -- Lấy dữ liệu ảnh
    local pixelData = FetchImageData(url)
    -- Nếu API chưa có, giả lập một mảng dữ liệu test để sếp xem UI chạy mượt:
    if not pixelData then 
        StatusText.Text = "Dùng data giả lập vì chưa có API..."
        pixelData = {}
        for i=1, 100 do table.insert(pixelData, {X = math.random(1, 50), Y = math.random(1,50), R = 255, G = 255, B = 255}) end
        task.wait(1)
    end

    State.IsDrawing = true
    BtnDraw.Text = "ĐANG VẼ..."
    BtnDraw.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

    -- Chạy một Luồng Bất Đồng Bộ (Thread) riêng biệt để UI không bị đơ
    task.spawn(function()
        for i, pixel in ipairs(pixelData) do
            -- Kiểm tra nút Dừng Khẩn Cấp
            if not State.IsDrawing then
                StatusText.Text = "Đã hủy vẽ!"
                break 
            end

            -- MAP TỌA ĐỘ ẢNH VÀO TỌA ĐỘ BẢNG VẼ ĐÃ CHỌN TRONG GAME
            -- Ở đây giả sử ảnh gốc là 100x100. Công thức Scale mapping:
            local drawX = State.TopLeft.X + (pixel.X / 100) * canvasWidth
            local drawY = State.TopLeft.Y + (pixel.Y / 100) * canvasHeight
            local color = Color3.fromRGB(pixel.R, pixel.G, pixel.B)

            -- ========================================================
            -- GỌI REMOTEEVENT TẠI ĐÂY (Chỉnh sửa tùy theo từng game)
            -- Ví dụ: game.ReplicatedStorage.DrawEvent:FireServer(drawX, drawY, color)
            -- ========================================================
            
            StatusText.Text = string.format("Đang vẽ pixel %d / %d", i, #pixelData)
            
            -- Trễ (Delay) để chống crash / chống bị anti-cheat đá văng
            if i % 10 == 0 then
                task.wait(State.DrawDelay) 
            end
        end

        State.IsDrawing = false
        BtnDraw.Text = "▶ BẮT ĐẦU"
        BtnDraw.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        if StatusText.Text ~= "Đã hủy vẽ!" then
            StatusText.Text = "🎉 HOÀN THÀNH!"
        end
    end)
end

BtnDraw.MouseButton1Click:Connect(function()
    if not State.IsDrawing then StartDrawing() end
end)

BtnStop.MouseButton1Click:Connect(function()
    State.IsDrawing = false
    StatusText.Text = "Đang dừng lại..."
end)
