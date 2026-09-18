# nasm-runtime

Prebuilt [NASM](https://www.nasm.us) binaries for macOS, Linux, and Windows.

```
npm i -g nasm-runtime
```

The versions mirror the NASM releases, except that npm rejects the leading zero in a release such as `2.16.03`, which is published as `2.16.3`. See `npm info nasm-runtime` for available versions.

## API

#### `runtime([referrer][, options])`

Resolve the path of a binary for the current platform and architecture. `referrer` is the name of the binary, either `nasm` or `ndisasm`, defaulting to `nasm`. Pass `platform` and `arch` in `options` to resolve for another target.

#### `spawn([referrer][, options])`

Spawn a binary, passing `options` on to `child_process.spawn()`. The arguments default to those of the current process.

```js
const spawn = require('nasm-runtime/spawn')
```

## License

Apache-2.0
