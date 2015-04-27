# single-dir.lua

[![License][]](LICENSE)
[![TravisStatus][]][Travis]
[![AppVeyorStatus][]][AppVeyor]

Gather all dependencies of Lua module together

## Usage

```bash
$ lua -l single-dir your-application.lua
```

## Description

All C and Lua modules used by your application are copied to
directory "single-dir-out/modules". Directory "single-dir-out/"
can be used as a distribution package. To run your Lua
application using modules from directory
"single-dir-out/modules", set `LUA_PATH` and `LUA_CPATH` as
follows:

```bash
$ export LUA_PATH="modules/?.lua;modules/?/init.lua"
$ export LUA_CPATH="modules/?.so"
$ lua your-application.lua
```

Replace `modules` with absolute path to that directory.

Create bash and batch scripts, which do this automatically
and run Lua module:

```bash
$ make-single-dir your-application.lua
```

Check directory "single-dir-out/" for bash and batch scripts.

File "single-dir-out/single-file.lua" is composed from all Lua
modules (including bytecode). It sets appropriate loaders in
`package.preload`. Require it or load with `-l` to get all Lua
dependencies ready to `require`.

[License]: http://img.shields.io/badge/License-MIT-brightgreen.svg
[Travis]: https://travis-ci.org/starius/single-dir.lua "Travis page"
[TravisStatus]: https://travis-ci.org/starius/single-dir.lua.svg
[AppVeyor]: https://ci.appveyor.com/project/starius/single-dir-lua "AppVeyor page"
[AppVeyorStatus]: https://ci.appveyor.com/api/projects/status/gkybptvp6vqjusgd?svg=true
