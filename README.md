# haxe-reusable-workflows

[![Build](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.reusable-workflow.yml/badge.svg)](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.reusable-workflow.yml)
[![Build](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.composite-action.yml/badge.svg)](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.composite-action.yml)
[![License](https://img.shields.io/github/license/vegardit/haxe-reusable-workflows.svg?label=license)](#license)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)


**Feedback and high-quality pull requests are highly welcome!**

1. [What is it?](#what-is-it)
1. [Usage](#usage)
  1. [Build/test using the `test-with-haxe` workflow](#test-with-haxe-workflow)
  1. [Build/test using the `test-with-haxe` action](#test-with-haxe-action)
  1. [Install compiler targets using the `setup-haxe-targets` action](#setup-haxe-targets-action)
  1. [Testing locally with `act`](#testing-locally)
1. [License](#license)

## <a name="what-is-it"></a>What is it?

A repository with [Reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows) and
[composite actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action) to build/test Haxe programs using Github Actions
on Ubuntu, MacOS, or Windows.

The workflows/actions do the heavy lifting of installing compatible versions of required compiler targets with the correct configuration/libraries depending on the runner OS and the desired Haxe version.

For faster re-runs caching of haxe libraries and other components is configured.


## Usage <a name="usage"></a>Usage

### <a name="test-with-haxe-workflow"></a>Build/test using the `test-with-haxe` reusable workflow

Simple config:
```yaml
name: My Haxe Build

on:
  push:
  pull_request:

jobs:
  my-haxe-build:
    uses: vegardit/haxe-reusable-workflows/.github/workflows/reusable.test-with-haxe.yml@v1
    with:
      runner-os: ubuntu-latest
      haxe-version: 4.2.5
      haxe-args: myconfig.hxml # default is "tests.hxml"
      haxe-libs: hx3compat hscript # libraries to be installed via "haxelib install"

      # Haxe targets to test with:
      test-cpp:    true
      test-cs:     true
      test-jvm:    true
      test-node:   true
      test-python: true
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
    uses: vegardit/haxe-reusable-workflows/.github/workflows/reusable.test-with-haxe.yml@v1
    strategy:
      fail-fast: false
      matrix:
        os:
        - ubuntu-latest
        - macos-latest
        - windows-latest
        haxe:
        - latest
        - 4.2.5
        - 3.4.7
    with:
      runner-os: ${{ matrix.os }}
      haxe-version: ${{ matrix.haxe }}
      haxe-args: myconfig.hxml # default is "tests.hxml"
      haxe-libs: hx3compat hscript # libraries to be installed via "haxelib install"

      # Haxe targets to test with, by default all are set to false:
      test-cpp:    true
      test-cs:     true
      test-eval:   true
      test-flash:  ${{ ! startsWith(matrix.os, 'macos') }} # FlashPlayer hangs on macOS
      test-hl:     ${{ matrix.haxe != '3.4.7' }} # HashLink not compatible with Haxe 3.x
      test-java:   true
      test-jvm:    true
      test-lua:    true
      test-neko:   true
      test-node:   tests-node.hxml # run tests with a target specific hxml file
      test-php:    true
      test-python: true

      continue-on-error: flash php # a list of targets that are allowed to fail
      retries: 2 # number of additional retries in case a test run fails, default is 0

      timeout-minutes: 30     # max. duration of the workflow, default is 60
      timeout-minutes-test: 5 # max. duration per target test, default is 10

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
        haxe-libs: hx3compat hscript # libraries to be installed via "haxelib install"

        # Haxe targets to test with:
      test-cpp:    true
      test-cs:     true
      test-jvm:    true
      test-node:   true
      test-python: true

    # other steps ...
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
        - latest
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
        haxe-libs: hx3compat hscript # libraries to be installed via "haxelib install"

        # Haxe targets to test with, by default all are set to false:
        test-cpp:    true
        test-cs:     true
        test-eval:   true
        test-flash:  ${{ ! startsWith(matrix.os, 'macos') }} # FlashPlayer hangs on macOS
        test-hl:     ${{ matrix.haxe != '3.4.7' }} # HashLink not compatible with Haxe 3.x
        test-java:   true
        test-jvm:    true
        test-lua:    true
        test-neko:   true
        test-node:   tests-node.hxml # run tests with a target specific hxml file
        test-php:    true
        test-python: true

        continue-on-error: flash php # a list of targets that are allowed to fail
        retries: 2 # number of additional retries in case a test run fails, default is 0

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

    # other steps ...
```


### <a name="setup-haxe-targets-action"></a>Install compiler targets using the `setup-haxe-targets` action

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
        - latest
        - 4.2.5
        - 3.4.7

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3

    - name: "Install: Haxe compiler targets"
      id: setup-haxe-targets
      uses: vegardit/haxe-reusable-workflows/.github/actions/setup-haxe-targets@v1
      with:
        setup-cpp:    true
        setup-cs:     true
        setup-flash:  true
        setup-hl:     true
        setup-java:   true  # or Java version, e.g. 11, 17
        setup-lua:    true  # or Lua version, e.g. "5.3.6"
        setup-node:   true  # or Node.js version, see https://github.com/actions/setup-node/#supported-version-syntax
        setup-php:    true  # or PHP version, e.g. "7.4"
        setup-python: true  # or Python version, e.g. "3.10"

    - name: "Install: Haxe ${{ matrix.haxe }}"
      uses: krdlab/setup-haxe@v1
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
