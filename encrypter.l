%option noyywrap
%x OFFSET
%x PARAMETERS
%x VOCABULARY

%{
#include <iostream>
#include <stdio.h>
#include <string>
#include <set>

std::string fastaFile = "./instructions/";
unsigned int offset;
unsigned int tries;
unsigned int parameterPos;
std::string curfilename; /* name of current input file */
char firstChar;
// set of chars 

std::set<char> vocabulary;
std::set<char> unusedVocabulary = {'B', 'Z', 'X', 'J', 'U', 'O'};
unsigned int numericValue;


struct bufstack {
    struct bufstack *prev;  /* previous entry */
    YY_BUFFER_STATE bs;     /* saved buffer */
    int lineno;             /* saved line number */
    std::string filename;         /* name of this file */
    FILE *f;                /* current file */
} *curbs = 0;               /* name of current input file */

int newfile(const char *fn);
int popfile(void);
        
%}

%%

^"#" {
    BEGIN PARAMETERS;
}

<PARAMETERS>[^,\n]+ {
    
    if (parameterPos == 0) {
        fastaFile += yytext;
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
    yylineno++;

    std::cout << "fasta file: " << fastaFile << std::endl;
    std::cout << "offset: " << offset << std::endl;
    std::cout << "tries: " << tries << std::endl;

    if(!newfile(fastaFile.c_str()))
        yyterminate();

    
    BEGIN OFFSET;
}

<OFFSET>^">".+ {
    // size of yytext
    unsigned int size = strlen(++yytext);

    if (offset > size) 
        offset-=size;
    else 
    {
        firstChar = yytext[offset];
        numericValue = static_cast<int>(firstChar);
        BEGIN VOCABULARY;
    }
}

<OFFSET>.|\n {
    // ignore the rest
}

<VOCABULARY>^[A-Z]+ {
    // if size of vocabulary is 20 change state
    if (vocabulary.size() >= 20)
    {
        BEGIN INITIAL;
        return 0;
    }

    unsigned int size = strlen(yytext);

    if(numericValue > size) 
        numericValue-=size;
    else 
    {
        unsigned int tempNumericValue = numericValue;
        numericValue = static_cast<int>(firstChar);

        while(tempNumericValue < size)
        {
            // std::cout << "Adding to vocabulary: " << yytext[tempNumericValue] << std::endl;
            auto it = unusedVocabulary.find(yytext[tempNumericValue]);

            // if the word is not in the unused vocabulary, add it to the vocabulary
            if (it == unusedVocabulary.end())
                vocabulary.insert(yytext[tempNumericValue]);
            

            tempNumericValue+=numericValue;
        }

        // normalize the value with respect to the size of the vocabulary
        tempNumericValue-=size;

        // if there was a missing value, use it for the next offset
        if (tempNumericValue > 0)
            numericValue = tempNumericValue;

    }
    
}

<VOCABULARY>.|\n {
    // ignore the rest
}

. |
\n {
    // ignore the rest
}

%%

int main(int argc, char **argv)
{
    if(argc < 2) {
        fprintf(stderr, "need filename\n");
        return 1;
    }
    if(newfile(argv[1]))
        yylex();

    /* first char */

    std::cout << "First char: " << firstChar << std::endl;
    std::cout << "Numeric value: " << static_cast<int>(firstChar) << std::endl;

    /* print vocabulary */
    std::cout << "Vocabulary: ";
    for (auto it = vocabulary.begin(); it != vocabulary.end(); ++it)
        std::cout << *it << " ";
    std::cout << std::endl;
    /* unused words */
    std::cout << "Unused vocabulary: ";
    for (auto it = unusedVocabulary.begin(); it != unusedVocabulary.end(); ++it)
        std::cout << *it << " ";
    std::cout << std::endl;

}

int newfile(const char *fn)
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