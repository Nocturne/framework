local NetworkModule = {}
NetworkModule.__index = NetworkModule

local HttpService = game:GetService("HttpService")
local CryptService = game:GetService("CryptService")
local RunService = game:GetService("RunService")
local mathRandom = math.random

function NetworkModule.new()
    local self = setmetatable({}, NetworkModule)
    self.encryptionKey = self:generateKey()
    self.remoteName = self:generateRemoteName()
    self.remoteLocation = self:generateRemoteLocation()
    self.fakeRemotes = {}
    self.realRemote = nil
    self.remoteChangeInterval = 300 -- 5 minutes
    self.remoteChangeConnection = nil
    self.remoteEventAmount = mathRandom(5, 10) -- Randomize remote event amount
    return self
end

function NetworkModule:generateKey()
    return CryptService:RandomBytes(32)
end

function NetworkModule:generateRemoteName()
    return HttpService:GenerateGUID(false)
end

function NetworkModule:generateRemoteLocation()
    local locations = {
        game.ReplicatedStorage,
        game.ServerStorage,
        game.Workspace,
    }
    return locations[mathRandom(1, #locations)]
end

function NetworkModule:encrypt(data)
    local json = HttpService:JSONEncode(data)
    local encrypted = ""
    for i = 1, #json do
        local keyByte = self.encryptionKey:byte((i - 1) % #self.encryptionKey + 1)
        local dataByte = json:byte(i)
        encrypted = encrypted .. string.char(bit32.bxor(dataByte, keyByte))
    end
    return HttpService:UrlEncode(HttpService:Base64Encode(encrypted))
end

function NetworkModule:decrypt(data)
    local decoded = HttpService:UrlDecode(data)
    local decrypted = ""
    for i = 1, #decoded do
        local keyByte = self.encryptionKey:byte((i - 1) % #self.encryptionKey + 1)
        local dataByte = decoded:byte(i)
        decrypted = decrypted .. string.char(bit32.bxor(dataByte, keyByte))
    end
    return HttpService:JSONDecode(HttpService:Base64Decode(decrypted))
end

function NetworkModule:shuffleArguments(args)
    local shuffled = {}
    for i = #args, 1, -1 do
        local j = mathRandom(1, i)
        args[i], args[j] = args[j], args[i]
    end
    return args
end

function NetworkModule:hideArguments(args)
    local hiddenArgs = {}
    local nestedTables = {}
    for i = 1, mathRandom(3, 5) do
        table.insert(nestedTables, {})
    end
    for i = 1, #args do
        local tableIndex = mathRandom(1, #nestedTables)
        table.insert(nestedTables[tableIndex], args[i])
    end
    table.insert(hiddenArgs, nestedTables)
    return hiddenArgs
end

function NetworkModule:changeRemote()
    if self.realRemote then
        self.realRemote:Destroy()
    end
    self.remoteName = self:generateRemoteName()
    self.remoteLocation = self:generateRemoteLocation()
    self.realRemote = Instance.new("RemoteEvent")
    self.realRemote.Name = self.remoteName
    self.realRemote.Parent = self.remoteLocation
    for _, fakeRemote in pairs(self.fakeRemotes) do
        fakeRemote:Destroy()
    end
    self.fakeRemotes = {}
    for i = 1, self.remoteEventAmount do
        local fakeRemote = Instance.new("RemoteEvent")
        fakeRemote.Name = HttpService:GenerateGUID(false)
        fakeRemote.Parent = self.remoteLocation
        table.insert(self.fakeRemotes, fakeRemote)
    end
end

function NetworkModule:init()
    self:changeRemote()
    self.remoteChangeConnection = RunService.RenderStepped:Connect(function()
        if tick() % self.remoteChangeInterval < 1 then
            self:changeRemote()
        end
    end)
end

function NetworkModule:fireRemoteEvent(...)
    local args = {...}
    args = self:shuffleArguments(args)
    args = self:hideArguments(args)
    local encryptedArgs = self:encrypt(args)
    self.realRemote:FireServer(encryptedArgs)
end

function NetworkModule:onServerEvent(callback)
    self.realRemote.OnServerEvent:Connect(function(player, encryptedArgs)
        local args = self:decrypt(encryptedArgs)
        local unpackedArgs = {}
        for _, nestedTable in pairs(args[1]) do
            for _, arg in pairs(nestedTable) do
                table.insert(unpackedArgs, arg)
            end
        end
        callback(player, unpack(unpackedArgs))
    end)
        for _, fakeRemote in pairs(self.fakeRemotes) do
        fakeRemote.OnServerEvent:Connect(function(player, encryptedArgs)
            
        end)
    end
end

return NetworkModule