include '../common.inc'

section 'const' readable
  filepath db 'C:\Users\e1006515\source\aoc2016\day1\input.txt',0
  teststr db 'test',0

section 'text' readable executable
main:
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
    imul r11,r10,8
    add r11,rbp
    add qword [r11],rax
    call parse_separator
  cmp rax,-1
  jne @b
  
  mov rax,0
  add rax,[rbp-0]
  sub rax,[rbp-16]
  jae @f
    imul rax,rax,-1
  @@:
  mov rbx,rax
  mov rax,0
  add rax,[rbp-8]
  sub rax,[rbp-24]
  jae @f
    imul rax,rax,-1
  @@:
  add rax,rbx
  
  int3
  
  add rsp,9*8
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
  @@:
    mov rbx,[rcx]
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
