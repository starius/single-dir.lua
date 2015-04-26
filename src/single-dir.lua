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
        local path = table.concat(parts, '/')
        if not dirExists(path) then
            os.execute("mkdir " .. path)
        end
    end
end

local function copyFile(old_path, new_path)
    local new_dir = new_path:match('.*/')
    mkDir(new_dir)
    local f = assert(io.open(old_path, "r"))
    local data = f:read('*all')
    f:close()
    local f = assert(io.open(new_path, "w"))
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

local function makeNewName(name, fname, pattern)
    local suffix = pattern:match('%?(.*)')
    return 'modules/' .. name:gsub('%.', '/') .. suffix
end

local function copyModule(name, path)
    local fname, pattern = searchModule(name, path)
    assert(fname, "Can't find module " .. name)
    local new_path = makeNewName(name, fname, pattern)
    copyFile(fname, new_path)
end

local function myLoader(original_loader, path, all_in_one)
    return function(name)
        local f = original_loader(name)
        if type(f) == "function" then
            if all_in_one then
                name = name:match('^([^.]+)')
            end
            copyModule(name, path)
        end
        return f
    end
end

-- change package loaders

local lua_loader = package.loaders[2]
local c_loader = package.loaders[3]
local aio_loader = package.loaders[4]

package.loaders[2] = myLoader(lua_loader, package.path)
package.loaders[3] = myLoader(c_loader, package.cpath)
package.loaders[4] = myLoader(aio_loader, package.cpath, true)
