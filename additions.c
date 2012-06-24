#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "./additions.h"



production_struct newProduction(char left, char * right){
	production_struct * p = (production_struct *)malloc(sizeof(production_struct));
	p->leftsimbol = left;
	p->rightsimbols = right;
	p->rightsimbolslenght= strlen(right);
	return *p;
}

int isTerminal(char c){
	return islower(c);
}

int isNonTerminal(char c){
	return isupper(c);
}

char getProductionComponent(production_struct production, int i){
	if(i < 0 ||i > production.rightsimbolslenght){
		return -1;
	}
	return (i == 0)? production.leftsimbol : production.rightsimbols[i-1];
}

void printProduction(production_struct production){
	printf("%c->%s\n",production.leftsimbol, production.rightsimbols);
}

int nonTerminalsinProd(production_struct p){
	int i,resp;
	resp = 0;
	for(i = 1; i <= p.rightsimbolslenght; i++){
		char comp = getProductionComponent(p, i);
		if (isTerminal(comp)){
			resp++;
		}
	}
	return resp;
}