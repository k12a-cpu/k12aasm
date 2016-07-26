#!/bin/sh

flex --header-file=k12a/assembler/lexer_gen.h --outfile=k12a/assembler/lexer_gen.c k12a/assembler/lexer.l
bison --defines=k12a/assembler/parser_gen.h --output=k12a/assembler/parser_gen.c k12a/assembler/parser.y
