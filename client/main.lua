local LastMarker, LastPart, thisGarage, thisPound  = nil, nil, nil, nil
local next                              = next
local nearMarker, menuIsShowed          = false, false
local vehiclesList                      = {}

RegisterNetEvent('esx_garage:closemenu')
AddEventHandler('esx_garage:closemenu', function()
    menuIsShowed = false
    vehiclesList = {}

    SetNuiFocus(false)
    SendNUIMessage({hideAll = true})

    if not menuIsShowed and thisGarage then ESX.TextUI(_U('access_parking')) end
    if not menuIsShowed and thisPound then ESX.TextUI(_U('access_pound')) end
end)

RegisterNUICallback('escape', function(data, cb)
    TriggerEvent('esx_garage:closemenu')
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    local spawnCoords = {
        x = data.spawnPoint.x,
        y = data.spawnPoint.y,
        z = data.spawnPoint.z
    }

    if thisGarage ~= nil then
        
        if ESX.Game.IsSpawnPointClear(spawnCoords, 2.5) then
            ESX.Game.SpawnVehicle(data.vehicleProps.model, spawnCoords,
                                  data.spawnPoint.heading, function(vehicle)
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                ESX.Game.SetVehicleProperties(vehicle, data.vehicleProps)
                SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), true, true)
            end)

            thisGarage       = nil
    
            TriggerServerEvent('esx_garage:updateOwnedVehicle', false, nil, nil, data.vehicleProps)
            TriggerEvent('esx_garage:closemenu')

            ESX.ShowNotification(_U('veh_released'))
            
        else
            ESX.ShowNotification(_U('veh_block'), 'error')
        end

    elseif thisPound ~= nil then
        ESX.TriggerServerCallback('esx_garage:checkMoney', 
        function(hasMoney)
            if hasMoney then
                if ESX.Game.IsSpawnPointClear(spawnCoords, 2.5) then
                    TriggerServerEvent('esx_garage:payPound', data.exitVehicleCost)

                    ESX.Game.SpawnVehicle(data.vehicleProps.model, spawnCoords,
                                        data.spawnPoint.heading, function(vehicle)
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                        ESX.Game.SetVehicleProperties(vehicle, data.vehicleProps)
                        SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), true, true)
                    end)

                    thisPound       = nil
            
                    TriggerServerEvent('esx_garage:updateOwnedVehicle', false, nil, nil, data.vehicleProps)
                    TriggerEvent('esx_garage:closemenu')
                    
                else
                    ESX.ShowNotification(_U('veh_block'), 'error')
                end
                else
                    ESX.ShowNotification(_U('missing_money'))
                end
        end, data.exitVehicleCost)
    end

    cb('ok')
end)

-- Create Blips
CreateThread(function()
    for k, v in pairs(Config.Garages) do
        local blip = AddBlipForCoord(v.EntryPoint.x, v.EntryPoint.y, v.EntryPoint.z)

        SetBlipSprite(blip, Config.Blips.Parking.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.Parking.Scale)
        SetBlipColour(blip, Config.Blips.Parking.Colour)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(_U('parking_blip_name'))
        EndTextCommandSetBlipName(blip)
    end

    for k, v in pairs(Config.Pounds) do
        local blip = AddBlipForCoord(v.GetOutPoint.x, v.GetOutPoint.y, v.GetOutPoint.z)

        SetBlipSprite(blip, Config.Blips.Pound.Sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.Pound.Scale)
        SetBlipColour(blip, Config.Blips.Pound.Colour)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(_U('pound_blip_name'))
        EndTextCommandSetBlipName(blip)
    end
end)

AddEventHandler('esx_garage:hasEnteredMarker', function(name, part)
    if part == 'EntryPoint' then
        local garage = Config.Garages[name]
        thisGarage   = garage

        ESX.TextUI(_U('access_parking'))
    end

    if part == 'StorePoint' then
        local garage = Config.Garages[name]
        thisGarage              = garage

        local isInVehicle = IsPedInAnyVehicle(PlayerPedId(), false)

        if isInVehicle then ESX.TextUI(_U('park_veh')) end
    end

    if part == 'GetOutPoint' then
        local pound = Config.Pounds[name]
        thisPound   = pound

        ESX.TextUI(_U('access_pound'))
    end
end)

AddEventHandler('esx_garage:hasExitedMarker', function()
    thisGarage                  = nil
    thisPound                   = nil
    ESX.HideUI()
    TriggerEvent('esx_garage:closemenu')
end)

-- Display markers
CreateThread(function()
    while true do
        local sleep             = 500

        local playerPed         = PlayerPedId()
        local coords            = GetEntityCoords(playerPed)
        local inVehicle         = IsPedInAnyVehicle(playerPed, false)

        -- parking
        for k, v in pairs(Config.Garages) do
            if (#(coords - vector3(v.EntryPoint.x, v.EntryPoint.y, v.EntryPoint.z)) < Config.DrawDistance) then
                DrawMarker(Config.Markers.EntryPoint.Type, v.EntryPoint.x, v.EntryPoint.y, v.EntryPoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Markers.EntryPoint.Size.x, Config.Markers.EntryPoint.Size.y, Config.Markers.EntryPoint.Size.z, Config.Markers.EntryPoint.Color.r, Config.Markers.EntryPoint.Color.g, Config.Markers.EntryPoint.Color.b, 100, false, true, 2, false, false, false, false)
                sleep           = 0
                break
            end

            if (#(coords -
                vector3(v.StorePoint.x, v.StorePoint.y, v.StorePoint.z)) < Config.DrawDistance) then
                DrawMarker(Config.Markers.StorePoint.Type, v.StorePoint.x, v.StorePoint.y, v.StorePoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Markers.StorePoint.Size.x, Config.Markers.StorePoint.Size.y, Config.Markers.StorePoint.Size.z, Config.Markers.StorePoint.Color.r, Config.Markers.StorePoint.Color.g, Config.Markers.StorePoint.Color.b, 100, false, true, 2, false, false, false, false)
                
                sleep           = 0
            end
        end

        -- pound
        for k, v in pairs(Config.Pounds) do
            if (#(coords - vector3(v.GetOutPoint.x, v.GetOutPoint.y, v.GetOutPoint.z)) < Config.DrawDistance) then
                DrawMarker(Config.Markers.EntryPoint.Type, v.GetOutPoint.x, v.GetOutPoint.y, v.GetOutPoint.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Markers.EntryPoint.Size.x, Config.Markers.EntryPoint.Size.y, Config.Markers.EntryPoint.Size.z, Config.Markers.EntryPoint.Color.r, Config.Markers.EntryPoint.Color.g, Config.Markers.EntryPoint.Color.b, 100, false, true, 2, false, false, false, false)
                sleep           = 0
                break
            end
        end

        if sleep == 0 then
            nearMarker          = true
        else
            nearMarker          = false
        end

        Wait(sleep)
    end
end)

-- Enter / Exit marker events (parking)
CreateThread(function()
    while true do
        if nearMarker then
            local playerPed         = PlayerPedId()
            local coords            = GetEntityCoords(playerPed)
            local isInMarker        = false
            local currentMarker     = nil
            local currentPart       = nil

            for k, v in pairs(Config.Garages) do
                if (#(coords - vector3(v.EntryPoint.x, v.EntryPoint.y, v.EntryPoint.z)) < Config.Markers.EntryPoint.Size.x) then
                    isInMarker          = true
                    currentMarker       = k
                    currentPart         = 'EntryPoint'

                    if IsControlJustReleased(0, 38) and not menuIsShowed then
                        ESX.TriggerServerCallback('esx_garage:getVehiclesInParking',
                            function(vehicles)
                                if next(vehicles) ~= nil then
                                    menuIsShowed        = true

                                    for i = 1, #vehicles, 1 do
                                        table.insert(vehiclesList, {
                                            model       = GetDisplayNameFromVehicleModel(vehicles[i].vehicle.model),
                                            plate       = vehicles[i].plate,
                                            props       = vehicles[i].vehicle
                                        })

                                    end

                                    local spawnPoint = {
                                        x               = v.SpawnPoint.x,
                                        y               = v.SpawnPoint.y,
                                        z               = v.SpawnPoint.z,
                                        heading         = v.SpawnPoint.heading
                                    }

                                    SendNUIMessage({
                                        showMenu = true,
                                        vehiclesList = {
                                            json.encode(vehiclesList)
                                        },
                                        spawnPoint          = spawnPoint,
                                        locales = {
                                            action          = _U('veh_exit'),
                                            veh_model       = _U('veh_model'),
                                            veh_plate       = _U('veh_plate'),
                                            veh_condition   = _U('veh_condition'),
                                            veh_action      = _U('veh_action')
                                        }
                                    })

                                    SetNuiFocus(true, true)

                                    if menuIsShowed then
                                        ESX.HideUI()
                                    end
                                else
                                    ESX.ShowNotification(_U('no_veh_parking'))
                                end
                            end, currentMarker)
                    end
                    break
                end

                if (#(coords - vector3(v.StorePoint.x, v.StorePoint.y, v.StorePoint.z)) < Config.Markers.StorePoint.Size.x) then
                    isInMarker          = true
                    currentMarker       = k
                    currentPart         = 'StorePoint'
                    local isInVehicle   = IsPedInAnyVehicle(playerPed, false)

                    if isInVehicle then
                        if IsControlJustReleased(0, 38) then
                            local vehicle           = GetVehiclePedIsIn(playerPed, false)
                            local vehicleProps      = ESX.Game.GetVehicleProperties(vehicle)
                            
                            ESX.TriggerServerCallback('esx_garage:checkVehicleOwner', function(owner)
                                if owner then
                                    ESX.Game.DeleteVehicle(vehicle)
                                    TriggerServerEvent('esx_garage:updateOwnedVehicle', true, currentMarker, nil, vehicleProps)
                                else
                                    ESX.ShowNotification(_U('not_owning_veh'), 'error')
                                end
                            end, vehicleProps.plate)
                        end
                    end
                end
            end

            for k, v in pairs(Config.Pounds) do
                if (#(coords - vector3(v.GetOutPoint.x, v.GetOutPoint.y, v.GetOutPoint.z)) < Config.Markers.EntryPoint.Size.x) then
                    isInMarker          = true
                    currentMarker       = k
                    currentPart         = 'GetOutPoint'

                    if IsControlJustReleased(0, 38) and not menuIsShowed then
                        ESX.TriggerServerCallback('esx_garage:getVehiclesInPound',
                            function(vehicles)
                                if next(vehicles) ~= nil then
                                    menuIsShowed        = true

                                    for i = 1, #vehicles, 1 do
                                        table.insert(vehiclesList, {
                                            model       = GetDisplayNameFromVehicleModel(vehicles[i].vehicle.model),
                                            plate       = vehicles[i].plate,
                                            props       = vehicles[i].vehicle
                                        })

                                    end

                                    local spawnPoint = {
                                        x               = v.SpawnPoint.x,
                                        y               = v.SpawnPoint.y,
                                        z               = v.SpawnPoint.z,
                                        heading         = v.SpawnPoint.heading
                                    }

                                    SendNUIMessage({
                                        showMenu = true,
                                        vehiclesList = {
                                            json.encode(vehiclesList)
                                        },
                                        spawnPoint          = spawnPoint,
                                        poundCost = v.Cost,
                                        locales = {
                                            action          = _U('pay_pound'),
                                            veh_model       = _U('veh_model'),
                                            veh_plate       = _U('veh_plate'),
                                            veh_condition   = _U('veh_condition'),
                                            veh_action      = _U('veh_action')
                                        }
                                    })

                                    SetNuiFocus(true, true)

                                    if menuIsShowed then
                                        ESX.HideUI()
                                    end
                                else
                                    ESX.ShowNotification(_U('no_veh_pound'))
                                end
                            end, currentMarker)
                    end
                    break
                end
            end

            if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastMarker ~= currentMarker or LastPart ~= currentPart)) then
                
                if LastMarker ~= currentMarker or LastPart ~= currentPart then
                    TriggerEvent('esx_garage:hasExitedMarker')
                end

                HasAlreadyEnteredMarker = true
                LastMarker      = currentMarker
                LastPart        = currentPart

                TriggerEvent('esx_garage:hasEnteredMarker', currentMarker, currentPart)
            end

            if not isInMarker and HasAlreadyEnteredMarker then
                HasAlreadyEnteredMarker = false

                TriggerEvent('esx_garage:hasExitedMarker')
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)
