include 'win32.asm'

section 'const' readable
  func_alloc db 'alloc: out of memory',10,0
  func_alloc_size = $ - func_alloc
  filepath db 'input.txt',0
  outstr db 'First crossing at (%1!d!,%2!d!), step %3!d!',10,0
  msg_no_cross db 'No crossing paths were found.',10,0
  msg_no_cross_size = $ - msg_no_cross

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

list_append_item1:
  enter 4*8,0
  cmp rcx,0
  jne @f
    sub rsp,2*8
    mov [rbp-8],rdx
    mov rcx,16
    call alloc
    mov qword [rax],0
    mov rdx,[rbp-8]
    mov [rax+8],rdx
    add rsp,2*8
    leave
    ret
  @@:
  mov rbx,rcx
  mov rcx,[rcx]
  call list_append_item
  mov [rbx],rax
  mov rax,rbx
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

main:
  push rbx
  push rsi
  push rdi
  push r12
  push r13
  push r14
  push r15
  enter 4*8,0
  call initialise_allocator
  mov rcx,filepath
  call read_file
  mov rsi,rax
  
  ; initial direction = North
  mov r12,0
  ; initial coordinates = (0,0)
  mov r13,0
  mov r14,0
  ; list of visited coordinates, starting with (0,0)
  mov rcx,0
  mov rdx,0
  call list_append_item
  mov r15,rax
  ; pointer to the last item in list, for convenience
  mov rdi,rax
  ;int3
  .next_move:
    call parse_direction
    add r12b,al
    and r12b,3
    call parse_number
    
    mov ebx,eax
    .moving:
      cmp ebx,0
      je .moved
        test r12b,2
        jnz .sw
        .ne:
          test r12b,1
          jnz .e
          .n:
            inc r13d
            jmp @f
          .e:
            inc r14d
            jmp @f
        .sw:
          test r12b,1
          jnz .w
          .s:
            dec r13d
            jmp @f
          .w:
            dec r14d
            jmp @f
        @@:
        
        mov rcx,r15
        mov edx,r14d
        shl rdx,32
        add rdx,r13
        mov r8d,0
        call find_match
        cmp eax,-1
        jne .found
        
        mov rcx,rdi
        mov edx,r14d
        shl rdx,32
        add rdx,r13
        call list_append_item
        mov rdi,[rdi]
        dec ebx
      jmp .moving
    .moved:
    call parse_separator
  cmp rax,-1
  jne .next_move
    mov rcx,msg_no_cross
    mov rdx,msg_no_cross_size
    call print
    leave
    ret
  .found:
  
  mov rcx,outstr
  mov edx,r13d
  mov r8d,r14d
  mov r9d,eax
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
  mov rax,0
  cmp [rsi],byte 'L'
  jne @f
    mov al,-1
  @@:
  cmp [rsi],byte 'R'
  jne @f
    mov al,1
  @@:
  inc rsi
  ret

parse_number:
  mov rax,0
  mov rbx,0
  @@:
    mov bl,[rsi]
    cmp rbx,'0'
    jb @f
    cmp rbx,'9'
    ja @f
    sub rbx,'0'
    imul rax,rax,10
    add rax,rbx
    inc rsi
    jmp @b
  @@:
  ret

parse_separator:
  mov rax,-1
  cmp [rsi],byte ','
  jne @f
    cmp [rsi+1],byte ' '
    jne @f
      mov rax,1
      add rsi,2
  @@:
  ret

find_match:
  cmp rcx,0
  je .nomatch
  cmp rdx,[rcx+8]
  je .match
  inc r8d
  mov rcx,[rcx]
  jmp find_match
  .match:
    mov eax,r8d
    ret
  .nomatch:
    mov eax,-1
    ret
