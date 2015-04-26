# single-dir.lua

[![Build Status](https://travis-ci.org/starius/single-dir.lua.svg?branch=master)](https://travis-ci.org/starius/single-dir.lua)

Gather all dependencies of Lua module together

## Usage

```bash
$ lua -l single-dir your-application.lua
```

## Description

All C and Lua modules used by your application are copied to
directory "single-dir-out/modules". It can be used as a
distribution package. To run your Lua application using modules
from directory "single-dir-out/modules", set `LUA_PATH` and
`LUA_CPATH` as follows:

```bash
$ export LUA_PATH="modules/?.lua;modules/?/init.lua"
$ export LUA_CPATH="modules/?.so"
$ lua your-application.lua
```

Replace `modules` with absolute path to that directory.
