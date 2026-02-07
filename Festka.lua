local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local pGui = player:WaitForChild("PlayerGui")

-- Полная очистка перед запуском
if pGui:FindFirstChild("Festka_Full_ESP") then pGui.Festka_Full_ESP:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Festka_Full_ESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = pGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
MainFrame.Size = UDim2.new(0, 250, 0, 150)
MainFrame.Active = true

local function ApplyStyle(obj, radius, strokeColor)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = obj
    local stroke = Instance.new("UIStroke")
    stroke.Color = strokeColor or Color3.fromRGB(0, 180, 255)
    stroke.Thickness = 2
    stroke.Parent = obj
end

ApplyStyle(MainFrame, 12)

-- ПЕРЕМЕЩЕНИЕ ОКНА [cite: 2026-02-04]
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = input.Position startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

-- АНИМАЦИЯ КНОПОК [cite: 2026-02-04]
local function AnimateButton(button)
    local originalColor = button.BackgroundColor3
    local originalSize = button.Size
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0, 180, 255)}):Play()
        button:TweenSize(originalSize - UDim2.new(0, 4, 0, 4), "Out", "Quad", 0.1, true)
    end)
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = originalColor}):Play()
        button:TweenSize(originalSize, "Out", "Quad", 0.2, true)
    end)
end

-- КОНТЕЙНЕРЫ ТАБОВ
local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Name = "Tabs"
TabHolder.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TabHolder.Position = UDim2.new(0, 5, 0, 5)
TabHolder.Size = UDim2.new(0, 70, 1, -10)
ApplyStyle(TabHolder, 8)
Instance.new("UIListLayout", TabHolder).Padding = UDim.new(0, 5)

local ContentHolder = Instance.new("Frame", MainFrame)
ContentHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ContentHolder.Position = UDim2.new(0, 80, 0, 5)
ContentHolder.Size = UDim2.new(1, -85, 1, -10)
ApplyStyle(ContentHolder, 8)

local combatPage = Instance.new("ScrollingFrame", ContentHolder)
combatPage.Size = UDim2.new(1, -10, 1, -10)
combatPage.Position = UDim2.new(0, 5, 0, 5)
combatPage.BackgroundTransparency = 1
combatPage.ScrollBarThickness = 0
Instance.new("UIListLayout", combatPage).Padding = UDim.new(0, 6)

local playersPage = Instance.new("ScrollingFrame", ContentHolder)
playersPage.Size = UDim2.new(1, -10, 1, -10)
playersPage.Position = UDim2.new(0, 5, 0, 5)
playersPage.BackgroundTransparency = 1
playersPage.Visible = false
playersPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", playersPage).Padding = UDim.new(0, 4)

-- ЛОГИКА SMART ATTACK (DEATH COUNTER)
-- ОБНОВЛЕННЫЙ БЛОК SMART ATTACK (DEATH COUNTER CUTSCENE)
local isAttacking = false
local function SmartAttackLogic(btn)
    if isAttacking then return end
    isAttacking = true
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then isAttacking = false return end
    local oldPos = hrp.CFrame
    
    -- Поиск ближайшей цели в радиусе 1000 студийных единиц
    local target = nil
    local dist = 1000
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < dist and p.Character.Humanoid.Health > 0 then 
                dist = d 
                target = p.Character 
            end
        end
    end
    
    if target then
        btn.Text = "TARGET FOUND"
        -- 1. Резкий телепорт за спину для активации скилла
        char:PivotTo(target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2.5))
        task.wait(0.1)
        
        -- 2. Прожимаем скилл 2 (нажатие через VirtualInputManager)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
        
        -- 3. Проверка на попадание (мониторинг ХП врага)
        local lastHP = target.Humanoid.Health
        local hit = false
        for i = 1, 15 do
            if target.Humanoid.Health < lastHP then hit = true break end
            task.wait(0.05)
        end
        
        if hit then
            btn.Text = "🌑 DEATH COUNTER..."
            
            -- Координаты локации катсцены (пустота)
            local CutscenePos = Vector3.new(5000, 5000, 5000)
            
            -- Создаем черную платформу для эффекта "пустоты"
            local plat = Instance.new("Part", workspace)
            plat.Size = Vector3.new(50, 1, 50)
            plat.Position = CutscenePos - Vector3.new(0, 4, 0)
            plat.Anchored = true
            plat.Color = Color3.fromRGB(0, 0, 0) -- Полностью черная
            plat.Material = Enum.Material.Neon
            game:GetService("Debris"):AddItem(plat, 3.5) -- Исчезнет после катсцены
            
            -- Телепортируем тебя и врага в пустоту
            char:PivotTo(CFrame.new(CutscenePos))
            if target:FindFirstChild("HumanoidRootPart") then
                target.HumanoidRootPart.CFrame = CFrame.new(CutscenePos + Vector3.new(0, 0, -5))
            end
            
            task.wait(3) -- Длительность катсцены
            btn.Text = "FATALITY"
        else
            btn.Text = "MISSED"
        end
        
        -- Возвращаемся на исходную позицию
        char:PivotTo(oldPos)
    else
        btn.Text = "NO TARGET"
    end
    
    task.wait(0.5)
    btn.Text = "SMART ATTACK (2)"
    isAttacking = false
end


-- СОЗДАНИЕ КНОПОК
local function CreateBtn(text, parent, func)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -6, 0, 30)
    b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.AutoButtonColor = false
    ApplyStyle(b, 6)
    AnimateButton(b)
    b.MouseButton1Click:Connect(function() func(b) end)
end

CreateBtn("SMART ATTACK (2)", combatPage, SmartAttack)
CreateBtn("TP: 500, 700, -350", combatPage, function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(500, 700, -350)
    end
end)
CreateBtn("TOGGLE ALL ESP", combatPage, function()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local h = v.Character:FindFirstChild("GlobalESP") or Instance.new("Highlight", v.Character)
            h.Name = "GlobalESP"
            h.FillColor = Color3.fromRGB(0, 180, 255)
            h.Enabled = not h.Enabled
        end
    end
end)

-- СПИСОК ИГРОКОВ [cite: 2026-02-02]
local function UpdateList()
    for _, c in pairs(playersPage:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        local b = Instance.new("TextButton", playersPage)
        b.Size = UDim2.new(1, -6, 0, 28)
        b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        b.Text = "  " .. p.Name
        b.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        b.Font = Enum.Font.Gotham
        b.TextSize = 10
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.AutoButtonColor = false
        ApplyStyle(b, 6)
        AnimateButton(b)
    end
end
UpdateList()

-- ТАБЫ
local function AddTab(name, page)
    local t = Instance.new("TextButton", TabHolder)
    t.Size = UDim2.new(1, -6, 0, 30)
    t.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    t.Text = name
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 9
    t.AutoButtonColor = false
    ApplyStyle(t, 6)
    AnimateButton(t)
    t.MouseButton1Click:Connect(function()
        combatPage.Visible = false
        playersPage.Visible = false
        page.Visible = true
    end)
end

AddTab("MAIN", combatPage)
AddTab("PLAYERS", playersPage)
