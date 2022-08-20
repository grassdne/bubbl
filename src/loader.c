#include "common.h"
#include <stdlib.h>
#include <stdio.h>

const char* mallocShaderSource(const char* fpath) {
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
