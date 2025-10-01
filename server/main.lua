local locale = lib.locale()

lib.addCommand(Config.GreenzonesCommand, {
    help = locale('commands.setzone'),
    restricted = 'group.admin'
}, function(source)
    lib.callback('outlawtwin_greenzones:adminZone', source, cb)
end)

lib.addCommand(Config.GreenzonesClearCommand, {
    help = locale('commands.deletezone'),
    restricted = 'group.admin'
}, function(source)
    lib.callback('outlawtwin_greenzones:adminZoneClear', source, cb)
end)

lib.callback.register('outlawtwin_greenzones:data', function(source, zoneCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
    TriggerClientEvent('outlawtwin_greenzones:createAdminZone', -1, zoneCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
end)

lib.callback.register('outlawtwin_greenzones:deleteZone', function()
    TriggerClientEvent('outlawtwin_greenzones:deleteAdminZone', -1)
end)