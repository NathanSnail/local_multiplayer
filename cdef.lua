local ffi = require("ffi")

-- what a mess, the first part is general win api stuff, the second is features we actually use
ffi.cdef([[
typedef signed char __int8_t;
typedef unsigned char __uint8_t;
typedef signed short int __int16_t;
typedef unsigned short int __uint16_t;
typedef signed int __int32_t;
typedef unsigned int __uint32_t;
typedef signed long int __int64_t;
typedef unsigned long int __uint64_t;

typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef signed short int16_t;
typedef unsigned short uint16_t;
typedef signed int int32_t;
typedef unsigned int uint32_t;




typedef int BOOL;
typedef char CHAR;
typedef short SHORT;
typedef int INT;
typedef long LONG;
typedef unsigned char UCHAR;
typedef unsigned short USHORT;
typedef unsigned int UINT;
typedef unsigned long ULONG;
typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef float FLOAT;
typedef unsigned long DWORD;

typedef wchar_t WCHAR;
typedef wchar_t *PWCHAR;
typedef WORD ATOM;
typedef unsigned int ULONG32;
typedef uint64_t DWORD64;
typedef uint64_t ULONG64;
typedef signed int INT32;
typedef __int64_t INT64;
typedef uint64_t DWORDLONG;


typedef void VOID;
typedef void *PVOID;
typedef void *LPVOID;
typedef BOOL *PBOOL;
typedef BOOL *LPBOOL;
typedef WORD *PWORD;
typedef LONG *PLONG;
typedef LONG *LPLONG;
typedef DWORD *PDWORD;

typedef LPVOID HANDLE;
typedef HANDLE HINSTANCE;
typedef HANDLE HWND;
typedef HINSTANCE HMODULE;
typedef HANDLE HDC;
typedef HANDLE HGLRC;
typedef HANDLE HMENU;
typedef HANDLE *PHANDLE;
typedef HANDLE *LPHANDLE;

typedef WCHAR *PWSTR;
typedef BYTE *LPBYTE;
typedef long *LPLONG;
typedef DWORD *LPDWORD;
typedef const void *LPCVOID;

typedef int64_t INT_PTR;
typedef int64_t LONG_PTR;
typedef uint64_t UINT_PTR;
typedef uint64_t ULONG_PTR;

typedef ULONG_PTR DWORD_PTR;
typedef DWORD_PTR *PDWORD_PTR;

typedef ULONG_PTR SIZE_T;
typedef LONG_PTR SSIZE_T;

typedef CHAR *LPSTR;
typedef WCHAR *LPWSTR;
typedef const CHAR *LPCSTR;
typedef const WCHAR *LPCWSTR;

typedef char TCHAR;
typedef unsigned char TBYTE;
typedef LPCSTR LPCTSTR;
typedef LPSTR LPTSTR;

typedef INT_PTR(__stdcall *FARPROC)(void);
typedef INT_PTR(__stdcall *NEARPROC)(void);
typedef INT_PTR(__stdcall *PROC)(void);

typedef DWORD ACCESS_MASK;
typedef ACCESS_MASK *PACCESS_MASK;

typedef HANDLE HICON;
typedef HANDLE HBRUSH;
typedef HICON HCURSOR;

typedef LONG HRESULT;
typedef LONG_PTR LRESULT;
typedef LONG_PTR LPARAM;
typedef UINT_PTR WPARAM;

typedef void *HGDIOBJ;

typedef HANDLE HKEY;
typedef HKEY *PHKEY;
typedef ACCESS_MASK REGSAM;







int __stdcall MessageBoxA(HWND hWND, LPCSTR lpText, LPCSTR lpCaption, UINT uType);

typedef DWORD(__stdcall *PTHREAD_START_ROUTINE)(LPVOID);

typedef PTHREAD_START_ROUTINE LPTHREAD_START_ROUTINE;

typedef struct _SECURITY_ATTRIBUTES {
	DWORD nLength;
	LPVOID lpSecurityDescriptor;
	BOOL bInheritHandle;
} SECURITY_ATTRIBUTES, *PSECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;


DWORD GetCurrentThreadId();

void Sleep(DWORD dwMilliseconds);
HANDLE CreateFileMappingA(HANDLE hFile, LPSECURITY_ATTRIBUTES lpFileMappingAttributes, DWORD flProtect, DWORD dwMaximumSizeHigh, DWORD dwMaximumSizeLow, LPCSTR lpName);
LPVOID MapViewOfFile(HANDLE hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, SIZE_T dwNumberOfBytesToMap);
HANDLE OpenFileMappingA(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCSTR lpName);
BOOL UnmapViewOfFile(LPVOID lpBaseAddress);
BOOL CloseHandle(HANDLE hObject);
USHORT GetAsyncKeyState(int vKey);
]])
