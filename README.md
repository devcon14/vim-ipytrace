# vim-ipytrace

Plugin to interact with an ipython/jupyter terminal.
It provides:

* Basic run script / run selection interaction with your REPL.
* Follow ipython, ipdb stack traces in your terminal buffer.

Ok it started as a vim plugin but it currently only supports
running in a [neovim](http://neovim.io) terminal.

This uses the awesome neovim built in terminal.

If anyone needs it I might consider adding:

* Tmux support in vim.
* Other kernels like R.

Some basic keys:

Key   | Action
---   | ------
F5  | selects the current buffer and runs it in a terminal.
F6  | selects a different buffer to run.
F9  | executes the current line or selection.
C-S | inside a terminal will look backwards from the cursor for a stack trace line (--> xxx) and open it in a buffer.

## configuration

Variable | Usage
-------- | ---
g:ipytrace_ipython_paste | 1 or 0, to use %cpaste magic or not when running a selection.
g:ipytrace_nobind_keys   | set to 1 if you want to bind your own keymaps.

## limitations

Only supports one terminal open at a time.
