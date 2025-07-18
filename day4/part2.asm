include 'win32.asm'

section 'const' readable
  func_alloc db 'alloc: out of memory',10,0
  func_alloc_size = $ - func_alloc
  filepath db 'input.txt',0
  outstr db '%1!u!: %2!s! %3!llu!',10,0

section 'data' readable writeable
  ; allocator data
  page_size dd ?
  first_block dq ?
  next_address dq ?
  last_address dq ?

section 'text' readable executable
initialise_allocator:
  enter 4*8,0
  call get_page_size
  mov [page_size],eax
  heap_size = 1024*1024 ; 1 MB is probably enough for our needs
  mov rcx,heap_size
  call raw_alloc
  mov [first_block],rax
  mov [next_address],rax
  add rax,heap_size
  mov [last_address],rax
  leave
  ret

alloc:
  enter 4*8,0
  ;mov eax,[page_size]
  ;cmp rcx,rax
  ;jl @f ; for large allocations, get them from the OS directly
  ;  call raw_alloc
  ;  leave
  ;  ret
  ;@@:
  mov rax,[next_address]
  add rax,rcx
  cmp rax,[last_address]
  jle @f
    mov rcx,func_alloc
    mov rdx,func_alloc_size
    call print
    mov rcx,1
    call exit
  @@:
  mov [next_address],rax
  sub rax,rcx
  leave
  ret

list_append_item:
  ; given a pointer to a list in rcx and an item in rdx,
  ; allocate a new list element, store the pointer to
  ; the new element in the last item of the list and
  ; return the pointer in rax.
  item equ [rbp+24]
  pointer equ [rbp+16]
  enter 4*8,0
  mov pointer,rcx
  mov item,rdx
  mov rcx,16
  call alloc
  mov qword [rax],0
  mov rdx,item
  mov [rax+8],rdx
  ; if rcx is 0, we are making a new list, so just return the pointer
  mov rcx,pointer
  cmp rcx,0
  jne @f
    leave
    ret
  @@:
  ; find the last item in the list
  cmp qword [rcx],0
  je @f
    mov rcx,[rcx]
    jmp @b
  @@:
  mov [rcx],rax
  leave
  ret

list_find_match:
  cmp rcx,0
  je .nomatch
  cmp rdx,[rcx+8]
  je .match
  inc r8d
  mov rcx,[rcx]
  jmp list_find_match
  .match:
    mov eax,r8d
    ret
  .nomatch:
    mov eax,-1
    ret

; -----------------------
; main
; -----------------------
main:
  push rbx
  push rsi
  push rdi
  push r12
  push r13
  push r14
  push r15
  enter 12*8,0
  call initialise_allocator
  mov rcx,filepath
  call read_file
  mov rsi,rax
  
  letters equ [rbp-32]
  letter_scores equ [rbp-64]
  
  mov rbx,0
  
  .loop:
    inc rbx
    mov r13,rsi
    mov qword [rbp-64],0
    mov qword [rbp-56], 0
    mov qword [rbp-48], 0
    mov qword [rbp-40], 0
    lea rcx,[rbp-64]
    call count_letters
    
    mov byte [rbp-32], 'a'
    mov byte [rbp-31], 'b'
    mov byte [rbp-30], 'c'
    mov byte [rbp-29], 'd'
    mov byte [rbp-28], 'e'
    mov byte [rbp-27], 'f'
    mov byte [rbp-26], 'g'
    mov byte [rbp-25], 'h'
    mov byte [rbp-24], 'i'
    mov byte [rbp-23], 'j'
    mov byte [rbp-22], 'k'
    mov byte [rbp-21], 'l'
    mov byte [rbp-20], 'm'
    mov byte [rbp-19], 'n'
    mov byte [rbp-18], 'o'
    mov byte [rbp-17], 'p'
    mov byte [rbp-16], 'q'
    mov byte [rbp-15], 'r'
    mov byte [rbp-14], 's'
    mov byte [rbp-13], 't'
    mov byte [rbp-12], 'u'
    mov byte [rbp-11], 'v'
    mov byte [rbp-10], 'w'
    mov byte [rbp-09], 'x'
    mov byte [rbp-08], 'y'
    mov byte [rbp-07], 'z'
    
    lea rcx,[rbp-32]
    lea rdx,[rbp-64]
    mov r9,26
    call sort_by_score
    
    call parse_number
    mov r12,rax
    
    inc rsi
    lea rcx,[rbp-32]
    mov rdx,rsi
    mov r9,5
    call cmp_str
    cmp rax,0
    jne @f
      mov rcx,r13
      mov rdx,r12
      call decrypt_name
      mov rcx,outstr
      mov rdx,rbx
      mov r8,r13
      mov r9,r12
      call printf
    @@:
    add rsi,6
    
    call parse_newline
    call parse_eof
    cmp rax,1
    jne .loop
  .end:
  
  leave
  pop r15
  pop r14
  pop r13
  pop r12
  pop rdi
  pop rsi
  pop rbx
  ret

sort_by_score:
  push rbx
  push r12
  push r13
  push r14
  push r15
  
  .loop1:
    mov rbx,0
    mov r12,0
    .loop2:
      lea rax,[r12+1]
      cmp rax,r9
      jae .end2
      
      mov r13b,[rdx+r12]
      mov r14b,[rdx+r12+1]
      cmp r13b,r14b
      jae @f
        mov rbx,1
        mov [rdx+r12+1],r13b
        mov [rdx+r12],r14b
        mov r13b,[rcx+r12]
        mov r14b,[rcx+r12+1]
        mov [rcx+r12+1],r13b
        mov [rcx+r12],r14b
      @@:
      
      inc r12
      jmp .loop2
    .end2:
    cmp rbx,1
    je .loop1
  .end1:
  
  pop r15
  pop r14
  pop r13
  pop r12
  pop rbx
  ret

cmp_str:
  push r12
  push r13
  mov r10,0
  .loop:
    cmp r10,r9
    jae .end
    
    mov r12b,[rcx+r10]
    mov r13b,[rdx+r10]
    cmp r12b,r13b
    jae @f
      mov rax,-1
      pop r13
      pop r12
      ret
    @@:
    je @f
      mov rax,1
      pop r13
      pop r12
      ret
    @@:
    
    inc r10
    jmp .loop
  .end:
  mov rax,0
  pop r13
  pop r12
  ret

decrypt_name:
  push rbx
  mov rax,rdx
  mov rdx,0
  mov rbx,26
  div rbx
  .loop:
    mov al,[rcx]
    cmp al,'-'
    jne @f
      mov byte [rcx],' '
      inc rcx
      jmp .loop
    @@:
    cmp al,'z'
    jbe @f
      mov byte [rcx],0
      jmp .end
    @@:
    cmp al,'a'
    jae @f
      mov byte [rcx],0
      jmp .end
    @@:
    add al,dl
    cmp al,'z'
    jbe @f
      sub al,26
    @@:
    mov [rcx],al
    
    inc rcx
    jmp .loop
  .end:
  pop rbx
  ret

; we keep the current parse location in rsi, instead of passing it in rcx
count_letters:
  .loop:
    mov dl,[rsi]
    cmp dl,'-'
    jne @f
      inc rsi
      jmp .loop
    @@:
    cmp dl,'z'
    ja .end
    sub dl,'a'
    jb .end
    inc rsi
    movzx rdx,dl
    inc byte [rcx+rdx]
    jmp .loop
  .end:
  ret

parse_line:
  push rbx
  push rdi
  push r12
  push r13
  push r14
  push r15
  enter 4*8,0
  mov rbx,rcx
  
  call parse_eof
  cmp rax,1
  jne @f
    mov rax,0
    ret
  @@:
  mov [rbx],rsi
  mov r12,0
  
  @@:
    inc rsi
    inc r12
    call parse_newline
    cmp rax,1
    je @f
    call parse_eof
    cmp rax,1
    je @f
    jmp @b
  @@:
  mov [rbx+8],r12
  
  leave
  pop r15
  pop r14
  pop r13
  pop r12
  pop rdi
  pop rbx
  ret

parse_direction:
  mov cl,[rsi]
  cmp cl,'U'
  jne @f
    inc rsi
    mov rax,0
    ret
  @@:
  cmp cl,'R'
  jne @f
    inc rsi
    mov rax,1
    ret
  @@:
  cmp cl,'D'
  jne @f
    inc rsi
    mov rax,2
    ret
  @@:
  cmp cl,'L'
  jne @f
    inc rsi
    mov rax,3
    ret
  @@:
  mov rax,-1
  ret

parse_number:
  mov rax,0
  mov rcx,0
  mov rdx,0
  @@:
    mov cl,[rsi]
    cmp cl,'9'
    ja @f
    sub cl,'0'
    jb @f
    mov rdx,1
    imul rax,rax,10
    add rax,rcx
    inc rsi
    jmp @b
  @@:
  cmp rdx,1
  je @f
    mov rax,-1
  @@:
  ret

parse_newline:
  mov rax,0
  .start:
    cmp [rsi],byte 10
    jne @f
      mov rax,1
      inc rsi
      jmp .start
    @@:
    cmp [rsi],byte 13
    jne @f
      mov rax,1
      inc rsi
      jmp .start
    @@:
  ret

parse_spaces:
  mov rax,0
  .start:
    cmp [rsi],byte ' '
    jne @f
      mov rax,1
      inc rsi
      jmp .start
    @@:
  ret

parse_eof:
  cmp [rsi],byte 0
  jne @f
    mov rax,1
    ret
  @@:
  mov rax,0
  ret