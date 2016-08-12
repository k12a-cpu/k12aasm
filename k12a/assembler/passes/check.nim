from strutils import startsWith, endsWith, `%`
import tables
import ../types

type
  Label = object
    defLoc: Loc
    useLoc: Loc
  
  Checker = object
    messages: seq[string]
    labels: Table[string, Label]

proc error(c: var Checker, loc: Loc, msg: string) {.noSideEffect.} =
  c.messages.add("$1: $2" % [$loc, msg])

proc checkLiteral(c: var Checker, exp: Expr): bool =
  case exp.kind
  of exprLiteral:
    result = true
  of exprReg:
    result = false
  of exprLabelRef:
    let name = exp.labelName
    if name notin c.labels:
      c.labels[name] = Label(useLoc: exp.loc)
    elif c.labels[name].useLoc == nil:
      c.labels[name].useLoc = exp.loc
    result = true
  of exprUnary:
    result = c.checkLiteral(exp.child)
  of exprBinary:
    result = c.checkLiteral(exp.leftChild) and c.checkLiteral(exp.rightChild)

template requireNumOperands(n: int) =
  if inst.operands.len != n:
    c.error(inst.loc, "wrong number of operands (expected $1, got $2)" % [$n, $inst.operands.len])

template requireOperandLiteral(i: int) =
  if not c.checkLiteral(inst.operands[i]):
    c.error(inst.loc, "operand $1 must be a literal or label reference" % [$(i+1)])

template requireOperandAnyReg(i: int) =
  if inst.operands[i].kind != exprReg:
    c.error(inst.loc, "operand $1 must be a register" % [$(i+1)])

template requireOperandReg(i: int, r: Register) =
  if inst.operands[i].kind != exprReg or inst.operands[i].reg != r:
    c.error(inst.loc, "operand $1 must be register $2" % [$(i+1), $r])

proc checkSignature(c: var Checker, inst: Item) =
  case inst.mnemonic
  of "addsp":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "add":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandReg(2, regB)
  of "addi":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandLiteral(2)
  of "and":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandReg(2, regB)
  of "andi":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandLiteral(2)
  of "asr":
    requireNumOperands(2)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
  of "dec":
    requireNumOperands(0)
  of "getsp":
    requireNumOperands(0)
  of "halt":
    requireNumOperands(0)
  of "in":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "inc":
    requireNumOperands(0)
  of "ld":
    requireNumOperands(0)
  of "ldd":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "ljmp":
    requireNumOperands(0)
  of "mov":
    requireNumOperands(2)
    requireOperandAnyReg(0)
    requireOperandAnyReg(1)
  of "movi":
    requireNumOperands(2)
    requireOperandAnyReg(0)
    requireOperandLiteral(1)
  of "or":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandReg(2, regB)
  of "ori":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandLiteral(2)
  of "out":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "pop":
    requireNumOperands(0)
  of "push":
    requireNumOperands(0)
  of "putsp":
    requireNumOperands(0)
  of "rcall":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "rjmp":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "st":
    requireNumOperands(0)
  of "std":
    requireNumOperands(1)
    requireOperandLiteral(0)
  of "sub":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandReg(2, regB)
  of "subi":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandLiteral(2)
  of "xor":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandReg(2, regB)
  of "xori":
    requireNumOperands(3)
    requireOperandAnyReg(0)
    requireOperandReg(1, regA)
    requireOperandLiteral(2)
  else:
    if inst.mnemonic.startsWith("sk"):
      var s = inst.mnemonic[2 .. inst.mnemonic.high]
      if s.endsWith("i"):
        s = s[0 .. s.high - 1]
        requireNumOperands(1)
        requireOperandLiteral(0)
      else:
        requireNumOperands(0)
      case s
      of "z", "eq", "n", "b", "v", "ult", "ule", "slt", "sle", "nz", "ne", "nn", "nb", "nv", "uge", "ugt", "sge", "sgt":
        discard # ok
      else:
        c.error(inst.loc, "invalid mnemonic")
    else:
      c.error(inst.loc, "invalid mnemonic")

proc check(c: var Checker, item: Item) =
  case item.kind
  of itemInstruction:
    c.checkSignature(item)
  of itemLabel:
    let name = item.labelName
    if name notin c.labels:
      c.labels[name] = Label(defLoc: item.loc)
    elif c.labels[name].defLoc == nil:
      c.labels[name].defLoc = item.loc
    else:
      c.error(item.loc, "redefinition of label '$1' (previous definition at $2)" % [name, $c.labels[name].defLoc])
  of itemByte, itemWord:
    if not c.checkLiteral(item.value):
      c.error(item.loc, "operand must be a literal or label reference")

proc check(c: var Checker, unit: CompilationUnit) =
  for item in unit.items.mitems:
    c.check(item)

proc check*(unit: CompilationUnit): seq[string] =
  var c = Checker(
    messages: @[],
    labels: initTable[string, Label](),
  )
  c.check(unit)
  for labelName, label in c.labels:
    if label.useLoc != nil and label.defLoc == nil:
      c.error(label.useLoc, "undefined reference to label '$1'" % [labelName])
  result = c.messages
