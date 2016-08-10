%define api.prefix {k12a_asm_yy}

%{

#include <stdint.h>
#include <stdio.h>

#include "lexer_gen.h"
#include "parser.h"

%}

%union{
    int64_t i;
    char *s;
}

%token NEWLINE
%token <i> INT REG
%token <s> IDENTIFIER

%type <i> operands

%%

compilation_unit
    : optional_newlines lines optional_newlines
    ;

optional_newlines
    : newlines
    |
    ;

newlines
    : newlines NEWLINE                  { k12a_asm_yylineno++; }
    | NEWLINE                           { k12a_asm_yylineno++; }
    ;

lines
    : lines newlines line
    | line
    ;

line
    : instruction
    | label
    ;

instruction
    : IDENTIFIER operands               { k12a_asm_make_instruction($1, $2); }
    | IDENTIFIER                        { k12a_asm_make_instruction($1, 0); }
    ;

label
    : IDENTIFIER ':'                    { k12a_asm_make_label($1); }
    ;

operands
    : operands ',' expr                 { $$ = $1 + 1; }
    | expr                              { $$ = 1; }
    ;

expr
    : expr '&' expr_sum                 { k12a_asm_make_expr_binary((uint8_t) '&'); }
    | expr '|' expr_sum                 { k12a_asm_make_expr_binary((uint8_t) '|'); }
    | expr '^' expr_sum                 { k12a_asm_make_expr_binary((uint8_t) '^'); }
    | expr_sum
    ;

expr_sum
    : expr_sum '+' expr_product         { k12a_asm_make_expr_binary((uint8_t) '+'); }
    | expr_sum '-' expr_product         { k12a_asm_make_expr_binary((uint8_t) '-'); }
    | expr_product
    ;

expr_product
    : expr_product '*' expr_unary       { k12a_asm_make_expr_binary((uint8_t) '*'); }
    | expr_product '/' expr_unary       { k12a_asm_make_expr_binary((uint8_t) '/'); }
    | expr_product '%' expr_unary       { k12a_asm_make_expr_binary((uint8_t) '%'); }
    | expr_unary
    ;

expr_unary
    : '-' expr_atom                     { k12a_asm_make_expr_unary((uint8_t) '-'); }
    | '~' expr_atom                     { k12a_asm_make_expr_unary((uint8_t) '~'); }
    | expr_atom
    ;

expr_atom
    : INT                               { k12a_asm_make_expr_literal($1); }
    | REG                               { k12a_asm_make_expr_reg($1); }
    | IDENTIFIER                        { k12a_asm_make_expr_labelref($1); }
    | '(' expr ')'

%%

void k12a_asm_parse_stdin() {
    k12a_asm_yyin = stdin;
    while (!feof(k12a_asm_yyin)) {
        k12a_asm_yyparse();
    }
    k12a_asm_yyin = NULL;
}

void k12a_asm_parse_file(const char *filename) {
    FILE *file = fopen(filename, "r");
    if (file != NULL) {
        k12a_asm_yyin = file;
        while (!feof(k12a_asm_yyin)) {
            k12a_asm_yyparse();
        }
        k12a_asm_yyin = NULL;
        fclose(file);
    }
}
