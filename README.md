# conjurex - Experimental clients for [Conjure](https://github.com/Olical/conjure)

This repo is for seeing what works for me. It's not part of Conjure so I'm free
to make things work for my needs without worrying about the main Conjure
clients.

## Goals

- Find out what works for me (the owner of this repo).
- Smooth integration with Conjure without being included in Conjure.
- Learn more about about Fennel, Lua, and writing Neovim plugins.
- Write tests using `busted` and `luaasert` to provide safety nets during my
experiments.
- Make it easy for others to test drive these clients with Conjure.
- Contribute to Conjure if things work out.

## About me

I've:
- Contributed some improvements to the **Python** client.
- Created the **SQL** and **snd-s7** clients.
- Helped with the [migration](https://github.com/Olical/conjure/discussions/605)
of Conjure off of [Aniseed](https://github.com/Olical/aniseed) and onto
[nfnl](https://github.com/Olical/nfnl).

## Python client

The original Python client was created by someone else. I contributed small
changes to make evaluating Python *forms* easier and more like what one would
expect.

One of the things that I don't like about the existing [Python
client](https://github.com/Olical/conjure/blob/master/fnl/conjure/client/python/stdio.fnl)
as of 09/24/2024 (master branch @6d2bc7f) is the notion of return value vs
printed output. The first thing I want to do is address this. I think that the
way things are handled are confusing and not what is expected if you type things
into the Python command line REPL directly.

### How to use this Python client

Have your plugin manager clone this repo and configure your Conjure plugin to
use `conjurex.client.python.stdio` as the filetype handler for Python files.

Add this to a Fennel configuration file (assumes you are using `nfnl` to
automatically compile .fnl to .lua):

```
(tset vim.g :conjure#filetype#python :conjurex.client.python.stdio)
```

Or in a Lua configuration file:

```lua
vim.g["conjure#filetype#python"] = "conjurex.client.python.stdio"
```

## SQL client

When I wrote the SQL client, I used [PostgresQL](https://www.postgresql.org/)
while developing the client. The
[psql](https://www.postgresql.org/docs/16/app-psql.html) command line program is
the REPL that I worked with. It has meta-commands that allow you to interact
with the `psql` client to get information about tables, indexes, etc. (database
objects).

[Commit
9346878](https://github.com/Olical/conjure/commit/934687860a71d1d03e569ce11f880a4d404e69aa),
*Default the psql command to something generic and append a ; to each
evaluation*, made a change to the client that takes away the ability use
meta-commands with `psql`. I need to be able to do this so my first order of
business it to make it optional. Of course, I think that automatically appending
the SQL statement terminator should be opt-in not the default.

