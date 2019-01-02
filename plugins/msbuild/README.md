msbuild
=======

`msbuild::build`
---------------
- builds `MSBUILD_SOLUTION`

optional arguments:
- path to .csproj or .sln

`msbuild::clean`
---------------
- cleans `MSBUILD_SOLUTION`

`msbuild::rebuild`
-----------------
- cleans and builds `MSBUILD_SOLUTION`


Dependencies
============
3rd party:
- `msbuild` - https://www.mono-project.com


Examples
========
```
$ bee msbuild::build
$ bee msbuild::build MyProject.csproj

$ bee msbuild::clean

$ bee msbuild::rebuild
```
