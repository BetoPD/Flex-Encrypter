%option noyywrap
/* %x FASTA */
%x PARAMETERS

%{
#include <iostream>
#include <stdio.h>
#include <string>

std::string fastaFile;
unsigned int offset;
unsigned int tries;
unsigned int parameterPos;


        
%}

%%

^"#" {
    BEGIN PARAMETERS;
}

<PARAMETERS>[^,]+ {

    int c;

    while((c = yyinput()) && c != '\n'); 
    
    
    if (parameterPos == 0) {
        fastaFile = yytext;
    } else if (parameterPos == 1) {
        offset = atoi(yytext);
    } else if (parameterPos == 2) {
        tries = atoi(yytext);
    }

    parameterPos++;
}



<PARAMETERS>\n {
    parameterPos = 0;
    /* BEGIN FASTA; */
}

. |
\n {
    // ignore the rest
}

%%

int main(int argc, char **argv)
{

    // parse the input
    yylex();

    // print the parsed values
    std::cout << "Fasta file: " << fastaFile << std::endl;
    std::cout << "Offset: " << offset << std::endl;
    std::cout << "Tries: " << tries << std::endl;


    return 0;
}