#!/usr/bin/env lua

-- lua-round-up, Gather all dependencies of Lua module together
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local function fileExists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function dirExists(name)
    local renamed = os.rename(name, name)
    return renamed
end

local function mkDir(dir)
    local parts = {}
    for part in dir:gmatch('([^/]+)') do
        table.insert(parts, part)
        local separator = package.config:sub(1, 1)
        local path = table.concat(parts, separator)
        if not dirExists(path) then
            os.execute("mkdir " .. path)
        end
    end
end

local function copyFile(old_path, new_path)
    local new_dir = new_path:match('.*/')
    mkDir(new_dir)
    local f = assert(io.open(old_path, "rb"))
    local data = f:read('*all')
    f:close()
    local f = assert(io.open(new_path, "wb"))
    f:write(data)
    f:close()
end

local function searchModule(name, path)
    name = name:gsub('%.', '/')
    for p in path:gmatch("([^;]+)") do
        local fname = p:gsub('%?', name)
        if fileExists(fname) then
            return fname, p
        end
    end
end

local function appendToFile(fname, text)
    local f = assert(io.open(fname, "a"))
    f:write(text)
    f:close()
end

local function makeNewName(name, fname, pattern)
    local suffix = pattern:match('%?(.*)')
    return 'single-dir-out/modules/' ..
        name:gsub('%.', '/') .. suffix
end

local function copyModule(name, path, mode)
    local fname, pattern = searchModule(name, path)
    assert(fname, "Can't find module " .. name)
    local new_path = makeNewName(name, fname, pattern)
    copyFile(fname, new_path)
    appendToFile('single-dir-out/list.txt',
        mode  .. ' ' .. name .. ' ' .. new_path .. '\n')
end

local function myLoader(original_loader, path, mode)
    return function(name)
        local f = original_loader(name)
        if type(f) == "function" then
            if mode == "all-in-one" then
                name = name:match('^([^.]+)')
            end
            copyModule(name, path, mode)
        end
        return f
    end
end

-- package.loaders (Lua 5.1), package.searchers (Lua >= 5.2)
local searchers = package.searchers or package.loaders

local lua_searcher = searchers[2]
local c_searcher = searchers[3]
local allinone_searcher = searchers[4]

local function replaceSearchers()
    searchers[2] = myLoader(lua_searcher, package.path, "Lua")
    searchers[3] = myLoader(c_searcher, package.cpath, "C")
    searchers[4] = myLoader(allinone_searcher, package.cpath,
        "all-in-one")
end

local function restoreSearchers()
    searchers[2] = lua_searcher
    searchers[3] = c_searcher
    searchers[4] = allinone_searcher
end

local BASH_CODE = [[
# SDO = single-dir-out
SDO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

export LUA_PATH="$SDO/modules/?.lua;$LUA_PATH"
export LUA_PATH="$SDO/modules/?/init.lua;$LUA_PATH"
export LUA_CPATH="$SDO/modules/?.so;$LUA_CPATH"

exec lua $SDO/%s "$@"
]]

local function makeBashScript(base_name)
    local bash_script = "single-dir-out/" .. base_name .. ".sh"
    local f = io.open(bash_script, "w")
    f:write(BASH_CODE:format(base_name))
    f:close()
    os.execute("chmod +x " .. bash_script)
end

if not arg then
    -- this file was loaded with "lua -l single-dir"
    replaceSearchers()
else
    -- called as a program
    if not dirExists("single-dir-out") then
        print("Run lua -l single-dir your-script.lua")
    else
        local arg = {...}
        local lua_file = arg[1]
        if not lua_file or not fileExists(lua_file) then
            print("Usage: single-dir script.lua")
        else
            local base_name = lua_file:match("([^/\\]+)$")
            local new_name = "single-dir-out/" .. base_name
            copyFile(lua_file, new_name)
            makeBashScript(base_name)
        end
    end
end
