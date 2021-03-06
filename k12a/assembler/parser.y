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

%token NEWLINE LSHIFT RSHIFT
%token BYTE_DIRECTIVE
%token WORD_DIRECTIVE
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
    : newlines NEWLINE                  { k12a_asm_inc_lineno(); }
    | NEWLINE                           { k12a_asm_inc_lineno(); }
    ;

lines
    : lines newlines line
    | line
    ;

line
    : instruction
    | label
    | byte_directive
    | word_directive
    ;

instruction
    : IDENTIFIER operands               { k12a_asm_make_instruction($1, $2); }
    | IDENTIFIER                        { k12a_asm_make_instruction($1, 0); }
    ;

label
    : IDENTIFIER ':'                    { k12a_asm_make_label($1); }
    ;

byte_directive
    : BYTE_DIRECTIVE expr               { k12a_asm_make_byte_directive(); }
    ;

word_directive
    : WORD_DIRECTIVE expr               { k12a_asm_make_word_directive(); }
    ;

operands
    : operands ',' expr                 { $$ = $1 + 1; }
    | expr                              { $$ = 1; }
    ;

expr
    : expr '&' expr_shift               { k12a_asm_make_expr_binary((uint8_t) '&'); }
    | expr '|' expr_shift               { k12a_asm_make_expr_binary((uint8_t) '|'); }
    | expr '^' expr_shift               { k12a_asm_make_expr_binary((uint8_t) '^'); }
    | expr_shift
    ;

expr_shift
    : expr_shift LSHIFT expr_sum        { k12a_asm_make_expr_binary((uint8_t) 'L'); }
    | expr_shift RSHIFT expr_sum        { k12a_asm_make_expr_binary((uint8_t) 'R'); }
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

void k12a_asm_parse_string(const char *string) {
    YY_BUFFER_STATE buffer_state = k12a_asm_yy_scan_string(string);
    k12a_asm_yyparse();
    k12a_asm_yy_delete_buffer(buffer_state);
}

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
