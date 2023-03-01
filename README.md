# TeXUse tool for installing TeX packages

```
Description: Install TeX packages and their dependencies
Copyright: 2023 (c) Jianrui Lyu <tolvjr@163.com>
Repository: https://github.com/lvjr/texuse
License: GNU General Public License v3.0
```

## Introduction

TeXUse makes it easy to install TeX packages and their dependencies by file names, command names or environment names.

- To install a package by its file name you can run `texlua texuse.lua install array.sty`;
- To install a package by some command name you can run `texlua texuse.lua install \SetTblrInner`;
- To install a package by some environment name you can run `texlua texuse.lua install {frame}`.

TeXUse supports both TeXLive and MiKTeX distributions. At present it focuses mainly on LaTeX packages, but may extend to ConTeXt packages if anyone would like to contribute.

## Building

TeXUse uses completion files of TeXstudio editor which are in `completion` folder of TeXstudio [repository](https://github.com/texstudio-org/texstudio). Also it needs `texlive.tlpdb` of TeXLive and `package-manifests.ini` of MiKTeX which can be found in the installation folders.

After putting `completion` folder, `texlive.tlpdb` file and `package-manifests.ini` file into `download` folder, you can run `texlua generate.lua` to generate `texuse.json` file.

## Contributing

Any updates of dependencies, commands or environments for packages should be contributed directly to TeXstudio project.
