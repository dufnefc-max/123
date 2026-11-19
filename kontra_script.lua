-- Загрузка библиотеки Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Настройки
local CFG = {
    aimbot = { enabled = false, fov = 150, smooth = 0.4 },
    esp    = { enabled = false, color = Color3.fromRGB(255, 60, 60) },
    speed  = { enabled = false, value = 80 },
    ammo   = { enabled = false, value = 9999 },
}

local is_aiming = false
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 then
        is_aiming = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        is_aiming = false
    end
end)

-- ================= ОКНО МЕНЮ =================
local Window = Rayfield:CreateWindow({
   Name = "Kontra Cheat | Xeno",
   LoadingTitle = "Загрузка...",
   LoadingSubtitle = "by Assistant",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, 
      FileName = "KontraConfig"
   },
   KeySystem = false
})

-- Вкладка Aim & Visuals
local AimTab = Window:CreateTab("Aimbot & ESP", 4483362458)

AimTab:CreateToggle({
   Name = "Aimbot (ПКМ)",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value)
       CFG.aimbot.enabled = Value
   end,
})

AimTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {10, 360},
   Increment = 5,
   Suffix = "px",
   CurrentValue = 150,
   Flag = "AimbotFov",
   Callback = function(Value)
       CFG.aimbot.fov = Value
   end,
})

AimTab:CreateToggle({
   Name = "ESP (Квадраты)",
   CurrentValue = false,
   Flag = "EspToggle",
   Callback = function(Value)
       CFG.esp.enabled = Value
   end,
})

-- Вкладка Player
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateToggle({
   Name = "Speed Hack",
   CurrentValue = false,
   Flag = "SpeedToggle",
   Callback = function(Value)
       CFG.speed.enabled = Value
       if not Value and LocalPlayer.Character then
           local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
           if hum then hum.WalkSpeed = 16 end
       end
   end,
})

PlayerTab:CreateSlider({
   Name = "Speed Value",
   Range = {16, 200},
   Increment = 1,
   Suffix = "ws",
   CurrentValue = 80,
   Flag = "SpeedValue",
   Callback = function(Value)
       CFG.speed.value = Value
   end,
})

PlayerTab:CreateToggle({
   Name = "Infinite Ammo",
   CurrentValue = false,
   Flag = "AmmoToggle",
   Callback = function(Value)
       CFG.ammo.enabled = Value
   end,
})


-- ================= ЛОГИКА =================

-- Aimbot
RunService.RenderStepped:Connect(function()
    if not CFG.aimbot.enabled or not is_aiming or not camera then return end
    local best, best_d = nil, CFG.aimbot.fov
    local center = camera.ViewportSize / 2
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local sp, on = camera:WorldToViewportPoint(head.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < best_d then best, best_d = head, d end
                end
            end
        end
    end
    
    if best then
        local goal = CFrame.new(camera.CFrame.Position, best.Position)
        camera.CFrame = camera.CFrame:Lerp(goal, CFG.aimbot.smooth)
    end
end)

-- ESP
local has_drawing = pcall(function() return Drawing.new("Square") end)
local esp_boxes = {}

local function manage_esp(plr)
    if plr == LocalPlayer or esp_boxes[plr] then return end
    if not has_drawing then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color     = CFG.esp.color
    box.Filled    = false
    box.Visible   = false
    esp_boxes[plr] = box

    RunService.RenderStepped:Connect(function()
        if not CFG.esp.enabled or not camera then box.Visible = false return end
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        
        if not (head and hrp) then box.Visible = false return end
        
        local h, hon = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
        local f, fon = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        
        if not (hon and fon) then box.Visible = false return end
        
        box.Size     = Vector2.new(math.abs(h.X - f.X) * 1.4, math.abs(h.Y - f.Y))
        box.Position = Vector2.new(f.X - box.Size.X / 2, h.Y)
        box.Visible  = true
    end)
end

for _, p in ipairs(Players:GetPlayers()) do manage_esp(p) end
Players.PlayerAdded:Connect(manage_esp)

-- Speed
RunService.Heartbeat:Connect(function()
    if not CFG.speed.enabled then return end
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.WalkSpeed ~= CFG.speed.value then
        hum.WalkSpeed = CFG.speed.value
    end
end)

-- Ammo (в отдельном потоке)
task.spawn(function()
    while task.wait(0.5) do
        if CFG.ammo.enabled then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                for _, n in ipairs({"Ammo", "AmmoValue", "Clip", "Bullets", "CurrentAmmo"}) do
                    local v = tool:FindFirstChild(n)
                    if v and v:IsA("ValueBase") then
                        v.Value = CFG.ammo.value
                    end
                end
            end
        end
    end
end)
