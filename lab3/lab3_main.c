/********
 * A simple program which integrate C and Assembly codes. The main program
 * calls printn function, written in assembly. The printn function, then,
 * determines and prints the number format (i.e. octal, hex, or decimal)
 * through JTAG UART terminal.
 *
 * (1) assmebly function(s)
 *     printn ( char * , ... ) ;
 * (2) C function(s)
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 * 
 * July 21 2007: Supakorn Komthong
 *
 * July 25 2007: Peter Yiannacouras
 ********/

#include <stdio.h>

void printn ( char *, ... );

void printOct ( int );
void printHex ( int );
void printDec ( int );

int main ( )
{

	char* text = "dddddddooooooohhhhhhh";
 
	printn (
	  text, 10, 11, 12, 13, 14, 15, 16,
		10, 11, 12, 13, 14, 15, 16,
		10, 11, 12, 13, 14, 15, 16
	);

	return 0;
}


void printOct ( int val ) { printf ("%o\n", val); }

void printHex ( int val ) { printf ("%X\n", val); } 

void printDec ( int val ) { printf ("%u\n", val); }

