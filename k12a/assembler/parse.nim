import tables
from os import parentDir
from strutils import `%`, toLower

import types

{.compile: "lexer_gen.c".}
{.compile: "parser_gen.c".}
{.passC: ("-I" & parentDir(currentSourcePath())).}

type
  ParseError* = object of Exception

var currentFilename: string
var currentLineno {.header: "lexer_gen.h", importc: "k12a_asm_yylineno".}: int

var unit: CompilationUnit
var exprStack = newSeq[Expr]()

proc reset() =
  unit = CompilationUnit(
    items: newSeq[Item](),
  )
  exprStack.setLen(0)

proc popn[T](a: var seq[T], count: int): seq[T] {.noSideEffect.} =
  let length = a.len()
  result = a[(length - count) .. (length - 1)]
  a.setLen(length - count)

proc currentLoc(): Loc =
  Loc(
    file: currentFilename,
    line: currentLineno,
    instantiation: MacroInstantiation(macroName: nil, loc: nil),
  )

proc unreachable[T](): T =
  assert(false, "control should not be able to reach this point")

proc parseError(msg: string) =
  raise newException(ParseError, "parse error at $1: $2" % [$currentLoc(), msg])

proc parseError(msg: cstring) {.cdecl, exportc: "k12a_asm_yyerror".} =
  parseError($msg)

proc makeInstruction(mnemonic: cstring, numOperands: int64) {.cdecl, exportc: "k12a_asm_make_instruction".} =
  let operands = exprStack.popn(numOperands.int)
  unit.items.add Item(
    loc: currentLoc(),
    kind: itemInstruction,
    mnemonic: ($mnemonic).toLower(),
    operands: operands,
  )

proc makeLabel(name: cstring) {.cdecl, exportc: "k12a_asm_make_label".} =
  unit.items.add Item(
    loc: currentLoc(),
    kind: itemLabel,
    labelName: $name,
  )

proc makeExprLiteral(value: int64) {.cdecl, exportc: "k12a_asm_make_expr_literal".} =
  exprStack.add Expr(
    loc: currentLoc(),
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
    loc: currentLoc(),
    kind: exprReg,
    reg: reg,
  )

proc makeExprLabelRef(name: cstring) {.cdecl, exportc: "k12a_asm_make_expr_labelref".} =
  exprStack.add Expr(
    loc: currentLoc(),
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
    loc: currentLoc(),
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
    of '+'.ord: bopAdd
    of '-'.ord: bopSub
    of '*'.ord: bopMul
    of '/'.ord: bopDiv
    of '%'.ord: bopMod
    else: unreachable[BinaryOp]()
  let rightChild = exprStack.pop()
  let leftChild = exprStack.pop()
  exprStack.add Expr(
    loc: currentLoc(),
    kind: exprBinary,
    binaryOp: op,
    leftChild: leftChild,
    rightChild: rightChild,
  )

proc parseStdinInternal() {.cdecl, header: "parser.h", importc: "k12a_asm_parse_stdin".}
proc parseFileInternal(filename: cstring) {.cdecl, header: "parser.h", importc: "k12a_asm_parse_file".}

proc parseStdin*(): CompilationUnit =
  reset()
  currentFilename = "<stdin>"
  parseStdinInternal()
  result = unit
  reset()

proc parseFile*(filename: string): CompilationUnit =
  reset()
  currentFilename = filename
  parseFileInternal(filename)
  result = unit
  reset()
