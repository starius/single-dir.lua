# lua-round-up, Gather all dependencies of Lua module together
# Copyright (C) 2015 Boris Nagaev
# See the LICENSE file for terms of use.

test-linux:
	# Lua
	lua -l src/single-dir -e 'require "pl.utils"'
	# C
	lua -l src/single-dir -e 'require "cjson"'
	# All in one package
	lua -l src/single-dir -e 'require "posix.curses"'
	# test loading
	export LUA_PATH="modules/?.lua;modules/?/init.lua"
	export LUA_CPATH="modules/?.so"
	lua -e 'require "pl.utils"'
	lua -e 'require "cjson"'
	lua -e 'require "posix.curses"'
