local slashing = false

-- Tire indices for most vehicles
local tireIndices = {
    { boneName = "wheel_lf", index = 0 }, -- Front Driver
    { boneName = "wheel_rf", index = 1 }, -- Front Passenger
    { boneName = "wheel_lr", index = 2 }, -- Rear Driver
    { boneName = "wheel_rr", index = 3 }, -- Rear Passenger
    { boneName = "wheel_lm1", index = 4 }, -- Middle Left 1 (for vehicles with 6 wheels)
    { boneName = "wheel_rm1", index = 5 }, -- Middle Right 1 (for vehicles with 6 wheels)
}

function getNearestTire(vehicle, playerCoords)
    local minDistance = 9999
    local nearestTireIndex = -1

    for _, tireData in ipairs(tireIndices) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, tireData.boneName)
        if boneIndex ~= -1 then
            local tirePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local distance = #(playerCoords - tirePos)

            -- Check if the tire is not already burst and is closer than previous tires
            if distance < minDistance and not IsVehicleTyreBurst(vehicle, tireData.index, false) then
                minDistance = distance
                nearestTireIndex = tireData.index
            end
        end
    end

    return nearestTireIndex
end

RegisterCommand('slashtires', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)

    if DoesEntityExist(vehicle) then
        local nearestTireIndex = getNearestTire(vehicle, coords)

        if nearestTireIndex ~= -1 then
            -- Check if the player is already slashing tires
            if not slashing then
                slashing = true

                -- Calculate position and rotation to aim at the tire
                local boneIndex = GetEntityBoneIndexByName(vehicle, tireIndices[nearestTireIndex + 1].boneName)
                local tirePos = GetWorldPositionOfEntityBone(vehicle, boneIndex)
                local playerHeading = GetEntityHeading(playerPed)
                local playerAnimPos = GetEntityCoords(playerPed) + GetEntityForwardVector(playerPed) * 0.5

                -- Request knife attack animation
                RequestAnimDict('melee@knife@streamed_core_fps')
                while not HasAnimDictLoaded('melee@knife@streamed_core_fps') do
                    Citizen.Wait(100)
                end

                -- Play animation aiming towards the tire position
                TaskPlayAnimAdvanced(playerPed, 'melee@knife@streamed_core_fps', 'ground_attack_on_spot', playerAnimPos.x, playerAnimPos.y, playerAnimPos.z, 0, 0, playerHeading, 1.0, 1.0, 5.0, 49, 0, 0, 0, 0)
                Citizen.Wait(5000) -- Time taken to slash the tire (5 seconds)

                -- Check again if the vehicle still exists and the tire is not already burst
                if DoesEntityExist(vehicle) and not IsVehicleTyreBurst(vehicle, tireIndices[nearestTireIndex + 1].index, false) then
                    SetVehicleTyreBurst(vehicle, nearestTireIndex, false, 1000.0) -- Gradual deflation
                    TriggerEvent('chat:addMessage', { args = { '^1Tire slashed!' } })
                end

                ClearPedTasksImmediately(playerPed)
                slashing = false
            else
                TriggerEvent('chat:addMessage', { args = { '^1You are already slashing a tire!' } })
            end
        else
            TriggerEvent('chat:addMessage', { args = { '^1No tires left to slash!' } })
        end
    else
        TriggerEvent('chat:addMessage', { args = { '^1No vehicle nearby!' } })
    end
end, false)
