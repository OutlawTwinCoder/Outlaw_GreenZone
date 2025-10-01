fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'OutlawTwinCoder'
description 'Outlaw Greenzones + Designer (final, tablet-style UI, transparency fixed)'
version '1.2.0'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'locales/en.json',
    'locales/fr.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}
