# NOTES

## mingw-gcc

The windows build configuration must add a dependency to the mingw-gcc
and possibly to wine.

```json
"devDependencies": {
  "@xpack-dev-tools/mingw-gcc": "11.2.0-1.1"
}
```

## TODO

- create a `mingw-gcc-xpack`, running on Intel Linux and producing
Windows binaries.
- create a `wine-xpack`, running on Intel Linux
