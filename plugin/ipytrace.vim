if !has('python')
    finish
endif

if has("nvim")
    augroup Terminal
      au!
      au TermOpen * let g:last_terminal_job_id = b:terminal_job_id
    augroup END
endif

let g:vitrace_ipython_paste = 0
let g:vitrace_script_file=expand("<sfile>")
let g:configured_run_file = ''
" Spyder style
" nmap <silent> <F9> :py neo_terminal_send_selection()<CR>
nmap <silent> <F9> :py configure_and_run()<CR>
nmap <silent> <F10> :py run_configuration()<CR>

" pycharm style
nmap <silent> <A-S-E> :py terminal_send_selection()<CR>
vmap <silent> <A-S-E> :py terminal_send_selection()<CR>
" nmap <silent> <A-S-F10> :py configure_and_run()<CR>
" NAnmap <silent> <S-F10> :py run_configuration()<CR>
" nmap <C-Q> :py see_docs()<CR>

nmap <silent> <C-T> :py follow_trace()<CR>

command! TogglePasteMode  :py toggle_paste_mode()

python << endpython
import re
import os
import subprocess
import time
# sys.path.append(os.path.dirname(vim.eval("g:vitrace_script_file")))
configured_run_file = None


# neoterminal
def neo_terminal_send(lines):
    escaped_lines = [l.replace('"', r'\"') for l in lines]
    escaped_lines.append("\n")
    selected_text = '["{}"]'.format('","'.join(escaped_lines))
    runstr = ("call jobsend(g:last_terminal_job_id, {})\n".format(selected_text))
    print runstr
    vim.command(runstr)

# idevim
def set_register(reg, value):
    vim.command("let @%s='%s'" % (reg, value.replace("'", "''")))


# main
def toggle_paste_mode():
    paste_mode = int(vim.eval("g:vitrace_ipython_paste"))
    paste_mode = not paste_mode
    vim.command("let g:vitrace_ipython_paste = '{}zL'".format(int(paste_mode)))


def get_selected_lines():
    selected = vim.current.range
    lines = vim.current.buffer[selected.start:selected.end]
    # remove any extra indentation in python
    if vim.current.buffer.name.endswith(".py"):
        firstline = vim.current.buffer[selected.start]
        nindent = 0
        for i in xrange(0, len(firstline)):
            if firstline[i] == ' ':
                nindent += 1
            else:
                break
        if nindent > 0:
            pat = r'\s'*nindent
            lines = [re.sub('^{}zLzL'.format(pat), '', l) for l in lines]
    return lines


def terminal_send(lines):
    if vim.eval("has('nvim')"):
        neo_terminal_send(lines)
    else:
        tmux_terminal_send(lines)


def terminal_send_selection():
    lines = get_selected_lines()
    # print "paste mode", vim.eval("g:vitrace_ipython_paste")
    if vim.current.buffer.name.endswith(".py") and vim.eval("g:vitrace_ipython_paste")=="1":
        set_register("+", "\n".join(lines))
        terminal_send(["%paste\n"])
    else:
        terminal_send(lines)


def configure_and_run():
    configure_runtime()
    run_configuration()


def configure_runtime():
    vim.command("let g:configured_run_file = '{}'".format(vim.current.buffer.name))
    return vim.current.buffer.name


def run_configuration():
    vim.command(":silent! wa")
    configured_run_file = vim.eval("g:configured_run_file")
    if configured_run_file == '':
        configured_run_file = configure_runtime()
    print configured_run_file
    terminal_send(["run {}".format(configured_run_file)])


def follow_trace():
    """
    Attempt to follow pdb trace
    """
    # cursor position change doesn't reflect
    # vim.command("?-->")
    # vim.command("?<module>")
    cursor_line_number = vim.current.range.start
    finished = False
    line_number = ""
    filename = ""
    while cursor_line_number != 0 and not finished:
        line = vim.current.buffer[cursor_line_number]
        m = re.search("--> ([0-9]+)", line)
        if m:
            line_number = m.group(1)
        m = re.search("[^/]*(/.*?\.pyc?)", line)
        if m:
            filename = m.group(1)
            filename = filename.replace(".pyc",".py")
        if filename != "" and line_number != "":
            finished = True
        cursor_line_number -= 1
    print filename, line_number
    # use <Ctrl-v><Ctrl-W> to create the ^W type chars
    # vim.command(":normal l")
    vim.command(":normal j")
    vim.command(":e {}".format(filename))
    vim.command(":normal {}G".format(line_number))
    # stack.append("{}:{}".format(filename,m.group(1)))
    # stack += ["gF (<c-w>F split, <c-w> gF tab, all goto with line)"]


endpython
