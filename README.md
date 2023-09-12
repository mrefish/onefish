# Description
A repository to reproduce https://github.com/python-poetry/poetry/issues/8433

When a project has two dependencies that specify a shared git dependency inconsistently with a `.git` at the end of the shared dependency URL, it results in a `SolverProblemError`. Credit for reproduction steps goes to @abefrandsen and @gvoronov <3.


## Repositories
- [onefish](https://github.com/mrefish/onefish): (this repo) A Project that reproduces the failure mode.
- [twofish](https://github.com/mrefish/twofish): A shared dependency that requires `requests`.
- [gitfish](https://github.com/mrefish/gitfish): A `onefish` depenency that requires `twofish` and added the dependency with a trailing `.git` in the URL.
- [nofish](https://github.com/mrefish/nofish): The dependency to add to `onefish` to cause the failure. A `onefish` dependency that requires `twofish` but added the dependency without a trailing `.git` in the URL.


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
poetry add git+https://github.com/mrefish/nofish.git -vvv
```


### `make broken`
Attempts to build the `onefish` project in the docker container. This will fail with the following error:
```shell
 => [installed 1/1] RUN poetry install                                           24.8s
 => ERROR [broken 1/1] RUN poetry add git+https://github.com/mrefish/nofish.git  11.0s
------
 > [broken 1/1] RUN poetry add git+https://github.com/mrefish/nofish.git -vvv:
2.521 Loading configuration file /app/poetry.toml
2.562 Trying to detect current active python executable as specified in the config.
2.767 Found: /app/.venv/bin/python
3.442 Using virtualenv: /app/.venv
4.532 [keyring.backend] Loading KWallet
4.535 [keyring.backend] Loading SecretService
4.596 [keyring.backend] Loading Windows
4.599 [keyring.backend] Loading chainer
4.600 [keyring.backend] Loading libsecret
4.603 [keyring.backend] Loading macOS
4.675 No suitable keyring backend found
4.675 No suitable keyring backends were found
4.676 Keyring is not available, credentials will be stored and retrieved from configuration files as plaintext.
4.683 [urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
5.747 [urllib3.connectionpool] https://github.com:443 "GET /mrefish/nofish.git/info/refs?service=git-upload-pack HTTP/1.1" 200 None
5.766 [urllib3.connectionpool] Starting new HTTPS connection (2): github.com:443
6.386 [urllib3.connectionpool] https://github.com:443 "POST /mrefish/nofish.git/git-upload-pack HTTP/1.1" 200 None
6.441 Cloning https://github.com/mrefish/nofish.git at 'HEAD' to /app/.venv/src/nofish
6.524
6.587 Updating dependencies
6.597 Resolving dependencies...
6.600    1: fact: onefish is 0.1.0
6.601    1: derived: onefish
6.615    1: fact: onefish depends on gitfish (*)
6.615    1: fact: onefish depends on nofish (0.1.0)
6.619    1: selecting onefish (0.1.0)
6.619    1: derived: nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git
6.620    1: derived: gitfish (*) @ git+https://github.com/mrefish/gitfish.git
6.634 [urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
7.309 [urllib3.connectionpool] https://github.com:443 "GET /mrefish/twofish/info/refs?service=git-upload-pack HTTP/1.1" 200 None
7.330 Cloning https://github.com/mrefish/twofish at 'HEAD' to /app/.venv/src/twofish
7.428    1: fact: nofish (0.1.0) depends on twofish (0.1.0)
7.433    1: selecting nofish (0.1.0 0e021da)
7.434    1: derived: twofish (0.1.0) @ git+https://github.com/mrefish/twofish
7.443    1: fact: gitfish (0.1.0) depends on twofish (*)
7.444    1: derived: not gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD
7.458 [urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
8.063 [urllib3.connectionpool] https://github.com:443 "GET /mrefish/gitfish.git/info/refs?service=git-upload-pack HTTP/1.1" 200 None
8.080 Cloning https://github.com/mrefish/gitfish.git at 'HEAD' to /app/.venv/src/gitfish
8.181    1: fact: gitfish (0.1.0) depends on twofish (*)
8.183    1: conflict: gitfish (0.1.0) depends on twofish (*)
8.188    1: ! gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD is partially satisfied by not gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD
8.189    1: ! which is caused by "gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on twofish (*) @ git+https://github.com/mrefish/twofish.git"
8.189    1: ! thus: twofish is required
8.190    1: fact: twofish is required
8.190    1: derived: twofish (*) @ git+https://github.com/mrefish/twofish.git
8.192    1: conflict: nofish (0.1.0) depends on twofish (0.1.0)
8.193    1: ! not twofish (0.1.0) @ git+https://github.com/mrefish/twofish is satisfied by twofish (*) @ git+https://github.com/mrefish/twofish.git
8.193    1: ! which is caused by "twofish is required"
8.193    1: ! thus: nofish is forbidden
8.194    1: ! nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git@HEAD is satisfied by nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git
8.194    1: ! which is caused by "onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git"
8.195    1: ! thus: version solving failed
8.196    1: Version solving took 1.598 seconds.
8.196    1: Tried 1 solutions.
8.562
8.562   Stack trace:
8.563
8.564   4  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/puzzle/solver.py:155 in _solve
8.701       153│
8.702       154│         try:
8.702     → 155│             result = resolve_version(self._package, self._provider)
8.703       156│
8.703       157│             packages = result.packages
8.703
8.704   3  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/mixology/__init__.py:18 in resolve_version
8.711        16│     solver = VersionSolver(root, provider)
8.711        17│
8.711     →  18│     return solver.solve()
8.711        19│
8.712
8.712   2  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/mixology/version_solver.py:163 in solve
8.861       161│             next: str | None = self._root.name
8.861       162│             while next is not None:
8.862     → 163│                 self._propagate(next)
8.862       164│                 next = self._choose_package_version()
8.862       165│
8.862
8.863   1  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/mixology/version_solver.py:202 in _propagate
9.010       200│                     # where that incompatibility will allow us to derive new assignments
9.010       201│                     # that avoid the conflict.
9.010     → 202│                     root_cause = self._resolve_conflict(incompatibility)
9.011       203│
9.011       204│                     # Back jumping erases all the assignments we did at the previous
9.011
9.011   SolveFailure
9.011
9.013   Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
9.013   So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.
9.013
9.013   at ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/mixology/version_solver.py:416 in _resolve_conflict
9.160       412│             )
9.161       413│             self._log(f'! which is caused by "{most_recent_satisfier.cause}"')
9.161       414│             self._log(f"! thus: {incompatibility}")
9.161       415│
9.162     → 416│         raise SolveFailure(incompatibility)
9.162       417│
9.163       418│     def _choose_package_version(self) -> str | None:
9.163       419│         """
9.163       420│         Tries to select a version of a required package.
9.163
9.163 The following error occurred when trying to handle this error:
9.163
9.163
9.163   Stack trace:
9.164
9.164   11  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/application.py:327 in run
9.372        325│
9.372        326│             try:
9.373      → 327│                 exit_code = self._run(io)
9.373        328│             except BrokenPipeError:
9.373        329│                 # If we are piped to another process, it may close early and send a
9.374
9.374   10  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/console/application.py:190 in _run
9.502        188│         self._load_plugins(io)
9.502        189│
9.503      → 190│         exit_code: int = super()._run(io)
9.503        191│         return exit_code
9.503        192│
9.503
9.504    9  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/application.py:431 in _run
9.711        429│             io.input.interactive(interactive)
9.711        430│
9.712      → 431│         exit_code = self._run_command(command, io)
9.712        432│         self._running_command = None
9.713        433│
9.713
9.713    8  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/application.py:473 in _run_command
9.920        471│
9.921        472│         if error is not None:
9.921      → 473│             raise error
9.921        474│
9.922        475│         return terminate_event.exit_code
9.922
9.922    7  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/application.py:457 in _run_command
10.13        455│
10.13        456│             if command_event.command_should_run():
10.13      → 457│                 exit_code = command.run(io)
10.13        458│             else:
10.13        459│                 exit_code = ConsoleCommandEvent.RETURN_CODE_DISABLED
10.13
10.13    6  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/commands/base_command.py:119 in run
10.18        117│         io.input.validate()
10.18        118│
10.18      → 119│         status_code = self.execute(io)
10.18        120│
10.18        121│         if status_code is None:
10.18
10.18    5  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/cleo/commands/command.py:62 in execute
10.28         60│
10.28         61│         try:
10.28      →  62│             return self.handle()
10.29         63│         except KeyboardInterrupt:
10.29         64│             return 1
10.29
10.29    4  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/console/commands/add.py:267 in handle
10.38        265│         self.installer.whitelist([r["name"] for r in requirements])
10.38        266│
10.38      → 267│         status = self.installer.run()
10.38        268│
10.38        269│         if status == 0 and not self.option("dry-run"):
10.38
10.38    3  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/installation/installer.py:104 in run
10.52        102│             self.verbose(True)
10.52        103│
10.52      → 104│         return self._do_install()
10.52        105│
10.52        106│     def dry_run(self, dry_run: bool = True) -> Installer:
10.52
10.52    2  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/installation/installer.py:241 in _do_install
10.67        239│                 source_root=self._env.path.joinpath("src")
10.67        240│             ):
10.67      → 241│                 ops = solver.solve(use_latest=self._whitelist).calculate_operations()
10.67        242│         else:
10.67        243│             self._io.write_line("Installing dependencies from lock file")
10.67
10.67    1  ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/puzzle/solver.py:72 in solve
10.78         70│         with self._progress(), self._provider.use_latest_for(use_latest or []):
10.78         71│             start = time.time()
10.78      →  72│             packages, depths = self._solve()
10.78         73│             end = time.time()
10.78         74│
10.78
10.78   SolverProblemError
10.78
10.78   Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
10.78   So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.
10.78
10.78   at ~/.local/share/pypoetry/venv/lib/python3.9/site-packages/poetry/puzzle/solver.py:161 in _solve
10.89       157│             packages = result.packages
10.89       158│         except OverrideNeeded as e:
10.89       159│             return self._solve_in_compatibility_mode(e.overrides)
10.89       160│         except SolveFailure as e:
10.89     → 161│             raise SolverProblemError(e)
10.89       162│
10.89       163│         combined_nodes = depth_first_search(PackageNode(self._package, packages))
10.89       164│         results = dict(aggregate_package_nodes(nodes) for nodes in combined_nodes)
10.89       165│
------
Dockerfile:40
--------------------
  38 |     #############################################
  39 |     FROM installed as broken
  40 | >>> RUN poetry add git+https://github.com/mrefish/nofish.git -vvv
  41 |
--------------------
ERROR: failed to solve: process "/bin/sh -c poetry add git+https://github.com/mrefish/nofish.git -vvv" did not complete successfully: exit code: 1
make: *** [broken] Error 1
```


## To reproduce failure manually (demonstrated on macOS Ventura version 13.5.2)
```shell
poetry install

poetry add git+https://github.com/mrefish/nofish.git -vvv
```

This results in the following error:
```shell
poetry add git+https://github.com/mrefish/nofish.git -vvv
Loading configuration file /Users/ericfish/Library/Application Support/pypoetry/config.toml
Loading configuration file /Users/ericfish/code/onefish/poetry.toml
Trying to detect current active python executable as specified in the config.
Found: /Users/ericfish/.pyenv/versions/3.9.17/bin/python
Using virtualenv: /Users/ericfish/code/onefish/.venv
[keyring.backend] Loading KWallet
[keyring.backend] Loading SecretService
[keyring.backend] Loading Windows
[keyring.backend] Loading chainer
[keyring.backend] Loading libsecret
[keyring.backend] Loading macOS
[urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
[urllib3.connectionpool] https://github.com:443 "GET /mrefish/nofish.git/info/refs?service=git-upload-pack HTTP/1.1" 200 None
[urllib3.connectionpool] Starting new HTTPS connection (2): github.com:443
[urllib3.connectionpool] https://github.com:443 "POST /mrefish/nofish.git/git-upload-pack HTTP/1.1" 200 None
Cloning https://github.com/mrefish/nofish.git at 'HEAD' to /Users/ericfish/code/onefish/.venv/src/nofish

Updating dependencies
Resolving dependencies...
   1: fact: onefish is 0.1.0
   1: derived: onefish
   1: fact: onefish depends on gitfish (*)
   1: fact: onefish depends on nofish (0.1.0)
   1: selecting onefish (0.1.0)
   1: derived: nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git
   1: derived: gitfish (*) @ git+https://github.com/mrefish/gitfish.git
[urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
[urllib3.connectionpool] https://github.com:443 "GET /mrefish/twofish/info/refs?service=git-upload-pack HTTP/1.1" 200 None
[urllib3.connectionpool] Starting new HTTPS connection (2): github.com:443
[urllib3.connectionpool] https://github.com:443 "POST /mrefish/twofish/git-upload-pack HTTP/1.1" 200 None
Cloning https://github.com/mrefish/twofish at 'HEAD' to /Users/ericfish/code/onefish/.venv/src/twofish
   1: fact: nofish (0.1.0) depends on twofish (0.1.0)
   1: selecting nofish (0.1.0 0e021da)
   1: derived: twofish (0.1.0) @ git+https://github.com/mrefish/twofish
   1: fact: gitfish (0.1.0) depends on twofish (*)
   1: derived: not gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD
[urllib3.connectionpool] Starting new HTTPS connection (1): github.com:443
[urllib3.connectionpool] https://github.com:443 "GET /mrefish/gitfish.git/info/refs?service=git-upload-pack HTTP/1.1" 200 None
[urllib3.connectionpool] Starting new HTTPS connection (2): github.com:443
[urllib3.connectionpool] https://github.com:443 "POST /mrefish/gitfish.git/git-upload-pack HTTP/1.1" 200 None
Cloning https://github.com/mrefish/gitfish.git at 'HEAD' to /Users/ericfish/code/onefish/.venv/src/gitfish
   1: fact: gitfish (0.1.0) depends on twofish (*)
   1: conflict: gitfish (0.1.0) depends on twofish (*)
   1: ! gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD is partially satisfied by not gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD
   1: ! which is caused by "gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on twofish (*) @ git+https://github.com/mrefish/twofish.git"
   1: ! thus: twofish is required
   1: fact: twofish is required
   1: derived: twofish (*) @ git+https://github.com/mrefish/twofish.git
   1: conflict: nofish (0.1.0) depends on twofish (0.1.0)
   1: ! not twofish (0.1.0) @ git+https://github.com/mrefish/twofish is satisfied by twofish (*) @ git+https://github.com/mrefish/twofish.git
   1: ! which is caused by "twofish is required"
   1: ! thus: nofish is forbidden
   1: ! nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git@HEAD is satisfied by nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git
   1: ! which is caused by "onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git"
   1: ! thus: version solving failed
   1: Version solving took 1.511 seconds.
   1: Tried 1 solutions.

  Stack trace:

  4  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/puzzle/solver.py:155 in _solve
      153│
      154│         try:
    → 155│             result = resolve_version(self._package, self._provider)
      156│
      157│             packages = result.packages

  3  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/mixology/__init__.py:18 in resolve_version
       16│     solver = VersionSolver(root, provider)
       17│
    →  18│     return solver.solve()
       19│

  2  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/mixology/version_solver.py:163 in solve
      161│             next: str | None = self._root.name
      162│             while next is not None:
    → 163│                 self._propagate(next)
      164│                 next = self._choose_package_version()
      165│

  1  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/mixology/version_solver.py:202 in _propagate
      200│                     # where that incompatibility will allow us to derive new assignments
      201│                     # that avoid the conflict.
    → 202│                     root_cause = self._resolve_conflict(incompatibility)
      203│
      204│                     # Back jumping erases all the assignments we did at the previous

  SolveFailure

  Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
  So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.

  at ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/mixology/version_solver.py:416 in _resolve_conflict
      412│             )
      413│             self._log(f'! which is caused by "{most_recent_satisfier.cause}"')
      414│             self._log(f"! thus: {incompatibility}")
      415│
    → 416│         raise SolveFailure(incompatibility)
      417│
      418│     def _choose_package_version(self) -> str | None:
      419│         """
      420│         Tries to select a version of a required package.

The following error occurred when trying to handle this error:


  Stack trace:

  11  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/application.py:327 in run
       325│
       326│             try:
     → 327│                 exit_code = self._run(io)
       328│             except BrokenPipeError:
       329│                 # If we are piped to another process, it may close early and send a

  10  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/console/application.py:190 in _run
       188│         self._load_plugins(io)
       189│
     → 190│         exit_code: int = super()._run(io)
       191│         return exit_code
       192│

   9  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/application.py:431 in _run
       429│             io.input.interactive(interactive)
       430│
     → 431│         exit_code = self._run_command(command, io)
       432│         self._running_command = None
       433│

   8  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/application.py:473 in _run_command
       471│
       472│         if error is not None:
     → 473│             raise error
       474│
       475│         return terminate_event.exit_code

   7  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/application.py:457 in _run_command
       455│
       456│             if command_event.command_should_run():
     → 457│                 exit_code = command.run(io)
       458│             else:
       459│                 exit_code = ConsoleCommandEvent.RETURN_CODE_DISABLED

   6  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/commands/base_command.py:119 in run
       117│         io.input.validate()
       118│
     → 119│         status_code = self.execute(io)
       120│
       121│         if status_code is None:

   5  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/cleo/commands/command.py:62 in execute
        60│
        61│         try:
     →  62│             return self.handle()
        63│         except KeyboardInterrupt:
        64│             return 1

   4  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/console/commands/add.py:267 in handle
       265│         self.installer.whitelist([r["name"] for r in requirements])
       266│
     → 267│         status = self.installer.run()
       268│
       269│         if status == 0 and not self.option("dry-run"):

   3  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/installation/installer.py:104 in run
       102│             self.verbose(True)
       103│
     → 104│         return self._do_install()
       105│
       106│     def dry_run(self, dry_run: bool = True) -> Installer:

   2  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/installation/installer.py:240 in _do_install
       238│                 source_root=self._env.path.joinpath("src")
       239│             ):
     → 240│                 ops = solver.solve(use_latest=self._whitelist).calculate_operations()
       241│         else:
       242│             self._io.write_line("Installing dependencies from lock file")

   1  ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/puzzle/solver.py:72 in solve
        70│         with self._progress(), self._provider.use_latest_for(use_latest or []):
        71│             start = time.time()
     →  72│             packages, depths = self._solve()
        73│             end = time.time()
        74│

  SolverProblemError

  Because gitfish (0.1.0) @ git+https://github.com/mrefish/gitfish.git@HEAD depends on both twofish (*) @ git+https://github.com/mrefish/twofish.git and twofish (*) @ git+https://github.com/mrefish/twofish.git, twofish is required.
  So, because onefish depends on nofish (0.1.0) @ git+https://github.com/mrefish/nofish.git which depends on twofish (0.1.0) @ git+https://github.com/mrefish/twofish, version solving failed.

  at ~/.local/pipx/venvs/poetry/lib/python3.11/site-packages/poetry/puzzle/solver.py:161 in _solve
      157│             packages = result.packages
      158│         except OverrideNeeded as e:
      159│             return self._solve_in_compatibility_mode(e.overrides)
      160│         except SolveFailure as e:
    → 161│             raise SolverProblemError(e)
      162│
      163│         combined_nodes = depth_first_search(PackageNode(self._package, packages))
      164│         results = dict(aggregate_package_nodes(nodes) for nodes in combined_nodes)
      165│
```
