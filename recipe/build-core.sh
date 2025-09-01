#!/bin/bash
set -xe

if [[ "$target_platform" == osx* ]]; then
  # make sure the vendored redis OSX build can find the correct toolchain. the SDKROOT is
  # also passed as we are using at least OSX 10.15 which moves the include directory out
  # of /usr/include to ${SDKROOT}/MacOSX.sdk/usr/include
  if [[ "$target_platform" == osx-arm64 ]]; then
    export LDFLAGS="$LDFLAGS -undefined dynamic_lookup -Wl,-framework,Foundation"
  else
    export LDFLAGS="$LDFLAGS -undefined dynamic_lookup"
  fi
  # https://github.com/conda-forge/bazel-toolchain-feedstock/issues/18
  # delete the line from the template and the CXXFLAGS
  export CXXFLAGS="${CXXFLAGS/-stdlib=libc++ /} -Wno-vla-cxx-extension"
  sed -i"''" -e'/stdlib=libc/d' $CONDA_PREFIX/share/bazel_toolchain/CROSSTOOL.template
  source gen-bazel-toolchain
  cat >> .bazelrc <<EOF
build --define CONDA_CC=${CC}
build --define CONDA_CFLAGS="${CFLAGS}"
build --define CONDA_AR=${AR}
build --define CONDA_NM=${NM}
build --define CONDA_RANLIB=${RANLIB}
build --define CONDA_SDKROOT=${SDKROOT}
# build --subcommands
build --crosstool_top=//bazel_toolchain:toolchain
build --cpu=${TARGET_CPU}
build --platforms=//bazel_toolchain:target_platform
build --host_platform=//bazel_toolchain:build_platform
build --experimental_ui_max_stdouterr_bytes=16000000
build --local_ram_resources=HOST_RAM*.8 --local_cpu_resources=2
EOF
fi

echo '---------------- .bazelrc --------------------------'
cat .bazelrc
echo '----------------------------------------------------'

cd python/
export SKIP_THIRDPARTY_INSTALL_CONDA_FORGE=1

# https://github.com/prefix-dev/rattler-build/issues/1865
find $CONDA_PREFIX/share/bazel/install | xargs -n 1 touch -mt 203601010101

"${PYTHON}" setup.py build
# bazel by default makes everything read-only,
# which leads to patchelf failing to fix rpath in binaries.
# find all ray binaries and make them writable
grep -lR ELF build/ | xargs chmod +w

# now install the thing so conda could pick it up
"${PYTHON}" setup.py install  --single-version-externally-managed --root=/

# now clean everything up so subsequent builds (for potentially
# different Python version) do not stumble on some after-effects
"${PYTHON}" setup.py clean --all
bazel clean --expunge
rm -rf "$SRC_DIR/../b-o" "$SRC_DIR/../bazel-root"

if [[ "$target_platform" == "linux-"* ]]; then
  ls -lR $SP_DIR
  # Remove RUNPATH and set RPATH
  for f in "ray/_raylet.so" "ray/core/src/ray/raylet/raylet" "ray/core/src/ray/gcs/gcs_server" "ray/core/libjemalloc.so"; do
    chmod +w $SP_DIR/$f
    patchelf --remove-rpath $SP_DIR/$f
    patchelf --force-rpath --add-rpath $PREFIX/lib $SP_DIR/$f
  done
fi
