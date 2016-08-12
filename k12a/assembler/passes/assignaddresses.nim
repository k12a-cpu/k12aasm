import ../types

proc size(item: Item): uint16 {.noSideEffect.} =
  case item.kind
  of itemInstruction:
    2
  of itemLabel:
    0
  of itemByte:
    1
  of itemWord:
    2

proc assignAddresses*(unit: CompilationUnit) {.noSideEffect.} =
  var address: uint16 = 0
  for item in unit.items:
    item.address = address
    address += item.size()
