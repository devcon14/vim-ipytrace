" NOTE we can also use :term jupyter console straight
if !has('python')
    finish
endif

if has("nvim")
    augroup Terminal
      au!
      au TermOpen * let g:last_terminal_job_id = b:terminal_job_id|py enter_terminal()
      au TermOpen * set bufhidden=hide
      au BufDelete * :py delete_terminal()
      " automatic insert mode when enter
      " au WinEnter term://* startinsert
    augroup END
endif

let g:ipytrace_ipython_paste = 0
let g:ipytrace_script_file=expand("<sfile>")
let g:configured_run_file = ''
" let g:terminal_scrollback_buffer_size = ?

" spyder style keybindings
nnoremap <F4> :py open_terminal()<CR>
nnoremap <F5> :py run_configuration()<CR>
" nnoremap <F9> :py terminal_send_selection()<CR>
" vnoremap <F9> :py terminal_send_selection()<CR>
vnoremap <F5> :py terminal_send_selection()<CR>
nnoremap <F6> :py configure_and_run()<CR>
" cycle windows
" nnoremap <F7> :exe normal "<C-W><p>"
nnoremap <leader><F12> :py toggle_windows(reverse=True)<CR>
nnoremap <F12> :py toggle_windows()<CR>
nnoremap <F3> :py custom_build_process()<CR>

" <C-I> :py see_object()

nnoremap <leader>c :py run_cell(True)<CR>
nnoremap <leader>ca :py run_cell(False)<CR>
nnoremap <C-S> :py follow_trace()<CR>
nnoremap <F2> :py popup_terminal_window()<CR>

" pycharm style keybindings
" nmap <silent> <A-S-E> :py terminal_send_selection()<CR>
" vmap <silent> <A-S-E> :py terminal_send_selection()<CR>
" nmap <silent> <A-S-F10> :py configure_and_run()<CR>
" NAnmap <silent> <S-F10> :py run_configuration()<CR>
" nmap <C-Q> :py see_docs()<CR>

" terminal mappings
if has("nvim")
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
    tmap <leader><cr> <C-\><C-n><leader><cr>
endif

command! TogglePasteMode  :py toggle_paste_mode()
command! CustomBuild  :py custom_build_process()

python << endpython
import re
import os
import subprocess
import time
# sys.path.append(os.path.dirname(vim.eval("g:ipytrace_script_file")))
terminals = []

# TODO move to dotfiles
def dev_env():
    items = []
    for buf in vim.buffers:
        items.append(buf.name)
        for var in buf.vars:
            print var
    # TODO
    # b:terminal_job_id is the buffer var of the "current" buffer
    # getbufvar
    # :echo getbufvar(2, 'terminal_job_id')
    # bufname(id or name_matcher)
    '''
    for tab in vim.tabpages:
        for win in tab.windows:
            items.append(win.buffer.name)
    print items
    '''
    # vim.windows[1].width = 10
    # set, get
    # vim.vars['global_var'], vim.eval("g:global_var")
    # did I try TermClose, TermCreate au events?

def custom_build_process():
    terminal_send(["!jekyll build --source jekyll/"])

def enter_terminal():
    global terminals
    # .endswith("/bin/bash") is good indicator of useful term
    if vim.current.buffer.name.endswith("FZF"):
        return
    if "git" in vim.current.buffer.name.lower():
        return
    last_terminal_buffer_name = last_terminal_buffer_number = terminal_job_id = None
    current_tab = vim.eval('tabpagenr()')
    current_winnr = vim.eval('tabpagewinnr({})'.format(current_tab))
    try:
        terminal_job_id =  vim.eval("g:last_terminal_job_id")
    except Exception as e:
        pass
    for b in vim.buffers:
        if b.name.startswith("term"):
            last_terminal_buffer_name = b.name
            last_terminal_buffer_number = b.number
    terminals.append([current_tab, current_winnr, last_terminal_buffer_name, terminal_job_id, last_terminal_buffer_number, vim.current.buffer.name])

def prune_terminals():
    # if fzf runs it opens and closes a new terminal
    # we need to remove that from the list
    pruned_terminals = []
    for term in terminals:
        for b in vim.buffers:
            if term[2] == b.name:
                pruned_terminals.append(term)
    print pruned_terminals

def print_terminals():
    print terminals
    """
    for b in vim.buffers:
        print dir(b)
    """

def delete_terminal():
    print "delete", vim.current.buffer.name
    to_delete_id = -1
    for index, terminal in enumerate(terminals):
        if terminal[2] == vim.current.buffer.name:
            to_delete_id = index
    if to_delete_id != -1:
        del terminals[to_delete_id]
    """
    print vim.current.buffer.name
    marked_terminal = None
    for i, terminal in enumerate(terminals):
        if terminal[1] == vim.current.buffer.name:
            marked_terminal = i
    if marked_terminal:
        del terminals[marked_terminal]
    ##
    if vim.current.buffer.name.startswith("term"):
       vim.command("unlet g:last_terminal_job_id")
    """

def to_visible_term():
    # FIXME is this duplicating popup_terminal_window?
    # no that is for a quick key to show the win
    for winnr, win in enumerate(vim.windows):
        # print winnr
        if win.buffer.name.startswith("term"):
            vim.command(":{}wincmd w".format(winnr + 1))
            return True
    return False


def go_to_terminal():
    global terminals
    terminal = terminals[-1]
    """
    # This is the window version
    vim.command(":{}tabn".format(terminal[0]))
    # vim.command(":{}wincmd w".format(int(terminal[1]) + 1))
    vim.command(":{}wincmd w".format(terminal[1]))
    # FIXME this causes nvim to go crazy, use startinsert instead
    # vim.command(":normal i")
    # terminal_send(["i"])
    """
    if not to_visible_term():
        # buffer version
        vim.command(":call BufOpen({})".format(terminal[4]))


def get_last_terminal_id():
    if len(terminals) <= 0:
        raise "no terminals"
    else:
        return terminals[-1][3]
    """
    try:
        # return vim.eval("g:last_terminal_job_id")
    except Exception as e:
        raise e
    """


def open_if_no_terminal():
    try:
        print "last tid", get_last_terminal_id()
    except Exception as e:
        open_neo_terminal()
        neo_terminal_send(["jupyter console\n"])
        # neo_terminal_send(["ipython\n"])
        # neo_terminal_send(["%load_ext autoreload"])
        # neo_terminal_send(["%autoreload 2"])


# ====
# tmux
# ====
def tmux_terminal_send(lines):
    set_tmux_buffer("\n".join(lines)+"\n")
    subprocess.check_output(["tmux", "paste-buffer"])


def set_tmux_buffer(text):
    """
    Put text on the tmux buffer
    """
    process = subprocess.Popen(
        ["tmux", "load-buffer", "-"],
        stdin=subprocess.PIPE)
    process.stdin.write(text)
    process.stdin.close()
    process.wait()


def open_tmux_terminal(in_folder=None):
    subprocess.Popen(["gnome-terminal", "-e", "tmux"])
    time.sleep(2)
    # term opens in vim cwd, not the buffer directory but it's a good default


# ===========
# neoterminal
# ===========
def neo_terminal_send(lines):
    escaped_lines = [l.replace('"', r'\"') for l in lines]
    escaped_lines.append("\n")
    selected_text = '["{}"]'.format('","'.join(escaped_lines))
    runstr = ("call jobsend({}, {})\n".format(get_last_terminal_id(), selected_text))
    vim.command(runstr)


def open_neo_terminal():
    # vim.command(":normal sj")
    # vim.command(":normal vl")
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
def is_nvim():
    if vim.eval("has('nvim')")=="1":
        return True
    else:
        return False


def toggle_windows(reverse=False):
    # buffer version
    if reverse:
        vim.command(":bp")
    else:
        vim.command(":bn")
    # window version
    # vim.command(":normal p")

    
def open_terminal():
    if is_nvim():
        open_neo_terminal()
    else:
        open_tmux_terminal()


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
    if is_nvim():
        lines = vim.current.buffer[selected.start:selected.end]
    else:
        lines = vim.current.buffer[selected.start:selected.end+1]
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
    if is_nvim():
        neo_terminal_send(lines)
    else:
        tmux_terminal_send(lines)


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


def run_configuration():
    vim.command(":silent! wa")
    configured_run_file = vim.eval("g:configured_run_file")
    if configured_run_file == '':
        configured_run_file = configure_runtime()
    # print "configuredrun", configured_run_file
    open_if_no_terminal()
    # clear the console line if anything remains
    terminal_send(["i"])
    # terminal_send(["exit", "ipython"])
    terminal_send(["exit", "jupyter console"])
    # custom_build_process()
    terminal_send(["run {}".format(configured_run_file)])
    if is_nvim():
        # vim.command(":normal j")
        go_to_terminal()
        vim.command(":startinsert")


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
