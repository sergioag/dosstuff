#include <stdio.h>

#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
	(byte & 0x80 ? '1' : '0'), \
	(byte & 0x40 ? '1' : '0'), \
	(byte & 0x20 ? '1' : '0'), \
	(byte & 0x10 ? '1' : '0'), \
	(byte & 0x08 ? '1' : '0'), \
	(byte & 0x04 ? '1' : '0'), \
	(byte & 0x02 ? '1' : '0'), \
	(byte & 0x01 ? '1' : '0')

char *charName(int c) {
	switch(c) {
		case 0x00:
			return "NUL ";
		case 0x01:
			return "SOH ";
		case 0x02:
			return "STX ";
		case 0x03:
			return "ETX ";
		case 0x04:
			return "EOT ";
		case 0x05:
			return "ENQ ";
		case 0x06:
			return "ACK ";
		case 0x07:
			return "BEL ";
		case 0x08:
			return "BS ";
		case 0x09:
			return "HT ";
		case 0x0a:
			return "LF ";
		case 0x0b:
			return "VT ";
		case 0x0c:
			return "FF ";
		case 0x0d:
			return "CR ";
		case 0x0e:
			return "SO ";
		case 0x0f:
			return "SI ";
		case 0x10:
			return "DLE ";
		case 0x11:
			return "DC1 ";
		case 0x12:
			return "DC2 ";
		case 0x13:
			return "DC3 ";
		case 0x14:
			return "DC4 ";
		case 0x15:
			return "NAK ";
		case 0x16:
			return "SYN ";
		case 0x17:
			return "ETB ";
		case 0x18:
			return "CAN ";
		case 0x19:
			return "EM ";
		case 0x1a:
			return "SUB ";
		case 0x1b:
			return "ESC ";
		case 0x1c:
			return "FS ";
		case 0x1d:
			return "GS ";
		case 0x1e:
			return "RS ";
		case 0x1f:
			return "US ";
		case 0x20:
			return "Space ";
		case 0x21:
			return "! ";
		case 0x22:
			return "\" ";
		case 0x23:
			return "# ";
		case 0x24:
			return "$ ";
		case 0x25:
			return "% ";
		case 0x26:
			return "& ";
		case 0x27:
			return "' ";
		case 0x28:
			return "( ";
		case 0x29:
			return ") ";
		case 0x2a:
			return "* ";
		case 0x2b:
			return "+ ";
		case 0x2c:
			return ", ";
		case 0x2d:
			return "- ";
		case 0x2e:
			return ". ";
		case 0x2f:
			return "/ ";
		case 0x30:
			return "0 ";
		case 0x31:
			return "1 ";
		case 0x32:
			return "2 ";
		case 0x33:
			return "3 ";
		case 0x34:
			return "4 ";
		case 0x35:
			return "5 ";
		case 0x36:
			return "6 ";
		case 0x37:
			return "7 ";
		case 0x38:
			return "8 ";
		case 0x39:
			return "9 ";
		case 0x3a:
			return ": ";
		case 0x3b:
			return "; ";
		case 0x3c:
			return "< ";
		case 0x3d:
			return "= ";
		case 0x3e:
			return "> ";
		case 0x3f:
			return "? ";
		case 0x40:
			return "@ ";
		case 0x41:
			return "A ";
		case 0x42:
			return "B ";
		case 0x43:
			return "C ";
		case 0x44:
			return "D ";
		case 0x45:
			return "E ";
		case 0x46:
			return "F ";
		case 0x47:
			return "G ";
		case 0x48:
			return "H ";
		case 0x49:
			return "I ";
		case 0x4a:
			return "J ";
		case 0x4b:
			return "K ";
		case 0x4c:
			return "L ";
		case 0x4d:
			return "M ";
		case 0x4e:
			return "N ";
		case 0x4f:
			return "O ";
		case 0x50:
			return "P ";
		case 0x51:
			return "Q ";
		case 0x52:
			return "R ";
		case 0x53:
			return "S ";
		case 0x54:
			return "T ";
		case 0x55:
			return "U ";
		case 0x56:
			return "V ";
		case 0x57:
			return "W ";
		case 0x58:
			return "X ";
		case 0x59:
			return "Y ";
		case 0x5a:
			return "Z ";
		case 0x5b:
			return "[ ";
		case 0x5c:
			return "\\ ";
		case 0x5d:
			return "] ";
		case 0x5e:
			return "^ ";
		case 0x5f:
			return "_ ";
		case 0x60:
			return "` ";
		case 0x61:
			return "a ";
		case 0x62:
			return "b ";
		case 0x63:
			return "c ";
		case 0x64:
			return "d ";
		case 0x65:
			return "e ";
		case 0x66:
			return "f ";
		case 0x67:
			return "g ";
		case 0x68:
			return "h ";
		case 0x69:
			return "i ";
		case 0x6a:
			return "j ";
		case 0x6b:
			return "k ";
		case 0x6c:
			return "l ";
		case 0x6d:
			return "m ";
		case 0x6e:
			return "n ";
		case 0x6f:
			return "o ";
		case 0x70:
			return "p ";
		case 0x71:
			return "q ";
		case 0x72:
			return "r ";
		case 0x73:
			return "s ";
		case 0x74:
			return "t ";
		case 0x75:
			return "u ";
		case 0x76:
			return "v ";
		case 0x77:
			return "w ";
		case 0x78:
			return "x ";
		case 0x79:
			return "y ";
		case 0x7a:
			return "z ";
		case 0x7b:
			return "{ ";
		case 0x7c:
			return "| ";
		case 0x7d:
			return "} ";
		case 0x7e:
			return "~ ";
		case 0x7f:
			return "";
		default:
			return "";
	}
}

int main(int argc, char **argv) {
	if(argc < 5) {
		fprintf(stderr, "Invalid parameters\n\n");
		fprintf(stderr, "%s binFile outputFile offset charHeight\n", argv[0]);
		return -1;
	}

	int offset;
	if(sscanf(argv[3], "%i", &offset) != 1) {
		fprintf(stderr, "Invalid offset: %s\n", argv[3]);
		goto _exit;
	}

	int charHeight;
	if(sscanf(argv[4], "%i", &charHeight) != 1) {
		fprintf(stderr, "Invalid char height: %s\n", argv[4]);
		goto _exit;
	}

	FILE *binFile = fopen(argv[1], "rb");
	if(binFile == NULL) {
		fprintf(stderr, "Cannot open bin file: %s\n", argv[1]);
		goto _exit;
	}

	FILE *outFile = fopen(argv[2], "wt");
	if(outFile == NULL) {
		fprintf(stderr, "Cannot open output file: %s\n", argv[2]);
		goto _exit;
	}

	printf("Processing file '%s', starting at offset %i with a character height of %i bytes...\n", argv[1], offset, charHeight);

	if(fseek(binFile, offset, SEEK_SET) != 0) {
		fprintf(stderr, "Error seeking to offset %i\n", offset);
		goto _exit;
	}

	for(int i = 0; i < 256; i++) {
		fprintf(outFile, "\t; %s(%02Xh)\n", charName(i), i);
		for(int j = 0; j < charHeight; j++) {
			unsigned char c;
			if(fread(&c, 1, 1, binFile) != 1) {
				fprintf(stderr, "Error readding input file.\n");
				goto _exit;
			}
			fprintf(outFile, "\tdb\t" BYTE_TO_BINARY_PATTERN "b\n", BYTE_TO_BINARY(c));
		}
		fprintf(outFile, "\n");
	}

_exit:
	if(outFile != NULL) {
		fclose(outFile);
		outFile = NULL;
	}

	if(binFile != NULL) {
		fclose(binFile);
		binFile = NULL;
	}
	return -1;
}
