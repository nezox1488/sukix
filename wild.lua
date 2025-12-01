-- Wild Client 2.1 — Полный скрипт
-- Настройки клавиш
local aimKey = Enum.KeyCode.X
local flyKey = Enum.KeyCode.R
local espKey = Enum.KeyCode.N
local weaponBoxESPKey = Enum.KeyCode.U
local killFlyKey = Enum.KeyCode.L
local menuKey = Enum.KeyCode.M -- кнопка для открытия GUI
local killFlyMurderKey = Enum.KeyCode.K
local autoMansKey = Enum.KeyCode.P
local noClipKey = Enum.KeyCode.Z
local fuckerMurderKey = Enum.KeyCode.H
local fuckerSheriffKey = Enum.KeyCode.I 
local teleportMapKey = Enum.KeyCode.Insert -- НОВАЯ КЛАВИША: TeleportMap

local flySpeed = 100
local aimRadius = 100
local flyAntiKickEnabled = true 

-- Сервисы
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Переменные состояния
local aiming, flying, espEnabled = false, false, false
local weaponBoxESPEnabled, killFlyMurderEnabled, autoMansEnabled, noClipEnabled = false, false, false, false
local fuckerMurderEnabled, fuckerSheriffEnabled = false, false
local flyVel, flyGyro, flyStartTime

-- Уведомления 
local notificationGui = Instance.new("ScreenGui", game.CoreGui)
notificationGui.Name = "WCNotification"
local notifLabel = Instance.new("TextLabel", notificationGui)
notifLabel.Size = UDim2.new(0,300,0,50) 
notifLabel.Position = UDim2.new(0.5,-150,0.1,0)
notifLabel.BackgroundTransparency = 0.3
notifLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
notifLabel.TextColor3 = Color3.new(1,1,1)
notifLabel.Font = Enum.Font.SourceSansBold
notifLabel.TextSize = 24 
notifLabel.Visible = false
local notifBusy = false

local function notify(t, d)
    if notifBusy then return end
    notifBusy = true
    notifLabel.Text = t
    notifLabel.Visible = true
    task.delay(d or 1.5, function()
        notifLabel.Visible = false
        notifBusy = false
    end)
end

-- Получение роли игрока
local function getRole(pl)
    local bp, ch = pl:FindFirstChild("Backpack"), pl.Character
    if ch and (ch:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife"))) then
        return "Murderer"
    elseif ch and (ch:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun"))) then
        return "Sheriff"
    end
    return "Innocent"
end

-- Функция TeleportMap
local function teleportToMapCenter()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    if root then
        -- Стандартные координаты центра (для большинства карт Murder Mystery)
        local mapCenterPos = Vector3.new(0, 50, 0) 
        
        -- Установка CFrame
        root.CFrame = CFrame.new(mapCenterPos) 
        
        -- Если игрок мертв или только что появился, иногда требуется принудительное "выталкивание"
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        notify("TeleportMap: к центру карты!", 2)
    else
        notify("TeleportMap: Нет персонажа для телепортации.", 2)
    end
end

-- Fly + AntiKick + NoClip + TeleportMap Input
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == flyKey then
        flying = not flying
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if flying and root then
            flyVel = Instance.new("BodyVelocity", root)
            flyGyro = Instance.new("BodyGyro", root)
            flyVel.MaxForce = Vector3.new(1e9,1e9,1e9)
            flyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
            flyGyro.CFrame = Camera.CFrame
            flyStartTime = tick()
            notify("Fly Вкл")
        else
            if flyVel then flyVel:Destroy() flyVel=nil end
            if flyGyro then flyGyro:Destroy() flyGyro=nil end
            flying = false
            notify("Fly Выкл")
        end
    elseif input.KeyCode == noClipKey then
        noClipEnabled = not noClipEnabled
        notify("NoClip " .. (noClipEnabled and "Вкл" or "Выкл"))
    elseif input.KeyCode == fuckerMurderKey then
        fuckerMurderEnabled = not fuckerMurderEnabled
        fuckerSheriffEnabled = false 
        notify("FuckerMurder " .. (fuckerMurderEnabled and "Вкл" or "Выкл"))
    elseif input.KeyCode == fuckerSheriffKey then 
        fuckerSheriffEnabled = not fuckerSheriffEnabled
        fuckerMurderEnabled = false 
        notify("FuckerSheriff " .. (fuckerSheriffEnabled and "Вкл" or "Выкл"))
    elseif input.KeyCode == teleportMapKey then -- Обработка TeleportMap
        teleportToMapCenter()
    end
end)

-- *** Остальная часть RenderStepped и других функций осталась без изменений ***

RunService.RenderStepped:Connect(function()
    -- Fly/AntiKick/NoClip Logic
    if flying and flyVel and flyGyro then
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local mv = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then mv -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then mv += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv += Camera.CFrame.UpVector end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Camera.CFrame.UpVector end
            flyVel.Velocity = mv.Magnitude>0 and mv.Unit*flySpeed or Vector3.zero
            flyGyro.CFrame = Camera.CFrame

            if flyAntiKickEnabled and tick() - flyStartTime > 10 then
                flying = false
                flyVel:Destroy(); flyGyro:Destroy()
                flyVel=nil; flyGyro=nil
                notify("FlyAntiKick сработал: Fly выкл")
            end
        end
    end
    if noClipEnabled and LocalPlayer.Character then
        for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- Aimbot Logic
    if aiming then
        local mp = UIS:GetMouseLocation()
        local closest, cd = nil, aimRadius
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("Humanoid") and pl.Character.Humanoid.Health>0 and pl.Character:FindFirstChild("Head") then
                local pos,vis = Camera:WorldToViewportPoint(pl.Character.Head.Position)
                if vis then
                    local d = (Vector2.new(pos.X,pos.Y) - Vector2.new(mp.X,mp.Y)).Magnitude
                    if d<cd then cd=d; closest=pl end
                end
            end
        end
        if closest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Character.Head.Position)
        end
    end

    -- FuckerMurder / FuckerSheriff Logic 
    if fuckerMurderEnabled or fuckerSheriffEnabled then
        local targetRole = fuckerMurderEnabled and "Murderer" or "Sheriff"
        local targetPlayer = nil
        
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer and getRole(pl) == targetRole and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character.Humanoid.Health > 0 then
                targetPlayer = pl
                break
            end
        end

        if targetPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = LocalPlayer.Character.HumanoidRootPart
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            
            local targetPos = targetRoot.Position + Vector3.new(0, 0.2, 0)
            root.CFrame = CFrame.new(targetPos) 
            
            if targetPlayer.Character.Humanoid.PlatformStand == false then
                targetRoot.Velocity = (root.CFrame.RightVector * 25) + Vector3.new(0, 25, 0) 
            end

        else
            if fuckerMurderEnabled then 
                fuckerMurderEnabled = false
                notify("FuckerMurder: цель потеряна")
            end
            if fuckerSheriffEnabled then 
                fuckerSheriffEnabled = false
                notify("FuckerSheriff: цель потеряна")
            end
        end
    end

    -- AutoMans Logic
    if autoMansEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl~=LocalPlayer and getRole(pl)=="Murderer" and pl.Character and pl.Character:FindFirstChild("Knife") then
                local root = LocalPlayer.Character.HumanoidRootPart
                local dist = (root.Position - pl.Character.HumanoidRootPart.Position).Magnitude
                if dist < 10 then
                    root.Velocity = (math.random()>0.5 and root.CFrame.RightVector or -root.CFrame.RightVector)*50 + Vector3.new(0,50,0)
                end
            end
        end
    end
end)

-- ESP по ролям (обновление раз в 5 сек)
local espBoxes = {}
task.spawn(function()
    while true do
        if espEnabled then
            for _,b in pairs(espBoxes) do b:Destroy() end; espBoxes={}
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local col = getRole(pl)=="Murderer" and Color3.new(1,0,0) or getRole(pl)=="Sheriff" and Color3.new(0,0.7,1) or Color3.new(1,1,1)
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = Vector3.new(4,6,1)
                    box.Adornee = pl.Character.HumanoidRootPart
                    box.AlwaysOnTop = true
                    box.Transparency = 0.4
                    box.Color3 = col
                    box.ZIndex = 5
                    box.Parent = pl.Character.HumanoidRootPart
                    espBoxes[pl] = box
                end
            end
        else
            for _,b in pairs(espBoxes) do b:Destroy() end; espBoxes={}
        end
        wait(5)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == espKey then
        espEnabled = not espEnabled
        notify("ESP " .. (espEnabled and "Вкл" or "Выкл"))
    end
end)

-- WeaponBoxESP (подсветка пистолетов Sheriff'а)
local weaponBoxes = {}
local function clearWBox()
    for _,v in pairs(weaponBoxes) do v:Destroy() end
    weaponBoxes = {}
end
task.spawn(function()
    while true do
        if weaponBoxESPEnabled then
            clearWBox()
            for _,obj in ipairs(workspace:GetDescendants()) do
                if obj.Name=="Gun" and obj:IsA("Tool") and obj.Parent~=LocalPlayer.Character then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = obj.Handle.Size + Vector3.new(0.2,0.2,0.2)
                    box.Adornee = obj.Handle
                    box.Color3 = Color3.new(0,1,0)
                    box.AlwaysOnTop = true
                    box.Transparency = 0.3
                    box.ZIndex = 6
                    box.Parent = obj.Handle
                    weaponBoxes[obj] = box
                end
            end
        else
            clearWBox()
        end
        wait(3)
    end
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == weaponBoxESPKey then
        weaponBoxESPEnabled = not weaponBoxESPEnabled
        notify("WeaponBoxESP " .. (weaponBoxESPEnabled and "Вкл" or "Выкл"))
    end
end)

-- KillFly и KillFlyMurder 
local function mouse1click()
    mouse1press(); wait(0.05); mouse1release() 
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == killFlyKey then
        if getRole(LocalPlayer) ~= "Murderer" then notify("KillFly только для Murderer") return end
        task.spawn(function()
            for _,pl in ipairs(Players:GetPlayers()) do
                if pl~=LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
                    local root = LocalPlayer.Character.HumanoidRootPart
                    local tgt = pl.Character.HumanoidRootPart
                    if (root.Position - tgt.Position).Magnitude < 500 then
                        root.CFrame = CFrame.new(tgt.Position + Vector3.new(0,2,0))
                        wait(0.2); mouse1click(); wait(0.3)
                    end
                end
            end
        end)
    elseif input.KeyCode == killFlyMurderKey then
        killFlyMurderEnabled = not killFlyMurderEnabled
        notify("KillFlyMurder " .. (killFlyMurderEnabled and "Вкл" or "Выкл"))
        if killFlyMurderEnabled then
            local conn
            conn = RunService.RenderStepped:Connect(function()
                local m = LocalPlayer.Character
                local tgt
                for _,pl in ipairs(Players:GetPlayers()) do
                    if pl~=LocalPlayer and getRole(pl)=="Murderer" and pl.Character and pl.Character.Humanoid and pl.Character.Humanoid.Health>0 then
                        tgt = pl break
                    end
                end
                if tgt and m and m:FindFirstChild("HumanoidRootPart") then
                    local root = m.HumanoidRootPart
                    local off = tgt.Character.HumanoidRootPart.CFrame.LookVector * -3 + Vector3.new(0,3,0)
                    root.CFrame = CFrame.new(tgt.Character.HumanoidRootPart.Position + off)
                    mouse1click()
                else
                    killFlyMurderEnabled = false
                    conn:Disconnect()
                    notify("KillFlyMurder: цель потеряна")
                end
            end)
        end
    end
end)

-- AutoMans на P
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == autoMansKey then
        autoMansEnabled = not autoMansEnabled
        notify("AutoMans " .. (autoMansEnabled and "Вкл" or "Выкл"))
    end
end)


-- GUI с сохранением статусов 
local toggles = {}
local function createToggle(name, key, func)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,35) 
    f.BackgroundColor3 = Color3.fromRGB(40,40,40)
    local lbl = Instance.new("TextLabel",f)
    lbl.Size = UDim2.new(0.7,0,1,0)
    lbl.Text = name.." ["..key.Name.."]"
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 24 
    local btn = Instance.new("TextButton",f)
    btn.Size = UDim2.new(0.3,0,1,0)
    btn.Position = UDim2.new(0.7,0,0,0)
    btn.Text="OFF"
    btn.BackgroundColor3 = Color3.fromRGB(200,0,0)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 20 
    local state = false
    local function update()
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    end
    btn.MouseButton1Click:Connect(function()
        state = not state
        func(state)
        update()
    end)
    UIS.InputBegan:Connect(function(i,g)
        if not g and i.KeyCode == key and key ~= Enum.KeyCode.Insert then -- Исключаем Insert из автоматического переключения
            state = not state
            func(state)
            update()
        end
    end)
    update()
    toggles[name] = state
    return f
end

-- Главное меню GUI (Увеличен)
local guiActive = false
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == menuKey then
        guiActive = not guiActive
        if guiActive then
            local sg = Instance.new("ScreenGui", game.CoreGui); sg.Name="WildClientGUI"
            local frm = Instance.new("Frame", sg)
            frm.Position = UDim2.new(0.3,0,0.2,0)
            frm.BackgroundColor3 = Color3.fromRGB(20,20,20)
            local title = Instance.new("TextLabel", frm)
            title.Size = UDim2.new(1,0,0,50) 
            title.Text = "Wild Client 2.1 (КРУТОЙ РЕЖИМ)" 
            title.Font = Enum.Font.SourceSansBold
            title.TextColor3 = Color3.new(1,1,1)
            title.BackgroundTransparency = 1
            title.TextSize = 30 
            local layout = Instance.new("UIListLayout",frm)
            layout.Padding = UDim.new(0,4)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                frm.Size = UDim2.new(0,400,0,50 + layout.AbsoluteContentSize.Y + 10) 
            end)
            for _,v in ipairs({
                {"Aimbot", aimKey, function(v) aiming=v end},
                {"ESP", espKey, function(v) espEnabled=v end},
                {"Fly", flyKey, function() UIS.InputBegan:Fire({KeyCode=flyKey},false) end},
                {"NoClip", noClipKey, function(v) noClipEnabled=v end},
                {"WeaponBoxESP", weaponBoxESPKey, function(v) weaponBoxESPEnabled=v end},
                {"AutoMans", autoMansKey, function(v) autoMansEnabled=v end},
                {"KillFly", killFlyKey, function() UIS.InputBegan:Fire({KeyCode=killFlyKey},false) end},
                {"KillFlyMurder", killFlyMurderKey, function() UIS.InputBegan:Fire({KeyCode=killFlyMurderKey},false) end},
                {"FuckerMurder", fuckerMurderKey, function(v) fuckerMurderEnabled=v; if v then fuckerSheriffEnabled=false end end}, 
                {"FuckerSheriff", fuckerSheriffKey, function(v) fuckerSheriffEnabled=v; if v then fuckerMurderEnabled=false end end}, 
                {"TeleportMap", teleportMapKey, function() teleportToMapCenter() end}, -- Новый элемент
            }) do
                local tk = createToggle(v[1], v[2], v[3])
                tk.Parent = frm
            end
        else
            local sg = game.CoreGui:FindFirstChild("WildClientGUI")
            if sg then sg:Destroy() end
        end
    end
end)
