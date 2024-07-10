#include <stdio.h>
#include <stdlib.h>
#include <process.h>
#include "updater.h"

int main(void) {
	system("powershell -command \"Expand-Archive -Force " downloadFilename " .\"");
	remove(downloadFilename);
	execv(binaryFilename, NULL);
	return 0;
}
