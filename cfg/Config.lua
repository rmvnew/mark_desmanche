Config = {
    webhookdesmanche = "https://discordapp.com/api/webhooks/1327363848528724132/utGA3CVZQqrEUWmEVrlAAmgACicTMu2ln4bn84ZUCjPkN99_k3cIU5PkhIU4OXWZFGxn", -- Link do webhook


    permissao = "admin.permissao", -- Permissão para desmanchar

    tempo_remover_pecas = 3000, -- Tempo em milisegundos que o player demora para remover a peça do veículo

    --Local onde o carro deve ser colocado para ser desmanchado
    coordenadas_locais_desmanche = {
        
        [1] = { ['x'] = 480.95, ['y'] = -1322.82, ['z'] = 29.2,},  -- SUL
        [2] = { ['x'] = 1533.84, ['y'] = 3534.98, ['z'] = 35.37 }, -- NORTE
    },

    -- Local onde o player pegará as ferramentas para iniciar o serviço (o ['h'] é a direção que o player está olhando)
    coordenadas_locais_ferramentas = {
        [1] = { ['x'] = 475.61, ['y'] = -1310.34, ['z'] = 29.2, ['h'] = 310.34 }, -- SUL 
        [2] = { ['x'] = 1532.46, ['y'] = 3533.0, ['z'] = 35.37, ['h'] = 34.44 }, -- NORTE
    },

    -- Local onde o player levará as peças removidas do carro (o ['h'] é a direção que o player está olhando)
    coordenadas_locais_guardarPecas = {
        [1] = { ['x'] = 481.8, ['y'] = -1326.19, ['z'] = 29.2, ['h'] = 205.04 }, -- SUL
        [2] = { ['x'] = 1544.6, ['y'] = 3538.65, ['z'] = 35.37, ['h'] = 295.01 }, -- NORTE
    },

    -- local de desmanche o player poderá vender as peças no local de venda abaixo.
    coordenadas_locais_venda = {
        [1] = { ['x'] = 472.2, ['y'] = -1310.83, ['z'] = 29.22 }, -- SUL
        [2] = { ['x'] = 1556.25, ['y'] = 3523.3, ['z'] = 36.11 }, -- NORTE
    },

    -- Bom, pode ser que no seu servidor os nomes dos itens sejam diferentes. Neste caso terá que mexer aqui:
    itens = {
        ['rodaDeCarro'] = "rodacarro",
        ['portaDeCarro'] = "portacarro",
        ['rodaDeMoto'] = "rodamoto",
    },

    -- Itens recebidos após o término do desmanche esses itens podem ser removidos.
    itens_extra = {
        -- DE 1 À 4 PARA CARROS
        [1] = { ['nome'] = "discofreio", ['valor'] = 3000 },
        [2] = { ['nome'] = "parachoque", ['valor'] = 3000 },
        [3] = { ['nome'] = "volante", ['valor'] = 3000 },
        [4] = { ['nome'] = "motorcarro", ['valor'] = 3000 },

        -- RESTANTE PARA MOTOS
        [5] = { ['nome'] = "motormoto", ['valor'] = 3000 },
        
    },

    props = {
        ['portas'] = 'imp_prop_impexp_car_door_04a',
        ['rodas'] = 'prop_tornado_wheel',
    },

    vendaNPC_location = {
        [1] = {x = 1548.7, y = 3513.14, z = 35.99, heading = 304.64}, --Norte
        [2] = {x = 473.7, y = -1313.96, z = 29.2, heading = 289.64} --Norte
    }

}