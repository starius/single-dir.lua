-- single-dir.lua, Gather all dependencies of Lua module together
-- Copyright (C) 2015 Boris Nagaev
-- See the LICENSE file for terms of use.

local single_dir = {}

function single_dir.fileExists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function single_dir.dirExists(name)
    local renamed = os.rename(name, name)
    return renamed
end

function single_dir.mkDir(dir)
    local parts = {}
    for part in dir:gmatch('([^/]+)') do
        table.insert(parts, part)
        local separator = package.config:sub(1, 1)
        local path = table.concat(parts, separator)
        if not single_dir.dirExists(path) then
            os.execute("mkdir " .. path)
        end
    end
end

function single_dir.copyFile(old_path, new_path)
    local new_dir = new_path:match('.*/')
    single_dir.mkDir(new_dir)
    local f = assert(io.open(old_path, "rb"))
    local data = f:read('*all')
    f:close()
    local f = assert(io.open(new_path, "wb"))
    f:write(data)
    f:close()
end

function single_dir.searchModule(name, path)
    name = name:gsub('%.', '/')
    for p in path:gmatch("([^;]+)") do
        local fname = p:gsub('%?', name)
        if single_dir.fileExists(fname) then
            return fname, p
        end
    end
end

function single_dir.appendToFile(fname, text)
    local f = assert(io.open(fname, "a"))
    f:write(text)
    f:close()
end

function single_dir.makeNewName(name, fname, pattern)
    local suffix = pattern:match('%?(.*)')
    return 'single-dir-out/modules/' ..
        name:gsub('%.', '/') .. suffix
end

function single_dir.copyModule(name, path, mode)
    local fname, pattern = single_dir.searchModule(name, path)
    assert(fname, "Can't find module " .. name)
    local new_path = single_dir.makeNewName(name, fname, pattern)
    single_dir.copyFile(fname, new_path)
    single_dir.appendToFile('single-dir-out/list.txt',
        mode  .. ' ' .. name .. ' ' .. new_path .. '\n')
end

function single_dir.myLoader(original_loader, path, mode)
    return function(name)
        local f = original_loader(name)
        if type(f) == "function" then
            if mode == "all-in-one" then
                name = name:match('^([^.]+)')
            end
            single_dir.copyModule(name, path, mode)
        end
        return f
    end
end

-- package.loaders (Lua 5.1), package.searchers (Lua >= 5.2)
local searchers = package.searchers or package.loaders

local lua_searcher = searchers[2]
local c_searcher = searchers[3]
local allinone_searcher = searchers[4]

function single_dir.replaceSearchers()
    searchers[2] = single_dir.myLoader(lua_searcher,
        package.path, "Lua")
    searchers[3] = single_dir.myLoader(c_searcher,
        package.cpath, "C")
    searchers[4] = single_dir.myLoader(allinone_searcher,
        package.cpath, "all-in-one")
end

function single_dir.restoreSearchers()
    searchers[2] = lua_searcher
    searchers[3] = c_searcher
    searchers[4] = allinone_searcher
end

-- this file was loaded with "lua -l single-dir"
single_dir.replaceSearchers()

return single_dir
