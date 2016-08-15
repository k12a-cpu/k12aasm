import docopt, streams, strutils
import k12a.assembler.types
import k12a.assembler.preprocess
import k12a.assembler.parse
import k12a.assembler.passes.check
import k12a.assembler.passes.assignaddresses
import k12a.assembler.passes.dereferencelabels
import k12a.assembler.passes.foldconstants
import k12a.assembler.passes.check2
import k12a.assembler.passes.assemble

proc writeImage(outputStream: Stream, image: Image, format: string) =
  case format
  of "binary":
    outputStream.write(image[])
  of "readmemh":
    outputStream.writeLine("@0")
    for val in image[]:
      outputStream.writeLine(val.int.toHex(2))
  else:
    echo "Invalid output format: $1" % format
    echo "Use --help to list all valid values."
    quit(2)

const doc = """
k12aasm - Assembler for the K12a CPU.

Usage:
  k12aasm [options] [<infile>]

Options:
  -h, --help                          Print this help text.
  -o <outfile>, --output <outfile>    Write output to <outfile>, instead of to
                                      standard output.
  -f <format>, --format <format>      Select output format. See the Formats
                                      section for possible values. [default: binary]

Formats:
  binary          Raw binary image
  readmemh        Format suitable for reading with $readmemh in Verilog
"""

let args = docopt(doc)

let preprocessedStream = newStringStream()

# Read input and preprocess
if args["<infile>"]:
  let inputFilename = $args["<infile>"]
  let inputFile =
    try:
      open(inputFilename, mode = fmRead)
    except IOError:
      echo "Failed to open $1: $2" % [inputFilename, getCurrentExceptionMsg()]
      quit(1)
      nil # the compiler requires that all branches return a value, even though this line is unreachable.
  let inputStream = newFileStream(inputFile)
  try:
    preprocess(inputStream, preprocessedStream, inputFilename)
  except PreprocessorError:
    echo "Preprocessor error: $1" % getCurrentExceptionMsg()
    quit(1)
  inputFile.close()
else:
  let inputStream = newFileStream(stdin)
  try:
    preprocess(inputStream, preprocessedStream, "<stdin>")
  except PreprocessorError:
    echo "Preprocessor error: $1" % getCurrentExceptionMsg()
    quit(1)

# Parse
let unit =
  try:
    parseString(preprocessedStream.data)
  except ParseError:
    echo "Parse error: $1" % getCurrentExceptionMsg()
    quit(1)
    nil

# Check
let messages = check(unit)
if messages.len != 0:
  for message in messages:
    echo message
  quit(1)

# Transformation passes
assignAddresses(unit)
dereferenceLabels(unit)
foldConstants(unit)

# Check
let messages2 = check2(unit)
if messages2.len != 0:
  for message in messages2:
    echo message
  quit(1)

# Assemble image
let image = assemble(unit)

# Write output file
let format = $args["--format"]
if args["--output"]:
  let outputFilename = $args["--output"]
  let outputFile =
    try:
      open(outputFilename, mode = fmWrite)
    except IOError:
      echo "Failed to open $1: $2" % [outputFilename, getCurrentExceptionMsg()]
      quit(1)
      nil
  let outputStream = newFileStream(outputFile)
  writeImage(outputStream, image, format)
  outputFile.close()
else:
  let outputStream = newFileStream(stdout)
  writeImage(outputStream, image, format)
