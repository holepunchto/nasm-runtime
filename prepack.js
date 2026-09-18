const fs = require('fs')
const path = require('path')

makeExecutable(path.join(process.cwd(), 'bin'))

function makeExecutable(directory) {
  let entries

  try {
    entries = fs.readdirSync(directory, { withFileTypes: true })
  } catch {
    return
  }

  for (const entry of entries) {
    if (entry.name[0] === '.') continue

    const file = path.join(directory, entry.name)

    if (entry.isDirectory()) makeExecutable(file)
    else if (entry.isFile()) fs.chmodSync(file, 0o755)
  }
}
