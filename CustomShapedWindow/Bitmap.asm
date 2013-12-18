.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc 
include \masm32\include\user32.inc 
include \masm32\include\kernel32.inc 
include \masm32\include\gdi32.inc 
includelib \masm32\lib\user32.lib 
includelib \masm32\lib\kernel32.lib 
includelib \masm32\lib\gdi32.lib

WinMain proto :DWORD, :DWORD, :DWORD, :DWORD
IDB_MYBITMAP equ 100

.data
ClassName db "Win32Bitmap",0
AppName db "Win32Bitmap",0
Error db "ERROR!",0

.data?
hInstance HINSTANCE ?
hBitmap dd ?

.code
start:
	invoke GetModuleHandle, NULL
	mov hInstance, eax
	invoke WinMain, hInstance, NULL, NULL, SW_SHOWDEFAULT
	invoke ExitProcess, eax
	
	WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
		LOCAL wc:WNDCLASSEX
		LOCAL msg:MSG
		LOCAL hWnd:HWND
		
		mov wc.cbSize, SIZEOF WNDCLASSEX
		mov wc.style, CS_HREDRAW or CS_VREDRAW
		mov wc.lpfnWndProc, OFFSET WndProc
		mov wc.cbClsExtra, NULL
		mov wc.cbWndExtra, NULL
		push hInstance
		pop wc.hInstance
		mov wc.hbrBackground, COLOR_WINDOW+3
		mov wc.lpszMenuName, NULL
		mov wc.lpszClassName, OFFSET ClassName
		invoke LoadIcon, NULL, IDI_APPLICATION
		mov wc.hIcon, eax
		mov wc.hIconSm, eax
		invoke LoadCursor, NULL, IDC_ARROW
		mov wc.hCursor, eax
		invoke RegisterClassEx, ADDR wc
		invoke CreateWindowEx, NULL, ADDR ClassName, ADDR AppName, WS_POPUP, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInst, NULL
		mov hWnd, eax
		invoke ShowWindow, hWnd, SW_SHOWNORMAL
		invoke UpdateWindow, hWnd
		
		.while TRUE
			invoke GetMessage, ADDR msg, NULL, 0, 0
			.break .if (!eax)
				invoke TranslateMessage, ADDR msg
				invoke DispatchMessage, ADDR msg
		.endw
		
		mov eax, msg.wParam
		ret
	WinMain endp

	WndProc proc hWnd:HWND, message:UINT, wParam:WPARAM, lParam:LPARAM
		LOCAL ps:PAINTSTRUCT
		LOCAL hdc:HDC
		LOCAL hMemDC:HDC
		LOCAL rect:RECT
		LOCAL hRegion:HRGN
		LOCAL hRgnTmp:HRGN
		LOCAL bmp:BITMAP
		LOCAL pixel:DWORD;
		LOCAL crTransparent:COLORREF;
		LOCAL cont:DWORD;
		
		.if message == WM_CREATE
			invoke BeginPaint, hWnd, ADDR ps
			mov hdc, eax
			invoke CreateCompatibleDC, hdc
			mov hMemDC, eax
			invoke GetModuleHandle, NULL
			invoke LoadBitmap, eax, 1
			mov hBitmap, eax
			invoke GetObject, hBitmap, SIZEOF bmp, ADDR bmp
			invoke SelectObject, hMemDC, hBitmap
			
			;centro la finestra
			invoke GetSystemMetrics, SM_CXSCREEN
			mov ebx, eax ;Width
			invoke GetSystemMetrics, SM_CYSCREEN
			mov ecx, eax ;Height
			
			sub ebx, bmp.bmWidth
			xor edx, edx
			mov eax, ebx
			mov ebx, 2
			div ebx
			xor ebx, ebx
			mov ebx, eax
			
			push ebx

			sub ecx, bmp.bmHeight
			xor edx, edx
			mov eax, ecx
			mov ebx, 2
			div ebx
			xor ecx, ebx
			mov ecx, eax
			
			xor ebx, ebx
			pop ebx

			invoke MoveWindow, hWnd, ebx, ecx, bmp.bmWidth, bmp.bmHeight, TRUE
			;applico l'effetto trasparenza
			mov crTransparent, 00ffffffh
			invoke CreateRectRgn, 0, 0, bmp.bmWidth, bmp.bmHeight
			mov hRegion, eax
			mov ebx, 0 ;Y
			mov ecx, 0 ;X
			.while (ebx < bmp.bmHeight)
				.while (ecx < bmp.bmWidth)
					.while (ecx < bmp.bmWidth)
						push ecx
						push ebx
						invoke GetPixel, hMemDC, ecx, ebx
						pop ebx
						pop ecx
						mov pixel, eax
						.if (eax == crTransparent)
							.break
						.endif
						inc ecx
						mov cont, ecx
					.endw
					mov edx, ecx ;salvo il pixel più a sinistra
					push edx
					.while (ecx < bmp.bmWidth)
						push ecx
						push ebx
						invoke GetPixel, hMemDC, ecx, ebx
						pop ebx
						pop ecx
						mov pixel, eax
						.if (eax != crTransparent)
							.break
						.endif
						inc ecx
						mov cont, ecx
					.endw
					mov eax, ebx
					inc eax
					pop edx
					;dec edx
					push ecx
					inc ecx
					inc ecx
					invoke CreateRectRgn, edx, ebx, ecx, eax
					pop ecx
					mov hRgnTmp, eax
					invoke CombineRgn, hRegion, hRegion, hRgnTmp, RGN_DIFF
					.if (eax == ERROR)
						invoke MessageBox, NULL, ADDR Error, ADDR Error, MB_OK
					.endif
					invoke DeleteObject, hRgnTmp
					mov ecx, cont
				.endw
				mov ecx, 0
				inc ebx
			.endw
			;applico la Region alla finestra
			invoke SetWindowRgn, hWnd, hRegion, TRUE
			invoke DeleteDC, hMemDC
			invoke EndPaint, hWnd, ADDR ps
		.elseif message == WM_PAINT
			invoke BeginPaint, hWnd, addr ps 
			mov    hdc, eax 
			invoke CreateCompatibleDC, hdc
			mov    hMemDC,eax
			invoke SelectObject, hMemDC, hBitmap
			invoke GetClientRect,hWnd,addr rect
			invoke BitBlt, hdc, 1, 0, rect.right, rect.bottom, hMemDC, 0, 0, SRCCOPY 
			invoke DeleteDC, hMemDC 
			invoke EndPaint, hWnd, addr ps 
		.elseif message == WM_DESTROY
			invoke DeleteObject, hBitmap
			invoke PostQuitMessage, NULL
		.elseif message == WM_LBUTTONDOWN
			invoke SendMessage, hWnd, WM_NCLBUTTONDOWN, HTCAPTION, NULL
		.else
			invoke DefWindowProc, hWnd, message, wParam, lParam
			ret
		.endif
			xor eax, eax
			ret
	WndProc endp
end start