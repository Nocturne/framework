local ControllerServiceLoader = {}
ControllerServiceLoader.__index = ControllerServiceLoader

--- Creates a new instance of ControllerServiceLoader
function ControllerServiceLoader.new()
    local self = setmetatable({}, ControllerServiceLoader)
    self.controllers = {}
    self.services = {}
    return self
end

--- Loads a controller
---@param controllerName string The name of the controller to load
function ControllerServiceLoader:loadController(controllerName)
    -- Implement the logic to load a controller
    print("Loading controller: " .. controllerName)
    self.controllers[controllerName] = true
end

--- Loads a service
---@param serviceName string The name of the service to load
function ControllerServiceLoader:loadService(serviceName)
    -- Implement the logic to load a service
    print("Loading service: " .. serviceName)
    self.services[serviceName] = true
end

--- Returns the list of loaded controllers
---@return table The list of loaded controllers
function ControllerServiceLoader:getLoadedControllers()
    return self.controllers
end

--- Returns the list of loaded services
---@return table The list of loaded services
function ControllerServiceLoader:getLoadedServices()
    return self.services
end

return ControllerServiceLoader