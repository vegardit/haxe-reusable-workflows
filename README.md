# haxe-reusable-workflows

[![License](https://img.shields.io/github/license/vegardit/haxe-reusable-workflows.svg?label=license)](#license)
[![Build](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.reusable-workflow.yml/badge.svg)](https://github.com/vegardit/haxe-reusable-workflows/actions/workflows/test.reusable-workflow.yml)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)


**Feedback and high-quality pull requests are highly welcome!**

1. [What is it?](#what-is-it)
1. [Usage](#usage)
  1. [Build/test using the `test-with-haxe` reusable workflow](#test-with-haxe-workflow)
  1. [Build/test using the `test-with-haxe` composite action](#test-with-haxe-action)
  1. [Configure compiler targets using the `setup-haxe-targets` composite action](#setup-haxe-targets-action)
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

```yaml
name: My Haxe Build

on:
  push:
  pull_request:

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
    with:
      runner-os: ${{ matrix.os }}
      haxe-version: ${{ matrix.haxe }}
      hxml-file: myconfig.hxml # default is "tests.hxml"
      haxe-libs: hx3compat hscript

      # by default all are set to false:
      test-cpp: true
      test-cs: true
      test-eval: true
      test-flash: true
      test-hl: true
      test-java: true
      test-jvm: true
      test-lua: true
      test-neko: true
      test-node: true
      test-php: true
      test-python: true

      timeout-minutes: 30     # max. duration of the workflow, default is 60
      timeout-minutes-test: 5 # max. duration per target test, default is 10

      before-tests: |
        echo "Preparing tests..."

      after-tests: |
        case "$GITHUB_JOB_STATUS" in
          success)   echo "Sending success report..." ;;
          failure)   echo "Sending failure report..." ;;
          cancelled) echo "Nothing to do, job cancelled" ;;
          *)         echo "ERROR: Unexpected job status [$GITHUB_JOB_STATUS]"; exit 1 ;;
        esac
```

### <a name="test-with-haxe-action"></a>Build/test using the `test-with-haxe` composite action

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

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3 #https://github.com/actions/checkout

    - name: Test with Haxe
      uses: vegardit/haxe-reusable-workflows/.github/actions/test-with-haxe@v1
      with:
        haxe-version: ${{ matrix.haxe }}
        hxml-file: myconfig.hxml # default is "tests.hxml"
        haxe-libs: hx3compat hscript

        # by default all are set to false:
        test-cpp: true
        test-cs: true
        test-eval: true
        test-flash: true
        test-hl: true
        test-java: true
        test-jvm: true
        test-lua: true
        test-neko: true
        test-node: true
        test-php: true
        test-python: true

    # other steps ...
```


### <a name="setup-haxe-targets-action"></a>Configure compiler targets using the `setup-haxe-targets` composite action

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

    steps:
    - name: Git Checkout
      uses: actions/checkout@v3 #https://github.com/actions/checkout

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
      uses: krdlab/setup-haxe@v1 # https://github.com/krdlab/setup-haxe
      with:
        haxe-version: ${{ matrix.haxe }}

    # ... custom steps to compile/test Haxe code
```

### <a name="testing-locally"></a> Testing locally with `act`

The composite actions and reusable workflows are compatible with [ACT](https://github.com/nektos/act) a commandline tool that allows you to run
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
