.PHONY:compile

compile:
		flex Gramatica.l && gcc -o gramatica lex.yy.c -lfl
		./gramatica $(FILE)
		gcc -o TPTLA ASDR.c additions.c -g
		
		

.PHONY: clean

clean:
		rm -Rf gramatica
		rm -Rf TPTLA