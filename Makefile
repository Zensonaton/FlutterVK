INNO_VERSION=6.2.0

innoinstall:
	powershell curl -o build\inno-installer.exe http://files.jrsoftware.org/is/6/innosetup-${INNO_VERSION}.exe
	.\build\inno-installer.exe /verysilent /allusers /dir=build\iscc

inno:
	powershell .\build\iscc\iscc.exe windows-setup-creator.iss
