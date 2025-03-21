format PE64 console

; Win32 constants
CREATE_NEW             = 1
CREATE_ALWAYS          = 2
OPEN_EXISTING          = 3
OPEN_ALWAYS            = 4
TRUNCATE_EXISTING      = 5

FILE_SHARE_READ        = 1
FILE_SHARE_WRITE       = 2
FILE_SHARE_DELETE      = 4

FILE_ATTRIBUTE_ARCHIVE       = 0x20
FILE_ATTRIBUTE_ENCRYPTED     = 0x4000
FILE_ATTRIBUTE_HIDDEN        = 0x2
FILE_ATTRIBUTE_NORMAL        = 0x80
FILE_ATTRIBUTE_OFFLINE       = 0x1000
FILE_ATTRIBUTE_READONLY      = 0x1
FILE_ATTRIBUTE_SYSTEM        = 0x4
FILE_ATTRIBUTE_TEMPORARY     = 0x100
FILE_FLAG_BACKUP_SEMANTICS   = 0x02000000
FILE_FLAG_DELETE_ON_CLOSE    = 0x04000000
FILE_FLAG_NO_BUFFERING       = 0x20000000
FILE_FLAG_OPEN_NO_RECALL     = 0x00100000
FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000
FILE_FLAG_OVERLAPPED         = 0x40000000
FILE_FLAG_POSIX_SEMANTICS    = 0x01000000
FILE_FLAG_RANDOM_ACCESS      = 0x10000000
FILE_FLAG_SESSION_AWARE      = 0x00800000
FILE_FLAG_SEQUENTIAL_SCAN    = 0x08000000
FILE_FLAG_WRITE_THROUGH      = 0x80000000
;SECURITY_ANONYMOUS           = ?
;SECURITY_CONTEXT_TRACKING    = ?
;SECURITY_DELEGATION          = ?
;SECURITY_EFFECTIVE_ONLY      = ?
;SECURITY_IDENTIFICATION      = ?
;SECURITY_IMPERSONATION       = ?

GENERIC_READ           = 80000000h
GENERIC_WRITE          = 40000000h

STD_INPUT_HANDLE       = 0FFFFFFF6h
STD_OUTPUT_HANDLE      = 0FFFFFFF5h
STD_ERROR_HANDLE       = 0FFFFFFF4h

MEM_COMMIT             = 1000h
MEM_RESERVE            = 2000h
MEM_DECOMMIT           = 4000h
MEM_RELEASE            = 8000h
MEM_FREE               = 10000h
MEM_PRIVATE            = 20000h
MEM_MAPPED             = 40000h
MEM_RESET              = 80000h
MEM_TOP_DOWN           = 100000h

PAGE_NOACCESS          = 1
PAGE_READONLY          = 2
PAGE_READWRITE         = 4
PAGE_WRITECOPY         = 8
PAGE_EXECUTE           = 10h
PAGE_EXECUTE_READ      = 20h
PAGE_EXECUTE_READWRITE = 40h
PAGE_EXECUTE_WRITECOPY = 80h
PAGE_GUARD             = 100h
PAGE_NOCACHE           = 200h

FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000
FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800
FORMAT_MESSAGE_FROM_STRING     = 0x00000400
FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000
FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200
FORMAT_MESSAGE_MAX_WIDTH_MASK  = 0x000000FF

section 'const' readable
  func_read_file db 'read_file: ',0
  func_read_file_size = $ - func_read_file
  func_printf db 'printf: ',0
  func_printf_size = $ - func_printf

section 'data' readable writeable
  stdout dq ?

section 'text' readable executable
entry $
  sub rsp,5*8
  mov ecx,STD_OUTPUT_HANDLE
  call [GetStdHandle]
  ; TODO: error checking
  mov [stdout],rax
  call main
  mov rcx,0
  call exit
  
read_file:
  push rbp
  mov rbp,rsp
  filehandle equ [rbp-8]
  filesize equ [rbp-16]
  file_contents equ [rbp-24]
  sub rsp,11*8
  
  mov rdx,GENERIC_READ
  mov r8,FILE_SHARE_READ
  mov r9,0
  mov qword [rsp+32],OPEN_EXISTING
  mov qword [rsp+40],0
  mov qword [rsp+48],0
  call [CreateFileA]
  
  cmp rax,-1
  jne @f
    mov rcx,func_read_file
    mov rdx,func_read_file_size
    call fail
  @@:
  mov filehandle,rax
  
  mov rcx,rax
  lea rdx,filesize
  call [GetFileSizeEx]
  
  cmp rax,0
  jne @f
    mov rcx,func_read_file
    mov rdx,func_read_file_size
    call fail
  @@:
  inc qword filesize
  
  mov rcx,0
  mov rdx,filesize
  mov r8,MEM_COMMIT or MEM_RESERVE
  mov r9,PAGE_READWRITE
  call [VirtualAlloc]
  
  cmp rax,0
  jne @f
    mov rcx,func_read_file
    mov rdx,func_read_file_size
    call fail
  @@:
  mov file_contents,rax
  
  mov rcx,filehandle
  mov rdx,rax
  mov r8,filesize
  mov r9,0
  mov qword [rsp+32],0
  call [ReadFile]
  
  cmp rax,0
  jne @f
    mov rcx,func_read_file
    mov rdx,func_read_file_size
    call fail
  @@:
  
  mov rax,file_contents
  mov rbx,filesize
  
  add rsp,11*8
  mov rsp,rbp
  pop rbp
  ret

print:
  sub rsp,5*8
  mov r8,rdx
  mov rdx,rcx
  mov rcx,[stdout]
  mov r9,0
  mov qword [rsp+32],0
  call [WriteConsoleA]
  add rsp,5*8
  ret

printf:
    mov [rsp+16],rdx
    mov [rsp+24],r8
    mov [rsp+32],r9
    lea rax,[rsp+16]
    push rbp
    mov rbp,rsp
    sub rsp,9*8
    msgbuf equ [rbp-8]
    args equ [rbp-16]
    mov rdx,rcx
    mov rcx,FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_STRING
    mov r8,0
    mov r9,0
    lea rbx,msgbuf
    mov [rsp+32],rbx
    mov qword [rsp+40],0
    mov args,rax
    lea rax,args
    mov [rsp+48],rax
    call [FormatMessageA]
    cmp rax,0
    jne @f
        mov rcx,func_printf
        mov rdx,func_printf_size
        call fail
    @@:
    mov rcx,msgbuf
    mov rdx,rax
    call print
    mov rcx,msgbuf
    call [LocalFree]
    cmp rax,0
    je @f
        mov rcx,func_printf
        mov rdx,func_printf_size
        call fail
    @@:
    add rsp,9*8
    mov rsp,rbp
    pop rbp
    ret

fail:
  push rbp
  mov rbp,rsp
  sub rsp,9*8
  errorbuffer equ [rbp-8]
  call print
  call [GetLastError]
  mov rcx,FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_IGNORE_INSERTS
  mov rdx,0
  mov r8,rax
  mov r9,0
  lea rax,errorbuffer
  mov qword [rsp+32],rax
  mov qword [rsp+40],0
  mov qword [rsp+48],0
  call [FormatMessageA]
  mov rcx,errorbuffer
  mov rdx,rax
  call print
  mov rcx,1
  call exit
  add rsp,9*8
  pop rbp
  ret

exit:
  sub rsp,5*8
  call [ExitProcess]


section 'import' import readable writeable
  dd 0,0,0, rva kernel_name, rva kernel_address_table
  dd 0,0,0,0,0

kernel_name: db 'KERNEL32.DLL',0

kernel_address_table:
  ExitProcess       dq rva ExitProcess_import
  TerminateProcess  dq rva TerminateProcess_import
  GetCurrentProcess dq rva GetCurrentProcess_import
  GetStdHandle      dq rva GetStdHandle_import
  WriteConsoleA     dq rva WriteConsoleA_import
  CreateFileA       dq rva CreateFileA_import
  ReadFile          dq rva ReadFile_import
  GetLastError      dq rva GetLastError_import
  FormatMessageA    dq rva FormatMessageA_import
  GetFileSizeEx	    dq rva GetFileSizeEx_import
  VirtualAlloc      dq rva VirtualAlloc_import
  LocalFree         dq rva LocalFree_import
  dq 0

ExitProcess_import: db 0,0,'ExitProcess',0
; https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess
; void ExitProcess(
;   [in] UINT uExitCode
; );

TerminateProcess_import db 0,0,'TerminateProcess',0
; https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-terminateprocess
; BOOL TerminateProcess(
;   [in] HANDLE hProcess,
;   [in] UINT   uExitCode
; );

GetCurrentProcess_import db 0,0,'GetCurrentProcess',0
; https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-getcurrentprocess
; HANDLE GetCurrentProcess();

GetStdHandle_import: db 0,0,'GetStdHandle',0
; https://learn.microsoft.com/en-us/windows/console/getstdhandle
; HANDLE WINAPI GetStdHandle(
;   _In_ DWORD nStdHandle
; );

WriteConsoleA_import: db 0,0,'WriteConsoleA',0
; https://learn.microsoft.com/en-us/windows/console/writeconsole
; BOOL WINAPI WriteConsole(
;   _In_             HANDLE  hConsoleOutput,
;   _In_       const VOID    *lpBuffer,
;   _In_             DWORD   nNumberOfCharsToWrite,
;   _Out_opt_        LPDWORD lpNumberOfCharsWritten,
;   _Reserved_       LPVOID  lpReserved
; );

CreateFileA_import: db 0,0,'CreateFileA',0
; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea
; HANDLE CreateFileA(
;   [in]           LPCSTR                lpFileName,
;   [in]           DWORD                 dwDesiredAccess,
;   [in]           DWORD                 dwShareMode,
;   [in, optional] LPSECURITY_ATTRIBUTES lpSecurityAttributes,
;   [in]           DWORD                 dwCreationDisposition,
;   [in]           DWORD                 dwFlagsAndAttributes,
;   [in, optional] HANDLE                hTemplateFile
; );

ReadFile_import: db 0,0,'ReadFile',0
; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
; BOOL ReadFile(
;   [in]                HANDLE       hFile,
;   [out]               LPVOID       lpBuffer,
;   [in]                DWORD        nNumberOfBytesToRead,
;   [out, optional]     LPDWORD      lpNumberOfBytesRead,
;   [in, out, optional] LPOVERLAPPED lpOverlapped
; );

GetLastError_import db 0,0,'GetLastError',0
; https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror
; _Post_equals_last_error_ DWORD GetLastError();

FormatMessageA_import db 0,0,'FormatMessageA',0
; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-formatmessagea
; DWORD FormatMessageA(
;   [in]           DWORD   dwFlags,
;   [in, optional] LPCVOID lpSource,
;   [in]           DWORD   dwMessageId,
;   [in]           DWORD   dwLanguageId,
;   [out]          LPSTR   lpBuffer,
;   [in]           DWORD   nSize,
;   [in, optional] va_list *Arguments
; );

GetFileSizeEx_import db 0,0,'GetFileSizeEx',0
; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getfilesizeex
; BOOL GetFileSizeEx(
;   [in]  HANDLE         hFile,
;   [out] PLARGE_INTEGER lpFileSize
; );

VirtualAlloc_import db 0,0,'VirtualAlloc',0
; https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualalloc
; LPVOID VirtualAlloc(
;   [in, optional] LPVOID lpAddress,
;   [in]           SIZE_T dwSize,
;   [in]           DWORD  flAllocationType,
;   [in]           DWORD  flProtect
; );

LocalFree_import db 0,0,'LocalFree',0
; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-localfree
; HLOCAL LocalFree(
;   [in] _Frees_ptr_opt_ HLOCAL hMem
; );