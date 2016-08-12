import tables
import ../types

proc getLabelAddresses(unit: CompilationUnit): Table[string, uint16] =
  result = initTable[string, uint16]()
  for item in unit.items:
    if item.kind == itemLabel:
      result[item.labelName] = item.address

proc dereferenceLabels*(unit: CompilationUnit) =
  let labelAddresses = getLabelAddresses(unit)
  
  proc walk(e: var Expr) =
    case e.kind
    of exprLabelRef:
      let val = labelAddresses[e.labelName]
      e = Expr(kind: exprLiteral, literal: int(val))
    of exprUnary:
      walk(e.child)
    of exprBinary:
      walk(e.leftChild)
      walk(e.rightChild)
    else:
      discard
  
  for item in unit.items:
    case item.kind
    of itemInstruction:
      for operand in item.operands.mitems():
        walk(operand)
    of itemByte, itemWord:
      walk(item.value)
    else:
      discard
