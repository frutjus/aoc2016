include '../common.inc'

section 'const' readable
  filepath db 'input.txt',0
  outstr db 'Blocks: %1!d!',0

section 'text' readable executable
main:
  ;int3
  push rbp
  mov rbp,rsp
  sub rsp,11*8
  mov rcx,filepath
  call read_file
  
  ; initial direction = North
  mov r10,0
  ; initial distance per direction = 0
  mov qword [rbp-8],0
  mov qword [rbp-16],0
  mov qword [rbp-24],0
  mov qword [rbp-32],0
  
  mov rcx,rax
  @@:
    call parse_direction
    add r10,rax
    and r10,3
    call parse_number
    lea r11,[r10*8+8]
    imul r11,-1
    add r11,rbp
    add qword [r11],rax
    call parse_separator
  cmp rax,-1
  jne @b
  
  mov rax,0
  add rax,[rbp-8]
  sub rax,[rbp-24]
  jae @f
    imul rax,rax,-1
  @@:
  mov rbx,rax
  mov rax,0
  add rax,[rbp-16]
  sub rax,[rbp-32]
  jae @f
    imul rax,rax,-1
  @@:
  add rax,rbx
  
  mov rcx,outstr
  mov rdx,rax
  call printf
  
  add rsp,11*8
  pop rbp
  ret

parse_direction:
  mov rax,0
  cmp [rcx],byte 'L'
  jne @f
    mov rax,-1
  @@:
  cmp [rcx],byte 'R'
  jne @f
    mov rax,1
  @@:
  inc rcx
  ret

parse_number:
  mov rax,0
  mov rbx,0
  @@:
    mov bl,[rcx]
    cmp rbx,'0'
    jb @f
    cmp rbx,'9'
    ja @f
    sub rbx,'0'
    imul rax,rax,10
    add rax,rbx
    inc rcx
    jmp @b
  @@:
  ret

parse_separator:
  mov rax,-1
  cmp [rcx],byte ','
  jne @f
    cmp [rcx+1],byte ' '
    jne @f
      mov rax,1
      add rcx,2
  @@:
  ret
