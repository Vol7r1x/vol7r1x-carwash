ESX = exports["es_extended"]:getSharedObject()

npc = false
isWash = false

Citizen.CreateThread(function()
	PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.WashPlaces) do
		CreateMapBlip(k,v)
	end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        local player = GetPlayerPed(-1)
        local coords = GetEntityCoords(player)
        for k,v in pairs(Config.WashPlaces) do
            local distance = GetDistanceBetweenCoords(coords.x, coords.y, coords.z, v.pos[1], v.pos[2], v.pos[3], false)
            local mk = v.marker
            if not isWash then               
                if distance <= 10.0 and distance >= 2.0 then 
                    DrawMarker(mk.type, v.pos[1], v.pos[2], v.pos[3], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, mk.scale.x, mk.scale.y, mk.scale.z, mk.color.r, mk.color.g, mk.color.b, mk.color.a, false, true, 2, false, false, false, false)
                elseif distance <= 2.0 then
                    if IsPedInAnyVehicle(PlayerPedId(), false) then
                        DrawText3Ds(v.pos[1], v.pos[2], v.pos[3] + 1.0, Lang['wash_car'])
                        if IsControlJustPressed(0, 38) then
                            WashPlace = v    
                            WashMenu(v)
                        end
                    else
                        DrawText3Ds(v.pos[1], v.pos[2], v.pos[3] + 1.0, Lang['be_in_car']) 
                    end  
                end
            else
                Citizen.Wait(1000)
            end          
        end
    end
end)



function WashMenu(Wash)
    ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'id_card_menu', {
            title   = Lang['wash_menu'],
            align    = 'center',
            elements = {
                {label = Lang['wash_car1'], value = 'washstandard'},  
                --{label = Lang['wash_car2'], value = 'washpremium'},
                --{label = Lang['wash_car3'], value = 'washice'}
            }
        },
        function(data, menu)
            local val = data.current.value
            if val == 'washstandard' then
                menu.close()
                WashStandard(Wash)
            elseif val == 'washpremium' then
                menu.close()  
                WashPremium(Wash)
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end


function WashStandard(WashPlace)
    local PlayerPed = GetPlayerPed(-1)
    local car = GetVehiclePedIsIn(PlayerPed, false)
    local hash = GetHashKey(Config.NPC)
    local hasMoney = false
    
    ESX.TriggerServerCallback('vol7r1x_CarWash:checkMoney', function(cbm)
        if cbm then
            hasMoney = true
        else
            hasMoney = false    
        end
        
        if hasMoney then
            -- PREP & FREEZE CAR
            isWash = true
            Citizen.Wait(1000)
            SetEntityCoords(car, WashPlace.carPos[1],WashPlace.carPos[2],WashPlace.carPos[3], false, false, false, true)
            SetEntityHeading(car, WashPlace.carHeading)
            SetVehicleOnGroundProperly(car)
            FreezeEntityPosition(car, true)

            --PREP MODEL & LOAD
            Citizen.Wait(100)
            RequestModel(hash)
            while not HasModelLoaded(hash) do
                Wait(1)
            end

           
            local npc = CreatePed(6, hash, WashPlace.NPCspawn[1], WashPlace.NPCspawn[2], WashPlace.NPCspawn[3], 90.0, true, true)
        
            TaskGoStraightToCoord(npc, WashPlace.NPCpos1[1], WashPlace.NPCpos1[2], WashPlace.NPCpos1[3], 2.0, -1, WashPlace.NPCpos1[4], 0.0)
            Citizen.Wait(8000)
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_MAID_CLEAN", -1, true)
            Citizen.Wait(Config.NPCwashTime)

            --PARTICLE & WASH
            RequestNamedPtfxAsset("core")
            while not HasNamedPtfxAssetLoaded("core") do
                Citizen.Wait(0)
            end
            ClearPedTasksImmediately(npc)
            UseParticleFxAssetNextCall("core")
            local particles  = StartParticleFxLoopedAtCoord("ent_amb_waterfall_splash_p", WashPlace.carPos[1], WashPlace.carPos[2], WashPlace.carPos[3], 0.0, 0.0, 90.0, 1.0, 1, 1, 1, false)
            UseParticleFxAssetNextCall("core")
            local particles2  = StartParticleFxLoopedAtCoord("ent_amb_waterfall_splash_p", WashPlace.carPos[1] + 2.0, WashPlace.carPos[2], WashPlace.carPos[3], 0.0, 0.0, 90.0, 1.0, 1, 1, 1, false)
            TaskGoToCoordAnyMeans(npc, WashPlace.NPCpos2[1], WashPlace.NPCpos2[2], WashPlace.NPCpos2[3], 2.0, 0, 0, 786603, 0xbf800000)
            Citizen.Wait(Config.ParticleTime)
            
            StopParticleFxLooped(particles, 0)
            StopParticleFxLooped(particles2, 0)
            SetEntityHeading(npc, WashPlace.NPCpos2[4])
            TaskStartScenarioInPlace(npc, "WORLD_HUMAN_MAID_CLEAN", -1, true)
            Citizen.Wait(Config.NPCwashTime)
            
            
            WashDecalsFromVehicle(car, 1.0)
            SetVehicleDirtLevel(car)
            FreezeEntityPosition(car, false)
            ShowNotifyESX(Lang["standard_wash"])
            TaskGoToCoordAnyMeans(npc, 175.5997, -1713.6248, 29.2918, 2.0, 0, 0, 786603, 0xbf800000)
            Wait(7000)
            DeletePed(npc)
            isWash = false
        else       
            ShowNotifyESX(Lang["no_money"])
        end
    end,"S")
end


function CreateMapBlip(k,v)
	local mk = v.blip
	if mk.enable then
		local blip = AddBlipForCoord(v.pos[1], v.pos[2], v.pos[3])
		SetBlipSprite (blip, mk.sprite)
		SetBlipDisplay(blip, mk.display)
		SetBlipScale  (blip, mk.scale)
		SetBlipColour (blip, mk.color)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(mk.name)
		EndTextCommandSetBlipName(blip)
	end
end

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 500
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 0, 0, 0, 80)
end

function ShowNotifyESX(msg) --Edit with your own notification system !
	ESX.ShowNotification(msg)
end
