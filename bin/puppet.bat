@ECHO OFF
IF NOT "%~f0" == "~f0" GOTO :WinNT
rem @"C:\Ruby\ruby-2.2.4-x64-mingw32\bin\ruby.exe" "C:/Ruby/ruby-2.2.4-x64-mingw32/bin/puppet" %1 %2 %3 %4 %5 %6 %7 %8 %9
@"%~dp0\ruby.exe" "%~dp0\puppet" %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO :EOF
:WinNT
@"%~dp0\ruby.exe" "%~dpn0" %*
