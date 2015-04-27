#!/usr/bin/env lua

-- single-dir.lua, Gather all dependencies of Lua module together
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local single_dir = require "single-dir"

single_dir.restoreSearchers()

local BASH_CODE = [[
# SDO = single-dir-out
SDO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export LUA_PATH="$SDO/modules/?.lua;$LUA_PATH"
export LUA_PATH="$SDO/modules/?/init.lua;$LUA_PATH"
export LUA_CPATH="$SDO/modules/?.so;$LUA_CPATH"

exec lua $SDO/%s "$@"
]]

local BATCH_CODE = [[
@echo off
REM SDO = single-dir-out
set SDO=%~dp0

set LUA_PATH=$SDO\modules\?.lua;%LUA_PATH%
set LUA_PATH=$SDO\modules\?\init.lua;%LUA_PATH%
set LUA_CPATH=$SDO\modules\?.so;%LUA_CPATH%

lua $SDO\base_name %*
]]

local PRELOAD_CODE = [[
package.preload[%q] = function(...)
    %s
end
]]

local PRELOAD_BYTECODE = [[
package.preload[%q] = function(...)
    local loadstring = loadstring or load
    return loadstring(%q)(...)
end
]]

local function makeBashScript(base_name)
    local bash_script = "single-dir-out/" .. base_name .. ".sh"
    local f = io.open(bash_script, "w")
    f:write(BASH_CODE:format(base_name))
    f:close()
    os.execute("chmod +x " .. bash_script)
end

local function makeBatchScript(base_name)
    local batch_script = "single-dir-out/" .. base_name .. ".bat"
    local f = io.open(batch_script, "w")
    f:write((BATCH_CODE:gsub("base_name", base_name)))
    f:close()
end

local function makeLuaSingleFile()
    local modules = {}
    for line in io.lines("single-dir-out/list.txt") do
        local mode, name, fname = line:match("(%S+) (%S+) (%S+)")
        if mode == "Lua" then
            modules[name] = fname
        end
    end
    local f = io.open("single-dir-out/single-file.lua", "wb")
    for name, fname in pairs(modules) do
        local content = single_dir.readFile(fname)
        if content:byte(1, 1) == 27 then
            -- bytecode
            f:write(PRELOAD_BYTECODE:format(name, content))
        else
            f:write(PRELOAD_CODE:format(name, content))
        end
    end
    f:close()
end

if not single_dir.dirExists("single-dir-out") then
    print("Run lua -l single-dir your-script.lua")
else
    local arg = {...}
    local lua_file = arg[1]
    if not lua_file or not single_dir.fileExists(lua_file) then
        print("Usage: make-single-dir script.lua")
    else
        local base_name = lua_file:match("([^/\\]+)$")
        local new_name = "single-dir-out/" .. base_name
        single_dir.copyFile(lua_file, new_name)
        makeBashScript(base_name)
        makeBatchScript(base_name)
        makeLuaSingleFile()
    end
end
