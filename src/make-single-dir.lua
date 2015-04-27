#!/usr/bin/env lua

-- lua-round-up, Gather all dependencies of Lua module together
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local single_dir = require "single-dir"

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
    end
end
