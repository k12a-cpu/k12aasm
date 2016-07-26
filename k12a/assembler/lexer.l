%option prefix="k12a_asm_yy"
%option noyywrap
%option yylineno

%{

#include <stdint.h>
#include <stdlib.h>

#include "parser_gen.h"

%}

%%

[ \t]                         ;
(\;.*)?\r?\n                  { return NEWLINE; }

[\(\)\:\,\&\|\^\+\-\*\/\%\~]  { return k12a_asm_yytext[0]; }

[Aa]/[^a-zA-Z0-9_]            { k12a_asm_yylval.i = 0;
                                return REG; }
[Bb]/[^a-zA-Z0-9_]            { k12a_asm_yylval.i = 1;
                                return REG; }
[Cc]/[^a-zA-Z0-9_]            { k12a_asm_yylval.i = 2;
                                return REG; }
[Dd]/[^a-zA-Z0-9_]            { k12a_asm_yylval.i = 3;
                                return REG; }

0x[0-9a-fA-F]+                { k12a_asm_yylval.i = (int64_t) strtol(k12a_asm_yytext+2, NULL, 16);
                                return INT; }
-0x[0-9a-fA-F]+               { k12a_asm_yylval.i = -((int64_t) strtol(k12a_asm_yytext+2, NULL, 16));
                                return INT; }
0b[01]+                       { k12a_asm_yylval.i = (int64_t) strtol(k12a_asm_yytext+2, NULL, 2);
                                return INT; }
-0b[01]+                      { k12a_asm_yylval.i = -((int64_t) strtol(k12a_asm_yytext+2, NULL, 2));
                                return INT; }
[0-9]+                        { k12a_asm_yylval.i = (int64_t) strtol(k12a_asm_yytext, NULL, 10);
                                return INT; }
-[0-9]+                       { k12a_asm_yylval.i = -((int64_t) strtol(k12a_asm_yytext, NULL, 10));
                                return INT; }

[a-zA-Z_][a-zA-Z0-9_]*        { k12a_asm_yylval.s = strdup(k12a_asm_yytext);
                                return IDENTIFIER; }

.                             { char msg[64];
                                snprintf(msg, 64, "invalid character '%c'", k12a_asm_yytext[0]);
                                k12a_asm_yyerror(msg); }

%%
