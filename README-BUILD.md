# How to build the xPack Test Next binaries

TBD

## Download the build scripts repo

The build scripts are available in the `scripts` folder of the
[`xpack-dev-tools/test-next-xpack`](https://github.com/xpack-dev-tools/test-next-xpack)
Git repo.

To download them, issue the following commands:

```sh
rm -rf ~/Downloads/test-next-xpack.git; \
git clone \
  https://github.com/xpack-dev-tools/test-next-xpack.git \
  ~/Downloads/test-next-xpack.git; \
git -C ~/Downloads/test-next-xpack.git submodule update --init --recursive
```

> Note: the repository uses submodules; for a successful build it is
> mandatory to recurse the submodules.

For development purposes, clone the `xpack-develop`
branch:

```sh
rm -rf ~/Downloads/test-next-xpack.git; \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/test-next-xpack.git \
  ~/Downloads/test-next-xpack.git; \
git -C ~/Downloads/test-next-xpack.git submodule update --init --recursive
```

## Install dependencies

```sh
cd ~/Downloads/test-next-xpack.git
xpm install
```

## Build

```console
xpm run build --config release
xpm run build-develop --config release
```

```console
xpm run build --config debug
```

## Clean

```console
xpm run clean --config release
```

```console
xpm run clean --config debug
```
