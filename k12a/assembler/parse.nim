import marshal, tables
from os import parentDir
from strutils import `%`, strip, toLowerASCII

import types

{.compile: "lexer_gen.c".}
{.compile: "parser_gen.c".}
{.passC: ("-I" & parentDir(currentSourcePath())).}

type
  ParseError* = object of Exception

var currentLoc: Loc
var unit: CompilationUnit
var exprStack = newSeq[Expr]()

proc copyCurrentLoc(): Loc =
  result.deepCopy(currentLoc)

proc reset(filename: string = "") =
  currentLoc = Loc(file: filename, line: 1)
  unit = CompilationUnit(
    items: newSeq[Item](),
  )
  exprStack.setLen(0)

proc popn[T](a: var seq[T], count: int): seq[T] {.noSideEffect.} =
  let length = a.len()
  result = a[(length - count) .. (length - 1)]
  a.setLen(length - count)

proc unreachable[T](): T =
  assert(false, "control should not be able to reach this point")

proc parseError(msg: string) =
  raise newException(ParseError, "parse error at $1: $2" % [$currentLoc, msg])

proc parseError(msg: cstring) {.cdecl, exportc: "k12a_asm_yyerror".} =
  parseError($msg)

proc updateLoc(marshalledLoc: cstring) {.cdecl, exportc: "k12a_asm_yy_update_loc".} =
  currentLoc = to[Loc](($marshalledLoc).strip)

proc incLineno() {.cdecl, exportc: "k12a_asm_yy_inc_lineno".} =
  inc currentLoc.line

proc makeInstruction(mnemonic: cstring, numOperands: int64) {.cdecl, exportc: "k12a_asm_make_instruction".} =
  let operands = exprStack.popn(numOperands.int)
  unit.items.add Item(
    loc: copyCurrentLoc(),
    kind: itemInstruction,
    mnemonic: ($mnemonic).toLowerASCII(),
    operands: operands,
  )

proc makeLabel(name: cstring) {.cdecl, exportc: "k12a_asm_make_label".} =
  unit.items.add Item(
    loc: copyCurrentLoc(),
    kind: itemLabel,
    labelName: $name,
  )

proc makeExprLiteral(value: int64) {.cdecl, exportc: "k12a_asm_make_expr_literal".} =
  exprStack.add Expr(
    loc: copyCurrentLoc(),
    kind: exprLiteral,
    literal: value.int,
  )

proc makeExprReg(regVal: int64) {.cdecl, exportc: "k12a_asm_make_expr_reg".} =
  let reg =
    case regVal
    of 0: regA
    of 1: regB
    of 2: regC
    of 3: regD
    else: unreachable[Register]()
  exprStack.add Expr(
    loc: copyCurrentLoc(),
    kind: exprReg,
    reg: reg,
  )

proc makeExprLabelRef(name: cstring) {.cdecl, exportc: "k12a_asm_make_expr_labelref".} =
  exprStack.add Expr(
    loc: copyCurrentLoc(),
    kind: exprLabelRef,
    labelName: $name,
  )

proc makeExprUnary(opChar: uint8) {.cdecl, exportc: "k12a_asm_make_expr_unary".} =
  let op =
    case opChar
    of '-'.ord: uopNeg
    of '~'.ord: uopNot
    else: unreachable[UnaryOp]()
  let child = exprStack.pop()
  exprStack.add Expr(
    loc: copyCurrentLoc(),
    kind: exprUnary,
    unaryOp: op,
    child: child,
  )

proc makeExprBinary(opChar: uint8) {.cdecl, exportc: "k12a_asm_make_expr_binary".} =
  let op =
    case opChar
    of '&'.ord: bopAnd
    of '|'.ord: bopOr
    of '^'.ord: bopXor
    of 'L'.ord: bopLShift
    of 'R'.ord: bopRShift
    of '+'.ord: bopAdd
    of '-'.ord: bopSub
    of '*'.ord: bopMul
    of '/'.ord: bopDiv
    of '%'.ord: bopMod
    else: unreachable[BinaryOp]()
  let rightChild = exprStack.pop()
  let leftChild = exprStack.pop()
  exprStack.add Expr(
    loc: copyCurrentLoc(),
    kind: exprBinary,
    binaryOp: op,
    leftChild: leftChild,
    rightChild: rightChild,
  )

proc parseStringInternal(str: cstring) {.cdecl, header: "parser.h", importc: "k12a_asm_parse_string".}
proc parseStdinInternal() {.cdecl, header: "parser.h", importc: "k12a_asm_parse_stdin".}
proc parseFileInternal(filename: cstring) {.cdecl, header: "parser.h", importc: "k12a_asm_parse_file".}

proc parseString*(str: string, filename: string = "<string>"): CompilationUnit =
  reset(filename)
  parseStringInternal(str)
  result = unit
  reset()

proc parseStdin*(filename: string = "<stdin>"): CompilationUnit =
  reset(filename)
  parseStdinInternal()
  result = unit
  reset()

proc parseFile*(filename: string): CompilationUnit =
  reset(filename)
  parseFileInternal(filename)
  result = unit
  reset()
