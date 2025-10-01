local resourceName = GetCurrentResourceName()

local function sendGreenzoneNotify(kind, overrides)
    if not lib or not lib.notify then return end

    local force = overrides and overrides.force
    if not force and (not Config or not Config.EnableNotifications) then return end

    local base = Notifications or {}
    local payload = {
        title = base.greenzoneTitle or 'Greenzone',
        icon = base.greenzoneIcon,
        position = base.position,
        type = base.type or 'inform'
    }

    if kind == 'enter' then
        payload.description = base.greenzoneEnter
    elseif kind == 'exit' then
        payload.description = base.greenzoneExit
    end

    if overrides then
        for key, value in pairs(overrides) do
            if key ~= 'force' then
                payload[key] = value
            end
        end
    end

    if not payload.description then
        payload.description = ''
    end

    lib.notify(payload)
end

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
    sendGreenzoneNotify('enter', {
        force = true,
        title = zoneName or (Notifications and Notifications.greenzoneTitle) or 'Greenzone',
        description = ('Radius %s, speed %s'):format(zoneSize or '?', speedLimit or 0)
    })
end)

RegisterNetEvent('outlawtwin_greenzones:deleteAdminZone', function()
    sendGreenzoneNotify('exit', {
        force = true,
        description = 'Zone supprimée'
    })
end)

RegisterNetEvent('outlawtwin_greenzones:notifyEnter', function(overrides)
    sendGreenzoneNotify('enter', overrides)
end)

RegisterNetEvent('outlawtwin_greenzones:notifyExit', function(overrides)
    sendGreenzoneNotify('exit', overrides)
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
