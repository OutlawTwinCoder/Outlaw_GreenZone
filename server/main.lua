-- Commands
Config = Config or {}
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
end)

-- Receive confirmed data from one admin and broadcast to everyone
RegisterNetEvent('outlawtwin_greenzones:serverConfirm', function(data)
    local src = source
    -- ped coords could be fetched server-side if needed, but the client creating the zone usually dictates center.
    -- For now we pass nil (clients can choose center themselves if implemented client-side).
    local pedCoords = nil
    TriggerClientEvent('outlawtwin_greenzones:createAdminZone', -1,
        pedCoords,
        data and data.zoneName or 'Greenzone',
        data and data.textUI or 'Greenzone active',
        data and data.textUIColor or '#FF5A47',
        data and data.textUIPosition or 'top-center',
        data and data.zoneSize or 50,
        data and (data.disarm and true or false),
        data and (data.invincible and true or false),
        data and data.speedLimit or 0,
        data and data.blipID or 487,
        data and data.blipColor or 1
    )
end)
