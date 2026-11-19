local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ================= CONFIG =================
local CFG = {
    aimbot = { enabled = true, fov = 150, smooth = 0.4 },
    esp    = { enabled = true, color = Color3.fromRGB(255, 60, 60) },
    speed  = { enabled = true, value = 80 },
    ammo   = { enabled = true, value = 9999 },
}
-- ==========================================

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

-- ================= AIMBOT =================
local function get_target()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local best, best_d = nil, CFG.aimbot.fov
    local center = camera.ViewportSize / 2
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local sp, on = camera:WorldToViewportPoint(head.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < best_d then 
                        best, best_d = head, d 
                    end
                end
            end
        end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if not CFG.aimbot.enabled or not is_aiming then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local t = get_target()
    if not t then return end
    
    local goal = CFrame.new(camera.CFrame.Position, t.Position)
    camera.CFrame = camera.CFrame:Lerp(goal, CFG.aimbot.smooth)
end)

-- ================== ESP ===================
local has_drawing = pcall(function() return Drawing.new("Square") end)
if has_drawing then
    local esp_boxes = {}
    
    local function add_esp(plr)
        if plr == LocalPlayer then return end
        local box = Drawing.new("Square")
        box.Thickness = 1
        box.Color     = CFG.esp.color
        box.Filled    = false
        box.Visible   = false
        esp_boxes[plr] = box

        RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if not CFG.esp.enabled or not camera then 
                box.Visible = false 
                return 
            end
            
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            
            if not (head and hrp) then 
                box.Visible = false 
                return 
            end
            
            local h, hon = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
            local f, fon = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            
            if not (hon and fon) then 
                box.Visible = false 
                return 
            end
            
            box.Size     = Vector2.new(math.abs(h.X - f.X) * 1.4, math.abs(h.Y - f.Y))
            box.Position = Vector2.new(f.X - box.Size.X / 2, h.Y)
            box.Visible  = true
        end)
    end
    
    for _, p in ipairs(Players:GetPlayers()) do add_esp(p) end
    Players.PlayerAdded:Connect(add_esp)
end

-- ================= SPEED ==================
if CFG.speed.enabled then
    RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= CFG.speed.value then
            hum.WalkSpeed = CFG.speed.value
        end
    end)
end

-- ================= AMMO ===================
-- Выполняем в отдельном потоке, чтобы не крашить игру каждый кадр
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
