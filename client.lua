------------- CONEXÃO VRP -------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
----------------------------------------

vSERVER = Tunnel.getInterface("vrp_desmanche")

--------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
--------------------------------------------------------------------------------------------------------------
local veh = nil

local desmanchando = false
local pegou_ferramentas = false
local pegou_peca = false
local pegou_item = false
local vendendo = false

local indice = 0
local quantidade_de_pecas_do_veiculo = 0
local quantidade_pecas_removidas = 0
local modelHash = 0

local coordenadasPartes_Veiculo = {}
local PecasRemovidas = {}

local itemNaMao = ''
local placa = ''
local nomeCarro = ''
local modeloCarro = ''
--------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------

----------------------
-- INICIAR DESMANCHE
----------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))

        if not desmanchando then

            -- Percorrer por todos os locais de desmanche
            for k,v in pairs(Config.coordenadas_locais_desmanche) do

                -- Encontrar local de desmanche que o player está mais próximo
                if Vdist(x,y,z,v.x,v.y,v.z) <= 10 then
                    thor = 1
                    indice = k
                    iniciarProcesso(indice) -- Chama a função que mostra as marcações no chão e inicia o desmanche
                end

            end

        end

        Citizen.Wait(thor)

    end

end)

-----------------------
-- PEGANDO FERRAMENTAS
-----------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))

        -- Se estiver iniciado o processo mas ainda não pegou as ferramentas
        if desmanchando and not pegou_ferramentas then

            thor = 1

            -- Desenhar marcações das ferramentas

            DrawMarker(27,Config.coordenadas_locais_ferramentas[indice].x,Config.coordenadas_locais_ferramentas[indice].y,Config.coordenadas_locais_ferramentas[indice].z-0.9,0,0,0,0.0,0,0,0.9,0.9,0.8,255,0,0,70,0,1,0,1)

            DrawMarker(2,Config.coordenadas_locais_ferramentas[indice].x,Config.coordenadas_locais_ferramentas[indice].y,Config.coordenadas_locais_ferramentas[indice].z-0.4,0,0,0,0.0,0,0,0.4,0.4,0.4,255,255,255,70,1,1,0,0)

            DrawText3D(Config.coordenadas_locais_ferramentas[indice].x,Config.coordenadas_locais_ferramentas[indice].y,Config.coordenadas_locais_ferramentas[indice].z+0.12, "~g~[E] ~w~Pegar Ferramentas", 1.3, 1)

            if Vdist(x,y,z,Config.coordenadas_locais_ferramentas[indice].x,Config.coordenadas_locais_ferramentas[indice].y,Config.coordenadas_locais_ferramentas[indice].z) <= 1 then

                -- Se apertar 'E' na marker das ferramentas,
                if IsControlJustPressed(0,38) then

                    -- Notificar e pegar ferramentas

                    TriggerEvent("Notify","importante","Você está pegando as ferramentas.")

                    FreezeEntityPosition(ped, true)
                    SetEntityHeading(ped, Config.coordenadas_locais_ferramentas[indice].h)

                    vRP.playAnim(false, {{"amb@medic@standing@kneel@idle_a", "idle_a"}}, true)

                    TriggerEvent('progress', 5000, 'PEGANDO FERRAMENTAS')
                    Wait(5000)  

                    pegou_ferramentas = true

                    TriggerEvent('Notify', 'sucesso', 'Você pegou as ferramentas, desmanche o veículo!')

                    FreezeEntityPosition(ped, false)
                    ClearPedTasks(ped)
                end

            end

        end


        Citizen.Wait(thor)
    end


end)

------------------------
-- DESMANCHANDO VEÍCULO
------------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))

        -- Se o processo foi iniciado e o player pegou as ferramentas
        if desmanchando and pegou_ferramentas and not vendendo then

            thor = 1

            local classe = GetVehicleClass(veh) -- Pegar classe do veículo

            if classe ~= 8 then -- Se for CARRO
                local pD = GetEntityBoneIndexByName(veh,"handle_dside_f")
                coordenadasPartes_Veiculo['Porta_Direita'] = GetWorldPositionOfEntityBone(veh, pD)
                local pE = GetEntityBoneIndexByName(veh,"handle_pside_f")
                coordenadasPartes_Veiculo['Porta_Esquerda'] = GetWorldPositionOfEntityBone(veh, pE )
                coordenadasPartes_Veiculo['Roda_EsquerdaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lf"))
                coordenadasPartes_Veiculo['Roda_DireitaFrente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rf"))
                coordenadasPartes_Veiculo['Roda_EsquerdaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lr"))
                coordenadasPartes_Veiculo['Roda_DireitaTras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_rr"))
                if pD == -1 and pE == -1 then
                    quantidade_de_pecas_do_veiculo = 4
                else
                    quantidade_de_pecas_do_veiculo = 6
                end
            else -- se for MOTO
                coordenadasPartes_Veiculo['Roda_Frente'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lf"))
                coordenadasPartes_Veiculo['Roda_Tras'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"wheel_lr"))
                --coordenadasPartes_Veiculo['Banco'] = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh,"bodyshell _dummy"))
                quantidade_de_pecas_do_veiculo = 2
            end

            -- Rodar por vetor de coordenadas das partes do veículo a serem removidas
            for k , v in pairs(coordenadasPartes_Veiculo) do

                local xVeh,yVeh,zVeh = table.unpack(v)

                local dist = Vdist(x,y,z,xVeh,yVeh,zVeh)

                -- Se não removeu a peça atual e não está com nenhuma peça na mão
                if not PecasRemovidas[k] and not pegou_peca then

                    if dist <= 8 then
                        DrawMarker(21, xVeh,yVeh,zVeh+1, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 20, 133, 92, 150, 0, 0, 0, 1)

                        if dist <= 2.5 then
                            desenharTextoNaTela("~w~Pressione ~g~[E] ~w~para remover as peças.")


                            if dist < 1.1 then

                                if IsControlJustPressed(0, 38) then
                                    
                                    if k == 'Capo' or k == 'pMalas' then

                                        vRP.playAnim(false, {{"mini@repair" , "fixing_a_player"}}, true)
                                        Citizen.Wait(5000)
                                        ClearPedTasks(ped)

                                    elseif k == 'Porta_Direita' or k == 'Porta_Esquerda' then

                                        vRP._playAnim(false,{task='WORLD_HUMAN_WELDING'},true)

                                        Citizen.Wait(Config.tempo_remover_pecas)
                                        ClearPedTasks(ped)

                                        vRP._CarregarObjeto("anim@heists@box_carry@","idle",Config.props['portas'],50,28422)

                                        pegou_item = vSERVER.entregaItem(Config.itens['portaDeCarro'])

                                        itemNaMao = Config.itens['portaDeCarro']
                                        pegou_peca = true

                                        if k == 'Porta_Direita' then
                                            SetVehicleDoorBroken(veh, 0, true)
                                        elseif k == 'Porta_Esquerda' then
                                            SetVehicleDoorBroken(veh, 1, true)
                                        end

                                    elseif k == 'Roda_DireitaFrente' or k == 'Roda_EsquerdaFrente' or k == 'Roda_DireitaTras' or k == 'Roda_EsquerdaTras' or k == 'Roda_Frente' or k == 'Roda_Tras' then

                                        vRP.playAnim(false, {{"amb@medic@standing@tendtodead@idle_a" , "idle_a"}}, true)

                                        Citizen.Wait(Config.tempo_remover_pecas)
                                        ClearPedTasks(ped)

                                        vRP._CarregarObjeto("anim@heists@box_carry@","idle",Config.props['rodas'],50,28422)

                                        if k == 'Roda_Frente' or k == 'Roda_Tras' then
                                            pegou_item = vSERVER.entregaItem(Config.itens['rodaDeMoto'])
                                            itemNaMao = Config.itens['rodaDeMoto']
                                        else
                                            pegou_item = vSERVER.entregaItem(Config.itens['rodaDeCarro'])
                                            itemNaMao = Config.itens['rodaDeCarro']
                                        end

                                        pegou_peca = true

                                        if classe ~= 8 then
                                            if k == 'Roda_EsquerdaFrente' then
                                                SetVehicleTyreBurst(veh, 0, true, 1000)
                                            elseif k == 'Roda_DireitaFrente' then
                                                SetVehicleTyreBurst(veh, 1, true, 1000)
                                            elseif k == 'Roda_EsquerdaTras' then
                                                SetVehicleTyreBurst(veh, 4, true, 1000)
                                            elseif k == 'Roda_DireitaTras' then
                                                SetVehicleTyreBurst(veh, 5, true, 1000)
                                            end
                                        else
                                            if k == 'Roda_Frente' then
                                                SetVehicleTyreBurst(veh, 0, true, 1000)
                                            elseif k == 'Roda_Tras' then
                                                SetVehicleTyreBurst(veh, 4, true, 1000)
                                            end
                                        end

                                    else
                                        vRP.playAnim(false, {{"amb@medic@standing@tendtodead@idle_a" , "idle_a"}}, true)
                                        Citizen.Wait(5000)
                                        ClearPedTasks(ped)
                                    end

                                    if k == 'Capo' then
                                        SetVehicleDoorBroken(veh, 4, true)
                                    end
                                    Wait(5000)
                                    PecasRemovidas[k] = true
                                    quantidade_pecas_removidas = quantidade_pecas_removidas + 1
                                    if quantidade_pecas_removidas == quantidade_de_pecas_do_veiculo and not pegou_peca then
                                        TriggerEvent('Notify','importante','Você desmanchou o veículo! Venda as peças no computador.')
                                        vendendo = true
                                        coordenadasPartes_Veiculo = {}
                                        PecasRemovidas = {}
                                    end
                                    

                                end
                            
                            end

                        end

                    end

                end

            end


        end

        Citizen.Wait(thor)
    end

end)

-------------------
-- GUARDANDO PEÇAS
-------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))

        if pegou_peca and not vendendo then

            thor = 1

            -- Passa por todas as coordenadas dos locais de guardar peças
            for k,v in pairs(Config.coordenadas_locais_guardarPecas) do

                local dist = Vdist(x,y,z,v.x,v.y,v.z)

                if dist <= 20 then

                    -- Marker flutuante
                    DrawMarker(21,v.x,v.y,v.z-0.25,0,0,0,0.0,0,0,0.4,0.4,0.4,255,255,255,100,1,1,0,0)

                    DrawMarker(27,v.x,v.y,v.z-0.9,0,0,0,0.0,0,0,0.7,0.7,0.4,255, 0, 0,150,0,1,0,1) -- Desenha a marker no chão.

                    if dist <= 1 then
                        -- Se estiver próximo do local de entregar a peça e apertar 'E'
                        if IsControlJustPressed(0,38) then

                            if itemNaMao ~= 'portacarro' then

                                RequestAnimDict("anim@heists@money_grab@briefcase")
                                while not HasAnimDictLoaded("anim@heists@money_grab@briefcase") do
                                    Citizen.Wait(0) 
                                end
                                TaskPlayAnim(ped,"anim@heists@money_grab@briefcase","put_down_case",100.0,200.0,0.3,120,0.2,0,0,0)
                                Wait(800)

                            end

                            vRP._DeletarObjeto()

                            ClearPedTasks(ped)
                            if pegou_item then
                                vSERVER.removeItem(itemNaMao)
                            end
                            pegou_peca = false

                        end
                    end

                end

            end

        end


        Citizen.Wait(thor)
    end


end)

------------------------------------------------------------
-- FINALIZANDO OPERAÇÃO DE DESMANCHE | RECEBENDO O DINHEIRO
------------------------------------------------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000
        local ped = PlayerPedId()
        local x,y,z = table.unpack(GetEntityCoords(ped))


        if desmanchando and not pegou_peca and quantidade_pecas_removidas == quantidade_de_pecas_do_veiculo and indice ~= 0 and vendendo then

            thor = 1

            xVenda = Config.coordenadas_locais_venda[indice].x
            yVenda = Config.coordenadas_locais_venda[indice].y
            zVenda = Config.coordenadas_locais_venda[indice].z

            local dist = Vdist(x,y,z,xVenda,yVenda,zVenda)

           if dist <= 10 then
                -- Marker flutuante
                DrawMarker(21,xVenda,yVenda,zVenda-0.25,0,0,0,0.0,0,0,0.4,0.4,0.4,255,255,255,100,1,1,0,0)

                DrawMarker(27,xVenda,yVenda,zVenda-0.9,0,0,0,0.0,0,0,0.7,0.7,0.4,255, 0, 0,150,0,1,0,1) -- Desenha a marker no chão.

                if dist <= 1 then
                    if IsControlJustPressed(0,38) then

                        vRP.playAnim(false, {{"anim@heists@prison_heistig1_p1_guard_checks_bus", "loop"}}, true)

                        TriggerEvent('progress', 5000, 'Anunciando Peças')
                        Wait(5000)

                        ClearPedTasks(ped)

                        TriggerEvent('Notify','sucesso','Parabéns! Você vendeu as peças no mercado livre.')

                        vSERVER.GerarPagamento(placa, modelHash)

                        local classe = GetVehicleClass(veh) -- Pegar classe do veículo

                        -- Para garantir que o veículo será deletado
                        DeleteVehicle(veh)

                        Wait(8000)
                        -- Entregar itens extra
                        for vx,vy in pairs(Config.itens_extra) do

                            if classe ~= 8 then -- Se for CARRO
                                if vx >= 1 and vx <= 4 then
                                    vSERVER.entregaItem(vy.nome)
                                    Wait(100)
                                end
                            else -- MOTO
                                if vx > 4 then
                                    vSERVER.entregaItem(vy.nome)
                                    Wait(100)
                                end
                            end

                        end

                        TriggerEvent('Notify','importante','O veículo foi totalmente desmontado pela sua equipe. Você recebeu o restante das peças.')
                        
                        vendendo = false
                        reseta()

                    end
                end


            end

        end

        Citizen.Wait(thor)
    end


end)

------------------------------------------------------------
-- CANCELAR DESMANCHE (TECLA F7)
------------------------------------------------------------
Citizen.CreateThread(function()

    while true do

        local thor = 1000

        if desmanchando then

            thor = 1
            
            -- Se pressionar (F7)
            if IsControlJustPressed(0,168) then
                if veh then -- Se veículo existir
                    FreezeEntityPosition(veh,false) -- Descongelar veículo
                end
                vendendo = false
                reseta()
                TriggerEvent('Notify','importante','Você pressionou a tecla (<b>F7</b>). O desmanche foi cancelado.')
            end

        end

        Citizen.Wait(thor)
    end

end)


----------------------------------------------------------------------------------------
-- FUNÇÕES !!!
----------------------------------------------------------------------------------------

-- FUNÇÃO PARA INICIAR O PROCESSO DE DESMANCHE
-- Recebe o 'index' como parametro
-- O index representa em qual local da lista da Config o veículo está sendo desmanchado
function iniciarProcesso(index)

    local ped = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(ped))

    -- Se player estiver dentro de um veículo ou entrando em um.
    if IsPedInAnyVehicle(ped,true) then

        -- Desenha a marcação no chão
        DrawMarker(27,Config.coordenadas_locais_desmanche[index].x,Config.coordenadas_locais_desmanche[index].y,Config.coordenadas_locais_desmanche[index].z-0.96,0,0,0,0,0,0,4.1,4.1,0.5,255,255,255,100,0,0,0,1)

        if Vdist(x,y,z,Config.coordenadas_locais_desmanche[index].x,Config.coordenadas_locais_desmanche[index].y,Config.coordenadas_locais_desmanche[index].z) <= 2 then

            -- Desenhar o texto na tela
            desenharTextoNaTela("~w~Pressione ~g~[E] ~w~para ~r~DESMANCHAR ~w~o veículo.")

            -- Se o player pressionar a tecla 'E'
            if IsControlJustPressed(0,38) then

                -- Pegar dados do veículo
                veh = GetVehiclePedIsIn(ped, false)
                placa = GetVehicleNumberPlateText(veh)
                nomeCarro = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                modeloCarro = GetLabelText(nomeCarro)

                -- Se o player tiver permissão para desmanchar
                if vSERVER.checkPermission(Config.permissao) then

                    -- Se o player estiver sentado no assento do motorista
                    if GetPedInVehicleSeat(veh,-1) == ped then

                        modelHash = GetEntityModel(veh)

                        if vSERVER.checkVeh(modelHash) then -- Verifica se o veículo está na lista das configs
                        
                            -- Congelar veículo na posição atual
                            FreezeEntityPosition(veh, true)

                            TriggerEvent("Notify","importante","Você iniciou o processo de desmanche, pegue as ferramentas ao lado!")

                            desmanchando = true

                        else
                            TriggerEvent("Notify","importante","Este veículo não pode ser desmanchado.")
                        end

                    else
                        TriggerEvent("Notify","importante","Vá para o assento do motorista para iniciar o processo.")
                    end

                else
                    TriggerEvent("Notify","importante","Você não possui permissão para desmanchar veículos!")
                end

            end

        end

    end

end

-- PARA ESCREVER TEXTO NA PARTE INFERIOR DA TELA
function desenharTextoNaTela(texto)

    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.5)
    SetTextColour(128, 128, 128, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(0, 0, 0, 1, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(texto)
    DrawText(0.35, 0.83)

end

-- PARA DESENHAR O TEXTO 3D
function DrawText3D(x,y,z, text, scl, font) 
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)

	local scale = (1/dist)*scl
	local fov = (1/GetGameplayCamFov())*100
	local scale = scale*fov
	if onScreen then
		SetTextScale(0.0*scale, 1.1*scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
	end
end

-- PARA RESETAR AS VARIÁVEIS 
function reseta()

    veh = nil

    desmanchando = false
    pegou_ferramentas = false
    pegou_peca = false
    pegou_item = false

    quantidade_de_pecas_do_veiculo = 0
    quantidade_pecas_removidas = 0
    modelHash = 0


    PecasRemovidas = {}

    itemNaMao = ''
    placa = ''
    nomeCarro = ''
    modeloCarro = ''

end


local npcEntities = {}

Citizen.CreateThread(function()
    while true do
        local sleep = 1000 -- Otimização
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for i, loc in ipairs(Config.vendaNPC_location) do
            local distance = #(playerCoords - vector3(loc.x, loc.y, loc.z))

            if distance < 10.0 then
                if not npcEntities[i] or not DoesEntityExist(npcEntities[i]) then
                    -- Solicitar o modelo do NPC
                    local npcHash = GetHashKey("s_m_y_dealer_01")
                    RequestModel(npcHash)
                    while not HasModelLoaded(npcHash) do
                        Wait(10)
                    end

                    -- Criar o NPC
                    npcEntities[i] = CreatePed(4, npcHash, loc.x, loc.y, loc.z - 1.0, loc.heading, false, true)
                    SetEntityInvincible(npcEntities[i], true) -- NPC invencível
                    SetBlockingOfNonTemporaryEvents(npcEntities[i], true) -- Impede que o NPC reaja
                    FreezeEntityPosition(npcEntities[i], true) -- Congela o NPC no local
                end
            else
                -- Remover NPC se estiver longe
                if npcEntities[i] and DoesEntityExist(npcEntities[i]) then
                    DeleteEntity(npcEntities[i])
                    npcEntities[i] = nil
                end
            end
        end

        Wait(sleep)
    end
end)

-- Função para interação com o NPC
Citizen.CreateThread(function()
    while true do
        local sleep = 1000 -- Otimização
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for i, loc in ipairs(Config.vendaNPC_location) do
            if npcEntities[i] and DoesEntityExist(npcEntities[i]) then
                local distance = #(playerCoords - vector3(loc.x, loc.y, loc.z))

                if distance < 3.0 then
                    sleep = 5 -- Reduz o tempo de espera para interação
                    DrawText3D(loc.x, loc.y, loc.z + 1.0, "[E] Falar com o NPC") -- Exibe a mensagem de interação

                    if IsControlJustReleased(0, 38) then -- Tecla 'E'
                        TriggerServerEvent("vendaNPC:execute") -- Envia evento para o servidor
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Função para desenhar texto 3D
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local scale = 0.35
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end


function ShowHelpNotification(msg)
    AddTextEntry('HelpNotification', msg)
    BeginTextCommandDisplayHelp('HelpNotification')
    EndTextCommandDisplayHelp(0, false, true, -1)
end
