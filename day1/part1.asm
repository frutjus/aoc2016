include '../common.inc'

section 'const' readable
  filepath db 'input.txt',0
  outstr db 'Blocks: %1!d!',10,0

section 'text' readable executable
main:
  ; these variables are to hold the amount moved in each direction.
  ; they are also accessed dynamically in line .l1 below.
  north equ [rbp-32]
  east  equ [rbp-24]
  south equ [rbp-16]
  west  equ [rbp-8]
  enter 8*8,0
  mov rcx,filepath
  call read_file
  
  ; initial direction = North
  mov r10,0
  ; initial distance per direction = 0
  mov qword north,0
  mov qword east,0
  mov qword south,0
  mov qword west,0
  
  mov rcx,rax
  @@:
    call parse_direction
    add r10,rax
    and r10,3
    call parse_number
.l1:add qword [rbp+r10*8-32],rax
    call parse_separator
  cmp rax,-1
  jne @b
  
  mov rax,0
  add rax,north
  sub rax,south
  jae @f
    neg rax
  @@:
  mov rbx,0
  add rbx,east
  sub rbx,west
  jae @f
    neg rbx
  @@:
  add rax,rbx
  
  mov rcx,outstr
  mov rdx,rax
  call printf
  
  leave
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
