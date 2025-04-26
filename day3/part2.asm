include 'win32.asm'

section 'const' readable
  func_alloc db 'alloc: out of memory',10,0
  func_alloc_size = $ - func_alloc
  filepath db 'input.txt',0
  outstr db 'possible triangles: %1!u!',10,0

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
  enter 14*8,0
  call initialise_allocator
  mov rcx,filepath
  call read_file
  mov rsi,rax
  
  mov rbx,0
  mov r15,0
  
  .loop:
    call parse_spaces
    call parse_number
    mov [rbp+8*r15-9*8],rax
    inc r15
    call parse_spaces
    call parse_number
    mov [rbp+8*r15-9*8],rax
    inc r15
    call parse_spaces
    call parse_number
    mov [rbp+8*r15-9*8],rax
    inc r15
    call parse_newline
  cmp r15,9
  jne .loop
    mov r15,0
    mov r12,[rbp-1*8]
    mov r13,[rbp-4*8]
    mov r14,[rbp-7*8]
    cmp r12,r14
    jle @f
      xchg r12,r14
    @@:
    cmp r13,r14
    jle @f
      xchg r13,r14
    @@:
    add r12,r13
    cmp r12,r14
    jle @f
      inc rbx
    @@:
    mov r12,[rbp-2*8]
    mov r13,[rbp-5*8]
    mov r14,[rbp-8*8]
    cmp r12,r14
    jle @f
      xchg r12,r14
    @@:
    cmp r13,r14
    jle @f
      xchg r13,r14
    @@:
    add r12,r13
    cmp r12,r14
    jle @f
      inc rbx
    @@:
    mov r12,[rbp-3*8]
    mov r13,[rbp-6*8]
    mov r14,[rbp-9*8]
    cmp r12,r14
    jle @f
      xchg r12,r14
    @@:
    cmp r13,r14
    jle @f
      xchg r13,r14
    @@:
    add r12,r13
    cmp r12,r14
    jle @f
      inc rbx
    @@:
  call parse_eof
  cmp rax,1
  jne .loop
  
  mov rcx,outstr
  mov rdx,rbx
  call printf
  
  leave
  pop r15
  pop r14
  pop r13
  pop r12
  pop rdi
  pop rsi
  pop rbx
  ret

; we keep the current parse location in rsi, instead of passing it in rcx
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
  @@:
    mov cl,[rsi]
    cmp cl,'9'
    ja @f
    sub cl,'0'
    jb @f
    imul rax,rax,10
    add rax,rcx
    inc rsi
    jmp @b
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