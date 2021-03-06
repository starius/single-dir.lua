-- single-dir.lua, Gather all dependencies of Lua module together
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

package = "single-dir.lua"
version = "dev-1"
source = {
    url = "git://github.com/starius/single-dir.lua.git"
}
description = {
    summary = "Gather all dependencies of Lua module together",
    homepage = "https://github.com/starius/single-dir.lua",
    license = "MIT",
}
dependencies = {
    "lua >= 5.1",
}
build = {
    type = "builtin",
    modules = {
        ['single-dir'] = 'src/single-dir.lua',
    },
    install = {
        bin = {
            ['make-single-dir'] = 'src/make-single-dir.lua',
        },
    },
}
