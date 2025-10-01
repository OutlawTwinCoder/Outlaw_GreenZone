local resourceName = GetCurrentResourceName()

-- Ensure closed on start
CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)

AddEventHandler('onResourceStop', function(res)
    if res == resourceName then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        if lib and lib.hideTextUI then lib.hideTextUI() end
    end
end)

-- Server asks to open the designer
RegisterNetEvent('outlawtwin_greenzones:openDesigner', function(payload)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload or {} })
end)

-- Receive "create zone" broadcast (demo notification for now)
RegisterNetEvent('outlawtwin_greenzones:createAdminZone', function(pedCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
    if lib and lib.notify then
        lib.notify({ title = zoneName or 'Greenzone', description = ('Radius %s, speed %s'):format(zoneSize or '?', speedLimit or 0), type = 'inform' })
    end
end)

RegisterNetEvent('outlawtwin_greenzones:deleteAdminZone', function()
    if lib and lib.notify then
        lib.notify({ title = 'Greenzone', description = 'Zone supprimée', type = 'inform' })
    end
end)

-- NUI callbacks
RegisterNUICallback('cancel', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb(1)
end)

RegisterNUICallback('confirm', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    -- Send to server
    TriggerServerEvent('outlawtwin_greenzones:serverConfirm', data)
    cb(1)
end)
