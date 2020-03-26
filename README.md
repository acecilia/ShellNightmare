# ShellNightmare

A repository to investigate how the environment is setup when opening a shell

## Introduction

There is quiet some discussion about how the `PATH` environmental variable is configured when opening a shell in MacOS:

* [An explanation about how PATH is constructed, and a warning about `path_helper`](https://scriptingosx.com/2017/05/where-paths-come-from/)
* [A very long discussion about how `path_helper` is broken](https://github.com/sorin-ionescu/prezto/issues/381)
* [An explanation about how `path_helper` works](http://www.softec.lu/site/DevelopersCorner/MasteringThePathHelper)

Thus, I decided to test it by myself to understand what is going on.

### Different kinds of shell:

Depending on how you open a shell, the files that will be sourced change:

* `interactive + login`: the shell opened when launching the terminal app
* `non-interactive + login`: the shell open when executing `$SHELL --login -c '<command>'`. Most commonly used from inside scripts, when running a command is required.
* `non-interactive + non-login`: the shell open when executing `$SHELL -c '<command>'`. Most commonly used from inside scripts, when running a command is required.


## Test methodology

I created a script that adds the line `export SOURCE_ORIGINS="<fileName>:$SOURCE_ORIGINS"` to every file in the system suspected to be sourced when opening a shell. As a result, after running the script, when openning a new shell the environmental variable `SOURCE_ORIGINS` will contain which of the files where sourced, and in which order.

I am running the test using the following versions:

* MacOS Catalina 10.15.3 (19D76)
* `/bin/zsh` (preinstalled with the OS): zsh 5.7.1 (x86_64-apple-darwin19.0)
* `/bin/bash` (preinstalled with the OS): GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin19)
* `/usr/local/bin/bash` (installed using brew): GNU bash, version 5.0.16(1)-release (x86_64-apple-darwin19.3.0)

## Results

The `*` found in the data below indicates that the file contains a call to `path_helper`.

### Raw data

The results below are the output of the [`analyzer.sh`](analyzer.sh) script. 

For `/bin/zsh`:

```
interactive_login: $HOME/.zlogin:/etc/zlogin:$HOME/.zshrc:/etc/zshrc:$HOME/.zprofile:/etc/zprofile*:$HOME/.zshenv:/etc/zshenv:
non_interactive_login: $HOME/.zlogin:/etc/zlogin:$HOME/.zprofile:/etc/zprofile*:$HOME/.zshenv:/etc/zshenv:
non_interactive_non_login: $HOME/.zshenv:/etc/zshenv:
```

For `/bin/bash` and `/usr/local/bin/bash`:

```
interactive_login: $HOME/.bash_profile:/etc/profile*:/etc/bashrc:
non_interactive_login: $HOME/.bash_profile:/etc/profile*:
non_interactive_non_login: 
```
### Tables

Tables below show the files that are sourced:

* From top to bottom, where the top files are sourced first
* For the diferent shell types

#### For `/bin/zsh`:

| interactive + login | non-interactive + login | non-interactive + non-login |
|---------------------|-------------------------|-----------------------------|
| /etc/zshenv         | /etc/zshenv             | /etc/zshenv                 |
| $HOME/.zshenv       | $HOME/.zshenv           | $HOME/.zshenv               |
| /etc/zprofile*      | /etc/zprofile*          |                             |
| $HOME/.zprofile     | $HOME/.zprofile         |                             |
| /etc/zshrc          | /etc/zlogin             |                             |
| $HOME/.zshrc        | $HOME/.zlogin           |                             |
| /etc/zlogin         |                         |                             |
| $HOME/.zlogin       |                         |                             |

#### For `/bin/bash` and `/usr/local/bin/bash`:

| interactive + login | non-interactive + login | non-interactive + non-login |
|---------------------|-------------------------|-----------------------------|
| /etc/bashrc         | /etc/profile*           |                             |
| /etc/profile*       | $HOME/.bash_profile     |                             |
| $HOME/.bash_profile |                         |                             |

## Discussion

### Effect of `path_helper`

In MacOS there is a tool called `path_helper` that is used to construct the `PATH` environmental variable: it adds several paths to `$PATH`, removes duplicates and **rearanges** them. This last part is the problematic one: if you set your `PATH` inside the file `$HOME/.zshenv` and `path_helper` is executed **after**, the system paths will have priority over your custom-defined paths, most probably causing you all shorts of problems.

In the results above the files that contain a call to `path_helper` are marked with an asterisk (`*`).

## Conclusions

After seeing the results, we can say that:

### About `zsh`:

1. `zsh` under MacOS sources `$HOME/.zshenv` regardless of the type of shell. You could think that this is a safe place to customize the environment. The problem is that `/etc/zprofile` is sourced **after** for the `interactive + login` and `non-interactive + login` shell types, which will rearange your `PATH` environmental variable and override any customization done in `$HOME/.zshenv`. 

  One way to work around this issue is to setup the files as follows:
	
	1. Setup your enviornment inside `$HOME/.zshenv`.
	2. Inside `$HOME/.zprofile`, write the following:
	
	```shell
	# Empty path
	PATH="" 
	
	# Reset path with the default MacOS values
	[ -f /etc/zshenv ] && source /etc/zshenv 
	[ -f /etc/zprofile ] && source /etc/zprofile
	
	# Customize the path
	[ -f $HOME/.zshenv ] && source $HOME/.zshenv 
	```

### About `bash`:

1. `bash` under MacOS does not source `$HOME/.bashrc`. A quick search on google confirms this very strange fact, for example: [Mac OS X .bashrc not working](https://superuser.com/questions/244964/mac-os-x-bashrc-not-working) or [OSX Terminal not recognizing ~/.bashrc and ~/.bash_profile on startup](https://stackoverflow.com/a/44658683)
2. When using `bash` under MacOS, changing the type of shell will most likely change the environment. It is not possible to customize the environment for all types of shells, as none of the files is sourced by all shell types.
3. The only way to customize the environment for a shell in `bash` under MacOS is to place it in `$HOME/.bash_profile`.

### General concerns:

1. There isn't an alternative to setup the environment for both `bash` and `zsh`.
