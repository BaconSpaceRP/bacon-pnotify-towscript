-- Created by Asser90 - modified by Deziel0495 and IllusiveTea - further modified by Vespura --

-- These vehicles will be registered as "allowed/valid" tow trucks.
-- Change the x, y and z offset values for the towed vehicles to be attached to the tow truck.
-- x = left/right, y = forwards/backwards, z = up/down
local allowedTowModels = { 
    ['flatbed'] = {x = 0.0, y = -0.85, z = 1.25} -- default GTA V flatbed
}

function SendNotification(options)
    options.animation = options.animation or {}
    options.sounds = options.sounds or {}
    options.docTitle = options.docTitle or {}

    local options = {
        type = options.type or "info",
        layout = options.layout or "centerleft",
        theme = options.theme or "gta",
        text = options.text or "Empty Notification",
        timeout = options.timeout or 5000,
        progressBar = options.progressBar ~= false and true or false,
        closeWith = options.closeWith or {},
        animation = {
            open = options.animation.open or "gta_effects_open",
            close = options.animation.close or "gta_effects_close"
        },
        sounds = {
            volume = options.sounds.volume or 1,
            conditions = options.sounds.conditions or {},
            sources = options.sounds.sources or {}
        },
        docTitle = {
            conditions = options.docTitle.conditions or {}
        },
        modal = options.modal or false,
        id = options.id or false,
        force = options.force or false,
        queue = options.queue or "global",

        killer = options.killer or false,
        container = options.container or false,
        buttons = options.button or false
    }

    SendNUIMessage({options = options})
end

RegisterNetEvent("pNotify:SendNotification")
AddEventHandler("pNotify:SendNotification", function(options)
    SendNotification(options)
end)

local allowTowingBoats = false -- Set to true if you want to be able to tow boats.
local allowTowingPlanes = false -- Set to true if you want to be able to tow planes.
local allowTowingHelicopters = false -- Set to true if you want to be able to tow helicopters.
local allowTowingTrains = false -- Set to true if you want to be able to tow trains.
local allowTowingTrailers = true -- Disables trailers. NOTE: THIS ALSO DISABLES THE AIRTUG, TOWTRUCK, SADLER, AND ANY OTHER VEHICLE THAT IS IN THE UTILITY CLASS.

local currentlyTowedVehicle = nil

RegisterCommand("tow", function()
	TriggerEvent("tow")
end,false)



function isTargetVehicleATrailer(modelHash)
    if GetVehicleClassFromName(modelHash) == 11 then
        return true
    else
        return false
    end
end

local xoff = 0.0
local yoff = 0.0
local zoff = 0.0

function isVehicleATowTruck(vehicle)
    local isValid = false
    for model,posOffset in pairs(allowedTowModels) do
        if IsVehicleModel(vehicle, model) then
            xoff = posOffset.x
            yoff = posOffset.y
            zoff = posOffset.z
            isValid = true
            break
        end
    end
    return isValid
end

RegisterNetEvent('tow')
AddEventHandler('tow', function()
	
	local playerped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(playerped, true)
	
	local isVehicleTow = isVehicleATowTruck(vehicle)

	if isVehicleTow then

		local coordA = GetEntityCoords(playerped, 1)
		local coordB = GetOffsetFromEntityInWorldCoords(playerped, 0.0, 5.0, 0.0)
		local targetVehicle = getVehicleInDirection(coordA, coordB)
        

		Citizen.CreateThread(function()
			while true do
				Citizen.Wait(0)
				isVehicleTow = isVehicleATowTruck(vehicle)
				local roll = GetEntityRoll(GetVehiclePedIsIn(PlayerPedId(), true))
				if IsEntityUpsidedown(GetVehiclePedIsIn(PlayerPedId(), true)) and isVehicleTow or roll > 70.0 or roll < -70.0 then
					DetachEntity(currentlyTowedVehicle, false, false)
					currentlyTowedVehicle = nil
                    exports.pNotify:SendNotification({text = "Tow Service: Looks like the cables holding on the vehicle have broke!", "centerLeft", type = "danger", timeout = math.random(1000, 10000)})
				end
                
			end
		end)

		if currentlyTowedVehicle == nil then
			if targetVehicle ~= 0 then
                local targetVehicleLocation = GetEntityCoords(targetVehicle, true)
                local towTruckVehicleLocation = GetEntityCoords(vehicle, true)
                local distanceBetweenVehicles = GetDistanceBetweenCoords(targetVehicleLocation, towTruckVehicleLocation, false)
                -- print(tostring(distanceBetweenVehicles)) -- debug only
		-- Distance allowed (in meters) between tow truck and the vehicle to be towed			
                if distanceBetweenVehicles > 12.0 then
                    exports.pNotify:SendNotification({text = "Tow Service: Your cables can't reach this far. Move your tow truck closer to the vehicle.", type = "info", "centerLeft", timeout = math.random(1000, 10000)})

                else
                    local targetModelHash = GetEntityModel(targetVehicle)
                    -- Check to make sure the target vehicle is allowed to be towed (see settings at lines 8-12)
                    if not ((not allowTowingBoats and IsThisModelABoat(targetModelHash)) or (not allowTowingHelicopters and IsThisModelAHeli(targetModelHash)) or (not allowTowingPlanes and IsThisModelAPlane(targetModelHash)) or (not allowTowingTrains and IsThisModelATrain(targetModelHash)) or (not allowTowingTrailers and isTargetVehicleATrailer(targetModelHash))) then 
                        if not IsPedInAnyVehicle(playerped, true) then
                            if vehicle ~= targetVehicle and IsVehicleStopped(vehicle) then
                                -- TriggerEvent('chatMessage', '', {255,255,255}, xoff .. ' ' .. yoff .. ' ' .. zoff) -- debug line
                                AttachEntityToEntity(targetVehicle, vehicle, GetEntityBoneIndexByName(vehicle, 'bodyshell'), 0.0 + xoff, -1.5 + yoff, 0.0 + zoff, 0, 0, 0, 1, 1, 0, 1, 0, 1)
                                currentlyTowedVehicle = targetVehicle
                                exports.pNotify:SendNotification({text = "Tow Service: Vehicle has been loaded onto the flatbed.", type = "success", "centerLeft", timeout = math.random(1000, 10000)})

                            else
                                exports.pNotify:SendNotification({text = "Tow Service: There is currently no vehicle on the flatbed.", type = "info", "centerLeft", timeout = math.random(1000, 10000)})
                            end
                        else
                            exports.pNotify:SendNotification({text = "Tow Service: You need to be outside of your vehicle to load or unload vehicles.", type = "info", "centerLeft", timeout = math.random(1000, 10000)})
                        end
                    else
                        exports.pNotify:SendNotification({text = "Tow Service: Your tow truck is not equipped to tow this vehicle.", type = "info", "centerLeft", timeout = math.random(1000, 10000)})
                    end
                end
            else
                exports.pNotify:SendNotification({text = "Tow Service: No towable vehicle detected.", type = "info", layout = "centerLeft", timeout = math.random(1000, 10000)})
			end
		elseif IsVehicleStopped(vehicle) then
            DetachEntity(currentlyTowedVehicle, false, false)
            local vehiclesCoords = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -12.0, 0.0)
			SetEntityCoords(currentlyTowedVehicle, vehiclesCoords["x"], vehiclesCoords["y"], vehiclesCoords["z"], 1, 0, 0, 1)
			SetVehicleOnGroundProperly(currentlyTowedVehicle)
			currentlyTowedVehicle = nil
            exports.pNotify:SendNotification({text = "Tow Service: Vehicle has been unloaded from the flatbed.", type = "info", layout = "centerLeft", timeout = math.random(1000, 10000)})
		end
	else
        exports.pNotify:SendNotification({text = "Tow Service: Your vehicle is not registered as an official tow truck.", type = "info", layout = "centerLeft",  timeout = math.random(1000, 10000)})
    end
end)

function getVehicleInDirection(coordFrom, coordTo)
	local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 10, PlayerPedId(), 0)
	local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
	return vehicle
end

function ShowNotification(text)
	SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
	DrawNotification(false, false)
end
