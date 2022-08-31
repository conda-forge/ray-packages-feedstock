#!/bin/bash
VERSION=$(grep -hoE 'set version = "([0-9\.]+)"' recipe/meta.yaml | grep -hoE '([0-9\.]+)')
FILENAME="ray-${VERSION}.tar.gz"
URL="https://github.com/ray-project/ray/archive/${FILENAME}"
DIRNAME="ray-ray-${VERSION}"

CACHED="$TMPDIR/$FILENAME"

if [ ! -f $CACHED ]; then
  echo "Downloading $FILENAME to $CACHED"
  curl -Lqo "$CACHED" "$URL"
fi

TMPDIR=$(mktemp -d)
cp -rf recipe/patches/*.patch $TMPDIR

pushd "${TMPDIR}" || exit 1
echo $TMPDIR
cp -rf "$CACHED" .
tar zxf "${FILENAME}"
for f in *.patch; do
  echo "---"
  echo "Applying patch: $f"
  patch -fNd "${DIRNAME}" -p1 < "$f"
  if [ $? -ne 0 ]; then
    echo "Patch failed!"
    find . -name '*.rej' -exec cat {} \;
    break
  fi
done

popd || exit 1
rm -rf "${TMPDIR}"
