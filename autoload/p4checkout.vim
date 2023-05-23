" =============================================================================
" File:          autoload/p4checkout.vim
" Description:   Automatically try to check out read-only files from Perforce
" Author:        Adam Slater <github.com/aslater>
" =============================================================================

function! p4checkout#Strip(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! p4checkout#ReadP4Info(filename)
   let b:p4localdir = fnamemodify(a:filename, ':p:h')

   let p4info = readfile(a:filename) + ["", ""]
   let b:p4cmd = 'p4'
   "echo p4info
   for line in p4info
      "echo line
      let splitline = split(line, '=')
      "echo splitline
      if len(splitline) > 1
         let var = p4checkout#Strip(splitline[0])
         "echo var
         let value = p4checkout#Strip(join(splitline[1:], '='))
         "echo value

         if var ==? "p4workspace"
            let b:p4cmd .= ' -c ' . value
         elseif var ==? "p4path"
            let b:p4repodir = value
         elseif var ==? "p4user"
            let b:p4cmd .= ' -u ' . value
         elseif var ==? "p4pass"
            let b:p4cmd .= ' -P ' . value
         elseif var ==? "p4port"
            let b:p4cmd .= ' -p ' . value
         endif
      endif
   endfor
   "echo b:p4cmd
   "echo "got p4 info:"
   "echo dirname
   "echo p4info[0]
   "echo p4info[1]
endfunction


function! p4checkout#IsUnderPerforce()
    if !exists('b:p4checked')
        let local_path = fnamemodify(expand('%:p:h'), ':p')

        let command = 'cd ' . local_path . ' && p4 info'

        " Execute the combined command
        let p4info = split(system(command), "\n")

        " Print the output of 'p4 info' command
        "echo p4info

        for line in p4info
            let splitline = split(line, ': ')
            if len(splitline) > 1 && splitline[0] == 'Client root'
                let p4root = splitline[1]
                "echo p4root
                if stridx(local_path, p4root) == 0
                    let b:p4path = expand('%:p')
                    let b:p4cmd = 'cd ' . p4root . ' && p4'
                    let b:p4checked = 1
                    return
                endif
            endif
        endfor
    endif
endfunction

" Confirm with the user, then checkout a file from perforce.
function! p4checkout#P4Checkout()
   "echo "Calling underPerforce"
   call p4checkout#IsUnderPerforce()
   if exists("b:p4path")
      "echo b:p4cmd . ' edit ' . b:p4path  
      call system(b:p4cmd . ' edit ' . b:p4path . ' > /dev/null')
      "echo b:p4cmd . ' edit ' . b:p4path . ' > /dev/null'
      if v:shell_error == 0
         set noreadonly
         edit
         syntax enable
      endif
   endif
endfunction
