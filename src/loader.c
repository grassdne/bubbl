#include "common.h"
#include <stdlib.h>
#include <stdio.h>

const char* mallocShaderSource(const char* fpath) {
	FILE* f;
	if ((f = fopen(fpath, "r")) == NULL) {
		fprintf(stderr, "Unable to open file (%s): %s", fpath, ERROR());
		exit(1);
	}
	if (fseek(f, 0, SEEK_END)) {
        fprintf(stderr, "Unable to seek file (%s): %s", fpath, ERROR());
        exit(1);
    }
	size_t size = ftell(f);
    rewind(f);

	char* s = malloc(size + 1);
    if (s == NULL) {
        exit(1);
    }
	if ((fread(s, sizeof(char), size, f)) == 0) {
		fprintf(stderr, "Unable to read file (%s): %s", fpath, ERROR());
		exit(1);
	}
    fclose(f);
	s[size] = '\0';

	return s;
}
