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
unsigned int parameterPos;
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
// File with the results
FILE *results;
        
%}

%%

^"#" {
    vocabulary.clear();
    alphabetMap.clear();
    std::cout << "New parameters" << std::endl;
    BEGIN PARAMETERS;
}

. |
\n {

    std::string word = yytext;
    std::string result = "";
    // convert the word to uppercase
    std::transform(word.begin(), word.end(), word.begin(), ::toupper);

    for (size_t i = 0; i < word.size(); i++)
    {
        char c = word[i];
        auto it = alphabetMap.find(c);

        if (it != alphabetMap.end())
            result += it->second;
        else
            result += c;
    }

    fprintf(results, "%s", result.c_str());
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
        popfile();
        newfile(fastaFile.c_str());
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
        std::cout << "Popping file" << std::endl;
        popfile();
        fastaFile = "./instructions/";
        offset = 0;
        tries = 0;
        parameterPos = 0;
        firstChar = 0;
        numericValue = 0;
        alphabetMap = createMap();
        printVocabulary();
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

<VOCABULARY>.|\n {
    // ignore the rest
}


%%

int main(int argc, char **argv)
{
    if(argc < 2) {
        fprintf(stderr, "need filename\n");
        return 1;
    }

    /* the second argument is the file where it will store the result encryption */
    results = fopen(argv[2], "w");

    if(newfile(argv[1]))
        yylex();

    fclose(results);

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
        alphabetMap[alphabet[i]] = *it;
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