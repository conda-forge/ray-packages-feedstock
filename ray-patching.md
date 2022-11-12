# How to deal with patches in this feedstock/recipe/

### Background
This feedstock needs to permanently carry patches, because
some of the things we need to adapt for the infrastructure of
conda-forge are not necessarily suitable for integration in
upstream ray

### Default Workflow

The main reason for touching these patches is of course when ray
releases a new version and the patches (may) fail to apply cleanly.

The default workflow is to keep a source-checkout of ray with a branch
containing the necessary patches for conda-forge. Once ray releases a new
version, it's (more or less) simply a matter or rebasing that branch and
and fixing the conflicts.

Initial setup:
* `git clone https://github.com/ray-project/ray`
* `cd ray`
* `git tag --list`
* `git checkout tags/ray-<old_version>`
* `git checkout -b conda`
* apply all the patches from the current feedstock (which are known to be good);
  since they're sorted in the `patches/` folder, you can even use `xargs`, e.g.
```sh
ls -d ../path/to/feedstock/recipe/patches/ | xargs git am
```

Rebase to new version or ray:
* `git rebase -i tags/ray-<new_version>` (the `-i` is optional, but you can
  use it to drop patches that you know where upstreamed even if git doesn't auto-recognize them)
* Fix eventual conflicts, taking care to keep the original patch attribution
  (if you make substantial changes, add a `Co-Authored-By: ...`)
  * I.e. if git tells you it couldn't apply commit `deadbeef`, then, after fixing the conflicts, do
  * `git add .`
  * `git show deadbeef`
  * `git commit --date="<date_of_deadbeef>" --author="<author_of_deadbeef>"` (commit message is kept as-is automatically while rebasing)
  * `git rebase --continue`
* `git format-patch tags/ray-<new_version>`
* remove all patches in the `patches`  folder
* copy patches produced by `git format-patch` over to recipe and update `meta.yaml`

## How to prepare or adapt patches for third party Ray components (using Redis as the example)

The above process is complicated by the fact that ray has patches for third party
dependencies (like redis) in its source code - in other words, we need to patch
the patches.

The process we just described then repeats for each dependency we need to patch
more or less as-is, with the exception that we now need to check in the patches
to third-party code into the ray source-code, and include _that_ in the ray-patches
we check into the feedstock. For added fun, it may happen that upstream ray changes
their patches from version to version in ways that conflict with ours.

Since patch application within the ray build is done by bazel (and may be subject
to destructive options like `-pN`, which changes the file hierarchy level the
patches apply to), it's best - for single patches at least - to extend the
ray patch directly to suit our purposes. This makes it also much clearer (well...)
when reviewing the diff(-of-the-diff-of-the-diff) on the feedstock.

### Prepare sources
1. Get Ray repository (using Ray 2.1.0 for example)
```sh
git clone https://github.com/ray-project/ray.git
cd ray
git checkout -b ray-2.1.0-original ray-2.1.0
# apply recipe patches
git am /ray-packages-feedstock/recipe/patches/*
cd ..
```
2. Find out repository and version needed (see `ray/bazel/ray_deps_setup.bzl`), clone it and checkout (taking version 7.0.5 for example):
```sh
git clone  https://github.com/redis/redis
cd redis
git checkout -b 7.0.5-patched 7.0.5
```
3. Apply relevant upstream patches first (2.1.0 has only one patch) and commit them:
```sh
patch -p1 < ../ray/thirdparty/patches/redis-quiet.patch
git add -u
git commit -m 'Upstream Ray patches'
```

### Make changes
1. Make new branch and make the necessary changes (maybe adapting existing conda recipe patches, etc.)
```sh
# do the necessary changes - edit files, etc.
git commit -m 'Fix the issue'
# if ray carries a single commit, squash it (and our changes) into one by interactive rebasing
git rebase -i 7.0.5
```
2. Prepare the patch for Redis in Ray sources (note that if the patch application
in bazel does not have a `-p1`, the call to `git format-patch` below also
needs a `--no-prefix` option):
```
git format-patch 7.0.5-patched..7.0.5 --stdout > ../ray/thirdparty/patches/redis-quiet.patch
```
3. Commit the patch for Redis:
```sh
cd ../ray
git checkout -b ray-2.1.0-patched
# edit ray/bazel/ray_deps_setup.bzl so it includes your patch
# if necessary, make sure it uses -p1 (or -p0 if patch was made with --no-prefix)
git add -u
git commit -m 'Fix the issue by Redis patch'
```

### Publish patch to recipe
1. Take commits as patches to the recipe:
```sh
git format-patch ray-2.1.0..ray-2.1.0-patched --output-directory /ray-packages-feedstock/recipe/patches/
```
2. Add the patches to the recipe:
```sh
cd /ray-packages-feedstock/recipe/
git add patches/
# edit meta.yaml to reference new patches
git add -u
git commit -m 'Fix the issue by Redis patch in Ray'
```