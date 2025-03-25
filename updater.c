#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include "updater.h"

void newProcess(const char *path) {
	STARTUPINFO si = { sizeof(si) };
	PROCESS_INFORMATION pi;
	if (CreateProcess(path, NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
		CloseHandle(pi.hProcess);
		CloseHandle(pi.hThread);
	} else {
		printf("Failed to start process. Error: %d\n", GetLastError());
	}
}

int main(void) {
	system("powershell -command \"Expand-Archive -Force " downloadFilename " .\"");
	remove(downloadFilename);
	newProcess(binaryFilename);
	return 0;
}
