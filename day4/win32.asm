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

INVALID_HANDLE_VALUE   = 0x6

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

MEM_DECOMMIT              = 0x00004000
MEM_RELEASE               = 0x00008000
MEM_COALESCE_PLACEHOLDERS = 0x00000001
MEM_PRESERVE_PLACEHOLDER  = 0x00000002

FORMAT_MESSAGE_ALLOCATE_BUFFER = 0x00000100
FORMAT_MESSAGE_ARGUMENT_ARRAY  = 0x00002000
FORMAT_MESSAGE_FROM_HMODULE    = 0x00000800
FORMAT_MESSAGE_FROM_STRING     = 0x00000400
FORMAT_MESSAGE_FROM_SYSTEM     = 0x00001000
FORMAT_MESSAGE_IGNORE_INSERTS  = 0x00000200
FORMAT_MESSAGE_MAX_WIDTH_MASK  = 0x000000FF

section 'const' readable
  func_get_std_handle      db 'get_std_handle: ',0
  func_get_std_handle_size = $ - func_get_std_handle
  func_read_file           db 'read_file: ',0
  func_read_file_size      = $ - func_read_file
  func_printf              db 'printf: ',0
  func_printf_size         = $ - func_printf
  func_raw_alloc           db 'raw_alloc: ',0
  func_raw_alloc_size      = $ - func_raw_alloc
  func_raw_free            db 'raw_free: ',0
  func_raw_free_size       = $ - func_raw_free
  timer_msg                db 'Ran in %1!u! microseconds',10,0

section 'data' readable writeable
  stdout dq ?


section 'text' readable executable
entry $
  tick_frequency equ [rbp-8]
  start_time equ [rbp-16]
  end_time equ [rbp-24]
  enter 8*8,0
  lea rcx,tick_frequency
  call [QueryPerformanceFrequency]
  lea rcx,start_time
  call [QueryPerformanceCounter]
  call get_std_handle
  call main ;call out to the main function of the user program
  lea rcx,end_time
  call [QueryPerformanceCounter]
  mov rcx,timer_msg
  mov rax,end_time
  sub rax,start_time
  mov rdx,0
  mov rbx,1000000
  mul rbx
  div qword tick_frequency
  mov rdx,rax
  call printf
  mov rcx,0
  call exit

get_std_handle:
  enter 4*8,0
  mov ecx,STD_OUTPUT_HANDLE
  call [GetStdHandle]
  cmp rax,INVALID_HANDLE_VALUE
  jne @f
    mov rcx,func_get_std_handle
    mov rdx,func_get_std_handle_size
    call print
    call fail
  @@:
  mov [stdout],rax
  leave
  ret

read_file:
  filehandle equ [rbp-8]
  filesize equ [rbp-16]
  file_contents equ [rbp-24]
  enter 10*8,0
  
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
    call print
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
    call print
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
    call print
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
    call print
    call fail
  @@:
  
  mov rcx,filehandle
  call [CloseHandle]
  
  mov rax,file_contents
  mov rbx,filesize
  
  leave
  ret

print:
  enter 6*8,0
  mov r8,rdx
  mov rdx,rcx
  mov rcx,[stdout]
  mov r9,0
  mov qword [rsp+32],0
  call [WriteConsoleA]
  leave
  ret

printf:
  mov [rsp+16],rdx
  mov [rsp+24],r8
  mov [rsp+32],r9
  lea rax,[rsp+16]
  msgbuf equ [rbp-8]
  args equ [rbp-16]
  push rbx
  enter 10*8,0
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
    call print
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
    call print
    call fail
  @@:
  leave
  pop rbx
  ret

get_page_size:
  enter 4*8+64,0 ;reserve space for SYSTEM_INFO struct
  lea rcx,[rbp-50]
  call [GetSystemInfo]
  mov eax,[rbp-46]
  leave
  ret

raw_alloc:
  enter 4*8,0
  mov rdx,rcx
  mov rcx,0
  mov r8,MEM_COMMIT or MEM_RESERVE
  mov r9,PAGE_READWRITE
  call [VirtualAlloc]
  cmp rax,0
  jne @f
    mov rcx,func_raw_alloc
    mov rdx,func_raw_alloc_size
    call print
    call fail
  @@:
  leave
  ret

raw_free:
  enter 4*8,0
  mov rdx,0
  mov r8,MEM_RELEASE
  call [VirtualFree]
  cmp rax,0
  jne @f
    mov rcx,func_raw_free
    mov rdx,func_raw_free_size
    call print
    call fail
  @@:
  leave
  ret

fail:
  errorbuffer equ [rbp-8]
  enter 8*8,0
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
  leave
  ret

exit:
  enter 4*8,0
  ; the stack must be 16-byte aligned or ExitProcess will crash!
  call [ExitProcess]


section 'import' import readable writeable
  dd 0,0,0, rva kernel_name, rva kernel_address_table
  dd 0,0,0,0,0

kernel_name db 'KERNEL32.DLL',0

kernel_address_table:
  ExitProcess               dq rva ExitProcess_import
  TerminateProcess          dq rva TerminateProcess_import
  GetCurrentProcess         dq rva GetCurrentProcess_import
  GetStdHandle              dq rva GetStdHandle_import
  WriteConsoleA             dq rva WriteConsoleA_import
  CreateFileA               dq rva CreateFileA_import
  ReadFile                  dq rva ReadFile_import
  CloseHandle               dq rva CloseHandle_import
  GetLastError              dq rva GetLastError_import
  FormatMessageA            dq rva FormatMessageA_import
  GetFileSizeEx	            dq rva GetFileSizeEx_import
  VirtualAlloc              dq rva VirtualAlloc_import
  VirtualFree               dq rva VirtualFree_import
  VirtualProtect            dq rva VirtualProtect_import
  LocalFree                 dq rva LocalFree_import
  QueryPerformanceFrequency dq rva QueryPerformanceFrequency_import
  QueryPerformanceCounter   dq rva QueryPerformanceCounter_import
  FlushInstructionCache     dq rva FlushInstructionCache_import
  GetSystemInfo             dq rva GetSystemInfo_import
  dq 0

ExitProcess_import db 0,0,'ExitProcess',0
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

GetStdHandle_import db 0,0,'GetStdHandle',0
; https://learn.microsoft.com/en-us/windows/console/getstdhandle
; HANDLE WINAPI GetStdHandle(
;   _In_ DWORD nStdHandle
; );

WriteConsoleA_import db 0,0,'WriteConsoleA',0
; https://learn.microsoft.com/en-us/windows/console/writeconsole
; BOOL WINAPI WriteConsole(
;   _In_             HANDLE  hConsoleOutput,
;   _In_       const VOID    *lpBuffer,
;   _In_             DWORD   nNumberOfCharsToWrite,
;   _Out_opt_        LPDWORD lpNumberOfCharsWritten,
;   _Reserved_       LPVOID  lpReserved
; );

CreateFileA_import db 0,0,'CreateFileA',0
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

ReadFile_import db 0,0,'ReadFile',0
; https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
; BOOL ReadFile(
;   [in]                HANDLE       hFile,
;   [out]               LPVOID       lpBuffer,
;   [in]                DWORD        nNumberOfBytesToRead,
;   [out, optional]     LPDWORD      lpNumberOfBytesRead,
;   [in, out, optional] LPOVERLAPPED lpOverlapped
; );

CloseHandle_import db 0,0,'CloseHandle',0
; https://learn.microsoft.com/en-us/windows/win32/api/handleapi/nf-handleapi-closehandle
; BOOL CloseHandle(
;   [in] HANDLE hObject
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

VirtualFree_import db 0,0,'VirtualFree',0
; https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualfree
; BOOL VirtualFree(
;   [in] LPVOID lpAddress,
;   [in] SIZE_T dwSize,
;   [in] DWORD  dwFreeType
; );

VirtualProtect_import db 0,0,'VirtualProtect',0
; https://learn.microsoft.com/en-us/windows/win32/api/memoryapi/nf-memoryapi-virtualprotect
; BOOL VirtualProtect(
;   [in]  LPVOID lpAddress,
;   [in]  SIZE_T dwSize,
;   [in]  DWORD  flNewProtect,
;   [out] PDWORD lpflOldProtect
; );

LocalFree_import db 0,0,'LocalFree',0
; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-localfree
; HLOCAL LocalFree(
;   [in] _Frees_ptr_opt_ HLOCAL hMem
; );

QueryPerformanceFrequency_import db 0,0,'QueryPerformanceFrequency',0
; https://learn.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancefrequency
; BOOL QueryPerformanceFrequency(
;   [out] LARGE_INTEGER *lpFrequency
; );

QueryPerformanceCounter_import db 0,0,'QueryPerformanceCounter',0
; https://learn.microsoft.com/en-us/windows/win32/api/profileapi/nf-profileapi-queryperformancecounter
; BOOL QueryPerformanceCounter(
;   [out] LARGE_INTEGER *lpPerformanceCount
; );

FlushInstructionCache_import db 0,0,'FlushInstructionCache',0
; https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-flushinstructioncache
; BOOL FlushInstructionCache(
;   [in] HANDLE  hProcess,
;   [in] LPCVOID lpBaseAddress,
;   [in] SIZE_T  dwSize
; );

GetSystemInfo_import db 0,0,'GetSystemInfo',0
; https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getsysteminfo
; void GetSystemInfo(
;   [out] LPSYSTEM_INFO lpSystemInfo
; );
; typedef struct _SYSTEM_INFO {
;   union {
;     DWORD dwOemId;
;     struct {
;       WORD wProcessorArchitecture;
;       WORD wReserved;
;     } DUMMYSTRUCTNAME;
;   } DUMMYUNIONNAME;
;   DWORD     dwPageSize;
;   LPVOID    lpMinimumApplicationAddress;
;   LPVOID    lpMaximumApplicationAddress;
;   DWORD_PTR dwActiveProcessorMask;
;   DWORD     dwNumberOfProcessors;
;   DWORD     dwProcessorType;
;   DWORD     dwAllocationGranularity;
;   WORD      wProcessorLevel;
;   WORD      wProcessorRevision;
; } SYSTEM_INFO, *LPSYSTEM_INFO;
