fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OutlawTwin Studio'
description 'TwinCoder Outlaw GreenZone - stylish safe-zones with bilingual UI for FiveM'
version '2.0.0'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

files {
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

ox_libs {
    'locale',
    'math'
}