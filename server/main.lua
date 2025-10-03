local adminZones = {}
local nextZoneId = 0

local function getNextZoneId()
    nextZoneId += 1
    return nextZoneId
end

local function sanitizeCoords(src, coords)
    if type(coords) == 'table' and coords.x and coords.y and coords.z then
        return {
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0
        }
    end

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local pedCoords = GetEntityCoords(ped)
        return { x = pedCoords.x, y = pedCoords.y, z = pedCoords.z }
    end

    return { x = 0.0, y = 0.0, z = 0.0 }
end

local function clamp(num, min, max)
    if num < min then return min end
    if num > max then return max end
    return num
end

lib.addCommand(Config.GreenzonesCommand, {
    help = locale('commands.setzone'),
    restricted = 'group.admin'
}, function(source)
    local defaults = Config.Defaults or {}
    TriggerClientEvent('lation_greenzones:openDesigner', source, defaults)
end)

lib.addCommand(Config.GreenzonesClearCommand, {
    help = locale('commands.deletezone'),
    restricted = 'group.admin'
}, function(source)
    TriggerClientEvent('lation_greenzones:openRemovalMenu', source)
end)

RegisterNetEvent('lation_greenzones:serverConfirm', function(data)
    local src = source
    if src <= 0 or type(data) ~= 'table' then return end

    local payload = {}
    payload.zoneName = (data.zoneName and data.zoneName ~= '') and data.zoneName or (Config.Defaults and Config.Defaults.zoneName) or 'Greenzone'
    payload.textUI = (data.textUI and data.textUI ~= '') and data.textUI or (Config.Defaults and Config.Defaults.textUI) or 'Greenzone active'
    payload.textUIColor = data.textUIColor or (Config.Defaults and Config.Defaults.textUIColor) or '#FF5A47'
    payload.textUIPosition = data.textUIPosition or (Config.Defaults and Config.Defaults.textUIPosition) or 'top-center'

    local radius = tonumber(data.zoneSize) or (Config.Defaults and tonumber(Config.Defaults.zoneSize)) or 50
    payload.zoneSize = clamp(radius, 5, 400)

    payload.disarm = data.disarm and true or false
    payload.invincible = data.invincible and true or false
    payload.speedLimit = clamp(tonumber(data.speedLimit) or 0, 0, 200)
    payload.blipID = clamp(tonumber(data.blipID) or 487, 1, 826)
    payload.blipColor = clamp(tonumber(data.blipColor) or 1, 1, 85)
    payload.coords = sanitizeCoords(src, data.coords)

    local zoneId = getNextZoneId()
    payload.id = zoneId

    adminZones[zoneId] = payload

    TriggerClientEvent('lation_greenzones:createAdminZone', -1, payload)
end)

RegisterNetEvent('lation_greenzones:serverDelete', function(id)
    local src = source
    if src <= 0 then return end

    if id and adminZones[id] then
        adminZones[id] = nil
        TriggerClientEvent('lation_greenzones:deleteAdminZone', -1, id)
        return
    end

    adminZones = {}
    TriggerClientEvent('lation_greenzones:deleteAdminZone', -1, nil)
end)

lib.callback.register('lation_greenzones:getAdminZones', function()
    return adminZones
end)
