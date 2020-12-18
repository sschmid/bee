spinner
=======
More Styles: https://raw.githubusercontent.com/sindresorhus/cli-spinners/master/spinners.json
Preview: https://cdn.rawgit.com/sindresorhus/cli-spinners/dcac74b75e52d4d9fe980e6fce98c2814275739e/screenshot.svg

`spinner::start`
------------------
- start and show spinner

`spinner::stop`
------------------
- stop the current spinner and run the specified optional commands if it has been stopped

`spinner::complete`
------------------
- stop the current spinner ending with the success state

`spinner::cancel`
------------------
- stop the current spinner ending with the cancel state

`spinner::wrap`
------------------
- run the specified commands and start and stop the spinner


Dependencies
============
none


Examples
========
```
$ bee spinner::wrap "Run Task" my_task
```
