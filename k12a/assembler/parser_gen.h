/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_K12A_ASM_YY_K12A_ASSEMBLER_PARSER_GEN_H_INCLUDED
# define YY_K12A_ASM_YY_K12A_ASSEMBLER_PARSER_GEN_H_INCLUDED
/* Debug traces.  */
#ifndef K12A_ASM_YYDEBUG
# if defined YYDEBUG
#if YYDEBUG
#   define K12A_ASM_YYDEBUG 1
#  else
#   define K12A_ASM_YYDEBUG 0
#  endif
# else /* ! defined YYDEBUG */
#  define K12A_ASM_YYDEBUG 0
# endif /* ! defined YYDEBUG */
#endif  /* ! defined K12A_ASM_YYDEBUG */
#if K12A_ASM_YYDEBUG
extern int k12a_asm_yydebug;
#endif

/* Token type.  */
#ifndef K12A_ASM_YYTOKENTYPE
# define K12A_ASM_YYTOKENTYPE
  enum k12a_asm_yytokentype
  {
    NEWLINE = 258,
    LSHIFT = 259,
    RSHIFT = 260,
    BYTE_DIRECTIVE = 261,
    WORD_DIRECTIVE = 262,
    INT = 263,
    REG = 264,
    IDENTIFIER = 265
  };
#endif

/* Value type.  */
#if ! defined K12A_ASM_YYSTYPE && ! defined K12A_ASM_YYSTYPE_IS_DECLARED

union K12A_ASM_YYSTYPE
{
#line 13 "k12a/assembler/parser.y" /* yacc.c:1909  */

    int64_t i;
    char *s;

#line 78 "k12a/assembler/parser_gen.h" /* yacc.c:1909  */
};

typedef union K12A_ASM_YYSTYPE K12A_ASM_YYSTYPE;
# define K12A_ASM_YYSTYPE_IS_TRIVIAL 1
# define K12A_ASM_YYSTYPE_IS_DECLARED 1
#endif


extern K12A_ASM_YYSTYPE k12a_asm_yylval;

int k12a_asm_yyparse (void);

#endif /* !YY_K12A_ASM_YY_K12A_ASSEMBLER_PARSER_GEN_H_INCLUDED  */
