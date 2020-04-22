# Jar update
A bourne based shell script to update a jar file. It updates an old jar with the modified and new files of a new jar.
Still a work in progress, the sunny day scenario works. But it does not have error handling when things go wrong.

## Requirements
The script requires `jar` to be in the path.
If you want, you can run the tests and validation on the script. To validate you will need [shellcheck](https://github.com/koalaman/shellcheck) and to test you will need [shunit2](https://github.com/kward/shunit2).

You can use [make](https://www.gnu.org/software/make/) to trigger validation and tests.
To use shellcheck on source files run the following command:
```
$ make check
```
To check, generate and run the tests use the following:
```
$ make test
```

## Usage
As of right now the script does not have a proper command line interface.

The script expects the updated jar as the first argument and the old jar as the second one.
A new jar is generated in the same directory as the old one. It has the files the old one had and the modified/new files of the updated one. It has the same name as the old one with "-new" appended to it. For example, if the old jar's name was `a.jar`, the new one would be `a-new.jar`.

