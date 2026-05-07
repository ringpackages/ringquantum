cls
setlocal enableextensions enabledelayedexpansion
call ../../language/build/locatevc.bat x64
cl /c /O2 /Ot /MD /openmp /arch:AVX2 /DUSE_OPENCL ring_quantum.c -I"..\..\language\include" -I"./include"
link /DLL ring_quantum.obj lib\OpenCL.lib ..\..\lib\ring.lib kernel32.lib /OUT:..\..\bin\ring_quantum.dll
del ring_quantum.obj
endlocal