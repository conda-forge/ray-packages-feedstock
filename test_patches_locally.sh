#!/bin/bash
VERSION=$(grep -hoE 'set version = "([0-9\.]+)"' recipe/meta.yaml | grep -hoE '([0-9\.]+)')
FILENAME="ray-${VERSION}.tar.gz"
URL="https://github.com/ray-project/ray/archive/${FILENAME}"
DIRNAME="ray-ray-${VERSION}"

TMPDIR=$(mktemp -d)
cp -rf recipe/patches/*.patch $TMPDIR

pushd "${TMPDIR}" || exit 1
echo $TMPDIR
curl -LO "${URL}"
tar zxf "${FILENAME}"
for f in *.patch; do
  echo "---"
  echo "Applying patch: $f"
  patch -fNd "${DIRNAME}" -p1 < "$f" || echo "Patch failed!"
done

popd || exit 1
rm -rf "${TMPDIR}"
