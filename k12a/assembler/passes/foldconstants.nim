import ../types

proc eval(op: UnaryOp, a: int): int =
  case op
  of uopNeg: -a
  of uopNot: not a

proc eval(op: BinaryOp, a, b: int): int =
  case op
  of bopAnd: a and b
  of bopOr: a or b
  of bopXor: a xor b
  of bopAdd: a + b
  of bopSub: a - b
  of bopMul: a * b
  of bopDiv: a div b
  of bopMod: a mod b

proc walk(e: var Expr) =
  case e.kind
  of exprUnary:
    walk(e.child)
    if e.child.kind == exprLiteral:
      let val = eval(e.unaryOp, e.child.literal)
      e = Expr(kind: exprLiteral, literal: val)
  of exprBinary:
    walk(e.leftChild)
    walk(e.rightChild)
    if e.leftChild.kind == exprLiteral and e.rightChild.kind == exprLiteral:
      let val = eval(e.binaryOp, e.leftChild.literal, e.rightChild.literal)
      e = Expr(kind: exprLiteral, literal: val)
  else:
    discard

proc foldConstants*(unit: CompilationUnit) =
  for item in unit.items:
    case item.kind
    of itemInstruction:
      for operand in item.operands.mitems():
        walk(operand)
    else:
      discard
