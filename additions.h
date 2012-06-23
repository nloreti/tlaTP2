#include "./TPE/structs.h"

int isTerminal(char c);
int isNonTerminal(char c);
char getProductionComponent(production_struct production, int i);
production_struct newProduction(char left, char * right);
void printProduction(production_struct production);