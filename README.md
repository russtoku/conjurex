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
- Have a different client implementation in parallel with the one in Conjure.

## About me

- Contributed some improvements to the **Python** client.
- Created the **SQL** and **snd-s7** clients.
- Helped with the [migration](https://github.com/Olical/conjure/discussions/605)
of Conjure off of [Aniseed](https://github.com/Olical/aniseed) and onto
[nfnl](https://github.com/Olical/nfnl).

## Python client

The original Python client was created by someone else.

I contributed small changes to make evaluating Python *forms* (statements, etc.)
easier. From the language user's perspective, things should *just work*. A large
challenge of this comes from Python not being a `Lisp` language.

Another problem with the Python client is how it deals with the notion of
`return value` vs `printed output`. I see a disconnect between what you see in
your buffer and what you see when you type things directly into a REPL. I want
to close that gap so you don't need to have the HUD (heads-up display) or the
Conjure log buffer opened.

### How to use this Python client

- Add it to your plugin manager's configuration and install it.
- Configure your Conjure plugin to:
    - Use `conjurex.client.python.stdio` as the filetype handler for Python files.
        ```lua
        vim.g["conjure#filetype#python"] = "conjurex.client.python.stdio"
        ```


## Elixir client

Brandon Pollack created an initial Elixir client in response to [Issue #635,
Elixir support?](https://github.com/Olical/conjure/issues/635). I created this
implementation based on his [add-elixir-client
branch](https://github.com/brandonpollack23/conjure/tree/add-elixir-client) in
his fork of Conjure but started with the Scheme client.

This is a proof of concept to demonstrate that you can create a new Conjure
client without having it merged into the main Conjure codebase.

### How to use this Elixir client

- Add it to your plugin manager's configuration and install it (clones this
repo).
- Configure your Conjure plugin to:
    - Add the `elixir` filetype.

    ```lua
        vim.g["conjure#filetypes"] = { "clojure", "fennel", "hy", "racket", "scheme", "lua", "lisp", "python", "rust", "sql", "javascript", "elixir" }
    ```

    - Use `conjurex.client.elixir.stdio` as the filetype handler for Elixir
    files.

        ```lua
        vim.g["conjure#filetype#elixir"] = "conjurex.client.elixir.stdio"
        ```

