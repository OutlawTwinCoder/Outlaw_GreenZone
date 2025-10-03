fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'iamlation'
description 'A greenzones script to create controlled areas on the map for FiveM'
version '1.0.1'

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

ui_page 'ui/index.html'

files {
    'locales/*.json',
    'ui/index.html',
    'ui/script.js',
    'ui/style.css'
}

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

ox_libs {
    'locale',
    'math'
}