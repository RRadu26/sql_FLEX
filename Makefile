build:
	flex program.l
	gcc -o SQLAnalyzer lex.yy.c
clean:
	rm *.yy.c
	rm SQLAnalyzer
