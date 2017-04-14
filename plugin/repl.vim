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

if !has('nvim') || exists('g:repl_nvim')
  finish
endif
let g:repl_nvim = 1


" ----------------------------------------------------------------------------
" The ':Repl' command
" ----------------------------------------------------------------------------
" The ':Repl' command is the public interface  for end users. The user can
" pass any number of command-line arguments.
command! -complete=file -bang -nargs=* Repl call <SID>repl(<q-mods>, '<bang>', <f-args>)


" ----------------------------------------------------------------------------
" The 's:repl' function is what is actually called by the ':Repl' command
" ----------------------------------------------------------------------------
function! s:repl(mods, bang, ...)
	" First we need to determine the REPL type. If there were no arguments
	" passed or the first argument is '-' deduce the type from the current
	" file type. Otherwise the type is the first argument.
	let l:type = ''
	if a:0 > 0 && a:1 !=? '-'
		if exists('g:repl["'.a:1.'"]')
			let l:type = a:1
		else
			echohl ErrorMsg
			echom 'No REPL of type '''.a:1.''' defined'
			echohl None
			return
		endif
	else
		" First split the file type at the dots, then loop over the list
		let l:fts = split(&filetype, '\v\.')

		" Start with single types and gradually move to longer types, i.e.
		" 'a', 'b', 'c', 'a.b', 'b.c', 'a.b.c'
		for l:i in range(0, len(l:fts) - 1)
			for l:j in range(0, len(l:fts) - l:i -1)
				let l:ft = join(l:fts[l:j : l:j + l:i], '.')
				if exists('g:repl["'.l:ft.'"]')
					let l:type = l:ft
				endif
			endfor
		endfor

		if empty(l:type)
			echohl ErrorMsg
			echom 'No REPL for current file type defined'
			echohl None
			return
		endif
	endif

	" If the '!' was not supplied and there is already an instance running
	" jump to that instance.
	if empty(a:bang) && exists('g:repl["'.l:type.'"].instances') && len(g:repl[l:type].instances) > 0
		" Always use the youngest instance
		let l:buffer = g:repl[l:type].instances[0].buffer
		let l:windows = win_findbuf(l:buffer)

		if empty(l:windows)
			silent execute a:mods 'new'
			silent execute 'buffer' l:buffer
		else
			call win_gotoid(l:windows[0])
		endif

		return
	endif

	" The actual option values to use are determined at runtime. Global
	" settings take precedence, so we loop over the global dictionary and
	" create local variants of every setting.
	"
	" After a local variable has been initialised with the global default we
	" loop over the lower scopes in a given order. If we encounter the same
	" setting it overwrites the previous values. The scopes are ordered by
	" ascending significance, with the most significant being last.
	let l:repl = copy(g:repl[l:type])
	for l:key in keys(l:repl)
		for l:scope in ['t', 'w', 'b']
			let l:entry = l:scope.':repl["'.l:type.'"]["'.l:key.'"]'
			if exists(l:entry)
				silent execute 'let l:repl["'.l:key.'"] = '.l:entry
			endif
		endfor
		" If the option is a function reference call it
		if type(l:repl[l:key]) == type(function('type'))
			let l:repl[l:key] = l:repl[l:key]()
		endif
	endfor

	" Append the argument to the command to the argument list (but skip the
	" first argument, that is the file type)
	let l:repl.args = l:repl.args + a:000[1:]

	" Open a new buffer and launch the terminal
	silent execute a:mods 'new'
	silent execute 'terminal' l:repl.binary join(l:repl.args, ' ')
	silent execute 'set syntax='.l:repl.syntax
	silent let b:term_title = l:repl.title

	" Collect information about this REPL instance
	let b:repl = {
		\ '-': {
			\ 'type'   : l:type,
			\ 'binary' : l:repl.binary,
			\ 'args'   : l:repl.args,
			\ 'job_id' : b:terminal_job_id,
			\ 'buffer' : bufnr('%')
		\ }
	\ }

	" Add This instance to the top of the list of instances
	if exists('g:repl["'.l:type.'"].instances')
		call insert(g:repl[l:type].instances, b:repl['-'])
	else
		let g:repl[l:type].instances = [b:repl['-']]
	endif

	" Hook up autocommand to clean up after the REPL terminates; the
	" autocommand is not guaranteed to have access to the b:repl variable,
	" that's why we instead use the literal job-id to identify this instance.
	silent execute 'au BufDelete <buffer> call <SID>remove_instance('. b:repl['-'].job_id .', "'.l:type.'")'
endfunction

" Remove an instance from the global list of instances
function! s:remove_instance(job_id, type)
	for i in range(len(g:repl[a:type].instances))
		if g:repl[a:type].instances[i].job_id == a:job_id
			call remove(g:repl[a:type].instances, i)
			break
		endif
	endfor
endfunction
