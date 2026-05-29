" Linters \& Fixers setting (mostly for python)
let g:ale_linters = {
\   'python': ['ruff'],
\   'c': ['clangd'],
\}

let g:ale_python_pylint_options = '--rcfile pylintrc'

" Run fixers when save.
" 0: disable, 1: enable
" I ususlly put it to 1, but due to strict homework submission rules, I have
" to disable it.
let g:ale_fix_on_save = 1
" let g:ale_python_black_options = '--line-length 79'


let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'python': ['ruff_format', 'isort'],
\}

" Ale completion
" let g:ale_completion_enabled = 1
" let g:ale_completion_autoimport = 1

" Ale text/sign settings
let g:ale_virtualtext_cursor = 'disabled' " 'enabled' or 'disabled' for virtual text
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'
let g:ale_sign_info = '=='
let g:ale_sign_column_always = 1
