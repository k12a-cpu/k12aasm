from strutils import toHex
import k12a.assembler.types
import k12a.assembler.parse
import k12a.assembler.passes.check
import k12a.assembler.passes.assignaddresses
import k12a.assembler.passes.dereferencelabels
import k12a.assembler.passes.foldconstants
import k12a.assembler.passes.assemble

let unit = parseStdin()

let messages = check(unit)
if messages.len != 0:
  for message in messages:
    echo message
  quit(1)

assignAddresses(unit)
dereferenceLabels(unit)
foldConstants(unit)

let image = assemble(unit)

# var f: File
# if not f.open("output.bin", fmWrite):
#   echo "Could not open output.bin"
#   quit(1)
# discard f.writeBytes(image[], 0, image[].len)
# f.close()

echo "@0"
for d in image[]:
  echo d.int.toHex(2)
