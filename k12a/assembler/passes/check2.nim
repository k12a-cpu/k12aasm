from strutils import startsWith, endsWith, `%`
import tables
import ../types
import k12a.types as k12atypes

type
  Checker = object
    messages: seq[string]

proc error(c: var Checker, loc: Loc, msg: string) {.noSideEffect.} =
  c.messages.add("$1: $2" % [$loc, msg])

template requireOperandRange(i: int, min, max: int) =
  let exp = inst.operands[i]
  if exp.kind != exprLiteral:
    c.error(inst.loc, "operand $1 must be a literal or label reference" % [$(i+1)])
  else:
    let val = exp.literal
    if val < min or val > max:
      c.error(inst.loc, "operand $1 value ($2) out of range $3..$4" % [$(i+1), $val, $min, $max])

template requireOperandRange(i: int, t: typedesc) =
  requireOperandRange(i, t.low.int, t.high.int)

proc checkSignature(c: var Checker, inst: Item) {.noSideEffect.} =
  case inst.mnemonic
  of "addsp":
    requireOperandRange(0, Offset)
  of "addi":
    requireOperandRange(2, Imm)
  of "andi":
    requireOperandRange(2, Imm)
  of "in":
    requireOperandRange(0, Port)
  of "ldd":
    requireOperandRange(0, Offset)
  of "movi":
    requireOperandRange(1, Imm)
  of "ori":
    requireOperandRange(2, Imm)
  of "out":
    requireOperandRange(0, Port)
  of "rcall":
    requireOperandRange(0, inst.address.int + Offset.low.int, inst.address.int + Offset.high.int)
  of "rjmp":
    requireOperandRange(0, inst.address.int + Offset.low.int, inst.address.int + Offset.high.int)
  of "std":
    requireOperandRange(0, Offset)
  of "subi":
    requireOperandRange(2, Imm)
  of "xori":
    requireOperandRange(2, Imm)
  else:
    if inst.mnemonic.startsWith("sk") and inst.mnemonic.endsWith('i'):
      requireOperandRange(0, Imm)

proc check(c: var Checker, item: Item) {.noSideEffect.} =
  case item.kind
  of itemInstruction:
    c.checkSignature(item)
  of itemByte:
    if item.value.kind != exprLiteral:
      c.error(item.loc, "operand must be a literal or label reference")
    else:
      let val = item.value.literal
      if val < 0x00 or val > 0xFF:
        c.error(item.loc, "operand value ($1) out of range 0..255" % [$val])
  of itemWord:
    if item.value.kind != exprLiteral:
      c.error(item.loc, "operand must be a literal or label reference")
    else:
      let val = item.value.literal
      if val < 0x0000 or val > 0xFFFF:
        c.error(item.loc, "operand value ($1) out of range 0..65535" % [$val])
  of itemLabel:
    discard

proc check(c: var Checker, unit: CompilationUnit) {.noSideEffect.} =
  for item in unit.items.mitems:
    c.check(item)

proc check2*(unit: CompilationUnit): seq[string] {.noSideEffect.} =
  var c = Checker(
    messages: @[],
  )
  c.check(unit)
  result = c.messages
