ForageSiloExtension = {}
ForageSiloExtension.feedFillTypeNames = {"GRASS_WINDROW", "DRYGRASS_WINDROW", "STRAW", "CHAFF", "SILAGE", "FORAGE", "PIGFOOD", "TMR", "MINERAL_FEED", "WHEAT", "BARLEY", "OAT", "SORGHUM", "MAIZE", "CANOLA", "SOYBEAN", "SUNFLOWER", "POTATO", "SUGARBEET", "SUGARBEET_CUT", "CARROT", "PARSNIP", "BEETROOT", "PEA", "GREENBEAN", "SPINACH", "MOLASSES"}
ForageSiloExtension.baseCropNames = {"WHEAT", "BARLEY", "OAT", "CANOLA", "SORGHUM", "SOYBEAN", "SUNFLOWER", "MAIZE"}
ForageSiloExtension.feedFillTypeIndexes = nil
ForageSiloExtension.baseCropIndexes = nil
ForageSiloExtension.allFillTypeIndexes = nil
ForageSiloExtension.settings = {
    feedFillTypes = true,
    allFillTypes = false
}
ForageSiloExtension.pendingSettings = {
    feedFillTypes = true,
    allFillTypes = false
}
ForageSiloExtension.settingKeys = {
    feedFillTypes = "fseFeedFillTypes",
    allFillTypes = "fseAllFillTypes"
}
ForageSiloExtension.systemFillTypeNames = {
    UNKNOWN = true,
    AIR = true,
    ELECTRICCHARGE = true,
    METHANE = true
}

function ForageSiloExtension:isValidFillTypeIndex(fillTypeIndex)
    return type(fillTypeIndex) == "number" and fillTypeIndex > 0 and fillTypeIndex < 256 and math.floor(fillTypeIndex) == fillTypeIndex
end

function ForageSiloExtension:addIndexToSet(target, fillTypeIndex)
    if target ~= nil and self:isValidFillTypeIndex(fillTypeIndex) then
        target[fillTypeIndex] = true
    end
end

function ForageSiloExtension:collectFillTypeIndexes(source, targetSet)
    targetSet = targetSet or {}
    if source ~= nil then
        for key, value in pairs(source) do
            if self:isValidFillTypeIndex(key) and value == true then
                targetSet[key] = true
            end
            if self:isValidFillTypeIndex(value) then
                targetSet[value] = true
            end
        end
    end
    return targetSet
end

function ForageSiloExtension:getSortedIndexes(fillTypeSet)
    local sorted = {}
    if fillTypeSet ~= nil then
        for fillTypeIndex, value in pairs(fillTypeSet) do
            if value == true and self:isValidFillTypeIndex(fillTypeIndex) then
                table.insert(sorted, fillTypeIndex)
            elseif self:isValidFillTypeIndex(value) then
                table.insert(sorted, value)
            end
        end
    end
    table.sort(sorted, function(a, b)
        if type(a) ~= "number" then
            return false
        end
        if type(b) ~= "number" then
            return true
        end
        return a < b
    end)
    local cleaned = {}
    local seen = {}
    for _, fillTypeIndex in ipairs(sorted) do
        if self:isValidFillTypeIndex(fillTypeIndex) and seen[fillTypeIndex] ~= true then
            seen[fillTypeIndex] = true
            table.insert(cleaned, fillTypeIndex)
        end
    end
    return cleaned
end

function ForageSiloExtension:assignFillTypeTable(target, fillTypeSet, arrayOnly)
    if target == nil then
        return
    end
    for key in pairs(target) do
        target[key] = nil
    end
    for _, fillTypeIndex in ipairs(self:getSortedIndexes(fillTypeSet)) do
        if arrayOnly == true then
            table.insert(target, fillTypeIndex)
        else
            target[fillTypeIndex] = true
            table.insert(target, fillTypeIndex)
        end
    end
end

function ForageSiloExtension:getSettingsFilename()
    if g_currentMission ~= nil and g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.savegameDirectory ~= nil then
        return g_currentMission.missionInfo.savegameDirectory .. "/FS25_ForageSiloExtension.xml"
    end
    return nil
end

function ForageSiloExtension:loadSettings()
    self.settings.feedFillTypes = true
    self.settings.allFillTypes = false
    self.pendingSettings.feedFillTypes = true
    self.pendingSettings.allFillTypes = false
    local filename = self:getSettingsFilename()
    if filename ~= nil and fileExists(filename) then
        local xmlFile = loadXMLFile("ForageSiloExtensionSettings", filename)
        if xmlFile ~= nil and xmlFile ~= 0 then
            local version = getXMLInt(xmlFile, "forageSiloExtension#version")
            if version == 7 then
                local feedFillTypes = getXMLBool(xmlFile, "forageSiloExtension.settings.fseFeedFillTypes") == true
                local allFillTypes = getXMLBool(xmlFile, "forageSiloExtension.settings.fseAllFillTypes") == true
                if allFillTypes then
                    feedFillTypes = true
                end
                self.settings.feedFillTypes = feedFillTypes
                self.settings.allFillTypes = allFillTypes
                self.pendingSettings.feedFillTypes = feedFillTypes
                self.pendingSettings.allFillTypes = allFillTypes
            end
            delete(xmlFile)
        end
    end
end

function ForageSiloExtension:saveSettings()
    local filename = self:getSettingsFilename()
    if filename == nil then
        return
    end
    local xmlFile = createXMLFile("ForageSiloExtensionSettings", filename, "forageSiloExtension")
    if xmlFile ~= nil and xmlFile ~= 0 then
        setXMLInt(xmlFile, "forageSiloExtension#version", 7)
        setXMLBool(xmlFile, "forageSiloExtension.settings.fseFeedFillTypes", self.pendingSettings.feedFillTypes == true)
        setXMLBool(xmlFile, "forageSiloExtension.settings.fseAllFillTypes", self.pendingSettings.allFillTypes == true)
        saveXMLFile(xmlFile)
        delete(xmlFile)
    end
end

function ForageSiloExtension:getSetting(name)
    return self.settings[name] == true
end

function ForageSiloExtension:getPendingSetting(name)
    return self.pendingSettings[name] == true
end

function ForageSiloExtension:setPendingSetting(name, value)
    local isActive = value == true or value == 2
    if name == "feedFillTypes" then
        self.pendingSettings.feedFillTypes = isActive
        if not isActive then
            self.pendingSettings.allFillTypes = false
        end
    elseif name == "allFillTypes" then
        self.pendingSettings.allFillTypes = isActive
        if isActive then
            self.pendingSettings.feedFillTypes = true
        end
    else
        self.pendingSettings[name] = isActive
    end
end

function ForageSiloExtension:getIndexesFromNames(names)
    local resultSet = {}
    for _, fillTypeName in ipairs(names) do
        local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
        self:addIndexToSet(resultSet, fillTypeIndex)
    end
    return self:getSortedIndexes(resultSet)
end

function ForageSiloExtension:getFeedFillTypeIndexes()
    if self.feedFillTypeIndexes == nil then
        self.feedFillTypeIndexes = self:getIndexesFromNames(self.feedFillTypeNames)
    end
    return self.feedFillTypeIndexes
end

function ForageSiloExtension:getBaseCropIndexes()
    if self.baseCropIndexes == nil then
        self.baseCropIndexes = self:getIndexesFromNames(self.baseCropNames)
    end
    return self.baseCropIndexes
end

function ForageSiloExtension:getAllFillTypeIndexes()
    if self.allFillTypeIndexes == nil then
        local resultSet = {}
        if g_fillTypeManager ~= nil and g_fillTypeManager.fillTypes ~= nil then
            for _, fillType in pairs(g_fillTypeManager.fillTypes) do
                if fillType ~= nil and self:isValidFillTypeIndex(fillType.index) and fillType.name ~= nil and self.systemFillTypeNames[fillType.name] ~= true then
                    resultSet[fillType.index] = true
                end
            end
        end
        self.allFillTypeIndexes = self:getSortedIndexes(resultSet)
    end
    return self.allFillTypeIndexes
end


function ForageSiloExtension:prepareSavedStorageFillTypes(storage, xmlFile, key)
    if storage == nil or xmlFile == nil or key == nil then
        return
    end
    self:rememberStorageBaseline(storage)
    local i = 0
    while true do
        local nodeKey = string.format(key .. ".node(%d)", i)
        if not xmlFile:hasProperty(nodeKey) then
            break
        end
        local fillTypeName = xmlFile:getValue(nodeKey .. "#fillType")
        local fillTypeIndex = fillTypeName ~= nil and g_fillTypeManager:getFillTypeIndexByName(fillTypeName) or nil
        if fillTypeIndex ~= nil then
            storage.fillTypes = storage.fillTypes or {}
            storage.fillLevels = storage.fillLevels or {}
            storage.fillLevelsLastSynced = storage.fillLevelsLastSynced or {}
            storage.fillLevelsLastPublished = storage.fillLevelsLastPublished or {}
            self:addFillTypeToTable(storage.fillTypes, fillTypeIndex)
            if storage.fillLevels[fillTypeIndex] == nil then
                storage.fillLevels[fillTypeIndex] = 0
            end
            if storage.fillLevelsLastSynced[fillTypeIndex] == nil then
                storage.fillLevelsLastSynced[fillTypeIndex] = 0
            end
            if storage.fillLevelsLastPublished[fillTypeIndex] == nil then
                storage.fillLevelsLastPublished[fillTypeIndex] = 0
            end
            self:setFillTypeCapacity(storage, fillTypeIndex)
            self:addSortedFillType(storage, fillTypeIndex)
        end
        i = i + 1
    end
end

function ForageSiloExtension.onStorageLoadFromXMLFile(storage, xmlFile, key)
    ForageSiloExtension:prepareSavedStorageFillTypes(storage, xmlFile, key)
end

function ForageSiloExtension:addSortedFillType(storage, fillTypeIndex)
    if storage == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    local fillTypeSet = self:collectFillTypeIndexes(storage.sortedFillTypes)
    fillTypeSet[fillTypeIndex] = true
    storage.sortedFillTypes = self:getSortedIndexes(fillTypeSet)
end

function ForageSiloExtension:addFillTypeToTable(fillTypes, fillTypeIndex)
    if fillTypes == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    fillTypes[fillTypeIndex] = true
    for _, value in pairs(fillTypes) do
        if value == fillTypeIndex then
            return
        end
    end
    table.insert(fillTypes, fillTypeIndex)
end

function ForageSiloExtension:setFillTypeCapacity(storage, fillTypeIndex)
    if storage == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    local capacity = storage.capacity or storage.totalCapacity or storage.defaultCapacity
    if capacity == nil and storage.capacityPerFillType ~= nil then
        for _, value in pairs(storage.capacityPerFillType) do
            if type(value) == "number" and value > 0 then
                capacity = value
                break
            end
        end
    end
    if type(capacity) == "number" and capacity > 0 then
        if storage.capacityPerFillType ~= nil then
            storage.capacityPerFillType[fillTypeIndex] = storage.capacityPerFillType[fillTypeIndex] or capacity
        end
        if storage.capacities ~= nil then
            storage.capacities[fillTypeIndex] = storage.capacities[fillTypeIndex] or capacity
        end
    end
end

function ForageSiloExtension:preserveStorage(storage, fillTypeIndex)
    if storage == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    self:rememberStorageBaseline(storage)
    storage.fillTypes = storage.fillTypes or {}
    self:addFillTypeToTable(storage.fillTypes, fillTypeIndex)
    self:setFillTypeCapacity(storage, fillTypeIndex)
end

function ForageSiloExtension:preserveStation(station, fillTypeIndex)
    if station == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    self:rememberStationBaseline(station)
    self:addFillTypeToTable(station.fillTypes, fillTypeIndex)
    self:addFillTypeToTable(station.supportedFillTypes, fillTypeIndex)
    self:addFillTypeToTable(station.fillTypeIndexes, fillTypeIndex)
    self:addFillTypeToTable(station.supportedFillTypeIndexes, fillTypeIndex)
    if station.loadTriggers ~= nil then
        for _, trigger in ipairs(station.loadTriggers) do
            self:extendTrigger(trigger, fillTypeIndex)
        end
    end
end

function ForageSiloExtension:extendStorage(storage, fillTypeIndex)
    if storage == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    self:rememberStorageBaseline(storage)
    storage.fillTypes = storage.fillTypes or {}
    storage.fillLevels = storage.fillLevels or {}
    storage.fillLevelsLastSynced = storage.fillLevelsLastSynced or {}
    storage.fillLevelsLastPublished = storage.fillLevelsLastPublished or {}
    self:addFillTypeToTable(storage.fillTypes, fillTypeIndex)
    if storage.fillLevels[fillTypeIndex] == nil then
        storage.fillLevels[fillTypeIndex] = 0
    end
    if storage.fillLevelsLastSynced[fillTypeIndex] == nil then
        storage.fillLevelsLastSynced[fillTypeIndex] = 0
    end
    if storage.fillLevelsLastPublished[fillTypeIndex] == nil then
        storage.fillLevelsLastPublished[fillTypeIndex] = 0
    end
    self:setFillTypeCapacity(storage, fillTypeIndex)
    self:addSortedFillType(storage, fillTypeIndex)
end

function ForageSiloExtension:extendTrigger(trigger, fillTypeIndex)
    if trigger == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    self:rememberTriggerBaseline(trigger)
    self:addFillTypeToTable(trigger.fillTypes, fillTypeIndex)
    self:addFillTypeToTable(trigger.supportedFillTypes, fillTypeIndex)
    self:addFillTypeToTable(trigger.acceptedFillTypes, fillTypeIndex)
    self:addFillTypeToTable(trigger.fillTypeIndexes, fillTypeIndex)
    self:addFillTypeToTable(trigger.supportedFillTypeIndexes, fillTypeIndex)
end

function ForageSiloExtension:extendStation(station, fillTypeIndex)
    if station == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return
    end
    self:rememberStationBaseline(station)
    self:addFillTypeToTable(station.fillTypes, fillTypeIndex)
    self:addFillTypeToTable(station.supportedFillTypes, fillTypeIndex)
    self:addFillTypeToTable(station.acceptedFillTypes, fillTypeIndex)
    self:addFillTypeToTable(station.fillTypeIndexes, fillTypeIndex)
    self:addFillTypeToTable(station.supportedFillTypeIndexes, fillTypeIndex)
    if station.loadTriggers ~= nil then
        for _, trigger in ipairs(station.loadTriggers) do
            self:extendTrigger(trigger, fillTypeIndex)
        end
    end
    if station.unloadTriggers ~= nil then
        for _, trigger in ipairs(station.unloadTriggers) do
            self:extendTrigger(trigger, fillTypeIndex)
        end
    end
end

function ForageSiloExtension:hasFillType(fillTypes, fillTypeIndex)
    if fillTypes == nil or not self:isValidFillTypeIndex(fillTypeIndex) then
        return false
    end
    if fillTypes[fillTypeIndex] ~= nil then
        return true
    end
    for _, value in pairs(fillTypes) do
        if value == fillTypeIndex then
            return true
        end
    end
    return false
end

function ForageSiloExtension:getFillTypeSet(fillTypes)
    return self:collectFillTypeIndexes(fillTypes, {})
end

function ForageSiloExtension:rememberFillTypeTable(object, fieldName)
    if object == nil or fieldName == nil then
        return
    end
    object._fseOriginalFillTypeTables = object._fseOriginalFillTypeTables or {}
    if object._fseOriginalFillTypeTables[fieldName] == nil then
        object._fseOriginalFillTypeTables[fieldName] = self:getFillTypeSet(object[fieldName])
    end
end

function ForageSiloExtension:getRememberedFillTypeSet(object, fieldName)
    if object ~= nil and object._fseOriginalFillTypeTables ~= nil and object._fseOriginalFillTypeTables[fieldName] ~= nil then
        return object._fseOriginalFillTypeTables[fieldName]
    end
    if object ~= nil then
        return self:getFillTypeSet(object[fieldName])
    end
    return {}
end

function ForageSiloExtension:addSetToSet(target, source)
    if target == nil or source == nil then
        return
    end
    for fillTypeIndex, value in pairs(source) do
        if value == true and self:isValidFillTypeIndex(fillTypeIndex) then
            target[fillTypeIndex] = true
        elseif self:isValidFillTypeIndex(value) then
            target[value] = true
        end
    end
end

function ForageSiloExtension:addIndexesToSet(target, indexes)
    if target == nil or indexes == nil then
        return
    end
    for _, fillTypeIndex in ipairs(indexes) do
        self:addIndexToSet(target, fillTypeIndex)
    end
end

function ForageSiloExtension:getStoredFillTypeSet(storage)
    local result = {}
    if storage ~= nil and storage.fillLevels ~= nil then
        for fillTypeIndex, fillLevel in pairs(storage.fillLevels) do
            if self:isValidFillTypeIndex(fillTypeIndex) and type(fillLevel) == "number" and fillLevel > 0 then
                result[fillTypeIndex] = true
            end
        end
    end
    return result
end

function ForageSiloExtension:applyFillTypeSet(object, fieldName, fillTypeSet)
    if object == nil or fieldName == nil or object[fieldName] == nil or fillTypeSet == nil then
        return
    end
    self:assignFillTypeTable(object[fieldName], fillTypeSet, fieldName == "sortedFillTypes")
end

function ForageSiloExtension:rememberStorageBaseline(storage)
    if storage == nil then
        return
    end
    self:rememberFillTypeTable(storage, "fillTypes")
    self:rememberFillTypeTable(storage, "sortedFillTypes")
end

function ForageSiloExtension:rememberTriggerBaseline(trigger)
    if trigger == nil then
        return
    end
    self:rememberFillTypeTable(trigger, "fillTypes")
    self:rememberFillTypeTable(trigger, "supportedFillTypes")
    self:rememberFillTypeTable(trigger, "acceptedFillTypes")
    self:rememberFillTypeTable(trigger, "fillTypeIndexes")
    self:rememberFillTypeTable(trigger, "supportedFillTypeIndexes")
end

function ForageSiloExtension:rememberStationBaseline(station)
    if station == nil then
        return
    end
    self:rememberFillTypeTable(station, "fillTypes")
    self:rememberFillTypeTable(station, "supportedFillTypes")
    self:rememberFillTypeTable(station, "acceptedFillTypes")
    self:rememberFillTypeTable(station, "fillTypeIndexes")
    self:rememberFillTypeTable(station, "supportedFillTypeIndexes")
    if station.loadTriggers ~= nil then
        for _, trigger in ipairs(station.loadTriggers) do
            self:rememberTriggerBaseline(trigger)
        end
    end
    if station.unloadTriggers ~= nil then
        for _, trigger in ipairs(station.unloadTriggers) do
            self:rememberTriggerBaseline(trigger)
        end
    end
end

function ForageSiloExtension:rememberPlaceableBaseline(placeable, validStorages)
    if placeable == nil then
        return
    end
    self:rememberFillTypeTable(placeable, "fillTypes")
    if validStorages ~= nil then
        for _, storage in ipairs(validStorages) do
            self:rememberStorageBaseline(storage)
        end
    end
    local spec = placeable.spec_silo
    if spec ~= nil then
        self:rememberStationBaseline(spec.unloadingStation)
        self:rememberStationBaseline(spec.loadingStation)
    end
    self:rememberStationBaseline(placeable.spec_unloadingStation)
    self:rememberStationBaseline(placeable.spec_loadingStation)
end

function ForageSiloExtension:rebuildTriggerFillTypes(trigger, fillTypeSet)
    if trigger == nil then
        return
    end
    self:applyFillTypeSet(trigger, "fillTypes", fillTypeSet)
    self:applyFillTypeSet(trigger, "supportedFillTypes", fillTypeSet)
    self:applyFillTypeSet(trigger, "acceptedFillTypes", fillTypeSet)
    self:applyFillTypeSet(trigger, "fillTypeIndexes", fillTypeSet)
    self:applyFillTypeSet(trigger, "supportedFillTypeIndexes", fillTypeSet)
end

function ForageSiloExtension:rebuildStationFillTypes(station, fillTypeSet)
    if station == nil then
        return
    end
    self:applyFillTypeSet(station, "fillTypes", fillTypeSet)
    self:applyFillTypeSet(station, "supportedFillTypes", fillTypeSet)
    self:applyFillTypeSet(station, "acceptedFillTypes", fillTypeSet)
    self:applyFillTypeSet(station, "fillTypeIndexes", fillTypeSet)
    self:applyFillTypeSet(station, "supportedFillTypeIndexes", fillTypeSet)
    if station.loadTriggers ~= nil then
        for _, trigger in ipairs(station.loadTriggers) do
            self:rebuildTriggerFillTypes(trigger, fillTypeSet)
        end
    end
    if station.unloadTriggers ~= nil then
        for _, trigger in ipairs(station.unloadTriggers) do
            self:rebuildTriggerFillTypes(trigger, fillTypeSet)
        end
    end
end

function ForageSiloExtension:getCombinedAllowedFillTypes(placeable, validStorages)
    local allowed = self:getRememberedFillTypeSet(placeable, "fillTypes")
    self:addIndexesToSet(allowed, self:getActiveFillTypeIndexes())
    if validStorages ~= nil then
        for _, storage in ipairs(validStorages) do
            self:addSetToSet(allowed, self:getStoredFillTypeSet(storage))
        end
    end
    return allowed
end

function ForageSiloExtension:rebuildPlaceableFillTypes(placeable, validStorages)
    if placeable == nil then
        return
    end
    local allowed = self:getCombinedAllowedFillTypes(placeable, validStorages)
    self:applyFillTypeSet(placeable, "fillTypes", allowed)
    if validStorages ~= nil then
        for _, storage in ipairs(validStorages) do
            local storageAllowed = self:getRememberedFillTypeSet(storage, "fillTypes")
            self:addIndexesToSet(storageAllowed, self:getActiveFillTypeIndexes())
            self:addSetToSet(storageAllowed, self:getStoredFillTypeSet(storage))
            self:applyFillTypeSet(storage, "fillTypes", storageAllowed)
            self:applyFillTypeSet(storage, "sortedFillTypes", storageAllowed)
            for fillTypeIndex in pairs(storageAllowed) do
                self:setFillTypeCapacity(storage, fillTypeIndex)
            end
        end
    end
    local spec = placeable.spec_silo
    if spec ~= nil then
        self:rebuildStationFillTypes(spec.unloadingStation, allowed)
        self:rebuildStationFillTypes(spec.loadingStation, allowed)
    end
    self:rebuildStationFillTypes(placeable.spec_unloadingStation, allowed)
    self:rebuildStationFillTypes(placeable.spec_loadingStation, allowed)
end


function ForageSiloExtension:getStorageBaseCropCount(storage)
    if storage == nil or storage.fillTypes == nil then
        return 0
    end
    local count = 0
    for _, fillTypeIndex in ipairs(self:getBaseCropIndexes()) do
        if self:hasFillType(storage.fillTypes, fillTypeIndex) then
            count = count + 1
        end
    end
    return count
end

function ForageSiloExtension:getValidStorages(spec)
    local validStorages = {}
    if spec == nil or spec.storages == nil then
        return validStorages
    end
    for _, storage in ipairs(spec.storages) do
        if self:getStorageBaseCropCount(storage) >= 3 then
            table.insert(validStorages, storage)
        end
    end
    return validStorages
end

function ForageSiloExtension:isExcludedPlaceable(placeable)
    if placeable == nil then
        return true
    end
    local excludedSpecs = {
        "spec_buyingStation",
        "spec_palletBuyingStation",
        "spec_vehicleBuyingStation",
        "spec_sellingStation",
        "spec_productionPoint",
        "spec_objectStorage",
        "spec_husbandry",
        "spec_husbandryFood",
        "spec_husbandryWater",
        "spec_husbandryStraw",
        "spec_husbandryMilk",
        "spec_husbandryLiquidManure",
        "spec_manureHeap",
        "spec_bunkerSilo",
        "spec_multiBunkerSilo"
    }
    for _, specName in ipairs(excludedSpecs) do
        if placeable[specName] ~= nil then
            return true
        end
    end
    return false
end

function ForageSiloExtension:getActiveFillTypeIndexes()
    if self:getSetting("allFillTypes") then
        return self:getAllFillTypeIndexes()
    end
    if self:getSetting("feedFillTypes") then
        return self:getFeedFillTypeIndexes()
    end
    return {}
end


function ForageSiloExtension:preserveStoredFillTypes(placeable)
    if placeable == nil or placeable.spec_silo == nil or self:isExcludedPlaceable(placeable) then
        return
    end
    local spec = placeable.spec_silo
    local validStorages = self:getValidStorages(spec)
    if #validStorages == 0 then
        return
    end
    for _, storage in ipairs(validStorages) do
        if storage.fillLevels ~= nil then
            for fillTypeIndex, fillLevel in pairs(storage.fillLevels) do
                if type(fillTypeIndex) == "number" and type(fillLevel) == "number" and fillLevel > 0 then
                    self:addFillTypeToTable(placeable.fillTypes, fillTypeIndex)
                    self:extendStorage(storage, fillTypeIndex)
                    self:preserveStation(spec.loadingStation, fillTypeIndex)
                    self:preserveStation(placeable.spec_loadingStation, fillTypeIndex)
                end
            end
        end
    end
end

function ForageSiloExtension:extendPlaceable(placeable)
    if placeable == nil or placeable.spec_silo == nil or self:isExcludedPlaceable(placeable) then
        return
    end
    local spec = placeable.spec_silo
    local validStorages = self:getValidStorages(spec)
    if #validStorages == 0 then
        return
    end
    self:rememberPlaceableBaseline(placeable, validStorages)
    self:preserveStoredFillTypes(placeable)

    local activeFillTypeIndexes = self:getActiveFillTypeIndexes()
    if #activeFillTypeIndexes == 0 then
        self:rebuildPlaceableFillTypes(placeable, validStorages)
        return
    end

    for _, fillTypeIndex in ipairs(activeFillTypeIndexes) do
        self:addFillTypeToTable(placeable.fillTypes, fillTypeIndex)
        for _, storage in ipairs(validStorages) do
            self:extendStorage(storage, fillTypeIndex)
        end
        self:extendStation(spec.unloadingStation, fillTypeIndex)
        self:extendStation(spec.loadingStation, fillTypeIndex)
        self:extendStation(placeable.spec_unloadingStation, fillTypeIndex)
        self:extendStation(placeable.spec_loadingStation, fillTypeIndex)
    end
end

function ForageSiloExtension:extendAllLoadedPlaceables()
    if g_currentMission == nil or g_currentMission.placeableSystem == nil or g_currentMission.placeableSystem.placeables == nil then
        return
    end
    for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
        pcall(function()
            self:extendPlaceable(placeable)
        end)
    end
end

function ForageSiloExtension:updateFocusIds(element)
    if element == nil then
        return
    end
    element.focusId = FocusManager:serveAutoFocusId()
    if element.elements ~= nil then
        for _, child in pairs(element.elements) do
            self:updateFocusIds(child)
        end
    end
end

function ForageSiloExtension:registerFocusControls()
    if self.focusRegistered == true then
        return
    end
    self.focusRegistered = true
    FocusManager.setGui = Utils.appendedFunction(FocusManager.setGui, function(_, gui)
        if self.uiControls ~= nil then
            for _, control in ipairs(self.uiControls) do
                if control.focusId == nil or FocusManager.currentFocusData.idToElementMapping[control.focusId] == nil then
                    FocusManager:loadElementFromCustomValues(control, nil, nil, false, false)
                end
            end
        end
        local controller = g_gui ~= nil and g_gui.screenControllers ~= nil and g_gui.screenControllers[InGameMenu] or nil
        local settingsPage = controller ~= nil and controller.pageSettings or nil
        local layout = settingsPage ~= nil and self:getSettingsLayout(settingsPage) or nil
        if layout ~= nil then
            layout:invalidateLayout()
        end
    end)
end

function ForageSiloExtension:getSettingsLayout(settingsPage)
    return settingsPage.generalSettingsLayout or settingsPage.gameSettingsLayout
end

function ForageSiloExtension:createSettingsSection(settingsPage)
    local layout = self:getSettingsLayout(settingsPage)
    if settingsPage == nil or layout == nil or layout.elements == nil then
        return nil
    end
    for _, elem in ipairs(layout.elements) do
        if elem.name == "sectionHeader" then
            local section = elem:clone(layout)
            section:setText(g_i18n:getText("fse_setting_title"))
            section.focusId = FocusManager:serveAutoFocusId()
            if settingsPage.controlsList ~= nil then
                table.insert(settingsPage.controlsList, section)
            end
            return section
        end
    end
    return nil
end

function ForageSiloExtension:createSettingsControl(settingsPage, settingName, key, callbackName)
    local layout = self:getSettingsLayout(settingsPage)
    if settingsPage == nil or settingsPage.checkWoodHarvesterAutoCutBox == nil or layout == nil then
        return nil
    end
    local elementBox = settingsPage.checkWoodHarvesterAutoCutBox:clone(layout)
    self:updateFocusIds(elementBox)
    elementBox.id = key .. "Box"
    elementBox.name = key .. "Box"
    elementBox.settingName = settingName
    local option = elementBox.elements[1]
    local textElement = elementBox.elements[2]
    option.id = key
    option.target = self
    self.name = settingsPage.name
    option:setDisabled(false)
    option:setCallback("onClickCallback", callbackName)
    if textElement ~= nil then
        textElement:setText(g_i18n:getText(key .. "_short"))
    end
    if option.elements ~= nil and option.elements[1] ~= nil then
        option.elements[1]:setText(g_i18n:getText(key .. "_long"))
    end
    elementBox.option = option
    if settingsPage.controlsList ~= nil then
        table.insert(settingsPage.controlsList, elementBox)
    end
    table.insert(self.uiControls, elementBox)
    return elementBox
end

function ForageSiloExtension:setControlState(control, value)
    if control ~= nil and control.option ~= nil and control.option.setState ~= nil and BinaryOptionElement ~= nil then
        control.option:setState(value and BinaryOptionElement.STATE_RIGHT or BinaryOptionElement.STATE_LEFT)
    end
end

function ForageSiloExtension:updateSettingsControls()
    if self.uiControls == nil then
        return
    end
    for _, control in ipairs(self.uiControls) do
        if control.settingName ~= nil then
            self:setControlState(control, self:getPendingSetting(control.settingName))
        end
    end
end

function ForageSiloExtension:getBoolValue(state)
    return state == 2
end

function ForageSiloExtension:applyPendingSettings()
    local oldFeedFillTypes = self.settings.feedFillTypes == true
    local oldAllFillTypes = self.settings.allFillTypes == true
    local newFeedFillTypes = self.pendingSettings.feedFillTypes == true
    local newAllFillTypes = self.pendingSettings.allFillTypes == true

    self.settings.feedFillTypes = newFeedFillTypes
    self.settings.allFillTypes = newAllFillTypes
    self:saveSettings()

    local enablesAdditionalFillTypes = (newAllFillTypes and not oldAllFillTypes) or (newFeedFillTypes and not oldFeedFillTypes)
    if enablesAdditionalFillTypes then
        return
    end

    self:extendAllLoadedPlaceables()
end

function ForageSiloExtension:onFseFeedFillTypesChanged(state)
    self:setPendingSetting("feedFillTypes", self:getBoolValue(state))
    self:applyPendingSettings()
    self:updateSettingsControls()
end

function ForageSiloExtension:onFseAllFillTypesChanged(state)
    self:setPendingSetting("allFillTypes", self:getBoolValue(state))
    self:applyPendingSettings()
    self:updateSettingsControls()
end

function ForageSiloExtension:injectSettingsUi()
    if g_dedicatedServer or self.uiInitialized == true then
        return
    end
    local controller = g_gui ~= nil and g_gui.screenControllers ~= nil and g_gui.screenControllers[InGameMenu] or nil
    local settingsPage = controller ~= nil and controller.pageSettings or nil
    local layout = settingsPage ~= nil and self:getSettingsLayout(settingsPage) or nil
    if settingsPage == nil or layout == nil then
        return
    end
    self.uiInitialized = true
    self.uiControls = {}
    self:createSettingsSection(settingsPage)
    self:createSettingsControl(settingsPage, "feedFillTypes", "fseFeedFillTypes", "onFseFeedFillTypesChanged")
    self:createSettingsControl(settingsPage, "allFillTypes", "fseAllFillTypes", "onFseAllFillTypesChanged")
    self:updateSettingsControls()
    self:registerFocusControls()
    layout:invalidateLayout()
end

function ForageSiloExtension.onSettingsFrameOpen()
    ForageSiloExtension:injectSettingsUi()
    ForageSiloExtension:updateSettingsControls()
end

function ForageSiloExtension.onSiloLoad(placeable, savegame)
    ForageSiloExtension:extendPlaceable(placeable)
end

function ForageSiloExtension.onSiloFinalizePlacement(placeable)
    ForageSiloExtension:extendPlaceable(placeable)
end

function ForageSiloExtension.onSiloLoadFromXMLFile(placeable, xmlFile, key)
    ForageSiloExtension:extendPlaceable(placeable)
end


function ForageSiloExtension.onSiloLoadFromXMLFileFinished(placeable, xmlFile, key)
    ForageSiloExtension:preserveStoredFillTypes(placeable)
    ForageSiloExtension:extendPlaceable(placeable)
end

function ForageSiloExtension.onMapLoaded()
    ForageSiloExtension:loadSettings()
    ForageSiloExtension:injectSettingsUi()
    ForageSiloExtension:extendAllLoadedPlaceables()
end

function ForageSiloExtension.onSaveGame()
    ForageSiloExtension:saveSettings()
end

function ForageSiloExtension.install()
    if InGameMenuSettingsFrame ~= nil then
        InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, ForageSiloExtension.onSettingsFrameOpen)
    end
    if PlaceableSilo ~= nil then
        PlaceableSilo.onLoad = Utils.appendedFunction(PlaceableSilo.onLoad, ForageSiloExtension.onSiloLoad)
        PlaceableSilo.onFinalizePlacement = Utils.appendedFunction(PlaceableSilo.onFinalizePlacement, ForageSiloExtension.onSiloFinalizePlacement)
        PlaceableSilo.loadFromXMLFile = Utils.prependedFunction(PlaceableSilo.loadFromXMLFile, ForageSiloExtension.onSiloLoadFromXMLFile)
        PlaceableSilo.loadFromXMLFile = Utils.appendedFunction(PlaceableSilo.loadFromXMLFile, ForageSiloExtension.onSiloLoadFromXMLFileFinished)
    end
    if BaseMission ~= nil then
        BaseMission.loadMapFinished = Utils.appendedFunction(BaseMission.loadMapFinished, ForageSiloExtension.onMapLoaded)
    end
    if ItemSystem ~= nil then
        ItemSystem.save = Utils.prependedFunction(ItemSystem.save, ForageSiloExtension.onSaveGame)
    end
    if Storage ~= nil then
        Storage.loadFromXMLFile = Utils.prependedFunction(Storage.loadFromXMLFile, ForageSiloExtension.onStorageLoadFromXMLFile)
    end
end

ForageSiloExtension.install()
