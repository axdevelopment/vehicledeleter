-- config
TimeInterval = 60               -- in minutes
DistanceToVehicles = 50.0       -- max distance allowed between vehicle and any player before deletion
Command = "delcars"             -- admin command

AllowedGroups = {               -- identifiers (steam:, license:, etc.)
    "license:3daad64b1e2edb06ccbc54ba44d4485ade246bdf"
}

Messages = {
    [1] = { time = 5, msg = "Cars more than 50 meters away from a ped will be deleted in 5 minutes!" },
    [2] = { time = 3, msg = "Cars more than 50 meters away from a ped will be deleted in 3 minutes!" },
    [3] = { time = 1, msg = "Cars more than 50 meters away from a ped will be deleted in 1 minute!" },
}

NotAllowed = "You are not allowed to use this command!"
DeletedVehs = " vehicles have been deleted!"

-- notify function
function notify(msg, source)
    if source then
        TriggerClientEvent('chat:addMessage', source, { args = { "[VehicleWipe]", msg } })
    else
        TriggerClientEvent('chat:addMessage', -1, { args = { "[VehicleWipe]", msg } })
    end
end

-- internal timer
local lastWipe = os.time()

-- message timing logic
function getWarningMessage(currentTime)
    for _, v in pairs(Messages) do
        if (TimeInterval * 60 - v.time * 60) == (currentTime - lastWipe) then
            return v.msg
        end
    end
end

-- vehicle wipe
function wipeVehicles()
    local deleted = 0
    local allPeds = GetAllPeds()
    local allVehicles = GetAllVehicles()

    for _, veh in pairs(allVehicles) do
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local tooClose = false

            for _, ped in pairs(allPeds) do
                if #(vehCoords - GetEntityCoords(ped)) <= DistanceToVehicles then
                    tooClose = true
                    break
                end
            end

            if not tooClose then
                DeleteEntity(veh)
                deleted = deleted + 1
            end
        end
    end

    notify(deleted .. DeletedVehs)
end

-- main timer loop
CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()

        if now - lastWipe >= TimeInterval * 60 then
            lastWipe = now
            wipeVehicles()
        else
            local msg = getWarningMessage(now)
            if msg then
                notify(msg)
            end
        end
    end
end)

-- manual command
RegisterCommand(Command, function(source)
    if source == 0 then
        wipeVehicles()
        return
    end

    local ids = GetPlayerIdentifiers(source)
    local isAllowed = false

    for _, id in pairs(ids) do
        for _, allowed in pairs(AllowedGroups) do
            if string.lower(id) == string.lower(allowed) then
                isAllowed = true
                break
            end
        end
        if isAllowed then break end
    end

    if isAllowed then
        wipeVehicles()
    else
        notify(NotAllowed, source)
    end
end, false)
