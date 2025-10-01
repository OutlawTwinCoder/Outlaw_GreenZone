-- Commands
Config = Config or {}
local resourceName = GetCurrentResourceName()
local saveFile = 'data/admin_zone.json'
local savedAdminZone = nil
local jsonDecode = (json and json.decode) or (lib and lib.json and lib.json.decode)
local jsonEncode = (json and json.encode) or (lib and lib.json and lib.json.encode)

local function loadSavedAdminZone()
    local raw = LoadResourceFile(resourceName, saveFile)
    if not raw or raw == '' then return end

    if not jsonDecode then return end

    local ok, decoded = pcall(jsonDecode, raw)
    if not ok or type(decoded) ~= 'table' then return end
    if next(decoded) == nil then return end

    savedAdminZone = decoded
    if savedAdminZone.zoneSize then
        savedAdminZone.zoneSize = tonumber(savedAdminZone.zoneSize) or 50
    end
    if savedAdminZone.speedLimit then
        savedAdminZone.speedLimit = tonumber(savedAdminZone.speedLimit) or 0
    end
    if savedAdminZone.blipID then
        savedAdminZone.blipID = tonumber(savedAdminZone.blipID) or 487
    end
    if savedAdminZone.blipColor then
        savedAdminZone.blipColor = tonumber(savedAdminZone.blipColor) or 1
    end
    savedAdminZone.disarm = savedAdminZone.disarm == true
    savedAdminZone.invincible = savedAdminZone.invincible == true
end

local function persistAdminZone()
    if savedAdminZone then
        if not jsonEncode then return end

        local ok, encoded = pcall(jsonEncode, savedAdminZone)
        if ok and encoded then
            SaveResourceFile(resourceName, saveFile, encoded, -1)
        end
    else
        SaveResourceFile(resourceName, saveFile, '{}', -1)
    end
end

local function broadcastAdminZone(target)
    if not savedAdminZone then return end

    local coords
    local dataCoords = savedAdminZone.pedCoords
    if dataCoords and dataCoords.x and dataCoords.y and dataCoords.z then
        coords = vec3(0.0 + dataCoords.x, 0.0 + dataCoords.y, 0.0 + dataCoords.z)
    end

    TriggerClientEvent('outlawtwin_greenzones:createAdminZone', target or -1,
        coords,
        savedAdminZone.zoneName or 'Greenzone',
        savedAdminZone.textUI or 'Greenzone active',
        savedAdminZone.textUIColor or '#FF5A47',
        savedAdminZone.textUIPosition or 'top-center',
        savedAdminZone.zoneSize or 50,
        savedAdminZone.disarm == true,
        savedAdminZone.invincible == true,
        savedAdminZone.speedLimit or 0,
        savedAdminZone.blipID or 487,
        savedAdminZone.blipColor or 1
    )
end

local function clearSavedAdminZone()
    savedAdminZone = nil
    persistAdminZone()
end

local cmdOpen = Config.GreenzonesCommand or 'outlawzone'
local cmdClear = Config.GreenzonesClearCommand or 'outlawclear'

lib.addCommand(cmdOpen, {
    help = 'Open Outlaw Greenzone designer',
    restricted = 'group.admin'
}, function(source, args, raw)
    -- Supply defaults from Config if available
    local defaults = Config.Defaults or {}
    TriggerClientEvent('outlawtwin_greenzones:openDesigner', source, defaults)
end)

lib.addCommand(cmdClear, {
    help = 'Clear Outlaw Greenzone',
    restricted = 'group.admin'
}, function(source, args, raw)
    TriggerClientEvent('outlawtwin_greenzones:deleteAdminZone', -1)
    clearSavedAdminZone()
end)

-- Receive confirmed data from one admin and broadcast to everyone
RegisterNetEvent('outlawtwin_greenzones:serverConfirm', function(data)
    local src = source
    -- ped coords could be fetched server-side if needed, but the client creating the zone usually dictates center.
    -- Use the submitting client's position when available so every client shares the same zone origin.
    local pedCoords = nil
    local coords = data and data.pedCoords
    if coords and coords.x and coords.y and coords.z then
        pedCoords = vec3(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    end
    savedAdminZone = {
        pedCoords = pedCoords and { x = pedCoords.x + 0.0, y = pedCoords.y + 0.0, z = pedCoords.z + 0.0 } or nil,
        zoneName = data and data.zoneName or 'Greenzone',
        textUI = data and data.textUI or 'Greenzone active',
        textUIColor = data and data.textUIColor or '#FF5A47',
        textUIPosition = data and data.textUIPosition or 'top-center',
        zoneSize = tonumber(data and data.zoneSize) or 50,
        disarm = data and (data.disarm and true or false) or false,
        invincible = data and (data.invincible and true or false) or false,
        speedLimit = tonumber(data and data.speedLimit) or 0,
        blipID = tonumber(data and data.blipID) or 487,
        blipColor = tonumber(data and data.blipColor) or 1
    }

    persistAdminZone()
    broadcastAdminZone(-1)
end)

RegisterNetEvent('outlawtwin_greenzones:requestAdminZone', function()
    local src = source
    if src and src > 0 then
        broadcastAdminZone(src)
    end
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= resourceName then return end
    loadSavedAdminZone()
    if savedAdminZone then
        CreateThread(function()
            Wait(500)
            broadcastAdminZone(-1)
        end)
    end
end)
