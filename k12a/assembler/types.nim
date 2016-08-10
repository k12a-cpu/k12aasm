from k12a.types import Register
from strutils import `%`

export Register

type
  Loc* = ref object
    file*: string
    line*: int
    instantiation*: MacroInstantiation
  
  MacroInstantiation* = object
    macroName*: string
    loc*: Loc

proc `$`*(loc: Loc): string =
  "$1:$2" % [loc.file, $loc.line]

type
  ExprKind* = enum
    exprLiteral
    exprReg
    exprLabelRef
    exprUnary
    exprBinary
  
  UnaryOp* = enum
    uopNeg
    uopNot
  
  BinaryOp* = enum
    bopAnd
    bopOr
    bopXor
    bopAdd
    bopSub
    bopMul
    bopDiv
    bopMod
  
  Expr* = ref object
    loc*: Loc
    case kind*: ExprKind
    of exprLiteral:
      literal*: int
    of exprReg:
      reg*: Register
    of exprLabelRef:
      labelName*: string
    of exprUnary:
      unaryOp*: UnaryOp
      child*: Expr
    of exprBinary:
      binaryOp*: BinaryOp
      leftChild*: Expr
      rightChild*: Expr
  
  ItemKind* = enum
    itemInstruction
    itemLabel
  
  Item* = ref object
    loc*: Loc
    address*: uint16
    case kind*: ItemKind
    of itemInstruction:
      mnemonic*: string
      operands*: seq[Expr]
    of itemLabel:
      labelName*: string
  
  CompilationUnit* = ref object
    items*: seq[Item]
  
  Image* = ref array[0x0000u16 .. 0x7FFFu16, uint8]
