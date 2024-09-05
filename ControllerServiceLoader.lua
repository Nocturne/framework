0ilocal ControllerServiceLoader = {}
ControllerServiceLoader.__index = ControllerServiceLoader

--- Creates a new ControllerServiceLoader instance.
-- @return ControllerServiceLoader A new instance of the loader.
function ControllerServiceLoader.new()
    local self = setmetatable({}, ControllerServiceLoader)
    self.controllers = setmetatable({}, { __index = self._loadModule })
    self.services = setmetatable({}, { __index = self._loadModule })
    self.loadingModules = {} -- Track modules being loaded to prevent circular dependencies.
    return self
end

--- Loads a list of modules in the specified order.
-- Modules already loaded are skipped.
-- @param moduleNames table An array of module names to load in order.
function ControllerServiceLoader:loadInOrder(moduleNames)
    for _, moduleName in ipairs(moduleNames) do
        if not (self.controllers[moduleName] or self.services[moduleName]) then
            self:_loadModule(nil, moduleName) 
        end
    end
end

--- Internal function to load a module on demand.
-- Handles lazy loading and circular dependency checks.
-- @param table (optional) The table to cache the loaded module in.
-- @param moduleName string The name of the module to load.
-- @return table The loaded module.
-- @throws error If a circular dependency is detected.
function ControllerServiceLoader:_loadModule(table, moduleName)
    if self.loadingModules[moduleName] then
        error("Circular dependency detected for module: " .. moduleName)
    end

    self.loadingModules[moduleName] = true 

    print("Loading module: " .. moduleName)
    local module = require(moduleName)

    self.loadingModules[moduleName] = nil 

    if table then
        table[moduleName] = module
    end

    return module
end

--- Returns the table of loaded controllers.
-- Controllers are lazily loaded when first accessed.
-- @return table The table of loaded controllers.
function ControllerServiceLoader:getLoadedControllers()
    return self.controllers
end

--- Returns the table of loaded services.
-- Services are lazily loaded when first accessed.
-- @return table The table of loaded services.
function ControllerServiceLoader:getLoadedServices()
    return self.services
end

return ControllerServiceLoader
