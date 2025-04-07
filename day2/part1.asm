include 'win32.asm'

section 'const' readable
  func_alloc db 'alloc: out of memory',10,0
  func_alloc_size = $ - func_alloc
  filepath db 'input.txt',0
  outstr db 'code: %1!s!',10,0
  
  keypad db '7','4','1'
         db 253 dup 0
         db '8','5','2'
         db 253 dup 0
         db '9','6','3'

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
  code equ [rbp-8]
  push rbx
  push rsi
  push rdi
  push r12
  push r13
  push r14
  push r15
  enter 6*8,0
  call initialise_allocator
  mov rcx,filepath
  call read_file
  mov rsi,rax
  
  ; keypad
  ; 1 2 3
  ; 4 5 6
  ; 7 8 9
  
  ; current coordinates = (1,1)
  mov bl,1
  mov bh,1
  ; r12 = code
  mov r12,0
  
  .loop:
    call parse_eof
    mov rdi,rax
    call parse_newline
    lea rdi,[rdi+rax*2]
    cmp rdi,0
    je @f
      mov rax,0
      mov al,[keypad + rbx]
      shl r12,8
      add r12,rax
      test rdi,1
      jnz .done
    @@:
    call parse_direction
    test rax,2
    jnz .sw
    .ne:
      test rax,1
      jnz .e
      .n:
        cmp bl,2
        je .loop
        inc bl
        jmp .loop
      .e:
        cmp bh,2
        je .loop
        inc bh
        jmp .loop
    .sw:
      test rax,1
      jnz .w
      .s:
        cmp bl,0
        je .loop
        dec bl
        jmp .loop
      .w:
        cmp bh,0
        je .loop
        dec bh
        jmp .loop
  .done:
  
  mov rcx,outstr
  mov code,r12
  lea rdx,code
  call printf ;the code is printed out backwards ;P
  
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

parse_eof:
  cmp [rsi],byte 0
  jne @f
    mov rax,1
    ret
  @@:
  mov rax,0
  ret