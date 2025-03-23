%option noyywrap
%x OFFSET
%x PARAMETERS
%x VOCABULARY

%{
#include <iostream>
#include <stdio.h>
#include <string>
#include <unordered_set>
#include <map>

std::string fastaFile = "./instructions/";
unsigned int offset;
unsigned int tries;
unsigned int thirdParameter;
unsigned int currentTries;
unsigned int parameterPos;
unsigned int lastPos = 0;
bool enc = true;
std::string curfilename; /* name of current input file */
char firstChar;
// set of chars 

std::unordered_set<char> vocabulary;
std::unordered_set<char> unusedVocabulary = {'B', 'Z', 'X', 'J', 'U', 'O'};
std::map<char, char> alphabetMap;
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
std::map<char, char> createMap();
void printVocabulary();
void resetParameters();
// File with the results
FILE *results;
        
%}

%%

^"#" {
    resetParameters();
    std::cout << "New parameters" << std::endl;
    BEGIN PARAMETERS;
}

\n {

    if (enc) 
    {
        fputc('\n', results);
        break;
    }

    if (yylineno > thirdParameter && thirdParameter != 0)
    {
        popfile();
        lastPos = yylineno;
        yylineno = 1;
        break;    
    }   
    
    if (yylineno > lastPos)
        fputc('\n', results);
    
    yylineno++;


}

. {

    if (yylineno <= lastPos && !enc)
        break;
    

    char c = *yytext;
    c = toupper(c);
    
    auto it = alphabetMap.find(c);

    if (it != alphabetMap.end())
        c = it->second;

    fputc(c, results);
        
}

<PARAMETERS>[^,\n]+ {
    
    if (parameterPos == 0) {
        fastaFile += yytext;
    } else if (parameterPos == 1) {
        offset = atoi(yytext);
    } else if (parameterPos == 2) {
        tries = atoi(yytext);
    } else {
        thirdParameter = atoi(yytext);
    }

    std::cout << "Adding parameter" << std::endl;
    parameterPos++;
}

<PARAMETERS>, {
    // ignore
}

<PARAMETERS>\n {
    parameterPos = 0;

    std::cout << "fasta file: " << fastaFile << std::endl;
    std::cout << "offset: " << offset << std::endl;
    std::cout << "tries: " << tries << std::endl;
    std::cout << "third parameter: " << thirdParameter << std::endl;


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
        popfile();
        newfile(fastaFile.c_str());
        BEGIN VOCABULARY;
    }
}

<OFFSET><<EOF>> {
    currentTries++;
    if (currentTries <= tries)
    {
        popfile();
        newfile(fastaFile.c_str());
        BEGIN OFFSET;
    }
    else
    {
        std::cout << "Unable to work with the offset" << std::endl;
        // delete the results file
        fclose(results);
        if (remove("decrypt/result.txt") != 0)
            perror("Error deleting file");
        else
            std::cout << "File successfully deleted" << std::endl;
        yyterminate();
    }
}

<OFFSET>.|\n {
    // ignore the rest
}

<VOCABULARY>^[A-Z]+ {
    // if size of vocabulary is 20 change state
    if (vocabulary.size() >= 20)
    {
        std::cout << "Popping file" << std::endl;
        popfile();
        alphabetMap = createMap();
        printVocabulary();

        if (!enc)
            newfile("./decrypt/result.txt");   
        
        BEGIN INITIAL;
        break;
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
            // current char
            char c = yytext[tempNumericValue];
            // std::cout << "Adding to vocabulary: " << yytext[tempNumericValue] << std::endl;
            auto it = unusedVocabulary.find(c);

            // if the word is not in the unused vocabulary, add it to the vocabulary
            if (it == unusedVocabulary.end())
                vocabulary.insert(c);
            

            tempNumericValue+=numericValue;
        }

        // normalize the value with respect to the size of the vocabulary
        tempNumericValue-=size;

        // if there was a missing value, use it for the next offset
        if (tempNumericValue > 0)
            numericValue = tempNumericValue;

    }
    
}

<VOCABULARY><<EOF>> {
    std::cout << "Not enough words to work with the offset" << int(firstChar) << std::endl;
    // delete the results file
    fclose(results);
    if (remove("decrypt/result.txt") != 0)
        perror("Error deleting file");
    else
        std::cout << "File successfully deleted" << std::endl;
    yyterminate();
}

<VOCABULARY>.|\n {
    // ignore the rest
}


%%

int main(int argc, char **argv)
{
    if (argc < 4) {
        fprintf(stderr, "Usage: %s input_file output_file operation\n", argv[0]);
        return 1;
    }

    /* Abre el archivo de salida */
    results = fopen(argv[2], "w");
    if (!results) {
        perror("Error opening output file");
        return 1;
    }

    /* Determina si la operación es 'encrypt' */
    enc = strcmp(argv[3], "encrypt") == 0;

    /* Procesa el archivo de entrada */
    if (newfile(argv[1]))
        yylex();

    /* Cierra el archivo de resultados */
    std::cout << "Closing result file" << std::endl;
    fclose(results);

    return 0;
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
    /* yylineno = 1; */
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
    /* yylineno = curbs->lineno; */
    curfilename = curbs->filename;
    return 1;
}

std::map<char, char> createMap()
{
    std::string alphabet = "ACDEFGHIKLMNPQRSTVWY";
    std::map<char, char> alphabetMap;
    alphabetMap['B'] = 'Z';
    alphabetMap['Z'] = 'B';
    alphabetMap['X'] = 'J';
    alphabetMap['J'] = 'X';
    alphabetMap['U'] = 'O';
    alphabetMap['O'] = 'U';

    auto it = vocabulary.begin();

    for (size_t i = 0; i < alphabet.size() && it != vocabulary.end(); ++i, ++it) 
    {
        if (enc)
            alphabetMap[alphabet[i]] = *it;
        else
            alphabetMap[*it] = alphabet[i];
    }

    return alphabetMap;
}

void printVocabulary()
{
    std::cout << "Printing vocabulary" << std::endl;
    for (auto it = alphabetMap.begin(); it != alphabetMap.end(); ++it)
    {
        std::cout << it->first << " => " << it->second << std::endl;
    }
    
}

void resetParameters()
{
    fastaFile = "./instructions/";
    offset = 0;
    tries = 0;
    parameterPos = 0;
    firstChar = 0;
    numericValue = 0;
    currentTries = 0;
    thirdParameter = 0;
    alphabetMap.clear();
    vocabulary.clear();
}