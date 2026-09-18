require.asset = require('require-asset')

exports.nasm = require.asset('./bin/nasm', __filename)
exports.ndisasm = require.asset('./bin/ndisasm', __filename)
