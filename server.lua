-- do not touch until you know what you're doing-stuff
ESX = exports["es_extended"]:getSharedObject()
local time = os.time()

-- config-stuff
TimeInterval = 60 -- time interval in minutes before wiping the vehicles
DistanceToVehicles = 50.0 -- minimum distance between car and vehicle, for the vehicle not to be deleted
Command = "delcars" -- admin command to execute the vehicle wipe manually

AllowedGroups = { -- allowed groups
    "owner",
	"admin",
	"dev"
}

Messages = { -- notify messages (more like warning messages before the vehiclewipe actually gets executed)
    [1] = { 
		time = 5, -- time in minutes before executing the vehiclewipe
        msg = "Cars located more than 50 meters away from a ped will be removed within 5 minutes!",  -- message to show
    },
    [2] = {
        time = 3,
        msg = "Cars located more than 50 meters away from a ped will be removed within 3 minutes!",
    },
    [3] = {
        time = 1,
        msg = "Cars located more than 50 meters away from a ped will be removed within 1 minute!",
    },
	-- add as many more as you want
}

NotAllowed = "Your bitchass is not allowed to use this command!"
DeletedVehs = " vehicles have been deleted!"

function notify(text, source)
	if not source then
		TriggerClientEvent('esx:showNotification', -1, text)
	else
		TriggerClientEvent('esx:showNotification', source, text)
	end
end

-- code-stuff
function gMT(cT)
	for _, v in pairs(Messages) do
		if (TimeInterval * 60 - v.time * 60) == (cT - time) then
			return v.msg
		end
	end
end

function wipeVehicles()
	local vehicles = GetAllVehicles()
	local delVhcs = 0
	for k, v in pairs(vehicles) do
		if v and DoesEntityExist(v) then
			local aVN = false
			for _, ped in pairs(GetAllPeds()) do
				if #(GetEntityCoords(v) - GetEntityCoords(ped)) <= DistanceToVehicles then
					aVN = true
					break
				end
			end
			if not aVN then
				DeleteEntity(v)
				delVhcs = delVhcs + 1
			end
		end
	end
	notify(delVhcs .. DeletedVehs)
end

CreateThread(function()
	while true do
		Wait(1000)
		local cT = os.time()
		if cT - time >= TimeInterval * 60 then
			time = cT
			wipeVehicles()
		else
			local msg = gMT(cT)
			if msg then
				notify(msg)
			end
		end
	end
end)

RegisterCommand(Command, function(source, args, rawCommand)
	local xPlayer = ESX.GetPlayerFromId(source)
    local playerGroup = xPlayer.getGroup()
    local hasPermissionAndABigDick = false
    for _, v in pairs(AllowedGroups) do
        if playerGroup == v then
            hasPermissionAndABigDick = true
            break
        end
    end
    if hasPermissionAndABigDick then
        wipeVehicles()
    else
		notify(NotAllowed, source)
    end
end, false)
