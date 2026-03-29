if not game:IsLoaded() then game.Loaded:Wait() end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "RGD GUI",
   LoadingTitle = "Randomly Generated Droids GUI",
   LoadingSubtitle = "by John Droids (Ali)",
   ShowText = "RGD",
   ToggleUIKeybind = "K"
})

local mainTab = Window:CreateTab("Main")
local keyTab = Window:CreateTab("Keybinds")
local debugTab = Window:CreateTab("Debug")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local plr = Players.LocalPlayer
local PlayerGui = plr.PlayerGui

local Camera = workspace.CurrentCamera

local genValues = workspace.GenValues
local friendlies = workspace.PassiveDroids
local roomNumber = genValues.RoomNumber
local GE = ReplicatedStorage.GuiEvent
local classFrame = PlayerGui:WaitForChild("ClassGui"):WaitForChild("Frame")
local yesorno
local sword

local as = false
local nb = false
local tka = false
local isAutoFarming = _G.autoFarm or false

local connections = {}

local function notif(txt, tit, dur)
    Rayfield:Notify({
        Content = txt or " ",
        Title = tit or "Notification",
        Duration = dur or 5
    })
end
local function getChar(player)
    return player.Character or player.CharacterAdded:Wait()
end

local function getHuman(char)
    return char:FindFirstChildOfClass("Humanoid")
end

local function getRoot(char, humanoid)
    humanoid = humanoid or getHuman(char)
    return char:FindFirstChild("HumanoidRootPart") or (humanoid and humanoid.RootPart)
end

local allRooms = {}
local function getRooms()
    allRooms = {}
    for _, room in workspace:GetChildren() do
        if room.Name == "Room" or room.Name == "Old Room" then
            table.insert(allRooms, room)
        end
    end
    return allRooms
end
getRooms()

local canPress = true
local function getMousePosition()
    local mouse = plr:GetMouse()
    local camera = workspace.CurrentCamera

    if mouse.Target then
        return mouse.Hit.Position
    else
        local rayOrigin = camera.CFrame.Position
        local rayDir = camera.CFrame.LookVector * 100

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {plr.Character}

        local result = workspace:Raycast(rayOrigin, rayDir, params)

        return result and result.Position or (rayOrigin + rayDir)
    end
end

local function killall()
    task.spawn(function()
        for _, droid in friendlies:GetChildren() do
            if droid.Name == "Friendly Droid" then
                local h = getHuman(droid)
                if h then
                    h.Health = 0
                end
            end
        end
    end)
    task.spawn(function()
        for _, room in allRooms do
            task.spawn(function()
                for _, h in room:GetDescendants() do
                    if not h:IsA("Humanoid") then continue end
                    h.Health = 0
                end
            end)
        end
    end)
end

local function clickAll()
    if not canPress then return end
    canPress = false

    local rooms = allRooms
    if not rooms then
        print("no rooms?")
        canPress = true
        return
    end

    local room
    for i, v in pairs(rooms) do
        if v.Name == "Room" then
            room = v
        end
    end
    local enemies = room and room:FindFirstChild("Enemies")
    if not enemies then
        canPress = true
        return
    end

    local targetPos = getMousePosition()
    local clicked = 0

    for _, b in enemies:GetChildren() do
        if b.Name:find("Button") then
            local cd = b:FindFirstChildOfClass("ClickDetector")
            if not cd then print("none") continue end

            b.CFrame = CFrame.new(targetPos)
            cd.MaxActivationDistance = math.huge
            task.wait(.1)

            VirtualInputManager:SendMouseButtonEvent(0,0,0, true, game, 0)
            task.wait(.05)
            VirtualInputManager:SendMouseButtonEvent(0,0,0, false, game, 0)
            clicked += 1

            task.wait(.1)
        end
    end

    canPress = true
end

local function collectCircuits()
    for _, circuit in workspace:GetChildren() do
        if (circuit.Name == "Circuit" or circuit.Name == "BigCircuit") and circuit:IsA("UnionOperation") then
            circuit.CanCollide = false
            circuit.Position = getRoot(getChar(plr)).Position
        end
    end
    for _, room in allRooms do
        task.spawn(function()
            for _, circuit in room:GetChildren() do
                if (circuit.Name == "Circuit" or circuit.Name == "BigCircuit") and circuit:IsA("UnionOperation") then
                    circuit.CanCollide = false
                    circuit.Position = getRoot(getChar(plr)).Position
                end
            end
        end)
    end
end

---------------------------------------------------------------------------------

local autofarmToggle = mainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = isAutoFarming,
    Callback = function(Value)
        isAutoFarming = Value
    end
})

mainTab:CreateDivider()

local ddd = mainTab:CreateToggle({
    Name = "Disable Droid and Hazard Damage",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            for _, part in getChar(plr):GetChildren() do
                if part:IsA("BasePart") then
                    if part.Name == "HumanoidRootPart" then part.CanTouch = true continue end
                    part.CanTouch = false
                end
            end
            notif("Disabled Droid Damage!")
        else
            for _, part in getChar(plr):GetChildren() do
                if part:IsA("BasePart") then
                    part.CanTouch = true
                end
            end
            notif("Enabled Droid Damage!")
        end
    end
})

local asbp = mainTab:CreateToggle({
    Name = "Auto Solve Box Puzzles",
    CurrentValue = as,
    Callback = function(Value)
        as = Value
    end
})
local dab = mainTab:CreateToggle({
    Name = "Destroy All Droid Projectiles",
    CurrentValue = nb,
    Callback = function(Value)
        nb = Value
    end
})
local ka = mainTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = tka,
    Callback = function(Value)
        tka = Value
    end
})

------------------------------

keyTab:CreateKeybind({
    Name = "Click All Buttons",
    CurrentKeybind = "C",
    HoldToInteract = false,
    Callback = function(key)
        clickAll()
    end
})
keyTab:CreateKeybind({
    Name = "Collect Circuits",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Callback = function(key)
        collectCircuits()
    end
})
keyTab:CreateKeybind({
    Name = "Kill All Once",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Callback = function(key)
        killall()
    end
})
keyTab:CreateKeybind({
    Name = "Toggle Auto Farm",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Callback = function()
        local value = not isAutoFarming
        autofarmToggle:Set(value)
    end
})

--debug

debugTab:CreateButton({
    Name = "Destroy Gui",
    Callback = function()
        destroygui()
    end
})

---connections

local function newWorkspaceChild(child)
    getRooms()

    if nb then
        if child.Name == "Bullet" or child.Name == "Snowball" or child.Name == "GigaIcicle" then
            child:Destroy()
        end
    end
end

local rc = workspace.ChildAdded:Connect(newWorkspaceChild)
table.insert(connections, rc)

--loop

local ishundred = 0
local runLoop = RunService.Heartbeat:Connect(function()
    if as then
        for _, room in allRooms do
            task.spawn(function()
                local boxes = {}
                local plates = {}
                for _, child in room:GetChildren() do
                    if child.Name:find("PuzzleBox") then
                        table.insert(boxes, #boxes + 1, child)
                    elseif child.Name:find("PressurePlate") then
                        table.insert(plates, #plates + 1, child)
                    end
                end

                if #boxes > 0 then
                    for i, v in pairs(boxes) do
                        local plate = plates[i]

                        v:PivotTo(plate.Activator.CFrame)
                    end
                end
            end)
        end
    end

    if tka then killall() end


    --autofarm
    if isAutoFarming then
        local char = getChar(plr)
        local root = char and getRoot(char)
        local currentRoom

        if not yesorno then
            yesorno = PlayerGui:FindFirstChild("YesOrNoPrompt")
        end

        for _, room in allRooms do
            if room.Name == "Room" then currentRoom = room end
        end

        if root and currentRoom and currentRoom:FindFirstChild("Gate") then
            if not sword then
                sword = plr.Backpack:FindFirstChild("Copper Sword") or char:FindFirstChild("Copper Sword")
                if sword then
                    sword.Parent = plr.Backpack
                end
            else
                sword.Parent = plr.Backpack
            end
            Rayfield:SetVisibility(false)
            local humanoid = getHuman(char)
            plr.CameraMode = Enum.CameraMode.LockFirstPerson
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
            asbp:Set(true)
            dab:Set(true)
            ka:Set(true)
            clickAll()
            collectCircuits()

            classFrame["ClassButton1"].AutoUse.Value = true
            classFrame["ClassButton2"].AutoUse.Value = true

            if currentRoom.Enemies:FindFirstChild("Bat Wing") then
                local wing = currentRoom.Enemies["Bat Wing"]
                wing.Handle.CFrame = char.PrimaryPart.CFrame
                task.wait()
                wing.Parent = char
                wing:Activate()
            end

            if currentRoom:FindFirstChild("DragonTreasureFolder") and currentRoom.Enemies:FindFirstChild("Interact") then
                char:PivotTo(currentRoom.Enemies.Interact.CFrame - Vector3.new(0,0, 3))
                currentRoom.Enemies.Interact.ProximityPrompt:InputHoldBegin()
                yesorno.RemoteEvent:FireServer(true)
            elseif currentRoom.Enemies:FindFirstChild("SlotMachine") then
                local b = currentRoom.Enemies.SlotMachine.Handle.Ball
                char:PivotTo(b.CFrame - Vector3.new(0, 0, 3))
                b.Attachment.ProximityPrompt:InputHoldBegin()
            else
                char:PivotTo(currentRoom.Gate.CFrame + Vector3.new(0, 0, -2))
                sword.Parent = char
            end

            for _, enemy in currentRoom.Enemies:GetChildren() do
                if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
                    task.spawn(function()
                        enemy:PivotTo(root.CFrame * root.CFrame.LookVector * 1.5)
                    end)
                end
            end

            if not humanoid:HasTag("onDiedEventAutoFarm") then
                humanoid:AddTag("onDiedEventAutoFarm")
                humanoid.Died:Connect(function()
                    queue_on_teleport([[
                        _G.autoFarm = true
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/alizeja/RGD-Gui/refs/heads/main/rgd.lua"))()
                    ]])
                    GE:FireServer("Restart")
                end)
            end

            if ishundred >= 3 then
                humanoid:ChangeState(Enum.HumanoidStateType.Dead)
                char:BreakJoints()
            end
            if roomNumber.Value == 100 then
                ishundred += 1
            end
        end
    else
        plr.CameraMode = Enum.CameraMode.Classic
    end
end)

function destroygui()
    runLoop:Disconnect()
    print("run loop disconnected")

    task.spawn(function()
        local n = 0
        for c = 1, #connections do
            connections[c]:Disconnect()
            connections[c] = nil
            n += 1
        end
        print("disconnected "..n.." connections. (background)")
    end)

    ddd:Set(false)
    print("droid damage enabled")
    asbp:Set(false)
    print("auto solve disabled")
    dab:Set(false)
    print("bullets no longer destroyed")
    ka:Set(false)
    print("kill aura disabled")
    autofarmToggle:Set(false)
    print("autofarm off")

    print("destroying rayfield...")
    task.wait(.5)
    Rayfield:Destroy()
end