## How to create a new patch stack

```sh
git apply --check path/to/0001-example.patch

```

## How to prepare or adapt patches for third party Ray components (using Redis as the example)

### Prepare sources
1. Get Ray repository (using Ray 1.1.0 for example)
```sh
git clone https://github.com/ray-project/ray.git
cd ray
git checkout -b ray-1.1.0-original ray-1.1.0
# apply recipe patches
git am /ray-packages-feedstock/recipe/patches/*
cd ..
```
2. Find out repository and version needed (see `ray/bazel/ray_deps_setup.bzl`), clone it and checkout (taking version 6.0.9 for example):
```sh
git clone  https://github.com/redis/redis
cd redis
git checkout -b 6.0.9-original 6.0.9
```
3. Apply relevant upstream patches first (1.1.0 has only one patch) and commit them:
```sh
patch -p0 < patch -p0 < ../ray/thirdparty/patches/redis-quiet.patch
git add -u
git commit -m 'Upstream Ray patches'
```

### Make changes
1. Make new branch and make the necessary changes (maybe adapting existing conda recipe patches, etc.)
```sh
git checkout -b 6.0.9-patched
# do the necessary changes - edit files, etc.
git commit -m 'Fix the issue'
```
2. Prepare the patch for Redis in Ray sources:
```
git format-patch 6.0.9-original..6.0.9-patched --no-prefix --stdout > ../ray/thirdparty/patches/redis-deps-ar.patch
```
3. Commit the patch for Redis:
```sh
cd ../ray
git checkout -b ray-1.1.0-patched
git add thirdparty/patches/redis-deps-ar.patch
# edit ray/bazel/ray_deps_setup.bzl so it references this patch
git add -u
git commit -m 'Fix the issue by Redis patch'
```

### Publish patch to recipe
1. Take commits as patches to the recipe:
```sh
git format-patch ray-1.1.0..ray-1.1.0-patched --output-directory /ray-packages-feedstock/recipe/patches/
```
2. Add the patches to the recipe:
```sh
cd /ray-packages-feedstock/recipe/
git add patches/
# edit meta.yaml to reference new patches
git add -u
git commit -m 'Fix the issue by Redis patch in Ray'
```