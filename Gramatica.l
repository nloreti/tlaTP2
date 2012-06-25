%{ 
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include "./includes/structs.h"

gramatica_struct * gramatica;
char leftPart=0;
%} 
%x DEFINITION
%x TERMINALS
%x ENDTERMINALS
%x NONTERMINALS
%x ENDNONTERMINALS
%x INITIALS
%x ENDINITIALS
%x LEFTPRODUCTION
%x RIGHTPRODUCTION
%x ENDPRODUCTIONS
%x ENDDEFINITION
%x TERMSEPARATOR
%x NONTERMSEPARATOR
%x PRODSEPARATOR
%x ARROW
%x ERROR

%%

\( BEGIN(DEFINITION);
<DEFINITION>\{ ;BEGIN(TERMINALS);
<TERMINALS>[A-Z] {addNonTerminal(*yytext);}BEGIN(TERMSEPARATOR);
<TERMSEPARATOR>[^(,|" "|\t|\})] {reportError("terminales",yytext);}; BEGIN(ERROR);
<TERMSEPARATOR>, BEGIN(TERMINALS);
<TERMINALS,TERMSEPARATOR>\} BEGIN(ENDTERMINALS);
<ENDTERMINALS>(,|" ") ;
<ENDTERMINALS>\{ BEGIN(NONTERMINALS);
<NONTERMINALS>[a-z] {addTerminal(*yytext);}BEGIN(NONTERMSEPARATOR);
<NONTERMSEPARATOR>[^(,|" "|\t|\})] {reportError("no terminales", yytext);}; BEGIN(ERROR);
<NONTERMSEPARATOR>, BEGIN(NONTERMINALS);
<NONTERMINALS,NONTERMSEPARATOR>\} BEGIN(ENDNONTERMINALS);
<ENDNONTERMINALS>, ;BEGIN(INITIALS);
<INITIALS>[A-Z] {addInitialSymbol(*yytext);};
<INITIALS>, ;BEGIN(ENDINITIALS);
<ENDINITIALS>\{ BEGIN(LEFTPRODUCTION);
<LEFTPRODUCTION>[A-Z] {getProductionLeftPart(*yytext);}; BEGIN(ARROW);
<ARROW>-> BEGIN(RIGHTPRODUCTION);
<RIGHTPRODUCTION>([a-zA-Z]*|\\) {getProduction(yytext,yyleng);}; BEGIN(PRODSEPARATOR);
<PRODSEPARATOR>, BEGIN(LEFTPRODUCTION);
<PRODSEPARATOR>\| BEGIN(RIGHTPRODUCTION);
<PRODSEPARATOR>\} BEGIN(ENDPRODUCTIONS);
<ENDPRODUCTIONS>\) BEGIN(ENDDEFINITION);
. ;
\n ;


%%

int
main(int argc, char* argv[]){
int err,pid;
FILE * file;
	FILE* fileToOpen= fopen(argv[1], "r");
	if(fileToOpen== NULL){
		printf("Error al abrir el archivo\n");
		return 1;
	}
	else
		yyin=fileToOpen;
	
	createGramatica();	
	yylex();	
	showTerminalSymbols();
	showNonTerminalSymbols();
	showInitialSymbol();
	showProductionSymbols();

	generateASDR();

}

/*Conversion*/
void generateASDR() {

	FILE * file;
	char * name = "ASDR.c";
	file = fopen(name, "w+");
	char * nonTerminals = gramatica->nonterminals->nonterminals;
	int i;
	production_struct ** productionsNT = malloc(sizeof(production_struct*) * gramatica->nonterminals->size);
	int * prodSize = malloc(sizeof(int) * gramatica->nonterminals->size);
	for ( i = 0; i < gramatica->nonterminals->size; i++) {
		productionsNT[i] = getProductionsByTerminal(nonTerminals[i], &(prodSize[i]));
	}
	//Se crea el archivo
	if (file) {

		fprintf(file, "#include <stdio.h>\n");
		fprintf(file, "#include <stdlib.h>\n");
		fprintf(file, "#include <string.h>\n");
		//fprintf(file, "#include \"include/Production.h\"\n");
		fprintf(file, "#include \"./includes/additions.h\"\n");
		fprintf(file, "#define TRUE 1\n");
		fprintf(file, "#define FALSE 0\n");
		fprintf(file, "int amountNT = 0;\n");
		fprintf(file, "int global = 0;\n");
		int k,j;
		for (k = 0; k < gramatica->nonterminals->size; k++) {
			fprintf(file, "production_struct * prods%d;\n", k);
			fprintf(file, "int prods%dquant;\n", k);
			fprintf(file, "int pn%d(int *, char * w);\n",k);
		}
		fprintf(file, "int procesar(production_struct p, char * w, int * t);\n");
		fprintf(file, "void init();\n");

	
		fprintf(file, "\nint main(int argc, char *argv[]) {\n");
		fprintf(file, "\tif(argc!=2) {\n");
		fprintf(file, "\t\tprintf(\"Mal uso del programa, se debería usar : %%s string \\n \", argv[0]);\n");
		fprintf(file, "\t\texit(1);\n");
		fprintf(file, "\t} else {\n");
		fprintf(file, "\t\tprintf(\"Procesando la cadena %%s\\n\", argv[1]);\n\t}\n");
		fprintf(file, "\tchar * w = argv[1];\n");
		fprintf(file, "\tinit();\n");
		fprintf(file, "\tint t = 0;\n");
	
		fprintf(file, "\tif(!pn0(&t,w) && (t==strlen(w))){\n");
		fprintf(file, "\t\tprintf(\"La cadena ha sido ACEPTADA! \\n\");\n");
		fprintf(file, "\t\tprintf(\"(---La cadena de derivacion esta invertida---)\\n\");\n");
		fprintf(file, "\t} else {\n");
		fprintf(file, "\t\tprintf(\"La cadena ha sido RECHAZADA!\\n\");\n");
	
		fprintf(file, "\t}\n");
		fprintf(file, "\treturn 0;\n");
		fprintf(file, "}\n");
		/*main*/
		

		/*init*/

		fprintf(file, "\n/*initializes all the structures*/\n");
		fprintf(file, "void init(){\n");

			
		for (k = 0; k < gramatica->nonterminals->size; k++) {
			
			production_struct * ps = productionsNT[k];
			fprintf(file, "\tprods%d = malloc(sizeof(production_struct *) * %d);\n",k, prodSize[k]);
			fprintf(file, "\tprods%dquant = %d;\n", k, prodSize[k]);
			int h;
			
			for (h = 0; h < prodSize[k]; h++) {
			
			
				production_struct p = ps[h];
				
				char * right = p.rightsimbols;
				if( right[0] == '\\'){
					fprintf(file, "\tprods%d[%d] = newProduction(\'%c\', \"\\\\\");\n", k, h, p.leftsimbol);
				}else{
				fprintf(file, "\tprods%d[%d] = newProduction(\'%c\', \"%s\");\n", k, h, p.leftsimbol, p.rightsimbols);
				}
				
			}
		}
			
		fprintf(file, "}\n");
		/*FIN init*/
		
		/*procesar*/
		fprintf(file, "\n/*returns TRUE if there is an error*/\n");
		fprintf(file, "int procesar(production_struct p, char * w, int * t) {\n");
		fprintf(file, "\tint i;\n");
		fprintf(file, "\tint n = p.rightsimbolslenght; /*number of symbols in the right side of the production*/\n");
		fprintf(file, "\tfor (i = 1; i <= n && *t < strlen(w); i++) {\n");
		fprintf(file, "\t\tchar comp = getProductionComponent(p, i);\n");
		fprintf(file, "\t\tif (isTerminal(comp)) {\n");
		fprintf(file, "\t\t\tif (w[*t] == comp) {\n");
		fprintf(file, "\t\t\t\t(*t) += 1;\n");
		fprintf(file, "\t\t\t} else {\n");
		fprintf(file, "\t\t\t\treturn TRUE;/*error*/\n\t\t\t}\n");
		fprintf(file, "\t\t} else {\n");
		fprintf(file, "\t\t\tint error= FALSE;\n");
		fprintf(file, "\t\t\tswitch(comp){\n");

		for (j = 0; j < gramatica->nonterminals->size; j++) {
			fprintf(file, "\t\t\tcase '%c':\n", nonTerminals[j]);
			fprintf(file, "\t\t\t\terror = pn%d(t,w);\n", j);
			fprintf(file, "\t\t\t\tbreak;\n");
		}
		fprintf(file, "\t\t\t}\n");
		fprintf(file, "\t\t\tif(error){\n");
		fprintf(file, "\t\t\t\treturn TRUE;\n");
		fprintf(file, "\t\t\t}\n\t\t}\n\t}\n");
		fprintf(file, "\treturn FALSE;\n}\n");

		/*procedures for each non terminal*/
		/*corresponding to S*/
		for (j = 0; j < gramatica->nonterminals->size; j++) {
			fprintf(file, "\nint pn%d(int *t, char * w) {\n", j);
			fprintf(file, "\tint j;\n");
			fprintf(file, "\tint n = prods%dquant; /*quantity of productions with this termina */\n", j);
			fprintf(file, "\tint error = TRUE;\n");
			fprintf(file, "\tint resto = FALSE;\n");
			fprintf(file, "\tfor(j = 0; j < n && error; j++) {\n");
			fprintf(file, "\t\tint t2 = *t;\n");
			fprintf(file, "\t\tif(!((amountNT + nonTerminalsinProd(prods%d[j])) > strlen(w))){\n",j);
			fprintf(file, "\t\t\tamountNT += nonTerminalsinProd(prods%d[j]);\n", j);	
			fprintf(file, "\t\t\t\terror = procesar(prods%d[j], w, &t2);\n", j);
			fprintf(file, "\t\t\t\tif( error == TRUE ){\n\t\t\tresto = TRUE;\n\t\t}\n");
			fprintf(file, "\t\t\t\n\t\t}\n");
			fprintf(file, "\t\tif(!error){\n");
			fprintf(file, "\t\t\t*t = t2;\n");
			fprintf(file, "\t\t\tprintProduction(prods%d[j]);\n", j);
			fprintf(file, "\t\t}\n",j);
			fprintf(file, "\t\tif(resto == TRUE){\n\t\t\tamountNT -= nonTerminalsinProd(prods%d[j]) + global;\n\t\t\tglobal=0;\n}\n\t}\n",j);
				
			fprintf(file, "\tglobal += nonTerminalsinProd(prods%d[j]);\n",j);
			fprintf(file, "\treturn error;\n}\n");
		}
		/*FIN Procesar*/
		fclose(file);
	}
}


production_struct * getProductionsByTerminal( char nonTerminal , int * quant){
	production_struct * ans = malloc(sizeof(production_struct*) * sizeof(production_struct));
	int i,k=0;
	for(i=0; i<gramatica->production_function->size;i++){
		production_struct p = gramatica->production_function->productions[i];
		char first = p.leftsimbol;
		if (first == nonTerminal){
			ans[k++] = p;
		}
		
	}
	(*quant) = k;
	return ans;
}



int addProductions(char leftside, char rightside1, char rightside2){
	int size = gramatica->production_function->size;
	gramatica->production_function->productions[size].leftsimbol = leftside;
	gramatica->production_function->productions[size].rightsimbols[0] = rightside1;
	gramatica->production_function->productions[size].rightsimbols[1] = rightside2;
	gramatica->production_function->size = size + 1;
	return 1;
}

int isContained(char left, char * new, int size){
	int i;
	
	for ( i = 0; i < size; i++){
		if ( left == new[i]){
			return 1;
		}
	}
	
	return 0;
	
}

int createGramatica(){
	
	gramatica=malloc(sizeof(gramatica_struct));
	if (gramatica == NULL)
		return 0;
	return initializeFunctions() && initializeNonTerminals() && initializeTerminals();
}

int initializeFunctions(){
	gramatica->production_function =malloc(sizeof(production_function_struct));
	if(gramatica->production_function == NULL)
	return 0;
	gramatica->production_function->productions=NULL;
	gramatica->production_function->size=0;
	return 1;
}

int initializeNonTerminals(){
	gramatica->nonterminals = malloc(sizeof(nonterminals_struct));
	if(gramatica->nonterminals == NULL)
	return 0;
	gramatica->nonterminals->nonterminals =NULL;
	gramatica->nonterminals->size=0;
	return 1;
}

int initializeTerminals(){
	gramatica->terminals =malloc(sizeof(terminals_struct));
	if(gramatica->terminals == NULL)
	return 0;
	gramatica->terminals->terminal=NULL;
	gramatica->terminals->size=0;
	return 1;
}
void reportError(char* errorMsg, char* token){

	printf("Se produjo un error tratando de leer %s cuando se leyo %s\n",errorMsg,token);
	exit(0);

}

int addTerminal(char c){
	int size = gramatica->terminals->size;
	if(size%BLOCK==0)
		gramatica->terminals->terminal=realloc(gramatica->terminals->terminal,(size+BLOCK)*sizeof(char));	
	gramatica->terminals->terminal[size] = c;
	gramatica->terminals->size = size+1;
	return 1;
}

int addNonTerminal(char c){
	int size = gramatica->nonterminals->size;
	if(size%BLOCK ==0)
		gramatica->nonterminals->nonterminals=realloc(gramatica->nonterminals->nonterminals,(size+BLOCK)*sizeof(char));
	gramatica->nonterminals->nonterminals[size] = c;
	gramatica->nonterminals->size = ++size;
	return 1;
}

int addInitialSymbol(char  c){
	gramatica->initial = c;
	return 1;
}

void getProductionLeftPart(char c){
	leftPart=c;
}

int getProduction(char* c,int lenght){
	int i=0;
	int size=gramatica->production_function->size;
	if(size%BLOCK==0)
		gramatica->production_function->productions=realloc(gramatica->production_function->productions, (size+BLOCK)*sizeof(production_struct));
	gramatica->production_function->productions[size].leftsimbol=leftPart;
	
	gramatica->production_function->productions[size].rightsimbols=malloc(lenght*sizeof(char));
	
	for(i=0;i< lenght;i++)
		gramatica->production_function->productions[size].rightsimbols[i]=c[i];
	gramatica->production_function->productions[size].rightsimbolslenght=lenght;
	gramatica->production_function->size=size+1;
	return 1;
		
}

void showTerminalSymbols(){
	int i;
	printf("Simbolos Terminales\n");
	for( i = 0; i < gramatica->terminals->size; i++){
		printf("%c\n", gramatica->terminals->terminal[i]);

	}
	printf("End\n\n");
}

void showNonTerminalSymbols(){
	int i;
	printf("Simbolos No Terminales\n");
	for( i = 0; i < gramatica->nonterminals->size; i++){
		printf("%c\n", gramatica->nonterminals->nonterminals[i]);

	}
	printf("End\n\n");
}


void showInitialSymbol(){

	printf("Simbolo Inicial\n");
	printf("%c\n", gramatica->initial);
	printf("End\n\n");
}

void showProductionSymbols(){
	int i,k;
	printf("Producciones\n");
	for( i = 0; i < gramatica->production_function->size; i++){
		if(gramatica->production_function->productions[i].leftsimbol != 0){
			printf("%c ->", gramatica->production_function->productions[i].leftsimbol);
			for (k=0; k< gramatica->production_function->productions[i].rightsimbolslenght ;k++)
			printf("%c",gramatica->production_function->productions[i].rightsimbols[k]);
			printf("\n");
		}
	}
	printf("End\n\n");
}





 