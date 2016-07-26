import k12a.assembler.parse

let unit = parseStdin()

for item in unit.items:
  echo $item[]
