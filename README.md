# haxe-reusable-workflows

[![Build](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/build.workflow-test-with-haxe.yml/badge.svg)](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/build.workflow-test-with-haxe.yml)
[![Build](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/build.action-test-with-haxe.yml/badge.svg)](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/build.action-test-with-haxe.yml)
[![License](https://img.shields.io/github/license/vegardit/haxe-reusable-workflows.svg?label=license)](#license)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)


**Feedback and high-quality pull requests are highly welcome!**

1. [What is it?](#what-is-it)
1. [Usage](#usage)
  1. [Build/test using the `test-with-haxe` workflow](#test-with-haxe-workflow)
  1. [Build/test using the `test-with-haxe` action](#test-with-haxe-action)
  1. [Install Haxe and Haxe Libraries using the `setup-haxe` action](#setup-haxe-action)
  1. [Install Haxe compiler targets using the `setup-haxe-targets` action](#setup-haxe-targets-action)
  1. [Testing locally with `act`](#testing-locally)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

A repository with [Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and
[composite actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action) to build/test Haxe programs using Github Actions
on Ubuntu, MacOS, or Windows.

The workflows/actions do the heavy lifting of installing compatible versions of required compiler targets with the correct configuration/libraries depending on the runner OS and the desired Haxe version.

For faster re-runs caching of Haxe libraries and other components is configured.


## Usage <a name="usage"></a>Usage

### <a name="test-with-haxe-workflow"></a>Build/test using the `test-with-haxe` reusable workflow

The `test-with-haxe-workflow` installs Haxe, Haxe libraries, compiler targets and runs the tests against the selected targets.

Simple config:
```yaml
name: My Haxe Build

on:
  push:
  pull_request:

jobs:
  my-haxe-build:
    uses: vegardit/haxe-reusable-workflows/.github/workflows/test-with-haxe.yml@v1
    with:
      runner-os: ubuntu-latest
      haxe-version: 4.2.5
      haxe-args: myconfig.hxml # default is "tests.hxml"
      haxe-libs: hx3compat hscript # haxe libraries to be installed

      # Haxe targets to test with:
      test-cpp:    true
      test-cs:     true
      test-eval:   true
      test-hl:     true
      test-java:   true
      test-jvm:    true
      test-lua:    true
      test-neko:   true
      test-node:   true
      test-php:    true
      test-python: true
```

The `test-<target>:` parameters accepts one of the following values:
- a boolean value (`true` or `false`) to enable/disable the target tests, or
- a string with Haxe compiler arguments, e.g. `my-custom.hxml -D foo=1`, or
- a multi-line YAML string for detailed configuration
  ```yaml
  test-cpp: |
    enabled:         true           # enable/disable tests of this target, default is ´false´
    haxe-args:       tests-cpp.hxml # custom Haxe compiler arguments for this target, default is the value specified for `haxe-args` or `tests.hxml`
    allow-failure:   true           # if tests of this targets fail don't fail the whole build, default is ´false´
    retries:         3              # number of test retries, default is `0`
    timeout-minutes: 5              # the maximum number of time the target tests can lasts otherwise the tests fail
  ```


Complex config:
```yaml
name: My Haxe Build

on:
  push:
  pull_request:
  workflow_dispatch: # this allows you to manually trigger a run with input parameters
    inputs:
      debug-with-ssh:
        description: "Start an SSH session for debugging purposes after tests ran:"
        default: never
        type: choice
        options: [ always, on_failure, on_failure_or_cancelled, never ]
      debug-with-ssh-only-for-actor:
        description: "Limit access to the SSH session to the GitHub user that triggered the job."
        default: true
        type: boolean
      debug-with-ssh-only-jobs-matching:
        description: "Only start an SSH session for jobs matching this regex pattern:"
        default: ".*"
        type: string

jobs:
  my-haxe-build:
    uses: vegardit/haxe-reusable-workflows/.github/workflows/test-with-haxe.yml@v1
    strategy:
      fail-fast: false
      matrix:
        os:
        - ubuntu-latest
        - macos-latest
        - windows-latest
        haxe:
        - nightly # latest development build
        - latest  # latest stable release
        - 4.2.5
        - 3.4.7
    with:
      runner-os: ${{ matrix.os }}
      haxe-version: ${{ matrix.haxe }}
      haxe-args: myconfig.hxml # default is "tests.hxml"
      haxe-libs: | # haxe libraries to be installed:
        hscript               # install latest version from lib.haxe.org
        haxe-concurrent@4.1.0 # install fixed version from lib.haxe.org
        haxe-files@git:https://github.com/vegardit/haxe-files # install version from default git branch
        haxe-strings@git:https://github.com/vegardit/haxe-strings#v7.0.2 # install version from specific git tag

      # Haxe targets to test with, by default all are set to false:
      test-cpp:  true
      test-cs:   true
      test-eval: true
      test-flash: |
        enabled:         ${{ ! startsWith(matrix.os, 'macos') }} # FlashPlayer hangs on macOS
        haxe-args:       tests-flash.hxml
        allow-failure:   true
        retries:         4
        timeout-minutes: 5
      test-hl: ${{ matrix.haxe != '3.4.7' }} # HashLink not compatible with Haxe 3.x
      test-java: |
        java-version: 11
      test-jvm: |
        java-version: 17
      test-lua: |
        lua-version: 5.1
      test-neko: true
      test-node: tests-node.hxml # run tests with a target specific hxml file
      test-php:  true
      test-python: |
        python-version: 3.9

      retries: 2 # number of additional retries in case a test run fails, default is 0

      job-timeout-minutes: 30 # max. duration of the workflow, default is 60
      test-timeout-minutes: 5 # max. duration per target test, default is 10

      # bash script to be executed after compiler targets are installed and before target tests are executed
      before-tests: |
        echo "Preparing tests..."

      # bash script to be executed after tests were executed
      after-tests: |
        case "$GITHUB_JOB_STATUS" in
          success)   echo "Sending success report..." ;;
          failure)   echo "Sending failure report..." ;;
          cancelled) echo "Nothing to do, job cancelled" ;;
          *)         echo "ERROR: Unexpected job status [$GITHUB_JOB_STATUS]"; exit 1 ;;
        esac

      # provide SSH access to the GitHub runner for manual debugging purposes
      debug-with-ssh: ${{ inputs.debug-with-ssh || 'never' }}
      debug-with-ssh-only-for-actor: ${{ inputs.debug-with-ssh-only-for-actor || false }}
      debug-with-ssh-only-jobs-matching: ${{ inputs.debug-with-ssh-only-jobs-matching }}

```

### <a name="test-with-haxe-action"></a>Build/test using the `test-with-haxe` action

The `test-with-haxe-action` installs Haxe, Haxe libraries, compiler targets and runs the tests against the selected targets.

Simple config:
```yaml
name: My Haxe Build

on:
  push:
  pull_request:

jobs:
  my-haxe-build:
    runs-on: ubuntu-latest
    steps:
    - name: Git Checkout
      uses: actions/checkout@v3

    - name: Test with Haxe
      uses: vegardit/haxe-reusable-workflows/.github/actions/test-with-haxe@v1
      with:
        haxe-version: 4.2.5
        haxe-args: myconfig.hxml # default is "tests.hxml"
        haxe-libs: hx3compat hscript # libraries to be installed

        # Haxe targets to test with:
        test-cpp:    true
        test-cs:     true
        test-eval:   true
        test-hl:     true
        test-java:   true
        test-jvm:    true
        test-lua:    true
        test-neko:   true
        test-node:   true
        test-php:    true
        test-python: true
    # other steps ...
```

The `test-<target>:` parameters accepts one of the following values:
- a boolean value (`true` or `false`) to enable/disable the target tests, or
- a string with Haxe compiler arguments, e.g. `my-custom.hxml -D foo=1`, or
- a multi-line YAML string for detailed configuration
  ```yaml
  test-cpp: |
    enabled:         true           # enable/disable tests of this target, default is ´false´
    haxe-args:       tests-cpp.hxml # custom Haxe compiler arguments for this target, default is the value specified for `haxe-args` or `tests.hxml`
    allow-failure:   true           # if tests of this targets fail don't fail the whole build, default is ´false´
    retries:         3              # number of test retries, default is `0`
    timeout-minutes: 5              # the maximum number of time the target tests can lasts otherwise the tests fail
  ```

Complex config:
```yaml
name: My Haxe Build

on:
  push:
  pull_request:
  workflow_dispatch: # this allows you to manually trigger a run with input parameters
    inputs:
      debug-with-ssh:
        description: "Start an SSH session for debugging purposes after tests ran:"
        default: never
        type: choice
        options: [ always, on_failure, on_failure_or_cancelled, never ]
      debug-with-ssh-only-for-actor:
        description: "Limit access to the SSH session to the GitHub user that triggered the job."
        default: true
        type: boolean
      debug-with-ssh-only-jobs-matching:
        description: "Only start an SSH session for jobs matching this regex pattern:"
        default: ".*"
        type: string

jobs:
  my-haxe-build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os:
        - ubuntu-latest
        - macos-latest
        - windows-latest
        haxe:
        - nightly # latest development build
        - latest  # latest stable release
        - 4.2.5
        - 3.4.7

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3

    - name: Test with Haxe
      uses: vegardit/haxe-reusable-workflows/.github/actions/test-with-haxe@v1
      with:
        haxe-version: ${{ matrix.haxe }}
        haxe-args: myconfig.hxml # default is "tests.hxml"
        haxe-libs: | # haxe libraries to be installed:
          hscript               # install latest version from lib.haxe.org
          haxe-concurrent@4.1.0 # install fixed version from lib.haxe.org
          haxe-files@git:https://github.com/vegardit/haxe-files # install version from default git branch
          haxe-strings@git:https://github.com/vegardit/haxe-strings#v7.0.2 # install version from specific git tag


        # Haxe targets to test with, by default all are set to false:
        test-cpp:  true
        test-cs:   true
        test-eval: true
        test-flash: |
          enabled:       ${{ ! startsWith(matrix.os, 'macos') }} # FlashPlayer hangs on macOS
          allow-failure: true
          haxe-args:     tests-flash.hxml
          retries:       10
        test-hl: ${{ matrix.haxe != '3.4.7' }} # HashLink not compatible with Haxe 3.x
        test-java: |
          java-version: 11
        test-jvm: |
          java-version: 17
        test-lua: |
          lua-version: 5.1
        test-neko: true
        test-node: tests-node.hxml # run tests with a target specific hxml file
        test-php:  true
        test-python: |
          python-version: 3.9

        retries: 2 # number of additional retries in case a test run fails, default is 0

        # provide SSH access to the GitHub runner for manual debugging purposes
        debug-with-ssh: ${{ inputs.debug-with-ssh || 'never' }}
        debug-with-ssh-only-for-actor: ${{ inputs.debug-with-ssh-only-for-actor || false }}
        debug-with-ssh-only-jobs-matching: ${{ inputs.debug-with-ssh-only-jobs-matching }}

    # other steps ...
```

### <a name="setup-haxe-action"></a>Install Haxe compiler and Haxe libraries using the `setup-haxe` action

The `setup-haxe-action` can be used to "only" install the Haxe compiler and Haxe libraries.
Since Neko is required by haxelib it will be installed too.


```yaml
name: My Haxe Build

on:
  push:
  pull_request:

jobs:
  my-haxe-build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os:
        - ubuntu-latest
        - macos-latest
        - windows-latest
        haxe:
        - nightly # latest development build
        - latest  # latest stable release
        - 4.2.5
        - 3.4.7

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3

    - name: "Install: Haxe ${{ matrix.haxe }} and Haxe Libraries"
      uses: vegardit/haxe-reusable-workflows/.github/actions/setup-haxe@v1
      with:
        haxe-version: ${{ matrix.haxe }}
        haxe-libs: | # haxe libraries to be installed:
          hscript               # install latest version from lib.haxe.org
          haxe-concurrent@4.1.0 # install fixed version from lib.haxe.org
          haxe-files@git:https://github.com/vegardit/haxe-files # install version from default git branch
          haxe-strings@git:https://github.com/vegardit/haxe-strings#v7.0.2 # install version from specific git tag

    # ... custom steps to compile/test Haxe code
```


### <a name="setup-haxe-targets-action"></a>Install Haxe compiler targets using the `setup-haxe-targets` action

The `setup-haxe-targets-action` can be used to "only" install Haxe compiler targets.

```yaml
name: My Haxe Build

on:
  push:
  pull_request:

jobs:
  my-haxe-build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os:
        - ubuntu-latest
        - macos-latest
        - windows-latest
        haxe:
        - nightly # latest development build
        - latest  # latest stable release
        - 4.2.5
        - 3.4.7

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3

    - name: "Install: Haxe compiler targets"
      id: setup-haxe-targets
      uses: vegardit/haxe-reusable-workflows/.github/actions/setup-haxe-targets@v1
      with:
        setup-cs:     true
        setup-flash:  true
        setup-hl:     true
        setup-java:   true  # or a Java version, e.g. 11, 17
        setup-lua:    true  # or a Lua version, e.g. "5.3.6"
        setup-node:   true  # or a Node.js version, see https://github.com/actions/setup-node/#supported-version-syntax
        setup-php:    true  # or a PHP version, e.g. "7.4"
        setup-python: true  # or a Python version, e.g. "3.11"

    - name: "Install: Haxe ${{ matrix.haxe }}"
      uses: vegardit/haxe-reusable-workflows/.github/actions/setup-haxe@v1
      with:
        haxe-version: ${{ matrix.haxe }}

    # ... custom steps to compile/test Haxe code
```

### <a name="testing-locally"></a> Testing locally with `act`

The composite actions and reusable workflows are compatible with [ACT](https://github.com/nektos/act) a command-line tool that allows you to run
GitHub action workflows locally.

1. Install docker
1. Install [ACT](https://github.com/nektos/act)
1. Navigate into the root of your project (where the .github folder is located)
1. Run the command `act`
1. On subsequent re-runs you can use `act -r` to reuse previous container which avoids reinstallation of Haxe compiler targets and reduces build time.


## <a name="license"></a>License

All files are released under the [Apache License 2.0](LICENSE.txt).

Individual files contain the following tag instead of the full license text:
```
SPDX-License-Identifier: Apache-2.0
```
