nspec
======

`nspec::run`
---------------
- runs `msbuild::build` with `NSPEC_TESTS_PROJECT`
- runs the test runner `NSPEC_TESTS_RUNNER` with `mono`

optional arguments:
- name of test class to focus on


Dependencies
============
3rd party:
- `mono` - https://www.mono-project.com


Examples
========
```
$ bee nspec::run
$ bee nspec::run MyTest
```
