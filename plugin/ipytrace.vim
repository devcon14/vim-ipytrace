" NOTE we can also use :term jupyter console straight
if !has('python')
    finish
endif

let g:ipytrace_ipython_paste = 0
let g:ipytrace_script_file=expand("<sfile>")
let g:configured_run_file = ''
" let g:ipytrace_nobind_keys = 1
" let g:terminal_scrollback_buffer_size = ?

augroup Terminal
  au!
  au TermOpen * set bufhidden=hide
  " au WinEnter term://* startinsert
augroup END

" spyder style keybindings
if !exists("g:ipytrace_nobind_keys")
    nnoremap <F2> :py popup_terminal_window()<CR>
    nnoremap <F3> :py custom_build_process()<CR>
    nnoremap <F4> :py open_terminal()<CR>
    nnoremap <F5> :py run_configuration()<CR>
    nnoremap <F9> :py terminal_send_selection()<CR>
    vnoremap <F9> :py terminal_send_selection()<CR>
    nnoremap <F6> :py configure_and_run()<CR>
    " cycle windows
    " nnoremap <F7> :exe normal "<C-W><p>"
    nnoremap <leader><F12> :py toggle_windows(reverse=True)<CR>
    nnoremap <F12> :py toggle_windows()<CR>

    " <C-I> :py see_object()

    nnoremap <leader>c :py run_cell(True)<CR>
    nnoremap <leader>ca :py run_cell(False)<CR>
    nnoremap <C-S> :py follow_trace()<CR>

    " terminal mappings
    tnoremap <A-space> <C-\><C-n>
    tnoremap <A-Left> <C-\><C-n><C-w>h
    tnoremap <A-Down> <C-\><C-n><C-w>j
    tnoremap <A-Up> <C-\><C-n><C-w>k
    tnoremap <A-Right> <C-\><C-n><C-w>l
    nnoremap <A-Left> <C-w>h
    nnoremap <A-Down> <C-w>j
    nnoremap <A-Up> <C-w>k
    nnoremap <A-Right> <C-w>l
    tnoremap <A-h> <C-\><C-n><C-w>h
    tnoremap <A-j> <C-\><C-n><C-w>j
    tnoremap <A-k> <C-\><C-n><C-w>k
    tnoremap <A-l> <C-\><C-n><C-w>l
    nnoremap <A-h> <C-w>h
    nnoremap <A-j> <C-w>j
    nnoremap <A-k> <C-w>k
    nnoremap <A-l> <C-w>l
    tnoremap <F5> <C-\><C-n>:py run_configuration()<CR>
    tnoremap <C-S> <C-\><C-n>:py follow_trace()<CR>
    tnoremap <C-o> <C-\><C-n><C-o>
    tnoremap <leader><F12> <C-\><C-n>:py toggle_windows(reverse=True)<CR>
    tnoremap <F12> <C-\><C-n>:py toggle_windows()<CR>
    tnoremap <C-b> <C-\><C-n><C-b>
    tnoremap {{ <C-\><C-n>{
    " tmap <leader><cr> <C-\><C-n><leader><cr>
end

" pycharm style keybindings
" nmap <silent> <A-S-E> :py terminal_send_selection()<CR>
" vmap <silent> <A-S-E> :py terminal_send_selection()<CR>
" nmap <silent> <A-S-F10> :py configure_and_run()<CR>
" NAnmap <silent> <S-F10> :py run_configuration()<CR>
" nmap <C-Q> :py see_docs()<CR>


command! TogglePasteMode  :py toggle_paste_mode()
command! CustomBuild  :py custom_build_process()

python << endpython
import re
import os
import subprocess
import time


def get_last_terminal_id():
    term_id_str = vim.eval("getbufvar('term:', 'terminal_job_id')")
    if term_id_str == '':
        return -1
    return int(term_id_str)


def to_visible_term():
    # get current tab
    tabnr = int(vim.eval('tabpagenr()')) - 1
    # print "tab", tabnr
    for winnr, win in enumerate(vim.tabpages[tabnr].windows):
        # print winnr, win
        if win.buffer.name.startswith("term"):
            # print win.buffer.name
            vim.command(":{}wincmd w".format(winnr + 1))
            return
    vim.command(":b term:")


def open_if_no_terminal():
    termid = get_last_terminal_id()
    if termid == -1:
        open_neo_terminal()
        neo_terminal_send(["jupyter console\n"])
        # neo_terminal_send(["bpython\n"])


# ===========
# neoterminal
# ===========
def neo_terminal_send(lines):
    escaped_lines = [l.replace('"', r'\"') for l in lines]
    escaped_lines.append("\n")
    selected_text = '["{}"]'.format('","'.join(escaped_lines))
    termid = get_last_terminal_id()
    runstr = ("call jobsend({}, {})\n".format(termid, selected_text))
    vim.command(runstr)


def open_neo_terminal():
    # vim.command(":normal sj")
    # vim.command(":normal vl")
    # NOTE we can use :term ipython directly as well
    vim.command(":terminal")


def popup_terminal_window():
    number_of_windows = vim.eval("winnr('$')")
    number_of_windows = int(number_of_windows)
    if number_of_windows > 1:
        vim.command(":normal l")
        vim.command(":q")
    else:
        # bring up existing term buffer in side window
        vim.command(":normal vl")
        vim.command(":b term")
        vim.command(":normal h")


# ======
# idevim
# ======
def set_register(reg, value):
    vim.command("let @%s='%s'" % (reg, value.replace("'", "''")))


# main
# ====
def toggle_windows(reverse=False):
    # buffer version
    if reverse:
        vim.command(":bp")
    else:
        vim.command(":bn")
    # window version
    # vim.command(":normal p")

    
def open_terminal():
    open_neo_terminal()


def run_cell(restore_cursor=False):
    if restore_cursor:
        (row, col) = vim.current.window.cursor
    vim.command(':?#%%?;/#%%/ :py terminal_send_selection()')
    selected = vim.current.range
    vim.current.window.cursor = (selected.end + 1, 0)
    if restore_cursor:
        vim.current.window.cursor = (row, col)


def toggle_paste_mode():
    paste_mode = int(vim.eval("g:ipytrace_ipython_paste"))
    paste_mode = not paste_mode
    vim.command("let g:ipytrace_ipython_paste = '{}'".format(int(paste_mode)))


def get_selected_lines():
    selected = vim.current.range
    # neovim
    lines = vim.current.buffer[selected.start:selected.end]
    # tmux
    # lines = vim.current.buffer[selected.start:selected.end+1]
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
            lines = [re.sub('^{}'.format(pat), '', l) for l in lines]
    return lines


def terminal_send(lines):
    neo_terminal_send(lines)
    # tmux_terminal_send(lines)


def terminal_send_selection():
    lines = get_selected_lines()
    # print "paste mode", vim.eval("g:ipytrace_ipython_paste")
    if vim.current.buffer.name.endswith(".py") and vim.eval("g:ipytrace_ipython_paste")=="1":
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


def reload_terminal():
    # terminal_send(["exit", "ipython"])
    # terminal_send(["exit", "jupyter console"])
    # terminal_send(["exit()", "bpython"])
    pass


def run_configuration():
    vim.command(":silent! wa")
    configured_run_file = vim.eval("g:configured_run_file")
    if configured_run_file == '':
        configured_run_file = configure_runtime()
    # print "configuredrun", configured_run_file
    open_if_no_terminal()
    # clear the console line if anything remains
    terminal_send(["i"])
    reload_terminal()
    # custom_build_process()
    terminal_send(["run {}".format(configured_run_file)])
    # terminal_send(["execfile('{}')".format(configured_run_file)])
    # vim.command(":normal j")
    # go_to_terminal()
    to_visible_term()
    vim.command(":startinsert")


def follow_trace():
    """
    Attempt to follow pdb trace
    """
    cursor_line_number = vim.current.range.start
    finished = False
    line_number = ""
    filename = ""
    while cursor_line_number != 0 and not finished:
        line = vim.current.buffer[cursor_line_number]
        m = re.search("-+> ([0-9]+)", line)
        if m:
            line_number = m.group(1)
        m = re.search("[^/]*(/.*?\.pyc?)", line)
        if m:
            filename = m.group(1)
            filename = filename.replace(".pyc",".py")
        if filename != "" and line_number != "":
            finished = True
        cursor_line_number -= 1
    # use <Ctrl-v><Ctrl-W> to create the ^W type chars
    # vim.command(":normal l")
    if filename != "" and line_number != "":
        # open split
        # vim.command(":normal j")
        vim.command(":e {}".format(filename))
        vim.command(":normal {}G".format(line_number))
    # stack.append("{}:{}".format(filename,m.group(1)))
    # stack += ["gF (<c-w>F split, <c-w> gF tab, all goto with line)"]


endpython
