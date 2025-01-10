
vRP = module("vrp", "lib/Proxy").getInterface("vRP")
vRPclient = module("vrp", "lib/Tunnel").getInterface("vRP")
thor = {}
module("vrp", "lib/Tunnel").bindInterface("vrp_desmanche", thor)
vCLIENT = module("vrp", "lib/Tunnel").getInterface("vrp_desmanche")

-- Adicione o vRP.prepare aqui
vRP._prepare("updatestatusvec", "UPDATE vrp_user_veiculos SET status = @status WHERE user_id = @user_id AND veiculo = @veiculo")

function SendWebhookMessage(webhook, message)
    if webhook ~= nil and webhook ~= "" then
        PerformHttpRequest(webhook, function(err, text, headers) end, "POST", json.encode({content = message}), {["Content-Type"] = "application/json"})
    end
end

function thor.checkVeh(hash)
    for _, veiculo in pairs(vehConfig.listaVeiculos) do
        if veiculo.hash == hash then
            return true
        end
    end
    return false
end

function thor.checkPermission(permission)
    local source = source
    return vRP.hasPermission(vRP.getUserId(source), permission)
end

function thor.entregaItem(item)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        vRP.giveInventoryItem(user_id, item, 1)
        return true
    end
    return false
end

function thor.removeItem(item)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        vRP.tryGetInventoryItem(user_id, item, 1)
    end
end

function thor.GerarPagamento(placa, hash)
    local source = source
    local user_id = vRP.getUserId(source)
  
    for _, veiculo in pairs(vehConfig.listaVeiculos) do
        if veiculo.hash == hash then
            local valor = veiculo.valor
            local multas = valor * 0.3 -- Exemplo de cálculo de multas, você pode ajustar de acordo com a lógica desejada
      
            vRP.giveInventoryItem(user_id, "dirty_money", valor)
      
            local puser_id = vRP.getUserByRegistration(placa)
            local rows = vRP.query("vRP/get_veiculos_status", {user_id = user_id, veiculo = veiculo.name})
            if puser_id and vRP.getUserSource(puser_id) then
                vRP._execute("updatestatusvec", { status = 1, user_id = user_id, veiculo = veiculo.name })      
                TriggerClientEvent("Notify", vRP.getUserSource(puser_id), "aviso", "AVISO SEGURADORA: Seu veículo foi desmanchado. Você deverá pagar uma taxa significativa para recuperar o veículo: <b>" .. veiculo.name .. "</b>.")
                local vehicle = NetworkGetEntityFromNetworkId(veiculo.networkId)
                if DoesEntityExist(vehicle) then
                    DeleteVehicle(vehicle)
                end                
                local logMessage = [[
                ```prolog
                [PASSAPORTE]: ]] .. user_id .. [[
                
                [NOME]: ]] .. vRP.getUserIdentity(user_id).nome .. " " .. vRP.getUserIdentity(user_id).sobrenome .. [[
                
                [DESMANCHOU]: ]] .. veiculo.name .. [[
                
                [PLACA]: ]] .. placa .. [[
                
                [E RECEBEU]: ]] .. vRP.format(valor) .. " " .. os.date("%d/%m/%y - %H:%M:%S") .. [[
                ```]]

                SendWebhookMessage(Config.webhookdesmanche, logMessage)
            end
      
            TriggerClientEvent("vrp_sound:source", source, "coins", 0.3)
      
            return
        end
    end
end

function thor.vendaNPC(item)
    local source = source
    local user_id = vRP.getUserId(source)
  
    if vRP.getInventoryItemAmount(user_id, item.nome) > 0 then
        local valorTotal = item.valor * vRP.getInventoryItemAmount(user_id, item.nome)
        vRP.giveInventoryItem(user_id, "dirty_money", valorTotal)
        TriggerClientEvent("Notify", source, "sucesso", "Você vendeu " .. vRP.getInventoryItemAmount(user_id, item.nome) .. " peças por <b>R$" .. valorTotal .. ",00</b>")
    else
        TriggerClientEvent("Notify", source, "importante", "Você não possui peças úteis para venda.")
    end
end

-- ... (outras funções existentes)



RegisterServerEvent("vendaNPC:execute")
AddEventHandler("vendaNPC:execute", function()
    local source = source
    local user_id = vRP.getUserId(source)

    if user_id then
        local totalVendido = 0

        for _, item in pairs(Config.itens_extra) do
            local quantidade = vRP.getInventoryItemAmount(user_id, item.nome)
            if quantidade > 0 then
                local total = quantidade * item.valor
                totalVendido = totalVendido + total
                vRP.tryGetInventoryItem(user_id, item.nome, quantidade)
            end
        end

        if totalVendido > 0 then
            vRP.giveInventoryItem(user_id, "dirty_money", totalVendido)
            TriggerClientEvent("Notify", source, "sucesso", "Você vendeu as peças por R$" .. totalVendido .. ",00.")
            TriggerClientEvent("pecas_vendidas",-1,"venda")
        else
            TriggerClientEvent("Notify", source, "importante", "Você não possui peças úteis para vender.")
        end
    end
end)
