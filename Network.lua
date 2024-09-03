local NetworkModule = {}
NetworkModule.__index = NetworkModule

local HttpService = game:GetService("HttpService")

function NetworkModule.new()
    local self = setmetatable({}, NetworkModule)
    self.encryptionKey = self:generateKey()
    return self
end

function NetworkModule:generateKey()
    return HttpService:GenerateGUID(false) .. HttpService:GenerateGUID(false)
end

function NetworkModule:encrypt(data)
    local json = HttpService:JSONEncode(data)
    local encrypted = ""
    for i = 1, #json do
        local keyByte = self.encryptionKey:byte((i - 1) % #self.encryptionKey + 1)
        local dataByte = json:byte(i)
        encrypted = encrypted .. string.char(bit32.bxor(dataByte, keyByte))
    end
    return HttpService:UrlEncode(encrypted)
end

function NetworkModule:decrypt(data)
    local decoded = HttpService:UrlDecode(data)
    local decrypted = ""
    for i = 1, #decoded do
        local keyByte = self.encryptionKey:byte((i - 1) % #self.encryptionKey + 1)
        local dataByte = decoded:byte(i)
        decrypted = decrypted .. string.char(bit32.bxor(dataByte, keyByte))
    end
    return HttpService:JSONDecode(decrypted)
end

function NetworkModule:shuffleArguments(args)
    local shuffled = {}
    for i = #args, 1, -1 do
        local j = math.random(1, i)
        args[i], args[j] = args[j], args[i]
    end
    return args
end

function NetworkModule:fireRemoteEvent(remote, ...)
    local args = {...}
    args = self:shuffleArguments(args)
    local encryptedArgs = self:encrypt(args)
    remote:FireServer(encryptedArgs)
end

function NetworkModule:onServerEvent(remote, callback)
    remote.OnServerEvent:Connect(function(player, encryptedArgs)
        local args = self:decrypt(encryptedArgs)
        callback(player, unpack(args))
    end)
end

return NetworkModule