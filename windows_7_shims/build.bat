call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cd /d "%~dp0"
cl.exe /O2 /LD /NODEFAULTLIB /GS- nt_w7.c /link /DEF:nt_w7.def /ENTRY:DllMain kernel32.lib ntdll.lib
