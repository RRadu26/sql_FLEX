%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct table{
    char name[255];
    char primary_key[255];
    int colomns;
    int records;
} table;
table *tables;
int no_tables = 0;
int iv_coumns = 0;
int table_ii = -1;
char word[255];

int add_Table(char *name_table);
int drop_Table(char *name_table);
int search_table(char *name_table);
int alter_table(char *name_table);
void describe_table(int tab);
%}
createtable "CREATE TABLE"
droptable "DROP TABLE"
insertinfo "INSERT INTO"
altertable "ALTER TABLE"
describe "DESCRIBE"
str [a-zA-Z0-9_\"\'\.]+
%s TABLE_NAME COLUMN_NAME CONSTRAINTS END_TABLE START_TABLE 
%s PRIMARY_KEY CONSTRAINT_COLUMN CONSTRAINT_COLUMN_NAME 
%s CONSTRAINT_CONT CONSTRAINT_CONT1 DROP_TABLE INSERT_INFO
%s IID II_COL II_VALUES II_MATCH ALTER_TABLE ADD_DEL_C DESCRIBE


%%
<INITIAL>{createtable} {BEGIN(TABLE_NAME);}
<INITIAL>{droptable} {BEGIN(DROP_TABLE);}
<INITIAL>{insertinfo} {iv_coumns = 0; table_ii = -1; BEGIN(INSERT_INFO);}
<INITIAL>{altertable} {table_ii = -1; BEGIN(ALTER_TABLE);}
<INITIAL>{describe} {table_ii = -1; BEGIN(DESCRIBE);}

<DESCRIBE>{str} {table_ii = search_table(yytext); if(table_ii >= 0) describe_table(table_ii); BEGIN(INITIAL);}

<ALTER_TABLE>{str} {table_ii = search_table(yytext);
                    if(table_ii == -1) BEGIN(INITIAL);
                    else BEGIN(ADD_DEL_C);}

<INSERT_INFO>{str} {table_ii = search_table(yytext); 
                    if(table_ii == -1) BEGIN(INITIAL);
                    else BEGIN(IID);}
<ADD_DEL_C>"ADD"  {tables[table_ii].colomns++; BEGIN(INITIAL);}
<ADD_DEL_C>"DROP COLUMN" {if(tables[table_ii].colomns > 0 ) tables[table_ii].colomns --; BEGIN(INITIAL);}
<IID>[ \n]*"(" {BEGIN(II_COL);}
<IID>[ \n]*"VALUES"[ \n]*"(" {iv_coumns = tables[table_ii].colomns; BEGIN(II_MATCH);}
 
<II_COL>{str}[ \n]*"," {iv_coumns++;}
<II_COL>{str}[ \n]*")" {iv_coumns++; if(iv_coumns > tables[table_ii].colomns) {printf("Invalid command.\n\n"); BEGIN(INITIAL);} else BEGIN(II_VALUES);}

<II_VALUES>"VALUES "[ \n]*"(" {BEGIN(II_MATCH);}

<II_MATCH>{str}[ \n]*"," {iv_coumns--;}
<II_MATCH>{str}[ \n]*")"[ \n]*";" {iv_coumns--; if(iv_coumns != 0) printf("Invalid command.\n\n");
                                else {
                                    tables[table_ii].records++;
                                }BEGIN(INITIAL);}

<DROP_TABLE>{str} {drop_Table(yytext); 
                    BEGIN(INITIAL);}

<TABLE_NAME>{str} {if(add_Table(yytext) == 1)
                          BEGIN(INITIAL);
                          else BEGIN(START_TABLE);}

<START_TABLE>[ \n]"(" {BEGIN(COLUMN_NAME);}

<COLUMN_NAME>"PRIMARY KEY"[ ]* {BEGIN(PRIMARY_KEY);}

<COLUMN_NAME>"CONSTRAINT"[ ]* {BEGIN(CONSTRAINT_COLUMN_NAME);}

<CONSTRAINT_COLUMN_NAME>{str} {strcpy(word, yytext);
                                 BEGIN(CONSTRAINT_CONT);}

<CONSTRAINT_CONT>" PRIMARY KEY"[ ]*"(" {BEGIN(CONSTRAINT_CONT1);
                                         BEGIN(CONSTRAINT_CONT1);}

<CONSTRAINT_CONT1>{str} {strcat(word, "(");
                         strcat(word, yytext);
                         strcat(word, ")");
                         strcpy(tables[no_tables -1].primary_key, word);
                         BEGIN(END_TABLE);}

<COLUMN_NAME>{str}" " {tables[no_tables - 1].colomns++;
                        strcpy(word, yytext);
                         BEGIN(CONSTRAINTS);}

<PRIMARY_KEY>{str} {strcpy(tables[no_tables - 1].primary_key, yytext);
                     BEGIN(END_TABLE);}

<CONSTRAINTS>" PRIMARY KEY" {strcpy(tables[no_tables -1].primary_key, word);
                             BEGIN(END_TABLE);}

<CONSTRAINTS>"," {BEGIN(COLUMN_NAME);}
<END_TABLE>","[ ]*"\n" {tables[no_tables - 1].colomns++;}

<END_TABLE>")"[ ]*";" {BEGIN(INITIAL);}
.|\n {};
<INITIAL>"end" {return 0;}
%%
int yywrap(){}
int main(int argc, char **argv) {
    if(argc != 2) {
        printf("Bad run.\n");
        return 0;
    }
    tables = (table*)malloc(sizeof(table) * 10);
    yyin = fopen(argv[1], "r");
    if(!yyin) {
        printf("No file with that name found.\n");
        return 1;
    }
    yylex();

    int ntan = sizeof(tables)/sizeof(table);
    free(tables);
}
int add_Table(char *name_table) {
    for(int i= 0; i< no_tables; i++) {
            if(strcmp(name_table, tables[i].name) == 0) {
                printf("Invalid command.\n\n");
                return 1;
            }
    }
    if(no_tables%10 == 8)
        tables = (table*) realloc(tables, sizeof(tables)/sizeof(table) + sizeof(table) * 10);
    strcpy(tables[no_tables].name, name_table);
    tables[no_tables].colomns = 0;
    tables[no_tables].records = 0;
    no_tables++;
    return 0;
}

int drop_Table(char *name_table) {
    for(int i= 0; i< no_tables; i++) {
            if(strcmp(name_table, tables[i].name) == 0) {
                if(i != no_tables - 1) {
                    strcpy(tables[i].name, tables[no_tables - 1].name);
                    strcpy(tables[i].primary_key, tables[no_tables - 1].primary_key);
                    tables[i].colomns = tables[no_tables - 1].colomns;
                    tables[i].records = tables[no_tables - 1].records;
                    no_tables--;
                    return 0;
                }
                no_tables--;
                return 0;
            }
    }
    printf("Invalid command.\n\n");
    return 1;
}
int search_table(char *name_table) {
    for(int i= 0; i< no_tables; i++) {
            if(strcmp(name_table, tables[i].name) == 0) {
                return i;
        }
    }
    printf("Invalid command\n\n");
    return -1;
}
void describe_table(int tab) {
    printf("Table Name: %s\n", tables[tab].name);
    printf("Primary Key: %s\n", tables[tab].primary_key);
    printf("Number of columns: %d\n", tables[tab].colomns);
    printf("Number of records: %d\n\n", tables[tab].records);
}