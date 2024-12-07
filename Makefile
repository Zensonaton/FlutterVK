INNO_VERSION=6.3.3

innoinstall:
	powershell curl -o build\inno-installer.exe http://files.jrsoftware.org/is/6/innosetup-${INNO_VERSION}.exe
	.\build\inno-installer.exe /verysilent /allusers /dir=build\iscc

inno:
	powershell .\build\iscc\iscc.exe .\scripts\windows-setup-creator.iss
