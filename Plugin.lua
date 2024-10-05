
local PluginManager = {}
PluginManager.__index = PluginManager

function PluginManager.new()
    local self = setmetatable({}, PluginManager)
    self.plugins = {}
    return self
end

function PluginManager:loadPlugin(pluginPath)
    local env = {
        print = print,
        pairs = pairs,
        ipairs = ipairs,
        -- TODO: Add more functions 
    }
    setfenv(plugin, env)

    local success, result = pcall(plugin)
    if not success then
        print("Error executing plugin: " .. result)
        return false
    end

    table.insert(self.plugins, result)
    return true
end

function PluginManager:executePlugins()
    for _, plugin in ipairs(self.plugins) do
        if type(plugin.run) == "function" then
            plugin.run()
        end
    end
end

return PluginManager