%option noyywrap
%x FASTA
%x PARAMETERS

%{
#include <iostream>
#include <stdio.h>
#include <string>

char *fastaFile;
unsigned int offset;
unsigned int tries;
unsigned int parameterPos;
char *curfilename; /* name of current input file */

struct bufstack {
    struct bufstack *prev;  /* previous entry */
    YY_BUFFER_STATE bs;     /* saved buffer */
    int lineno;             /* saved line number */
    char *filename;         /* name of this file */
    FILE *f;                /* current file */
} *curbs = 0;               /* name of current input file */

int newfile(char *fn);
int popfile(void);
        
%}

%%

^"#" {
    BEGIN PARAMETERS;
}

<PARAMETERS>[^,\n]+ {
    
    if (parameterPos == 0) {
        fastaFile = yytext;
    } else if (parameterPos == 1) {
        offset = atoi(yytext);
    } else if (parameterPos == 2) {
        tries = atoi(yytext);
    }

    parameterPos++;
}

<PARAMETERS>, {
    // ignore
}

<PARAMETERS>\n {
    parameterPos = 0;
    newfile(fastaFile);
    BEGIN FASTA;
}

<FASTA> {
    // ignore
}

. |
\n {
    // ignore the rest
}

%%

int  main(int argc, char **argv)
{
    if(argc < 2) {
        fprintf(stderr, "need filename\n");
        return 1;
    }
    if(newfile(argv[1]))
        yylex();
}

int newfile(char *fn)
{
    FILE *f = fopen(fn, "r");
    struct bufstack *bs = (struct bufstack *)malloc(sizeof(struct bufstack));
    /* die if no file or no room */
    if(!f) { perror(fn); return 0; }
    if(!bs) { perror("malloc"); exit(1); }
    /* remember state */
    if(curbs)curbs->lineno = yylineno;
    bs->prev = curbs;
    /* set up current entry */
    bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
    bs->f = f;
    bs->filename = fn;
    yy_switch_to_buffer(bs->bs);
    curbs = bs;
    yylineno = 1;
    curfilename = fn;
    return 1;
}

int popfile(void)
{
    struct bufstack *bs = curbs;
    struct bufstack *prevbs;
    if(!bs) return 0;
    /* get rid of current entry
    fclose(bs->f);
    yy_delete_buffer(bs->bs);
    switch back to previous */
    prevbs = bs->prev;
    free(bs);
    if(!prevbs) return 0;
    yy_switch_to_buffer(prevbs->bs);
    curbs = prevbs;
    yylineno = curbs->lineno;
    curfilename = curbs->filename;
    return 1;
}