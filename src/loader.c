#include "common.h"
#include <stdlib.h>
#include <stdio.h>

static void getSourceFilePath(const char* name, char *out_fullpath) {
    //trim off the end of __FILE__ to get current directory
	const char sourcepath[] = __FILE__;
	int last = sizeof(sourcepath) - 1;
	while (sourcepath[last] != '\\' && sourcepath[last] != '/' && last >= 0) --last;
	int base_len = last + 1;

	strncpy(out_fullpath, sourcepath, base_len); /* directory path */
	strcpy(out_fullpath + base_len, name); /* ending */
}

const char* mallocShaderSource(const char* fname) {
    char fpath[1024];
    getSourceFilePath(fname, fpath);

	FILE* f;
	if ((f = fopen(fpath, "r")) == NULL) {
		fprintf(stderr, "File (%s): %s", fpath, ERROR());
		exit(1);
	}
	fseek(f, 0, SEEK_END);
	size_t size = ftell(f);
	fseek(f, 0, SEEK_SET);

	char* s = malloc(size + 1);
	if ((fread(s, sizeof(char), size, f)) == 0) {
		fprintf(stderr, "File (%s): %s", fpath, ERROR());
		exit(1);
	}
    fclose(f);
	s[size] = '\0';

	return s;
}
