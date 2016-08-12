#ifndef __K12A_ASM_PARSER_H
#define __K12A_ASM_PARSER_H

// Defined at the bottom of parser.y
void k12a_asm_parse_string(const char *string);
void k12a_asm_parse_stdin();
void k12a_asm_parse_file(const char *filename);

#endif
