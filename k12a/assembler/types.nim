from strutils import `%`

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
  Register* = enum
    regA
    regB
    regC
    regD
  
  ExprKind* = enum
    exprLiteral
    exprReg
    exprLabelRef
    exprUnary
    exprBinary
  
  UnaryOp* = enum
    opNeg
    opNot
  
  BinaryOp* = enum
    opAnd
    opOr
    opXor
    opAdd
    opSub
    opMul
    opDiv
    opMod
  
  Expr* = ref object
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
    case kind*: ItemKind
    of itemInstruction:
      mnemonic*: string
      operands*: seq[Expr]
    of itemLabel:
      labelName*: string
  
  CompilationUnit* = ref object
    items*: seq[Item]
