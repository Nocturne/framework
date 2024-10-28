local ControllerServiceLoader = {}
ControllerServiceLoader.__index = ControllerServiceLoader

local MODULE_TYPES = {
    CONTROLLER = "Controllers",
    SERVICE = "Services"
}

local function getModulePath(moduleType, moduleName)
    return game:GetService("ReplicatedStorage"):WaitForChild(moduleType):WaitForChild(moduleName)
end

--- Creates a new ControllerServiceLoader instance.
-- @param baseFolder The base folder containing Controllers and Services folders (optional, defaults to ReplicatedStorage)
-- @return ControllerServiceLoader A new instance of the loader.
function ControllerServiceLoader.new(baseFolder)
    local self = setmetatable({}, ControllerServiceLoader)
    
    self.baseFolder = baseFolder or game:GetService("ReplicatedStorage")
    self.controllers = setmetatable({}, {
        __index = function(t, k)
            return self:_loadModule(MODULE_TYPES.CONTROLLER, k)
        end
    })
    self.services = setmetatable({}, {
        __index = function(t, k)
            return self:_loadModule(MODULE_TYPES.SERVICE, k)
        end
    })
    
    self.loadedModules = {}
    self.loadingModules = {}
    self.dependencies = {}
    
    return self
end

--- Registers dependencies for a module
-- @param moduleName string The name of the module
-- @param dependencies table Array of dependency module names
function ControllerServiceLoader:registerDependencies(moduleName, dependencies)
    self.dependencies[moduleName] = dependencies
end

--- Loads a module's dependencies
-- @param moduleName string The name of the module
-- @private
function ControllerServiceLoader:_loadDependencies(moduleName)
    local deps = self.dependencies[moduleName]
    if not deps then return end
    
    for _, depName in ipairs(deps) do
        if not self.loadedModules[depName] then
            self:_loadModule(self:_getModuleType(depName), depName)
        end
    end
end

--- Determines the type of a module based on its name or location
-- @param moduleName string The name of the module
-- @return string The module type (CONTROLLER or SERVICE)
-- @private
function ControllerServiceLoader:_getModuleType(moduleName)
    -- First check if the module exists in Controllers
    if self.baseFolder:FindFirstChild(MODULE_TYPES.CONTROLLER):FindFirstChild(moduleName) then
        return MODULE_TYPES.CONTROLLER
    else
        return MODULE_TYPES.SERVICE -- Default to Service if not found in Controllers
    end
end

--- Internal function to load a module on demand.
-- Handles lazy loading, dependencies, and circular dependency checks.
-- @param moduleType string The type of module (CONTROLLER or SERVICE)
-- @param moduleName string The name of the module to load
-- @return table The loaded module
-- @throws error If a circular dependency is detected
function ControllerServiceLoader:_loadModule(moduleType, moduleName)
    if self.loadingModules[moduleName] then
        error(string.format("Circular dependency detected for module: %s", moduleName))
    end
    
    if self.loadedModules[moduleName] then
        return self.loadedModules[moduleName]
    end
    
    self.loadingModules[moduleName] = true
    
    -- Load dependencies first
    self:_loadDependencies(moduleName)
    
    local success, result = pcall(function()
        local moduleInstance = getModulePath(moduleType, moduleName)
        local module = require(moduleInstance)
        
        -- Initialize the module if it has an init function
        if type(module) == "table" and type(module.init) == "function" then
            module:init()
        end
        
        return module
    end)
    
    self.loadingModules[moduleName] = nil
    
    if not success then
        error(string.format("Failed to load module %s: %s", moduleName, result))
    end
    
    self.loadedModules[moduleName] = result
    
    -- Cache in appropriate table
    if moduleType == MODULE_TYPES.CONTROLLER then
        self.controllers[moduleName] = result
    else
        self.services[moduleName] = result
    end
    
    return result
end

--- Loads a list of modules in the specified order.
-- @param moduleNames table An array of module names to load in order
-- @param forceReload boolean Whether to reload modules even if already loaded
function ControllerServiceLoader:loadInOrder(moduleNames, forceReload)
    for _, moduleName in ipairs(moduleNames) do
        if forceReload or not self.loadedModules[moduleName] then
            self:_loadModule(self:_getModuleType(moduleName), moduleName)
        end
    end
end

--- Loads all modules in the Controllers and Services folders
function ControllerServiceLoader:loadAll()
    local function loadFromFolder(folder)
        for _, moduleScript in ipairs(folder:GetChildren()) do
            if moduleScript:IsA("ModuleScript") then
                self:_loadModule(folder.Name, moduleScript.Name)
            end
        end
    end
    
    loadFromFolder(self.baseFolder:WaitForChild(MODULE_TYPES.CONTROLLER))
    loadFromFolder(self.baseFolder:WaitForChild(MODULE_TYPES.SERVICE))
end

--- Returns a loaded module by name
-- @param moduleName string The name of the module
-- @return table The loaded module or nil if not found
function ControllerServiceLoader:getModule(moduleName)
    return self.loadedModules[moduleName]
end

--- Returns all loaded modules
-- @return table A table of all loaded modules
function ControllerServiceLoader:getLoadedModules()
    return self.loadedModules
end

return ControllerServiceLoader