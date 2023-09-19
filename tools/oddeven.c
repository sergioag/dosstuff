
#include <stdio.h>
#include <stdlib.h>


void usage(char *path) {
	printf("%s: odd_file even_file output_file\n", path);
	printf("Combines odd_file and even_file alternatively to output_file\n");
	printf("Useful for combining 286+ BIOS images in separate Odd & Even ROMs\n");
}

long getSize(FILE *fh) {
	long curPos = ftell(fh);
	fseek(fh, 0, SEEK_END);
	long endPos = ftell(fh);
	fseek(fh, curPos, SEEK_SET);
	return endPos;
}

int main(int argc, char **argv) {
	FILE *oddFile = NULL, *evenFile = NULL, *outputFile = NULL;
	char *oddBuffer = NULL, *evenBuffer = NULL, *outputBuffer = NULL;;
	if(argc != 4) {
		usage(argv[0]);
		return -2;
	}

	oddFile = fopen(argv[1], "rb");
	if(oddFile == NULL) {
		printf("Error opening odd file: %s\n", argv[1]);
		goto _exit;
	}

	evenFile = fopen(argv[2], "rb");
	if(evenFile == NULL) {
		printf("Error opening even file: %s\n", argv[2]);
		goto _exit;
	}

	outputFile = fopen(argv[3], "wb");
	if(outputFile == NULL) {
		printf("Error opening output file: %s\n", argv[3]);
		goto _exit;
	}

	long oddSize = getSize(oddFile);
	long evenSize = getSize(evenFile);
	
	if(oddSize != evenSize) {
		printf("Odd and even files don't have a matching size: %li vs %li\n", oddSize, evenSize);
		goto _exit;
	}

	oddBuffer = malloc(oddSize);
	if(oddBuffer == NULL) {
		printf("Cannot allocate %li bytes for odd file\n", oddSize);
		goto _exit;
	}

	evenBuffer = malloc(evenSize);
	if(evenBuffer == NULL) {
		printf("Cannot allocate %li bytes for even file\n", evenSize);
		goto _exit;
	}

	size_t n = fread(oddBuffer, 1, oddSize, oddFile);
	if(n != oddSize) {
		printf("Error reading from odd file. Could only read %lu bytes.\n", n);
		goto _exit;
	}
	
	n = fread(evenBuffer, 1, evenSize, evenFile);
	if(n != evenSize) {
		printf("Error reading from even file. Could only read %lu bytes.\n", n);
		goto _exit;
	}

	outputBuffer = malloc(oddSize+evenSize);

	for(long i = 0; i < oddSize; i++) {
		outputBuffer[(2*i)+0] = evenBuffer[i];
		outputBuffer[(2*i)+1] = oddBuffer[i];
	}

	n = fwrite(outputBuffer, 1, evenSize+oddSize, outputFile);
	if(n != (evenSize+oddSize)) {
		printf("Error writing output file. Could only write %lu bytes.\n", n);
		goto _exit;
	}

	free(outputBuffer);
	free(evenBuffer);
	free(oddBuffer);
	fclose(outputFile);
	fclose(evenFile);
	fclose(oddFile);
	return 0;
_exit:
	if(outputBuffer != NULL) {
		free(outputBuffer);
		outputBuffer = NULL;
	}
	if(evenBuffer != NULL) {
		free(evenBuffer);
		evenBuffer = NULL;
	}

	if(oddBuffer != NULL) {
		free(oddBuffer);
		oddBuffer = NULL;
	}

	if(oddFile != NULL) {
		fclose(oddFile);
		oddFile = NULL;
	}
	if(evenFile != NULL) {
		fclose(evenFile);
		evenFile = NULL;
	}
	if(outputFile != NULL) {
		fclose(outputFile);
		outputFile = NULL;
	}

	return -2;
}
