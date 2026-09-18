require.asset = require('require-asset')

exports.nasm = require.asset('./bin/nasm.exe', __filename)
exports.ndisasm = require.asset('./bin/ndisasm.exe', __filename)
