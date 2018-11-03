dotnet
======

`dotnet::build`
---------------
- builds `DOTNET_SOLUTION`

optional arguments:
- path to .csproj or .sln

`dotnet::clean`
---------------
- cleans `DOTNET_SOLUTION`

`dotnet::rebuild`
-----------------
- cleans and builds `DOTNET_SOLUTION`


Dependencies
============
3rd party:
- `msbuild` - https://www.mono-project.com


Examples
========
```
$ bee dotnet::build
$ bee dotnet::build MyProject.csproj

$ bee dotnet::clean

$ bee dotnet::rebuild
```
