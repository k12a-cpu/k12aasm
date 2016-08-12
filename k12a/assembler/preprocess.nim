import locs, marshal, pegs, re, streams, strutils, tables

let commentPeg = peg"';' @ $"
let definePeg = peg"^ '.define' \s+ {\ident} {(\s .*)?} $"
let macroPeg = peg"^ '.macro' \s+ {'%' \ident} {(\s .*)?} $"
let macroParamPeg = peg"^ \s* {\ident} \s* $"
let macroInvokePeg = peg"^ {'%' \ident} {(\s .*)?} $"

type
  MacroLine = object
    line: string
    loc: Loc
  
  MacroInfo = object
    params: seq[string]
    body: seq[MacroLine]
  
  DefineContext = ref object
    defines: Table[string, tuple[pattern: Regex, repl: string]]
    parent: DefineContext
  
  Preprocessor = object
    output: Stream
    macros: Table[string, MacroInfo]
    currentMacro: string
    rootDefineContext: DefineContext
    defineContext: DefineContext
    defineSubs: seq[tuple[pattern: Regex, repl: string]]
    defineSubsNeedsUpdating: bool
    nextNonce: int
    predictedLoc: Loc
  
  PreprocessorError* = object of Exception

proc init(pp: var Preprocessor, output: Stream) =
  pp.output = output
  pp.macros = initTable[string, MacroInfo]()
  pp.currentMacro = nil
  pp.rootDefineContext = DefineContext(
    defines: initTable[string, tuple[pattern: Regex, repl: string]](),
    parent: nil,
  )
  pp.defineContext = pp.rootDefineContext
  pp.defineSubs = @[]
  pp.defineSubsNeedsUpdating = false
  pp.nextNonce = 1
  pp.predictedLoc = nil

proc initPreprocessor(output: Stream): Preprocessor =
  result.init(output)

proc newNonce(pp: var Preprocessor): int =
  result = pp.nextNonce
  inc pp.nextNonce

proc pushDefineContext(pp: var Preprocessor) =
  pp.defineContext = DefineContext(
    defines: initTable[string, tuple[pattern: Regex, repl: string]](),
    parent: pp.defineContext,
  )

proc popDefineContext(pp: var Preprocessor) =
  pp.defineContext = pp.defineContext.parent

proc addDefine(pp: var Preprocessor, name: string, pattern: Regex, value: string, global: bool = false) =
  let t = (pattern: pattern, repl: value)
  let dc =
    if global:
      pp.rootDefineContext
    else:
      pp.defineContext
  dc.defines[name] = t
  if name in dc.defines:
    # too much effort to find and update it in the list, so just force a rebuild
    pp.defineSubsNeedsUpdating = true
  else:
    pp.defineSubs.add(t)

proc addDefine(pp: var Preprocessor, name, value: string, global: bool = false) =
  let pattern = re("\\b" & escapeRe(name) & "\\b")
  pp.addDefine(name, pattern, value)

proc substitute(pp: var Preprocessor, text: string): string =
  if pp.defineSubsNeedsUpdating:
    var dc = pp.defineContext
    pp.defineSubs.setLen(0)
    while not dc.isNil:
      for t in dc.defines.values:
        pp.defineSubs.add(t)
      dc = dc.parent
  result = text.parallelReplace(pp.defineSubs)

proc error(pp: var Preprocessor, loc: Loc, msg: string) =
  raise newException(PreprocessorError, "$1: $2" % [$loc, msg])

proc emit(pp: var Preprocessor, line: string, loc: Loc) =
  if pp.predictedLoc != loc:
    pp.output.writeLine(".loc " & $$loc)
    pp.predictedLoc.deepCopy(loc)
  pp.output.writeLine(line)
  inc pp.predictedLoc.line

proc feed(pp: var Preprocessor, rawLine: string, loc: Loc)

proc instantiateMacro(pp: var Preprocessor, name, argStr: string, loc: Loc) =
  if name == pp.currentMacro:
    pp.error(loc, "recursive macro instantiation is disallowed")
  elif name notin pp.macros:
    pp.error(loc, "undefined macro: " & name)
  else:
    let info = pp.macros[name]
    var args = newSeq[string]()
    for rawArg in argStr.split(','):
      args.add(rawArg.strip())
    if args.len < info.params.len:
      pp.error(loc, "not enough arguments to macro instantation (expected $1, got $2)" % [$info.params.len, $args.len])
    elif args.len > info.params.len:
      pp.error(loc, "too many arguments to macro instantation (expected $1, got $2)" % [$info.params.len, $args.len])
    else:
      let instantiation = MacroInstantiation(macroName: name, loc: loc)
      pp.pushDefineContext()
      pp.addDefine("$$", re"\$\$", $pp.newNonce())
      for i, param in info.params:
        pp.addDefine(param, args[i])
      for ml in info.body:
        let lineLoc = Loc(
          file: ml.loc.file,
          line: ml.loc.line,
          instantiation: instantiation,
        )
        pp.feed(ml.line, lineLoc)
      pp.popDefineContext()

proc processMacro(pp: var Preprocessor, name, paramStr: string, loc: Loc) =
  var params = newSeq[string]()
  for rawParam in paramStr.split(','):
    if rawParam =~ macroParamPeg:
      params.add(matches[0])
    else:
      pp.error(loc, "invalid macro parameter syntax: " & rawParam)
  let macroInfo = MacroInfo(params: params, body: @[])
  pp.macros[name] = macroInfo
  pp.currentMacro = name

proc processDefine(pp: var Preprocessor, name, value: string) =
  pp.addDefine(name, value, global = true)

proc feedToplevel(pp: var Preprocessor, line: string, loc: Loc) =
  if line.startsWith('%'):
    if line =~ macroInvokePeg:
      pp.instantiateMacro(matches[0], matches[1], loc)
    else:
      pp.error(loc, "invalid macro instantiation syntax: " & line)
  elif line.startsWith(".macro"):
    if line =~ macroPeg:
      pp.processMacro(matches[0], matches[1], loc)
    else:
      pp.error(loc, "invalid .macro syntax: " & line)
  elif line.startsWith(".define"):
    if line =~ definePeg:
      pp.processDefine(matches[0], matches[1].strip())
    else:
      pp.error(loc, "invalid .define syntax: " & line)
  else:
    pp.emit(line, loc)

proc feedInMacro(pp: var Preprocessor, line: string, loc: Loc) =
  if line.startsWith(".endmacro"):
    pp.currentMacro = nil
  else:
    let ml = MacroLine(line: line, loc: loc)
    pp.macros[pp.currentMacro].body.add(ml)

proc feed(pp: var Preprocessor, rawLine: string, loc: Loc) =
  let line = pp.substitute(rawLine.strip().replace(commentPeg, ""))
  if line.len != 0:
    if pp.currentMacro.isNil:
      pp.feedToplevel(line, loc)
    else:
      pp.feedInMacro(line, loc)

proc preprocess*(input, output: Stream, filename: string = "<input>") =
  var pp = initPreprocessor(output)
  var lineno = 1
  while not input.atEnd():
    let loc = Loc(file: filename, line: lineno)
    pp.feed(input.readLine, loc)
    inc lineno

when isMainModule:
  preprocess(newFileStream(stdin), newFileStream(stdout), "<stdin>")
