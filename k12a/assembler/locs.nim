from strutils import `%`

type
  Loc* = ref object
    file*: string
    line*: int
    instantiation*: MacroInstantiation
  
  MacroInstantiation* = object
    macroName*: string
    loc*: Loc

proc `$`*(loc: Loc): string {.noSideEffect.} =
  "$1:$2" % [loc.file, $loc.line]

proc `==`*(a, b: Loc): bool {.noSideEffect.} =
  if a.isNil:
    b.isNil
  elif b.isNil:
    false
  else:
    a.line == b.line and a.file == b.file and a.instantiation.macroName == b.instantiation.macroName and a.instantiation.loc == b.instantiation.loc
