#define BLOCK 10
#include <stdio.h>

//GRAMATICA

typedef struct productionStruct{
	char leftsimbol;
	char* rightsimbols;
	int rightsimbolslenght;
}production_struct;

typedef struct{
	production_struct* productions;
	int size;
}production_function_struct;

typedef struct{
	char * nonterminals;
	int size;
}nonterminals_struct;

typedef struct{
	char * terminal;
	int size;
}terminals_struct;


typedef struct{
	production_function_struct * production_function;
	nonterminals_struct * nonterminals;
	terminals_struct * terminals;
	char initial;
}gramatica_struct;

//Gramatica Funciones
int createGramatica();
int initializeFunctions();
int initializeNonTerminals();
int initializeTerminals();

void generateASDR();
production_struct * getProductionsByTerminal( char nonTerminal , int * quant);

int addTerminalSymbols(char *);
int addNonTerminalSymbols(char *);
int isContained(char, char * , int);
int addProductions(char, char, char);
int addProductionSymbols(char *);

int addTerminals(char *);
int addNonTermianls(char *);
int addProduction(char *);

int addTerminal(char c);
int addNonTerminal(char c);
int addInitialSymbol(char c);
void addInitialSymbols(char * c);

void getProductionLeftPart(char c);
int getProduction(char* c,int lenght);
void showProductionSymbols();
void showInitialSymbol();
void showNonTerminalSymbols();
void showTerminalSymbols();

void reportError(char* msg,char* error);

