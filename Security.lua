local SecurityService = {}
SecurityService.__index = SecurityService

function SecurityService.new()
    local self = setmetatable({}, SecurityService)
    self.allowedItems = {"Sword", "Shield", "Potion"} -- Define the whitelist of allowed items
    self.allowedRemoteEvents = {"AttackEvent", "DefendEvent"} -- Define the whitelist of allowed RemoteEvents
    self.keys = {}
    self.playerOffenses = {}
    return self
end

function SecurityService:start()
    self:setupAntiCheat()
end

function SecurityService:setupAntiCheat()
    game.Players.PlayerAdded:Connect(function(player)
        local key = self:generateKey()
        self.keys[player.UserId] = key
        player:SetAttribute("SecurityKey", key)
        self.playerOffenses[player.UserId] = 0
        player.CharacterAdded:Connect(function(character)
            self:monitorPlayerMovement(player, character)
            self:monitorPlayerHealth(player, character)
            self:monitorPlayerTools(player, character)
        end)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        self.keys[player.UserId] = nil
        self.playerOffenses[player.UserId] = nil
    end)

    game.ReplicatedStorage.ChildAdded:Connect(function(child)
        if child:IsA("RemoteEvent") then
            self:validateRemoteEvent(child)
        end
    end)
end

function SecurityService:generateKey()
    return math.random(100000, 999999)
end

function SecurityService:monitorPlayerMovement(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local lastPosition = character.PrimaryPart.Position
    local walkSpeed = humanoid.WalkSpeed
    local tolerableDelta = walkSpeed * 1.4

    game:GetService("RunService").Heartbeat:Connect(function()
        local currentPosition = character.PrimaryPart.Position
        local distanceDelta = (currentPosition - lastPosition).magnitude

        if distanceDelta > tolerableDelta then
            self.playerOffenses[player.UserId] = self.playerOffenses[player.UserId] + 1
            if self.playerOffenses[player.UserId] > 5 then
                player:Kick("Suspicious movement detected.")
                print("Player " .. player.Name .. " kicked for suspicious movement.")
            end
        else
            self.playerOffenses[player.UserId] = 0
        end

        lastPosition = currentPosition
    end)
end

function SecurityService:monitorPlayerHealth(player, character)
    local humanoid = character:WaitForChild("Humanoid")

    humanoid.HealthChanged:Connect(function(health)
        if health > humanoid.MaxHealth then
            player:Kick("Suspicious health detected.")
            print("Player " .. player.Name .. " kicked for suspicious health.")
        end
    end)
end

function SecurityService:monitorPlayerTools(player, character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and not table.find(self.allowedItems, child.Name) then
            player:Kick("Unauthorized tool usage detected.")
            print("Player " .. player.Name .. " kicked for using unauthorized tool: " .. child.Name)
        end
    end)
end

function SecurityService:validateRemoteEvent(event)
    if not table.find(self.allowedRemoteEvents, event.Name) then
        event:Destroy()
        print("Unauthorized RemoteEvent detected and destroyed: " .. event.Name)
   end
end 

return SecurityService 