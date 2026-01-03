# conjurex - Experimental clients for [Conjure](https://github.com/Olical/conjure)

This repo is for seeing what works for me. It's not part of Conjure so I'm free
to make things work for my needs without worrying about the main Conjure
clients.

It's also an example of how to make your own Conjure client for your favorite programming
language. After cloning the repo, you can copy another language client like the Ruby
one and modify it for your programming language.

After generating the tags file (`:helptags doc` in the repo directory), you should be able
to use `:he conjurex` to access the help documentation for Conjurex clients.


## Goals

- Find out what works for me (the owner of this repo).
- Smooth integration with Conjure without being included in Conjure.
- Learn more about about Fennel, Lua, and writing Neovim plugins.
- Write tests using `busted` and `luaasert` to provide safety nets during my
experiments.
- Make it easy for others to test drive these clients with Conjure.
- Contribute to Conjure if things work out.
- Have a different client implementation in parallel with the one in Conjure.

## About me

- Contributed some improvements to the **Python** client.
- Created the **SQL** and **snd-s7** clients.
- Helped with the [migration](https://github.com/Olical/conjure/discussions/605)
of Conjure off of [Aniseed](https://github.com/Olical/aniseed) and onto
[nfnl](https://github.com/Olical/nfnl).

## Clients

### Ruby

*01/02/2026: The code for this client was merged into
[Conjure](https://github.com/Olical/conjure) with [commit 5c69263](https://github.com/Olical/conjure/commit/5c692630257a02696dec59adcef4127f7cd11b62).*


### Elixir

*01/02/2026: The code for this client was merged into
[Conjure](https://github.com/Olical/conjure) with [commit 6770556](https://github.com/Olical/conjure/commit/67705566318002cc0a88b075f695518a43aa0ca7).*


### Python

*Broken: still a work in progress!*

The original Python client was created by someone else.

I contributed small changes to make evaluating Python *forms* (statements, etc.)
easier. From the language user's perspective, things should *just work*. The big
challenge for this client comes from Python not being a `Lisp` language.

So, the Python client has to deal with the notion of `return value` vs `printed
output`. I see a gap between what you see in your buffer and what you see when
you type things directly into a REPL. I want to close that gap so you don't need
to have the HUD (heads-up display) or the Conjure log buffer opened.

#### How to use this Python client

- Add it to your plugin manager's configuration and install it.
- Configure your Conjure plugin to:
    - Use `conjurex.client.python.stdio` as the filetype handler for Python files.
        ```lua
        vim.g["conjure#filetype#python"] = "conjurex.client.python.stdio"
        ```

