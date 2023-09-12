# Description
This is a test repo to reproduce an issue resolving git dependencies with Poetry. Credit for reproduction steps goes to @abefrandsen and @gvoronov <3.


## Repositories
- [onefish](https://github.com/mrefish/onefish): A Project that reproduces the failure mode.
- [twofish](https://github.com/mrefish/twofish): A shared dependency that also requires `requests`.
- [gitfish](https://github.com/mrefish/gitfish): A `onefish` depenency that also requires `twofish` and added the dependency with a trailing `.git` in the URL.
- [nofish](https://github.com/mrefish/nofish): The dependency to add to `onefish` to cause the failure. Also requires `twofish` but added the dependency without a trailing `.git` in the URL.


# Usage
## Makefile
The `Makefile` contains a number of targets to help with testing


### `make docker`
Build a docker image with the `onefish` project installed in a virtual environment, but in a working state.

The environment should look like this:
```shell
root@f459d06f9b5b:/app# tree -a -L 2
.
├── .venv
│   ├── .gitignore
│   ├── bin
│   ├── lib
│   ├── pyvenv.cfg
│   └── src
├── README.md
├── onefish
│   └── __init__.py
├── poetry.lock
├── poetry.toml
├── pyproject.toml
└── tests
    └── __init__.py

6 directories, 8 files
```


### `make dev`
An interactive shell in the working docker container. The virtual environment should exist and be working.
```shell
root@f459d06f9b5b:/app# python
Python 3.9.17 (main, Aug 16 2023, 05:50:47)
[GCC 10.2.1 20210110] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import onefish
>>> import twofish
>>> import gitfish
>>> import requests
>>> poetry_json = requests.get("https://api.github.com/repos/python-poetry/poetry").json()
```

To reproduce the failure, run this command inside the container:
```shell
poetry add git+https://github.com/mrefish/nofish.git
```


### `make broken`
Attempts to build the `onefish` project in the docker container. This will fail with the following error:
```shell
 => ERROR [broken 1/1] RUN poetry add git+https://github.com/mrefish/nofish.git   6.4s
------
 > [broken 1/1] RUN poetry add git+https://github.com/mrefish/nofish.git:
5.127
5.190 Updating dependencies
5.199 Resolving dependencies...
6.264
6.264 Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
6.264 So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.
------
Dockerfile:41
--------------------
  39 |     #############################################
  40 |     FROM installed as broken
  41 | >>> RUN poetry add git+https://github.com/mrefish/nofish.git
  42 |
--------------------
ERROR: failed to solve: process "/bin/sh -c poetry add git+https://github.com/mrefish/nofish.git" did not complete successfully: exit code: 1
make: *** [broken] Error 1
```


## To reproduce failure manually
```shell
poetry install

poetry add git+https://github.com/mrefish/nofish.git
```

This results in the following error:
```shell
Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.
```
