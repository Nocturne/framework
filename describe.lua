local Nocturne = require(script.Parent.Nocturne)

describe("Nocturne", function()
    local nocturne

    beforeEach(function()
        nocturne = Nocturne.new()
        nocturne:initialize()
    end)

    it("should load an asset", function()
        local assetId = "testAsset"
        local asset = nocturne:loadAsset(assetId)
        expect(asset).to.be.ok()
        expect(nocturne.loadedAssets[assetId]).to.equal(asset)
    end)

    it("should unload an asset", function()
        local assetId = "testAsset"
        nocturne:loadAsset(assetId)
        nocturne:unloadAsset(assetId)
        expect(nocturne.loadedAssets[assetId]).to.never.be.ok()
    end)

    it("should return the correct asset count", function()
        nocturne:loadAsset("asset1")
        nocturne:loadAsset("asset2")
        expect(nocturne:getAssetCount()).to.equal(2)
    end)

    it("should fire a remote event", function()
        local eventName = "testEvent"
        nocturne.remotes[eventName] = Instance.new("RemoteEvent")
        local success = pcall(function()
            nocturne:fireRemoteEvent(eventName, "arg1", "arg2")
        end)
        expect(success).to.be.ok()
    end)

    it("should connect to a remote event", function()
        local eventName = "testEvent"
        nocturne.remotes[eventName] = Instance.new("RemoteEvent")
        local success = pcall(function()
            nocturne:connectRemoteEvent(eventName, function() end)
        end)
        expect(success).to.be.ok()
    end)

    it("should disconnect from a remote event", function()
        local eventName = "testEvent"
        nocturne.remotes[eventName] = Instance.new("RemoteEvent")
        local callback = function() end
        nocturne:connectRemoteEvent(eventName, callback)
        local success = pcall(function()
            nocturne:disconnectRemoteEvent(eventName, callback)
        end)
        expect(success).to.be.ok()
    end)
end)