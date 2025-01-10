fx_version 'adamant'
game 'gta5'

dependency "vrp"

client_scripts {
    "@vrp/lib/utils.lua",
    'client.lua',
    'cfg/Config.lua'
}

server_scripts {
    "@vrp/lib/utils.lua",
    'server.lua',
    'cfg/veiculos.lua',
    'cfg/Config.lua'
}