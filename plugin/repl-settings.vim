" Author: Alejandro "HiPhish" Sanchez
" License:  The MIT License (MIT) {{{
"    Copyright (c) 2017 HiPhish
" 
"    Permission is hereby granted, free of charge, to any person obtaining a
"    copy of this software and associated documentation files (the
"    "Software"), to deal in the Software without restriction, including
"    without limitation the rights to use, copy, modify, merge, publish,
"    distribute, sublicense, and/or sell copies of the Software, and to permit
"    persons to whom the Software is furnished to do so, subject to the
"    following conditions:
" 
"    The above copyright notice and this permission notice shall be included
"    in all copies or substantial portions of the Software.
" 
"    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
"    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
"    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
"    USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

if !has('nvim')
  finish
endif


" ----------------------------------------------------------------------------
" The default settings
" ----------------------------------------------------------------------------
" bin    : Which REPL binary to execute
" args   : Arguments to pass to every execution, come before user arguments
" syntax : Syntax highlighting to use for the REPL buffer
" title  : Value of b:term_title
" ----------------------------------------------------------------------------
let s:repl = {
	\ 'guile': {
		\ 'bin': 'guile',
		\ 'args': ['-L', '.'],
		\ 'syntax': 'scheme',
		\ 'title': 'Guile REPL',
	\ },
	\ 'lua': {
		\ 'bin': 'lua',
		\ 'args': [],
		\ 'syntax': '',
		\ 'title': 'Lua',
	\ },
	\ 'python': {
		\ 'bin': 'python',
		\ 'args': [],
		\ 'syntax': '',
		\ 'title': 'Python REPL',
	\ },
	\ 'r7rs-small': {
		\ 'bin': 'chibi-scheme',
		\ 'args': [],
		\ 'syntax': 'scheme',
		\ 'title': 'Chibi Scheme',
	\ },
	\ 'sh': {
		\ 'bin': 'sh',
		\ 'args': [],
		\ 'syntax': '',
		\ 'title': 'Bourne Shell',
	\ },
\ }

" ----------------------------------------------------------------------------
let s:repl['r7rs'] = copy(s:repl['r7rs-small'])
let s:repl['scheme'] = copy(s:repl['r7rs-small'])
" ----------------------------------------------------------------------------


" Build a dictionary to hold global setting if there is none
if !exists('g:repl')
	let g:repl = {}
endif

" Assign the default options, respect user settings
for s:type in keys(s:repl)
	call repl#define_repl(s:type, s:repl[s:type], 'keep')
endfor
