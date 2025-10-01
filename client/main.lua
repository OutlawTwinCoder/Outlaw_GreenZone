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

local function getPed()
    return (cache and cache.ped) or PlayerPedId()
end

local function getPlayerId()
    return (cache and cache.playerId) or PlayerId()
end

local function getVehicle(ped)
    return GetVehiclePedIsIn(ped or getPed(), false)
end

local function setEntityAlphaForOthers(alpha)
    local myPed = getPed()
    local myVeh = getVehicle(myPed)
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= getPlayerId() then
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
    if myVeh ~= 0 then
        SetEntityAlpha(myVeh, alpha, false)
    end
end

local function enforceNoCollision()
    local myPed = getPed()
    local myVeh = getVehicle(myPed)
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= getPlayerId() then
            local otherPed = GetPlayerPed(player)
            if otherPed and otherPed ~= 0 then
                SetEntityNoCollisionEntity(myPed, otherPed, true)
                SetEntityNoCollisionEntity(otherPed, myPed, true)
                local otherVeh = GetVehiclePedIsIn(otherPed, false)
                if otherVeh and otherVeh ~= 0 then
                    if myVeh ~= 0 then
                        SetEntityNoCollisionEntity(myVeh, otherVeh, true)
                        SetEntityNoCollisionEntity(otherVeh, myVeh, true)
                    end
                    SetEntityNoCollisionEntity(myPed, otherVeh, true)
                    SetEntityNoCollisionEntity(otherVeh, myPed, true)
                end
            end
        end
    end
end

local function configureRadiusBlip(blip, color, alpha, shortRange)
    if not blip or blip == 0 then return end

    SetBlipColour(blip, color or 0)
    SetBlipAlpha(blip, alpha or 100)
    SetBlipDisplay(blip, 4)
    SetBlipHighDetail(blip, true)
    SetBlipAsShortRange(blip, shortRange == true)
end

local function createConfiguredBlip(cfg)
    if not cfg.blip then return end
    if cfg.blipType == 'radius' then
        local radius = tonumber(cfg.radius) or 0.0
        if radius > 0 then
            local radiusBlip = AddBlipForRadius(cfg.coords.x, cfg.coords.y, cfg.coords.z, radius)
            configureRadiusBlip(radiusBlip, cfg.blipColor, cfg.blipAlpha, cfg.radiusShortRange)
            if cfg.enableSprite then
                local spriteBlip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
                SetBlipSprite(spriteBlip, cfg.blipSprite or 1)
                SetBlipColour(spriteBlip, cfg.blipColor or 0)
                SetBlipScale(spriteBlip, cfg.blipScale or 1.0)
                SetBlipAsShortRange(spriteBlip, true)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentString(cfg.blipName or 'Greenzone')
                EndTextCommandSetBlipName(spriteBlip)
            end
        end
    else
        local spriteBlip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
        SetBlipSprite(spriteBlip, cfg.blipSprite or 1)
        SetBlipColour(spriteBlip, cfg.blipColor or 0)
        SetBlipScale(spriteBlip, cfg.blipScale or 1.0)
        SetBlipAsShortRange(spriteBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(cfg.blipName or 'Greenzone')
        EndTextCommandSetBlipName(spriteBlip)
    end
end

local persistentZones = {}

local function setupPersistentZones()
    if not Config or not Config.GreenZones then return end
    if not lib or not lib.points or not lib.points.new then return end

    for _, cfg in pairs(Config.GreenZones) do
        if cfg.coords and cfg.radius then
            local zone = lib.points.new(cfg.coords, cfg.radius)
            table.insert(persistentZones, zone)

            local speedLimit = 0.0
            if cfg.enableSpeedLimits and cfg.setSpeedLimit then
                speedLimit = (tonumber(cfg.setSpeedLimit) or 0) * 0.44
            end
            local lastVehicle = 0

            function zone:onEnter()
                local ped = getPed()
                if cfg.disablePlayerVehicleCollision then
                    setEntityAlphaForOthers(153)
                end
                if cfg.removeWeapons then
                    local currentWeapon = GetSelectedPedWeapon(ped)
                    if currentWeapon and currentWeapon ~= `WEAPON_UNARMED` then
                        RemoveWeaponFromPed(ped, currentWeapon)
                    end
                end
                if cfg.disableFiring then
                    SetPlayerCanDoDriveBy(getPlayerId(), false)
                end
                if cfg.setInvincible then
                    SetEntityInvincible(ped, true)
                end
                if speedLimit > 0 then
                    lastVehicle = getVehicle(ped)
                    if lastVehicle ~= 0 then
                        SetVehicleMaxSpeed(lastVehicle, speedLimit)
                    end
                end
                if cfg.displayTextUI and lib and lib.showTextUI then
                    lib.showTextUI(cfg.textToDisplay or 'Greenzone', {
                        position = cfg.displayTextPosition or 'top-center',
                        icon = cfg.displayTextIcon or 'shield-halved',
                        style = {
                            borderRadius = 4,
                            backgroundColor = cfg.backgroundColorTextUI or '#ff5a47',
                            color = cfg.textColor or '#000000'
                        }
                    })
                end
                sendGreenzoneNotify('enter')
            end

            function zone:onExit()
                if cfg.disablePlayerVehicleCollision then
                    setEntityAlphaForOthers(255)
                end
                if cfg.disableFiring then
                    SetPlayerCanDoDriveBy(getPlayerId(), true)
                end
                if cfg.setInvincible then
                    SetEntityInvincible(getPed(), false)
                end
                if speedLimit > 0 then
                    if lastVehicle ~= 0 then
                        SetVehicleMaxSpeed(lastVehicle, 0.0)
                    else
                        local ped = getPed()
                        local veh = getVehicle(ped)
                        if veh ~= 0 then
                            SetVehicleMaxSpeed(veh, 0.0)
                        end
                    end
                    lastVehicle = 0
                end
                if cfg.displayTextUI and lib and lib.hideTextUI then
                    lib.hideTextUI()
                end
                sendGreenzoneNotify('exit')
            end

            function zone:nearby()
                if cfg.disablePlayerVehicleCollision then
                    enforceNoCollision()
                end
                if cfg.disableFiring then
                    DisablePlayerFiring(getPed(), true)
                end
                if speedLimit > 0 then
                    local ped = getPed()
                    local veh = getVehicle(ped)
                    if veh ~= 0 then
                        lastVehicle = veh
                        SetVehicleMaxSpeed(veh, speedLimit)
                    end
                end
            end

            createConfiguredBlip(cfg)
        end
    end
end

local adminState = {
    point = nil,
    radiusBlip = nil,
    spriteBlip = nil,
    speed = 0.0,
    disarm = false,
    invincible = false,
    text = nil
}

local function clearAdminZone()
    if adminState.point then
        adminState.point:remove()
        adminState.point = nil
    end
    if adminState.radiusBlip then
        RemoveBlip(adminState.radiusBlip)
        adminState.radiusBlip = nil
    end
    if adminState.spriteBlip then
        RemoveBlip(adminState.spriteBlip)
        adminState.spriteBlip = nil
    end
    if lib and lib.hideTextUI then
        lib.hideTextUI()
    end
    local ped = getPed()
    local veh = getVehicle(ped)
    if veh ~= 0 then
        SetVehicleMaxSpeed(veh, 0.0)
    end
    SetEntityInvincible(ped, false)
    adminState.speed = 0.0
    adminState.disarm = false
    adminState.invincible = false
    adminState.text = nil
end

local function createAdminBlip(name, coords, radius, sprite, color)
    if adminState.radiusBlip then
        RemoveBlip(adminState.radiusBlip)
        adminState.radiusBlip = nil
    end
    if adminState.spriteBlip then
        RemoveBlip(adminState.spriteBlip)
        adminState.spriteBlip = nil
    end

    local blipRadius = tonumber(radius) or 0.0
    if blipRadius > 0 then
        adminState.radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, blipRadius)
        configureRadiusBlip(adminState.radiusBlip, color or 0, 175, false)
    end

    adminState.spriteBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(adminState.spriteBlip, sprite or 487)
    SetBlipDisplay(adminState.spriteBlip, 4)
    SetBlipColour(adminState.spriteBlip, color or 0)
    SetBlipScale(adminState.spriteBlip, 1.0)
    SetBlipAsShortRange(adminState.spriteBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name or 'Greenzone')
    EndTextCommandSetBlipName(adminState.spriteBlip)
end

local function toVector3(value)
    if not value then return nil end
    local valueType = type(value)
    if valueType == 'vector3' then
        return value
    elseif valueType == 'table' then
        local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
        if x and y and z then
            return vec3(x, y, z)
        end
    end
    return nil
end

CreateThread(function()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    setupPersistentZones()
    TriggerServerEvent('outlawtwin_greenzones:requestAdminZone')
end)

AddEventHandler('onResourceStop', function(res)
    if res == resourceName then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        clearAdminZone()
        if lib and lib.hideTextUI then lib.hideTextUI() end
        setEntityAlphaForOthers(255)
        for _, zone in ipairs(persistentZones) do
            zone:remove()
        end
    end
end)

RegisterNetEvent('outlawtwin_greenzones:openDesigner', function(payload)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload or {} })
end)

RegisterNetEvent('outlawtwin_greenzones:createAdminZone', function(pedCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
    clearAdminZone()

    local center = toVector3(pedCoords) or GetEntityCoords(getPed())
    local radius = tonumber(zoneSize) or 50.0

    createAdminBlip(zoneName, center, radius, blipID or 487, blipColor or 1)

    adminState.speed = (tonumber(speedLimit) or 0) * 0.44
    adminState.disarm = disarm and true or false
    adminState.invincible = invincible and true or false
    adminState.text = {
        content = textUI or 'Greenzone active',
        color = textUIColor or '#FF5A47',
        position = textUIPosition or 'top-center'
    }

    if lib and lib.points and lib.points.new then
        adminState.point = lib.points.new(center, radius)
        function adminState.point:onEnter()
            local ped = getPed()
            if lib and lib.showTextUI and adminState.text.content and adminState.text.content ~= '' then
                lib.showTextUI(adminState.text.content, {
                    position = adminState.text.position or 'top-center',
                    icon = 'shield-halved',
                    style = {
                        borderRadius = 4,
                        backgroundColor = adminState.text.color or '#FF5A47',
                        color = '#000000'
                    }
                })
            end
            if adminState.invincible then
                SetEntityInvincible(ped, true)
            end
        end

        function adminState.point:onExit()
            if lib and lib.hideTextUI then
                lib.hideTextUI()
            end
            local ped = getPed()
            if adminState.invincible then
                SetEntityInvincible(ped, false)
            end
            local veh = getVehicle(ped)
            if veh ~= 0 then
                SetVehicleMaxSpeed(veh, 0.0)
            end
        end

        function adminState.point:nearby()
            local ped = getPed()
            if adminState.disarm then
                DisablePlayerFiring(ped, true)
            end
            if adminState.speed > 0 then
                local veh = getVehicle(ped)
                if veh ~= 0 then
                    SetVehicleMaxSpeed(veh, adminState.speed)
                end
            end
        end
    end

    sendGreenzoneNotify('enter', {
        force = true,
        title = zoneName or (Notifications and Notifications.greenzoneTitle) or 'Greenzone',
        description = ('Radius %s, speed %s'):format(radius or '?', speedLimit or 0)
    })
end)

RegisterNetEvent('outlawtwin_greenzones:deleteAdminZone', function()
    clearAdminZone()
    sendGreenzoneNotify('exit', {
        force = true,
        description = (Notifications and Notifications.greenzoneExit) or 'Zone supprimée'
    })
end)

RegisterNetEvent('outlawtwin_greenzones:notifyEnter', function(overrides)
    sendGreenzoneNotify('enter', overrides)
end)

RegisterNetEvent('outlawtwin_greenzones:notifyExit', function(overrides)
    sendGreenzoneNotify('exit', overrides)
end)

RegisterNUICallback('cancel', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb(1)
end)

RegisterNUICallback('confirm', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    local ped = getPed()
    local coords = GetEntityCoords(ped)
    data = data or {}
    data.pedCoords = { x = coords.x, y = coords.y, z = coords.z }
    TriggerServerEvent('outlawtwin_greenzones:serverConfirm', data)
    cb(1)
end)
