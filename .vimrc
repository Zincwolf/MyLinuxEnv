set number
set mouse=a
set encoding=utf-8
set tabstop=4
set expandtab
set shiftwidth=4
set smartindent
set wildmenu
set nocompatible
set noswapfile
set autoindent
set incsearch
set hlsearch
set termguicolors
syntax on
filetype plugin indent on

" --- Auto Pair Brackets and Quotes ---

" Configuration (Optional)
let g:autopair_enable_angle_brackets = 1 " Set to 0 to disable < > pairing

" Dictionary defining pairs for backspace handling
let s:pairs = { '(': ')', '[': ']', '{': '}' }
if get(g:, 'autopair_enable_angle_brackets', 1)
    let s:pairs['<'] = '>'
endif
" Add quotes - needed for backspace handling
let s:pairs["'"] = "'"
let s:pairs['"'] = '"'
let s:pairs['`'] = '`'

" --- Insert Mode Mappings ---

" Function to handle inserting opening pair OR overtyping a closing quote/bracket
" Returns the characters Vim should insert
function! s:HandlePair(open, close) abort
    if pumvisible()
        return a:open " Don't interfere with completion
    endif

    let l:col = col('.')
    let l:line = getline('.')
    let l:next_char = (l:col < strlen(l:line)) ? l:line[l:col] : '' " Get char after cursor

    " Check if we just typed a character that is its own closer (like a quote)
    " AND if the character immediately after the cursor is the same character.
    " If so, just move the cursor right (effectively 'overtyping').
    if a:open ==# a:close && l:next_char ==# a:open
        return "\<Right>"
    endif

    " Default behavior: Insert the pair and move the cursor between them
    return a:open . a:close . "\<Left>"
endfunction

" Function to handle typing a DISTINCT closing character (like ')')
" Checks if we should 'overwrite' the auto-inserted char or insert normally
function! s:CheckOvertype(char) abort
    if pumvisible()
        return a:char " Insert char normally if completion is active
    endif

    let l:col = col('.')
    let l:line = getline('.')
    let l:next_char = (l:col < strlen(l:line)) ? l:line[l:col] : ''

    " If the next character is the closing bracket we just typed, just move right
    if l:next_char ==# a:char
        return "\<Right>"
    else
        " Otherwise, insert the character normally
        return a:char
    endif
endfunction

" Function to handle backspace potentially deleting a pair
function! s:HandleBackspace() abort
    if pumvisible()
        return "\<BS>" " Normal backspace during completion
    endif

    let l:col = col('.')
    let l:line = getline('.')

    if l:col <= 1
        return "\<BS>" " Normal backspace at start of line
    endif

    " Get characters immediately surrounding the cursor
    let l:char_before = l:line[l:col - 2] " Char left of cursor
    let l:char_after = (l:col <= strlen(l:line)) ? l:line[l:col - 1] : '' " Char right of cursor

    " Check if these two characters form a pair from our s:pairs dictionary
    if has_key(s:pairs, l:char_before) && s:pairs[l:char_before] ==# l:char_after
        " It's a pair, delete both
        return "\<BS>\<Del>"
    else
        " Not a pair, perform normal backspace
        return "\<BS>"
    endif
endfunction

" --- Define Insert Mode Mappings using <expr> ---

" Opening Brackets/Quotes (now also handles quote overtyping)
inoremap <expr> ( <SID>HandlePair('(', ')')
inoremap <expr> [ <SID>HandlePair('[', ']')
inoremap <expr> { <SID>HandlePair('{', '}')
if get(g:, 'autopair_enable_angle_brackets', 1)
    inoremap <expr> <lt> <SID>HandlePair('<', '>') " Use <lt> for mapping '<'
endif
inoremap <expr> ' <SID>HandlePair("'", "'")
inoremap <expr> " <SID>HandlePair('"', '"')
inoremap <expr> ` <SID>HandlePair("`", "`")

" Closing Brackets (Overtype Check - ONLY for distinct closing chars)
inoremap <expr> ) <SID>CheckOvertype(')')
inoremap <expr> ] <SID>CheckOvertype(']')
inoremap <expr> } <SID>CheckOvertype('}')
if get(g:, 'autopair_enable_angle_brackets', 1)
    inoremap <expr> > <SID>CheckOvertype('>')
endif
" REMOVED CheckOvertype mappings for quotes ' " ` here, as HandlePair now handles them

" Backspace (Pair Deletion Check)
inoremap <expr> <BS> <SID>HandleBackspace()


" --- Visual Mode Mappings (Surround Selection) ---

" Function to surround the visual selection with a pair
function! s:SurroundSelection(open, close) range abort
    " range keyword makes '<,'> implicit when called from visual mode.
    execute "normal! gvc" . escape(a:open, '\') . "\<C-r>\"" . escape(a:close, '\') . "\<Esc>"
    " Added escape() just in case special chars are used in pairs later
    " gv - reselect visual area
    " c  - delete selection (into register ") and enter insert mode
    " a:open - insert opening char
    " \<C-r>" - insert original selection
    " a:close - insert closing char
    " \<Esc> - exit insert mode
endfunction

" Define Visual Mode Mappings (Corrected version without <C-u>)
vnoremap <silent> ( :call <SID>SurroundSelection('(', ')')<CR>
vnoremap <silent> [ :call <SID>SurroundSelection('[', ']')<CR>
vnoremap <silent> { :call <SID>SurroundSelection('{', '}')<CR>
if get(g:, 'autopair_enable_angle_brackets', 1)
    vnoremap <silent> <lt> :call <SID>SurroundSelection('<', '>')<CR> " Use <lt> for '<'
endif
vnoremap <silent> ' :call <SID>SurroundSelection("'", "'")<CR>
vnoremap <silent> " :call <SID>SurroundSelection('"', '"')<CR>
vnoremap <silent> ` :call <SID>SurroundSelection("`", "`")<CR>

" --- End of Auto Pair ---
