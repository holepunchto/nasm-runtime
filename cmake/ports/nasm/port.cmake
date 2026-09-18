include_guard(GLOBAL)

# The release tarball rather than the repository: it carries `configure` and the
# sources NASM generates from its instruction tables with Perl, neither of which
# is committed, so building it needs no autotools and no Perl.
set(NASM_PORT_VERSION "2.16.03" CACHE STRING "The NASM release to build")

set(env)
set(path)
set(args)

if(CMAKE_SYSTEM_NAME)
  set(platform ${CMAKE_SYSTEM_NAME})
else()
  set(platform ${CMAKE_HOST_SYSTEM_NAME})
endif()

string(TOLOWER "${platform}" platform)

if(platform MATCHES "darwin|ios")
  set(platform "darwin")
elseif(platform MATCHES "linux|android")
  set(platform "linux")
elseif(platform MATCHES "windows")
  set(platform "windows")
else()
  message(FATAL_ERROR "Unsupported platform '${platform}'")
endif()

if(APPLE AND CMAKE_OSX_ARCHITECTURES)
  set(arch ${CMAKE_OSX_ARCHITECTURES})
elseif(MSVC AND CMAKE_GENERATOR_PLATFORM)
  set(arch ${CMAKE_GENERATOR_PLATFORM})
elseif(ANDROID AND CMAKE_ANDROID_ARCH_ABI)
  set(arch ${CMAKE_ANDROID_ARCH_ABI})
elseif(CMAKE_SYSTEM_PROCESSOR)
  set(arch ${CMAKE_SYSTEM_PROCESSOR})
else()
  set(arch ${CMAKE_HOST_SYSTEM_PROCESSOR})
endif()

string(TOLOWER "${arch}" arch)

if(arch MATCHES "arm64|aarch64")
  set(arch "aarch64")
elseif(arch MATCHES "armv7-a|armeabi-v7a")
  set(arch "arm")
elseif(arch MATCHES "x64|x86_64|amd64")
  set(arch "x86_64")
elseif(arch MATCHES "x86|i386|i486|i586|i686")
  set(arch "i686")
else()
  message(FATAL_ERROR "Unsupported architecture '${arch}'")
endif()

list(APPEND args --host=${arch}-${platform})

if(APPLE)
  list(APPEND args --with-sysroot=${CMAKE_OSX_SYSROOT})
elseif(ANDROID)
  list(APPEND args --with-sysroot=${CMAKE_SYSROOT})
endif()

if(platform MATCHES "windows")
  # NASM resolves the embedded manifest against the build directory rather than
  # the source directory, so the resource compilation only works in tree. The
  # manifest asks for nothing we need, so skip it rather than reach for whichever
  # `windres` happens to be on the PATH.
  list(APPEND env "WINDRES=false")

  # `<stdnoreturn.h>` defines `noreturn` as a macro, which the Windows headers
  # then expand inside their own `__declspec(noreturn)`. NASM reaches for the
  # header only when configure finds it, so hide it.
  list(APPEND env "ac_cv_header_stdnoreturn_h=no")
endif()

if(CMAKE_C_COMPILER)
  cmake_path(GET CMAKE_C_COMPILER PARENT_PATH CC_path)
  cmake_path(GET CMAKE_C_COMPILER FILENAME CC_filename)

  # NASM's configure hands the compiler GNU style warning flags, which the MSVC
  # style driver reads as their MSVC namesakes: `-Wall` becomes `/Wall`, which
  # is `-Weverything`. The target triple already selects the MSVC ABI, so reach
  # for the GNU driver from the same toolchain instead.
  if(WIN32 AND CC_filename MATCHES "clang-cl.exe")
    set(CC_filename "clang.exe")
  endif()

  list(APPEND env "CC=${CC_filename}")

  # A compiler without a target of its own is already pointed at the right one,
  # so naming it would be at best redundant and at worst wrong.
  set(flags)

  if(CMAKE_C_COMPILER_TARGET)
    list(APPEND flags "--target=${CMAKE_C_COMPILER_TARGET}")
  endif()

  list(JOIN flags " " cflags)

  if(CMAKE_LINKER_TYPE MATCHES "LLD")
    list(APPEND flags "-fuse-ld=lld")
  endif()

  list(JOIN flags " " ldflags)

  list(APPEND env "CFLAGS=${cflags}" "LDFLAGS=${ldflags}")

  list(APPEND path "${CC_path}")
endif()

if(CMAKE_AR)
  cmake_path(GET CMAKE_AR PARENT_PATH AR_path)
  cmake_path(GET CMAKE_AR FILENAME AR_filename)

  if(WIN32 AND AR_filename MATCHES "llvm-lib.exe")
    set(AR_filename "llvm-ar.exe")
  endif()

  list(APPEND env "AR=${AR_filename}")
  list(APPEND path "${AR_path}")
endif()

if(CMAKE_RANLIB)
  cmake_path(GET CMAKE_RANLIB PARENT_PATH RANLIB_path)
  cmake_path(GET CMAKE_RANLIB FILENAME RANLIB_filename)

  list(APPEND env "RANLIB=${RANLIB_filename}")
  list(APPEND path "${RANLIB_path}")
endif()

foreach(part "$ENV{PATH}")
  cmake_path(NORMAL_PATH part)

  list(APPEND path "${part}")
endforeach()

list(REMOVE_DUPLICATES path)

if(CMAKE_HOST_WIN32)
  list(TRANSFORM path REPLACE "([A-Z]):" "/\\1")
endif()

list(JOIN path ":" path)

list(APPEND env "PATH=${path}")

declare_port(
  "https://www.nasm.us/pub/nasm/releasebuilds/${NASM_PORT_VERSION}/nasm-${NASM_PORT_VERSION}.tar.gz"
  nasm
  AUTOTOOLS
  ENTRYPOINT "<SOURCE_DIR>/configure"
  BYPRODUCTS
    bin/nasm${CMAKE_EXECUTABLE_SUFFIX}
    bin/ndisasm${CMAKE_EXECUTABLE_SUFFIX}
  ARGS ${args}
  ENV ${env}
)

foreach(program nasm ndisasm)
  add_executable(${program} IMPORTED GLOBAL)

  add_dependencies(${program} ${nasm})

  set_target_properties(
    ${program}
    PROPERTIES
    IMPORTED_LOCATION "${nasm_PREFIX}/bin/${program}${CMAKE_EXECUTABLE_SUFFIX}"
  )
endforeach()
