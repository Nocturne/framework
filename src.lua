local Nocturne = Class.new("Nocturne")

---@class Nocturne
---@brief Manages core functionalities for the game, including assets, remotes, and security.

function Nocturne:initialize()
  self.loadedAssets = {}
  self.remotes = {}
  self.controllerServiceLoader = ControllerServiceLoader.new()
  self.securityService = SecurityService.new()
  self.securityService:start()
end

---@param assetId string The ID of the asset to load.
---@return Asset The loaded asset.
function Nocturne:loadAsset(assetId)
  local asset = game.Assets:Load(assetId)
  self.loadedAssets[assetId] = asset
  return asset
end

---@param assetId string The ID of the asset to unload.
function Nocturne:unloadAsset(assetId)
  local asset = self.loadedAssets[assetId]
  if asset then
    game.Assets:Unload(assetId)
    self.loadedAssets[assetId] = nil
  end
end

---@return number The number of loaded assets.
function Nocturne:getAssetCount()
  return #self.loadedAssets
end

---@param eventName string The name of the remote event.
---@param ... any The arguments to pass to the remote event.
function Nocturne:fireRemoteEvent(eventName, ...)
  local remote = self.remotes[eventName]
  if remote then
    remote:FireServer(...)
  else
    warn("Remote event not found: " .. eventName)
  end
end

---@param eventName string The name of the remote event.
---@param callback function The callback function to execute when the remote event is fired.
function Nocturne:connectRemoteEvent(eventName, callback)
  local remote = self.remotes[eventName]
  if remote then
    remote.OnServerEvent:Connect(callback)
  else
    warn("Remote event not found: " .. eventName)
  end
end

---@param eventName string The name of the remote event.
---@param callback function The callback function to disconnect.
function Nocturne:disconnectRemoteEvent(eventName, callback)
  local remote = self.remotes[eventName]
  if remote then
    remote.OnServerEvent:Disconnect(callback)
  else
    warn("Remote event not found: " .. eventName)
  end
end

---@return ControllerServiceLoader The controller and service loader.
function Nocturne:getControllerServiceLoader()
  return self.controllerServiceLoader
end

---@return SecurityService The security and exploit prevention service.
function Nocturne:getSecurityService()
  return self.securityService
end

return Nocturne
