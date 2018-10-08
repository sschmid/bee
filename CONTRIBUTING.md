Contributing to bee
===================

The project is hosted on [GitHub](https://github.com/sschmid/bee) where
you can [report issues](https://github.com/sschmid/bee/issues), fork the project
and [submit pull requests](https://github.com/sschmid/bee/pulls).

Setup bee on your machine
=========================

Fork the repository on [GitHub](https://github.com/sschmid/bee) and clone your forked repository to your machine

```
$ git clone https://github.com/<username>/bee.git
````

If you want to contribute please consider to set up [git-flow](https://github.com/nvie/gitflow).
The default branch of this repository is `master`

```
$ cd bee
$ git branch master origin/master
$ git flow init -d
```


Make changes
============

[Create a new issue](https://github.com/sschmid/bee/issues/new) to let people know what you're working on
and to encourage a discussion. Follow the git-flow conventions and create a new feature branch
starting with `#` and the issue number:

```
$ git flow feature start <#123-your-feature>
```

Coding Style
============

Please follow the Shell Style Guide
https://google.github.io/styleguide/shell.xml


Contribute
==========

If you have many commits please consider using [git rebase](https://git-scm.com/docs/git-rebase) to cleanup the commits.
This can simplify reviewing the pull request. Once you're happy with your changes
create a [pull request](https://github.com/sschmid/bee/pulls) from your feature branch. The default branch is `master`.

---

By submitting a pull request, you represent that you have the right to license your contribution to the community,
and agree by submitting the patch that your contributions are licensed
under the [bee license](https://github.com/sschmid/bee/blob/master/LICENSE.txt).

Thanks for your contributions and happy coding :)

Simon
