from strutils import startsWith, endsWith
import k12a/types as k12atypes
import ../types

proc encodeInstruction(inst: Item): Instruction =
  case inst.mnemonic
  of "addsp":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let offset = inst.operands[0].literal.Offset
    result = encodeOperation(opAddsp) or encodeOffset(offset)
  of "add":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprReg
    assert inst.operands[2].reg == regB
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluAdd)
  of "addi":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprLiteral
    let imm = inst.operands[2].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluAdd) or encodeImm(imm)
  of "and":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprReg
    assert inst.operands[2].reg == regB
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluAnd)
  of "andi":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprLiteral
    let imm = inst.operands[2].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluAnd) or encodeImm(imm)
  of "asr":
    assert inst.operands.len == 2
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluAsr)
  of "dec":
    assert inst.operands.len == 0
    result = encodeOperation(opDec)
  of "getsp":
    assert inst.operands.len == 0
    result = encodeOperation(opGetsp)
  of "halt":
    assert inst.operands.len == 0
    result = encodeOperation(opHalt)
  of "in":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let port = inst.operands[0].literal.Port
    result = encodeOperation(opIn) or encodePort(port)
  of "inc":
    assert inst.operands.len == 0
    result = encodeOperation(opInc)
  of "ld":
    assert inst.operands.len == 0
    result = encodeOperation(opLd)
  of "ldd":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let offset = inst.operands[0].literal.Offset
    result = encodeOperation(opLdd) or encodeOffset(offset)
  of "ljmp":
    assert inst.operands.len == 0
    result = encodeOperation(opLjmp)
  of "mov":
    assert inst.operands.len == 2
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    let srcEncoding =
      case inst.operands[1].reg
      of regA: encodeMovSrc(msAluAB) or encodeAluOperation(aluA)
      of regB: encodeMovSrc(msAluAB) or encodeAluOperation(aluB)
      of regC: encodeMovSrc(msC)
      of regD: encodeMovSrc(msD)
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or srcEncoding
  of "movi":
    assert inst.operands.len == 2
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprLiteral
    let imm = inst.operands[1].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluB) or encodeImm(imm)
  of "or":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprReg
    assert inst.operands[2].reg == regB
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluOr)
  of "ori":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprLiteral
    let imm = inst.operands[2].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluOr) or encodeImm(imm)
  of "out":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let port = inst.operands[0].literal.Port
    result = encodeOperation(opOut) or encodePort(port)
  of "pop":
    assert inst.operands.len == 0
    result = encodeOperation(opPop)
  of "push":
    assert inst.operands.len == 0
    result = encodeOperation(opPush)
  of "putsp":
    assert inst.operands.len == 0
    result = encodeOperation(opPutsp)
  of "rcall":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let source = inst.address.int + 2
    let target = inst.operands[0].literal
    let offset = Offset(target - source)
    result = encodeOperation(opRcall) or encodeOffset(offset)
  of "rjmp":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let source = inst.address.int + 2
    let target = inst.operands[0].literal
    let offset = Offset(target - source)
    result = encodeOperation(opRjmp) or encodeOffset(offset)
  of "st":
    assert inst.operands.len == 0
    result = encodeOperation(opSt)
  of "std":
    assert inst.operands.len == 1
    assert inst.operands[0].kind == exprLiteral
    let offset = inst.operands[0].literal.Offset
    result = encodeOperation(opStd) or encodeOffset(offset)
  of "sub":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprReg
    assert inst.operands[2].reg == regB
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluSub)
  of "subi":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprLiteral
    let imm = inst.operands[2].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluSub) or encodeImm(imm)
  of "xor":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprReg
    assert inst.operands[2].reg == regB
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAB) or encodeAluOperation(aluXor)
  of "xori":
    assert inst.operands.len == 3
    assert inst.operands[0].kind == exprReg
    assert inst.operands[1].kind == exprReg
    assert inst.operands[1].reg == regA
    assert inst.operands[2].kind == exprLiteral
    let imm = inst.operands[2].literal.Imm
    result = encodeOperation(opMov) or encodeMovDest(inst.operands[0].reg) or
             encodeMovSrc(msAluAI) or encodeAluOperation(aluXor) or encodeImm(imm)
  else:
    if inst.mnemonic.startsWith("sk"):
      var s = inst.mnemonic[2 .. inst.mnemonic.high]
      var cond: Condition
      var skipFlags: set[SkipFlag]
      if s.endsWith("i"):
        skipFlags.incl(skipImm)
        s = s[0 .. s.high - 1]
        assert inst.operands.len == 1
        assert inst.operands[0].kind == exprLiteral
        let imm = inst.operands[0].literal.Imm
        result = encodeImm(imm)
      else:
        assert inst.operands.len == 0
      case s
      of "z", "eq": cond = condZero
      of "n":       cond = condNegative
      of "b":       cond = condLSB
      of "v":       cond = condOverflow
      of "ult":     cond = condULT
      of "ule":     cond = condULE
      of "slt":     cond = condSLT
      of "sle":     cond = condSLE
      of "nz", "ne":
        cond = condZero
        skipFlags.incl(skipNegate)
      of "nn":
        cond = condNegative
        skipFlags.incl(skipNegate)
      of "nb":
        cond = condLSB
        skipFlags.incl(skipNegate)
      of "nv":
        cond = condOverflow
        skipFlags.incl(skipNegate)
      of "uge":
        cond = condULT
        skipFlags.incl(skipNegate)
      of "ugt":
        cond = condULE
        skipFlags.incl(skipNegate)
      of "sge":
        cond = condSLT
        skipFlags.incl(skipNegate)
      of "sgt":
        cond = condSLE
        skipFlags.incl(skipNegate)
      else:
        assert false, "mnemonic should already have been vetted"
      result = result or encodeOperation(opSkip) or encodeCondition(cond) or encodeSkipFlags(skipFlags)
    else:
      assert false, "mnemonic should already have been vetted"

proc assemble*(unit: CompilationUnit): Image =
  result.new()
  
  for item in unit.items:
    case item.kind
    of itemInstruction:
      let word = encodeInstruction(item)
      result[item.address] = uint8(word shr 8)
      result[item.address+1] = uint8(word)
    of itemByte:
      assert item.value.kind == exprLiteral
      let val = item.value.literal
      result[item.address] = uint8(val)
    of itemWord:
      assert item.value.kind == exprLiteral
      let val = item.value.literal
      result[item.address] = uint8(val shr 8)
      result[item.address+1] = uint8(val)
    else:
      discard
