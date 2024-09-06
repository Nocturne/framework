local SecurityService = {}
SecurityService.__index = SecurityService
local DataStoreService = game:GetService("DataStoreService")
local banDataStore = DataStoreService:GetDataStore("BanDataStore")
local allowedItems = {"Sword", "Shield", "Potion"}
local allowedRemoteEvents = {"AttackEvent", "DefendEvent"}
local punishmentThresholds = {
    {threshold = 3, penalty = "warn"},
    {threshold = 5, penalty = "kick"},
    {threshold = 10, penalty = "ban"}
}
local discordWebhookUrl = "YOUR_DISCORD_WEBHOOK_URL"

function SecurityService.new()
    local self = setmetatable({}, SecurityService)
    self.keys = {}
    self.playerOffenses = {}
    self.punishmentHistory = {}
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
        self.punishmentHistory[player.UserId] = {}
        player.CharacterAdded:Connect(function(character)
            self:monitorPlayerMovement(player, character)
            self:monitorPlayerHealth(player, character)
            self:monitorPlayerTools(player, character)
            self:monitorClientBehavior(player, character)
        end)
    end)

    game.Players.PlayerRemoving:Connect(function(player)
        self.keys[player.UserId] = nil
        self.playerOffenses[player.UserId] = nil
        self.punishmentHistory[player.UserId] = nil
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
            self:applyPunishment(player)
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
            self.playerOffenses[player.UserId] = self.playerOffenses[player.UserId] + 1
            self:applyPunishment(player)
        end
    end)
end

function SecurityService:monitorPlayerTools(player, character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and not table.find(allowedItems, child.Name) then
            self.playerOffenses[player.UserId] = self.playerOffenses[player.UserId] + 1
            self:applyPunishment(player)
        end
    end)
end

function SecurityService:validateRemoteEvent(event)
    if not table.find(allowedRemoteEvents, event.Name) then
        event:Destroy()
        self:logSecurityEvent(event, "unauthorized RemoteEvent")
    end
end

function SecurityService:monitorClientBehavior(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local lastFireTime = 0
    local fireCooldown = 0.5

    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.MouseButton1 then
            local currentTime = tick()
            if currentTime - lastFireTime < fireCooldown then
                self.playerOffenses[player.UserId] = self.playerOffenses[player.UserId] + 1
                self:applyPunishment(player)
            end
            lastFireTime = currentTime
        end
    end)
end

function SecurityService:applyPunishment(player)
    local offenses = self.playerOffenses[player.UserId]
    for _, threshold in ipairs(punishmentThresholds) do
        if offenses >= threshold.threshold then
            local penalty = threshold.penalty
            if penalty == "warn" then
                self:warnPlayer(player)
            elseif penalty == "kick" then
                self:kickPlayer(player)
            elseif penalty == "ban" then
                self:banPlayer(player)
            end
            return
        end
    end
end

function SecurityService:warnPlayer(player)
    print("Player " .. player.Name .. " warned for suspicious behavior.")
    self:logSecurityEvent(player, "warn")
end

function SecurityService:kickPlayer(player)
    player:Kick("Suspicious behavior detected.")
    print("Player " .. player.Name .. " kicked for suspicious behavior.")
    self:logSecurityEvent(player, "kick")
end

function SecurityService:banPlayer(player)
    local playerId = player.UserId
    local banData = {
        reason = "Suspicious behavior detected",
        timestamp = tick()
    }
    local success, errorMessage = pcall(function()
        banDataStore:SetAsync(playerId, banData)
    end)
    if success then
        print("Player " .. player.Name .. " banned for suspicious behavior.")
        self:kickPlayer(player)
        self:logSecurityEvent(player, "ban")
    else
        print("Error banning player: " .. errorMessage)
    end
end

function SecurityService:checkIfPlayerIsBanned(player)
    local playerId = player.UserId
    local banData = banDataStore:GetAsync(playerId)
    if banData then
        local banReason = banData.reason
        local banTimestamp = banData.timestamp
        local currentTime = tick()
        -- You can add a ban duration check here if you want
        -- For example:
        -- if currentTime - banTimestamp < 86400 then (86400 is 1 day in seconds)
        print("Player " .. player.Name .. " is banned for: " .. banReason)
        player:Kick("You are banned for: " .. banReason)
        return true
    end
    return false
end

-- Call this function when a player joins the game
game.Players.PlayerAdded:Connect(function(player)
    if SecurityService:checkIfPlayerIsBanned(player) then
        return
    end
    -- Rest of your code here
end)
function SecurityService:logSecurityEvent(player, eventType)
    local playerName = player.Name
    local playerId = player.UserId
    local eventTypeString = eventType == "warn" and "warned" or eventType == "kick" and "kicked" or "banned"
    local message = "Player " .. playerName .. " (" .. playerId .. ") " .. eventTypeString .. " for suspicious behavior."
    self:sendDiscordWebhook(message)
end

function SecurityService:sendDiscordWebhook(message)
    local httpRequest = game:GetService("HttpService"):RequestAsync({
        Url = discordWebhookUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = game:GetService("HttpService"):JSONEncode({
            content = message
        })
    })
    if httpRequest.Success then
        print("Discord webhook sent successfully.")
    else
        print("Error sending Discord webhook: " .. httpRequest.StatusCode .. " - " .. httpRequest.StatusMessage)
    end
end

return SecurityService