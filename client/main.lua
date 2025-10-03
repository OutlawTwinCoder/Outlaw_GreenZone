local AdminZones = {}
local removalOpen = false
local resourceName = GetCurrentResourceName()

local function getPlayerId()
    return (cache and cache.playerId) or PlayerId()
end

local function getPed()
    return (cache and cache.ped) or PlayerPedId()
end

local function ensureTableCoords(value)
    if type(value) == 'vector3' then
        return { x = value.x, y = value.y, z = value.z }
    elseif type(value) == 'table' then
        return { x = value.x or 0.0, y = value.y or 0.0, z = value.z or 0.0 }
    end
    return { x = 0.0, y = 0.0, z = 0.0 }
end

local function toVec3(data)
    if type(data) == 'vector3' then
        return data
    elseif type(data) == 'table' then
        return vec3(tonumber(data.x) or 0.0, tonumber(data.y) or 0.0, tonumber(data.z) or 0.0)
    end
    return vec3(0.0, 0.0, 0.0)
end

local function applyBlipVisuals(blip, colour, alpha)
    if not blip or blip == 0 then return end

    local hudColour = tonumber(colour) or 1
    SetBlipColour(blip, hudColour)

    local r, g, b = GetHudColour(hudColour)
    if r then
        SetBlipSecondaryColour(blip, r, g, b)
    end

    if alpha then
        SetBlipAlpha(blip, alpha)
    end
end

local function notify(kind, payload)
    if not Config.EnableNotifications or not lib or not lib.notify then return end

    local entering = kind == 'enter'

    local message = {
        title = Notifications.greenzoneTitle,
        icon = Notifications.greenzoneIcon,
        position = Notifications.position,
        duration = 6000,
        type = entering and 'success' or 'error',
        description = entering and Notifications.greenzoneEnter or Notifications.greenzoneExit,
        style = {
            backgroundColor = entering and '#ff5a47' or '#72E68F',
            color = '#2C2C2C',
            ['.description'] = {
                color = '#2C2C2C'
            }
        },
        iconColor = '#2C2C2C'
    }

    if payload then
        for key, value in pairs(payload) do
            message[key] = value
        end
    end

    lib.notify(message)
end

local function fadeEntities(alpha)
    local myPlayerId = getPlayerId()
    local ped = getPed()

    for _, player in pairs(GetActivePlayers()) do
        if player ~= myPlayerId then
            local otherPed = GetPlayerPed(player)
            if otherPed and otherPed ~= 0 then
                SetEntityAlpha(otherPed, alpha, false)
                local otherVeh = GetVehiclePedIsIn(otherPed, false)
                if otherVeh and otherVeh ~= 0 then
                    SetEntityAlpha(otherVeh, alpha, false)
                end
            end
        end
    end

    if ped and ped ~= 0 then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 then
            SetEntityAlpha(veh, alpha, false)
        end
    end
end

local function applyNoCollision()
    local ped = getPed()
    local myPlayerId = getPlayerId()
    local myVeh = GetVehiclePedIsIn(ped, false)

    for _, player in pairs(GetActivePlayers()) do
        if player ~= myPlayerId then
            local otherPed = GetPlayerPed(player)
            if otherPed and otherPed ~= 0 then
                SetEntityNoCollisionEntity(ped, otherPed, true)
                SetEntityNoCollisionEntity(otherPed, ped, true)

                local otherVeh = GetVehiclePedIsIn(otherPed, false)
                if otherVeh and otherVeh ~= 0 then
                    SetEntityNoCollisionEntity(ped, otherVeh, true)
                    SetEntityNoCollisionEntity(otherVeh, ped, true)

                    if myVeh and myVeh ~= 0 then
                        SetEntityNoCollisionEntity(myVeh, otherVeh, true)
                        SetEntityNoCollisionEntity(otherVeh, myVeh, true)
                    end
                end
            end
        end
    end
end

local function createPersistentZones()
    for _, zoneCfg in pairs(Config.GreenZones or {}) do
        local point = lib.points.new(zoneCfg.coords, zoneCfg.radius)

        function point:onEnter()
            if zoneCfg.disablePlayerVehicleCollision then
                fadeEntities(153)
            end

            if zoneCfg.removeWeapons then
                local currentWeapon = GetSelectedPedWeapon(getPed())
                if currentWeapon and currentWeapon ~= `WEAPON_UNARMED` then
                    RemoveWeaponFromPed(getPed(), currentWeapon)
                end
            end

            if zoneCfg.disableFiring then
                SetPlayerCanDoDriveBy(getPlayerId(), false)
            end

            if zoneCfg.setInvincible then
                SetEntityInvincible(getPed(), true)
            end

            if zoneCfg.enableSpeedLimits then
                local veh = GetVehiclePedIsIn(getPed(), false)
                if veh and veh ~= 0 then
                    SetVehicleMaxSpeed(veh, (zoneCfg.setSpeedLimit or 0) * 0.44)
                end
            end

            if zoneCfg.displayTextUI then
                lib.showTextUI(zoneCfg.textToDisplay, {
                    position = zoneCfg.displayTextPosition,
                    icon = zoneCfg.displayTextIcon,
                    style = {
                        borderRadius = 4,
                        backgroundColor = zoneCfg.backgroundColorTextUI,
                        color = zoneCfg.textColor
                    }
                })
            end

            notify('enter')
        end

        function point:onExit()
            if zoneCfg.disablePlayerVehicleCollision then
                fadeEntities(255)
            end

            if zoneCfg.disableFiring then
                SetPlayerCanDoDriveBy(getPlayerId(), true)
            end

            if zoneCfg.setInvincible then
                SetEntityInvincible(getPed(), false)
            end

            if zoneCfg.enableSpeedLimits then
                local veh = GetVehiclePedIsIn(getPed(), false)
                if veh and veh ~= 0 then
                    SetVehicleMaxSpeed(veh, 0.0)
                end
            end

            if zoneCfg.displayTextUI then
                lib.hideTextUI()
            end

            notify('exit')
        end

        function point:nearby()
            if zoneCfg.disablePlayerVehicleCollision then
                fadeEntities(153)
                applyNoCollision()
            end

            if zoneCfg.disableFiring then
                DisablePlayerFiring(getPed(), true)
            end

            if zoneCfg.enableSpeedLimits then
                local veh = GetVehiclePedIsIn(getPed(), false)
                if veh and veh ~= 0 then
                    SetVehicleMaxSpeed(veh, (zoneCfg.setSpeedLimit or 0) * 0.44)
                end
            end
        end

        if zoneCfg.blip then
            if zoneCfg.blipType == 'radius' then
                local blip = AddBlipForRadius(zoneCfg.coords.x, zoneCfg.coords.y, zoneCfg.coords.z, zoneCfg.radius)
                applyBlipVisuals(blip, zoneCfg.blipColor, zoneCfg.blipAlpha)
                SetBlipDisplay(blip, 4)
                SetBlipHighDetail(blip, true)

                if zoneCfg.enableSprite then
                    local blip2 = AddBlipForCoord(zoneCfg.coords.x, zoneCfg.coords.y, zoneCfg.coords.z)
                    SetBlipSprite(blip2, zoneCfg.blipSprite)
                    applyBlipVisuals(blip2, zoneCfg.blipColor)
                    SetBlipScale(blip2, zoneCfg.blipScale)
                    SetBlipAsShortRange(blip2, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString(zoneCfg.blipName)
                    EndTextCommandSetBlipName(blip2)
                end
            else
                local blip = AddBlipForCoord(zoneCfg.coords.x, zoneCfg.coords.y, zoneCfg.coords.z)
                SetBlipSprite(blip, zoneCfg.blipSprite)
                applyBlipVisuals(blip, zoneCfg.blipColor)
                SetBlipScale(blip, zoneCfg.blipScale)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(zoneCfg.blipName)
                EndTextCommandSetBlipName(blip)
            end
        end
    end
end

local function removeAdminZone(id)
    local entry = AdminZones[id]
    if not entry then return false end

    if entry.zone then
        entry.zone:remove()
    end

    if entry.invincible then
        SetEntityInvincible(getPed(), false)
    end

    if entry.vehicle and entry.vehicle ~= 0 then
        SetVehicleMaxSpeed(entry.vehicle, 0.0)
    end

    if entry.radiusBlip then
        RemoveBlip(entry.radiusBlip)
    end

    if entry.spriteBlip then
        RemoveBlip(entry.spriteBlip)
    end

    if entry.textVisible then
        lib.hideTextUI()
    end

    AdminZones[id] = nil

    refreshRemovalUi()
    return true
end

local function createAdminBlips(entry)
    local roundedRadius = lib.math.round(entry.radius, 1)
    entry.radiusBlip = AddBlipForRadius(entry.coords.x, entry.coords.y, entry.coords.z, roundedRadius)
    applyBlipVisuals(entry.radiusBlip, entry.blipColor, 100)
    SetBlipDisplay(entry.radiusBlip, 4)
    SetBlipHighDetail(entry.radiusBlip, true)

    entry.spriteBlip = AddBlipForCoord(entry.coords.x, entry.coords.y, entry.coords.z)
    SetBlipSprite(entry.spriteBlip, entry.blipID)
    SetBlipDisplay(entry.spriteBlip, 4)
    applyBlipVisuals(entry.spriteBlip, entry.blipColor)
    SetBlipScale(entry.spriteBlip, 1.0)
    SetBlipAsShortRange(entry.spriteBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(entry.name)
    EndTextCommandSetBlipName(entry.spriteBlip)
end

local function buildRemovalUiData()
    local payload = {
        title = locale('admin.title'),
        removeLabel = locale('admin.remove'),
        removeAllLabel = locale('admin.removeAll'),
        empty = locale('admin.none')
    }

    payload.confirmLabel = payload.removeAllLabel

    local zones = {}
    for id, zone in pairs(AdminZones) do
        zones[#zones + 1] = {
            id = id,
            name = zone.name or locale('menu.blipNamePlaceholder'),
            subtitle = locale('admin.optionDescription', string.format('%.1f', zone.radius or 0.0))
        }
    end

    table.sort(zones, function(a, b)
        return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
    end)

    payload.zones = zones
    return payload
end

local function refreshRemovalUi()
    if not removalOpen then return end

    SendNUIMessage({
        action = 'updateRemoval',
        data = buildRemovalUiData()
    })
end

local function registerAdminZone(data)
    removeAdminZone(data.id)

    local entry = {
        id = data.id,
        name = data.zoneName or locale('menu.blipNamePlaceholder'),
        coords = toVec3(data.coords),
        radius = tonumber(data.zoneSize) or 50.0,
        textUI = data.textUI or 'Greenzone active',
        textUIColor = data.textUIColor or '#FF5A47',
        textUIPosition = data.textUIPosition or 'top-center',
        disarm = data.disarm or false,
        invincible = data.invincible or false,
        speedLimit = (tonumber(data.speedLimit) or 0) * 0.277778,
        blipID = tonumber(data.blipID) or 487,
        blipColor = tonumber(data.blipColor) or 1
    }

    entry.coords = vec3(entry.coords.x, entry.coords.y, entry.coords.z)

    createAdminBlips(entry)

    entry.zone = lib.points.new(entry.coords, entry.radius)

    function entry.zone:onEnter()
        entry.vehicle = GetVehiclePedIsIn(getPed(), false)
        lib.showTextUI(entry.textUI, {
            position = entry.textUIPosition,
            icon = 'shield-halved',
            style = {
                borderRadius = 4,
                backgroundColor = entry.textUIColor,
                color = 'black'
            }
        })
        entry.textVisible = true

        if entry.invincible then
            SetEntityInvincible(getPed(), true)
        end
    end

    function entry.zone:onExit()
        if entry.textVisible then
            lib.hideTextUI()
            entry.textVisible = false
        end

        if entry.invincible then
            SetEntityInvincible(getPed(), false)
        end

        if entry.vehicle and entry.vehicle ~= 0 then
            SetVehicleMaxSpeed(entry.vehicle, 0.0)
        end
    end

    function entry.zone:nearby()
        if entry.disarm then
            DisablePlayerFiring(getPed(), true)
        end

        if entry.speedLimit > 0 then
            entry.vehicle = GetVehiclePedIsIn(getPed(), false)
            if entry.vehicle and entry.vehicle ~= 0 then
                SetVehicleMaxSpeed(entry.vehicle, entry.speedLimit)
            end
        end
    end

    AdminZones[data.id] = entry

    refreshRemovalUi()
end

local function openRemovalMenu()
    removalOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openRemoval',
        data = buildRemovalUiData()
    })
end

CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    if lib and lib.callback then
        local existing = lib.callback.await('lation_greenzones:getAdminZones', false) or {}
        for _, zone in pairs(existing) do
            registerAdminZone(zone)
        end
    end

    createPersistentZones()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resourceName then return end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    removalOpen = false

    for id in pairs(AdminZones) do
        removeAdminZone(id)
    end

    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
end)

RegisterNetEvent('lation_greenzones:openDesigner', function(defaults)
    removalOpen = false
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = defaults or {},
        meta = {
            title = locale('menu.title')
        }
    })
end)

RegisterNetEvent('lation_greenzones:createAdminZone', function(data)
    if type(data) ~= 'table' then return end
    registerAdminZone(data)
end)

RegisterNetEvent('lation_greenzones:deleteAdminZone', function(id)
    if not id then
        for zoneId in pairs(AdminZones) do
            removeAdminZone(zoneId)
        end
        refreshRemovalUi()
        return
    end

    if not removeAdminZone(id) then
        refreshRemovalUi()
    end
end)

RegisterNetEvent('lation_greenzones:openRemovalMenu', function()
    openRemovalMenu()
end)

RegisterNUICallback('cancel', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    removalOpen = false
    cb(1)
end)

RegisterNUICallback('confirm', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    removalOpen = false

    local coords = GetEntityCoords(getPed())
    data.coords = ensureTableCoords(coords)
    TriggerServerEvent('lation_greenzones:serverConfirm', data)

    cb(1)
end)

RegisterNUICallback('remove', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    removalOpen = false

    if data and data.id then
        TriggerServerEvent('lation_greenzones:serverDelete', tonumber(data.id))
    end

    cb(1)
end)

RegisterNUICallback('removeAll', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    removalOpen = false

    TriggerServerEvent('lation_greenzones:serverDelete')

    cb(1)
end)
