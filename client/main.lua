local locale = lib.locale()

local greenZone = nil
local zone = lib.points.new(vec3(0, 0, 0), 0)
local pedCoords = nil
local radiusBlip = nil
local sprite = nil
local vehicle = nil
local speed = 0
local designerPromise = nil

local noop = function() end
local activeLocale = GetConvar('ox:locale', 'en')

local function sanitizeString(value, fallback)
    if type(value) ~= 'string' then
        return fallback
    end

    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then
        return fallback
    end

    return trimmed
end

local function designerLabels()
    return {
        title = locale('menu.title'),
        subtitle = locale('menu.subtitle'),
        actions = {
            confirm = locale('menu.confirm'),
            cancel = locale('menu.cancel')
        },
        fields = {
            blipName = {
                label = locale('menu.blipName'),
                description = locale('menu.blipNameDescription'),
                placeholder = locale('menu.blipNamePlaceholder')
            },
            banner = {
                label = locale('menu.displayText'),
                description = locale('menu.displayTextDescription'),
                placeholder = locale('menu.displayTextPlaceholder')
            },
            bannerColor = {
                label = locale('menu.displayTextColor'),
                description = locale('menu.displayTextColorDescription')
            },
            bannerPosition = {
                label = locale('menu.displayTextPosition'),
                description = locale('menu.displayTextPositionDescription')
            },
            radius = {
                label = locale('menu.size')
            },
            disableFiring = {
                label = locale('menu.disableFiring')
            },
            invincible = {
                label = locale('menu.invincible')
            },
            speedLimit = {
                label = locale('menu.speedLimit')
            },
            blipID = {
                label = locale('menu.blipID'),
                description = locale('menu.blipIDDescription')
            },
            blipColor = {
                label = locale('menu.blipColor'),
                description = locale('menu.blipColorDescription')
            }
        },
        positions = {
            { value = 'top-center', label = locale('menu.positionTopCenter') },
            { value = 'right-center', label = locale('menu.positionRightCenter') },
            { value = 'left-center', label = locale('menu.positionLeftCenter') }
        },
        helpers = {
            radiusSuffix = locale('menu.radiusSuffix'),
            speedUnit = locale('menu.speedUnit'),
            unlimited = locale('menu.speedUnlimited')
        }
    }
end

local function openDesigner(defaults)
    if designerPromise then
        return nil
    end

    designerPromise = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        labels = designerLabels(),
        defaults = defaults,
        lang = activeLocale
    })

    local result = Citizen.Await(designerPromise)
    designerPromise = nil
    return result
end

local function closeDesigner()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function resolveDesigner(value)
    closeDesigner()
    if designerPromise then
        designerPromise:resolve(value)
        designerPromise = nil
    end
end

-- Default greenzones configured beforehand in the config
for k, v in pairs(Config.GreenZones) do
    greenZone = lib.points.new(v.coords, v.radius)
    function greenZone:onEnter()
        if v.disablePlayerVehicleCollision then
            for _, player in pairs(GetActivePlayers()) do
                if player ~= cache.ped then
                    local ped = cache.ped
                    local ped2 = GetPlayerPed(player)
                    local veh = GetVehiclePedIsIn(ped, false)
                    local veh2 = GetVehiclePedIsIn(ped2, false)
                    SetEntityAlpha(ped2, 153, false)
                    if veh ~= 0 then
                        SetEntityAlpha(veh, 153, false)
                    end
                    if veh2 ~= 0 then
                        SetEntityAlpha(veh2, 153, false)
                    end
                end
            end
        end
        if v.removeWeapons then
            local currentWeapon = GetSelectedPedWeapon(cache.ped)
            RemoveWeaponFromPed(cache.ped, currentWeapon)
        end
        if v.disableFiring then
            SetPlayerCanDoDriveBy(cache.ped, false)
        end
        if v.setInvincible then
            SetEntityInvincible(cache.ped, true)
        end
        if v.enableSpeedLimits then
            vehicle = GetVehiclePedIsIn(cache.ped, false)
            speed = v.setSpeedLimit * 0.44
        end
        if v.displayTextUI then
            lib.showTextUI(v.textToDisplay, {
                position = v.displayTextPosition,
                icon = v.displayTextIcon,
                style = {
                    borderRadius = 4,
                    backgroundColor = v.backgroundColorTextUI,
                    color = v.textColor
                }
            })
        end
        if Config.EnableNotifications then
            lib.notify({
                title = Notifications.greenzoneTitle,
                description = Notifications.greenzoneEnter,
                type = 'success',
                position = Notifications.position,
                duration = 6000,
                style = {
                backgroundColor = '#ff5a47',
                color = '#2C2C2C',
                    ['.description'] = {
                        color = '#2C2C2C',
                    }
                },
                icon = Notifications.greenzoneIcon,
                iconColor = '#2C2C2C'
            })
        end
    end
    function greenZone:onExit()
        if v.disablePlayerVehicleCollision then
            for _, player in pairs(GetActivePlayers()) do
                if player ~= cache.ped then
                    local ped = cache.ped
                    local ped2 = GetPlayerPed(player)
                    local veh = GetVehiclePedIsIn(ped, false)
                    local veh2 = GetVehiclePedIsIn(ped2, false)
                    SetEntityAlpha(ped2, 255, false)
                    if veh ~= 0 then
                        SetEntityAlpha(veh, 255, false)
                    end
                    if veh2 ~= 0 then
                        SetEntityAlpha(veh2, 255, false)
                    end
                end
            end
        end
        if v.disableFiring then
            SetPlayerCanDoDriveBy(cache.ped, true)
        end
        if v.setInvincible then
            SetEntityInvincible(cache.ped, false)
        end
        if v.enableSpeedLimits then
            vehicle = GetVehiclePedIsIn(cache.ped, false)
            SetVehicleMaxSpeed(vehicle, 0.0)
        end
        if v.displayTextUI then
            lib.hideTextUI()
        end
        if Config.EnableNotifications then
            lib.notify({
                title = Notifications.greenzoneTitle,
                description = Notifications.greenzoneExit,
                type = 'error',
                position = Notifications.position,
                style = {
                backgroundColor = '#72E68F',
                color = '#2C2C2C',
                    ['.description'] = {
                        color = '#2C2C2C',
                    }
                },
                icon = Notifications.greenzoneIcon,
                iconColor = '#2C2C2C'
            })
        end
    end
    function greenZone:nearby()
        if v.disablePlayerVehicleCollision then
            for _, player in pairs(GetActivePlayers()) do
                if player ~= PlayerId() then
                    local ped = PlayerPedId()
                    local ped2 = GetPlayerPed(player)
                    local veh = GetVehiclePedIsIn(ped, false)
                    local veh2 = GetVehiclePedIsIn(ped2, false)
                    SetEntityAlpha(ped2, 153, false)
                    if veh2 ~= 0 then
                        if veh ~= 0 then
                            SetEntityAlpha(veh, 153, false)
                            SetEntityNoCollisionEntity(veh, veh2, true)
                            SetEntityNoCollisionEntity(veh2, veh, true)
                        end
                        SetEntityAlpha(veh2, 153, false)
                        SetEntityNoCollisionEntity(ped, veh2, true)
                        SetEntityNoCollisionEntity(veh2, ped, true)
                    else
                        SetEntityNoCollisionEntity(ped, ped2, true)
                        SetEntityNoCollisionEntity(ped2, ped, true)
                    end
                end
            end
        end
        if v.disableFiring then
            DisablePlayerFiring(cache.ped, true)
        end
        if v.enableSpeedLimits then
            vehicle = GetVehiclePedIsIn(cache.ped, false) -- This isn't 100% needed, could be commented out if performance is impacted too much. Only difference would be if player spawns into this zone, they can drive at any speed until exit/re-enter
            SetVehicleMaxSpeed(vehicle, speed)
        end
    end
end

-- Blip creation for the default persistent greenzones configured beforehand
for k, v in pairs(Config.GreenZones) do
    if v.blip then
        if v.blipType == 'radius' then
            local blip = AddBlipForRadius(v.coords.x, v.coords.y, v.coords.z, v.radius)
            SetBlipColour(blip, v.blipColor)
            SetBlipAlpha(blip, v.blipAlpha)
            if v.enableSprite then
                local blip2 = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
                SetBlipSprite(blip2, v.blipSprite)
                SetBlipColour(blip2, v.blipColor)
                SetBlipScale(blip2, v.blipScale)
                SetBlipAsShortRange(blip2, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.blipName)
                EndTextCommandSetBlipName(blip2)
            end
        else
            local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, v.blipSprite)
            SetBlipColour(blip, v.blipColor)
            SetBlipScale(blip, v.blipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blipName)
            EndTextCommandSetBlipName(blip)
        end
    end
end

RegisterNUICallback('designerSubmit', function(data, cb)
    resolveDesigner(data)
    cb('ok')
end)

RegisterNUICallback('designerCancel', function(_, cb)
    resolveDesigner(nil)
    cb('ok')
end)

RegisterNUICallback('designerEscape', function(_, cb)
    resolveDesigner(nil)
    cb('ok')
end)

-- Start of events for creating Greenzones in-game, this is the menu that takes data, passes it to server
lib.callback.register('outlawtwin_greenzones:adminZone', function()
    pedCoords = GetEntityCoords(cache.ped)
    local notifyPosition = (Notifications and Notifications.position) or 'top'
    lib.notify({
        title = locale('menu.title'),
        description = locale('menu.subtitle'),
        position = notifyPosition,
        type = 'inform',
        duration = 6000,
        icon = 'draw-polygon'
    })

    local defaults = {
        blipName = locale('menu.blipNamePlaceholder'),
        banner = locale('menu.displayTextPlaceholder'),
        bannerColor = '#ff5a47',
        bannerPosition = 'top-center',
        radius = 10,
        disableFiring = false,
        invincible = false,
        speedLimit = 0,
        blipID = 487,
        blipColor = 1
    }

    local adminZoneMenu = openDesigner(defaults)
    if not adminZoneMenu then
        return
    end

    local zoneName = sanitizeString(adminZoneMenu.blipName, defaults.blipName)
    local textUI = sanitizeString(adminZoneMenu.banner, defaults.banner)
    local textUIColor = sanitizeString(adminZoneMenu.bannerColor, defaults.bannerColor)
    if not textUIColor:match('^#%x%x%x%x%x%x$') then
        textUIColor = defaults.bannerColor
    else
        textUIColor = textUIColor:upper()
    end

    local textUIPosition = sanitizeString(adminZoneMenu.bannerPosition, defaults.bannerPosition)
    if textUIPosition ~= 'top-center' and textUIPosition ~= 'right-center' and textUIPosition ~= 'left-center' then
        textUIPosition = defaults.bannerPosition
    end
    local zoneSize = tonumber(adminZoneMenu.radius) or defaults.radius
    local disarm = adminZoneMenu.disableFiring and true or false
    local invincible = adminZoneMenu.invincible and true or false
    local speedLimit = tonumber(adminZoneMenu.speedLimit) or defaults.speedLimit
    local blipID = tonumber(adminZoneMenu.blipID) or defaults.blipID
    local blipColor = tonumber(adminZoneMenu.blipColor) or defaults.blipColor

    if zoneSize < 1.0 then zoneSize = 1.0 end
    if zoneSize > 100.0 then zoneSize = 100.0 end
    if speedLimit < 0 then speedLimit = 0 end
    if speedLimit > 120 then speedLimit = 120 end
    if blipID < 1 then blipID = defaults.blipID end
    if blipID > 826 then blipID = 826 end
    if blipColor < 1 then blipColor = defaults.blipColor end
    if blipColor > 85 then blipColor = 85 end

    lib.callback('outlawtwin_greenzones:data', false, noop, pedCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
end)

-- The function that creates a temporary greenzone via in-game command for all clients from the data passed
RegisterNetEvent('outlawtwin_greenzones:createAdminZone')
AddEventHandler('outlawtwin_greenzones:createAdminZone', function(zoneCoords, zoneName, textUI, textUIColor, textUIPosition, zoneSize, disarm, invincible, speedLimit, blipID, blipColor)
    vehicle = GetVehiclePedIsIn(cache.ped, false)
    zone:remove() -- Removes any existing zones
    RemoveBlip(radiusBlip) -- Removes any exisitng radius blips
    RemoveBlip(sprite) -- Removes any existing blip sprites
    lib.hideTextUI() -- Hides any existing textUI's
    SetVehicleMaxSpeed(vehicle, 0.0) -- Ensures no vehicle speed limits are enforced
    SetEntityInvincible(cache.ped, false) -- Ensures no one is still invincible anywhere
    createTwinBlip(zoneName, zoneCoords, zoneSize, blipID, blipColor) -- Creates the new blip
    zone = lib.points.new(zoneCoords, zoneSize) -- Creates a new point
    speed = speedLimit * 0.44 -- Converts to MPH (probably not 100% accurate but works enough lul)
    function zone:onEnter()
        vehicle = GetVehiclePedIsIn(cache.ped, false)
        lib.showTextUI(textUI, {
            position = textUIPosition,
            icon = 'shield-halved',
            style = {
                borderRadius = 4,
                backgroundColor = textUIColor,
                color = 'black'
            }
        })
        if invincible then
            SetEntityInvincible(cache.ped, true)
        end
    end
    function zone:onExit()
        lib.hideTextUI()
        if invincible then
            SetEntityInvincible(cache.ped, false)
        end
        SetVehicleMaxSpeed(vehicle, 0.0)
    end
    function zone:nearby()
        if disarm then
            DisablePlayerFiring(cache.ped, true)
        end
        if speedLimit ~= 0 then
            vehicle = GetVehiclePedIsIn(cache.ped, false)
            SetVehicleMaxSpeed(vehicle, speed)
        end
    end
end)

-- The function that creates blips for Greenzones created in-game
local function createTwinBlip(blipName, blipCoords, blipRadius, blipID, blipColor)
    local radius = lib.math.round(blipRadius, 1)
    radiusBlip = AddBlipForRadius(blipCoords, radius)
    SetBlipColour(radiusBlip, blipColor)
    SetBlipAlpha(radiusBlip, 100)
    sprite = AddBlipForCoord(blipCoords)
    SetBlipSprite(sprite, blipID)
    SetBlipDisplay(sprite, 4)
    SetBlipColour(sprite, blipColor)
    SetBlipScale(sprite, 1.0)
    SetBlipAsShortRange(sprite, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipName)
    EndTextCommandSetBlipName(sprite)
end

-- The actual removal of all tempoary greenzone related things
local function deleteTwinZone()
    vehicle = GetVehiclePedIsIn(cache.ped, false)
    zone:remove()
    RemoveBlip(radiusBlip)
    RemoveBlip(sprite)
    lib.hideTextUI()
    SetVehicleMaxSpeed(vehicle, 0.0)
    SetEntityInvincible(cache.ped, false)
end

-- The confirmation for deleting an active temporary greenzone
lib.callback.register('outlawtwin_greenzones:adminZoneClear', function()
    local confirm = lib.alertDialog({
        header = locale('confirm.title'),
        content = locale('confirm.content'),
        centered = true,
        cancel = true
    })
    if confirm == 'confirm' then
        lib.callback('outlawtwin_greenzones:deleteZone')
    else
        return
    end
end)

-- The event that gets triggered for all clients when deleting a temporary greenzone
RegisterNetEvent('outlawtwin_greenzones:deleteAdminZone')
AddEventHandler('outlawtwin_greenzones:deleteAdminZone', function()
    deleteTwinZone()
end)