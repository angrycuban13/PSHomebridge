---
title: Contributing
description: Contribute code and documentation to PSHomebridge.
---

<!-- markdownlint-disable MD025 -->
# Contributing
<!-- markdownlint-enable MD025 -->

PSHomebridge accepts fixes, command additions, tests, and documentation updates through pull requests.

## Requirements

- PowerShell 7 or later
- [Git](https://git-scm.com/)
- [uv](https://docs.astral.sh/uv/) to build the documentation site
- A fork with a branch from the latest `main` branch
- The repository rules in `AGENTS.md`

Do not include real passwords, access tokens, or other secrets in code, tests, logs, or examples.

## Module guidelines

- Place public functions in `PSHomebridge/Source/Public`.
- Place private functions in `PSHomebridge/Source/Private`.
- Use one function in each script.
- Name each script the same as its function.
- Add Pester tests for changed behavior.
- Add complete comment-based help to each public function.
- Describe observable behavior. Do not describe internal implementation.

Run the complete release gate from the repository root:

```powershell
./PSHomebridge/tools/Test-Release.ps1
```

Changes to module source or packaging require a new manifest version and changelog entry. Prepare these changes before you open the pull request:

```powershell
./PSHomebridge/tools/Prepare-Release.ps1 -Version <new-version>
```

Review the manifest and changelog changes before you commit them.

## Build the documentation

The command reference comes from the comment-based help in the built module.

!!! WARNING
    Do not edit generated command pages directly.

Install the required PowerShell modules:

```powershell
Install-Module Configuration -RequiredVersion 1.6.0 -Scope CurrentUser
Install-Module Microsoft.PowerShell.PlatyPS -RequiredVersion 1.0.3 -Scope CurrentUser
Install-Module ModuleBuilder -RequiredVersion 3.2.18 -Scope CurrentUser
```

Build the module and generate the command reference:

```powershell
$manifest = Import-PowerShellDataFile ./PSHomebridge/Source/PSHomebridge.psd1
$version = [System.String]$manifest.ModuleVersion

Build-Module ./PSHomebridge/build.psd1

$newModuleDocsParameters = @{
    ModulePath = "./PSHomebridge/Output/PSHomebridge/$version/PSHomebridge.psd1"
    OutputPath = './docs/command-reference'
}

./ci/New-ModuleDocs.ps1 @newModuleDocsParameters
```

The generator creates one index and one page for each exported command. The root `.nav.yml` file controls the main navigation.

Synchronize the locked documentation environment:

```console
uv sync --locked --only-group docs
```

Start the local documentation server:

```console
uv run --locked --only-group docs zensical serve
```

Open `http://localhost:8000`. Check the navigation, links, examples, input types, and output types.

Run the strict site build before you commit:

```console
uv run --locked --only-group docs zensical build --clean --strict
```

## Open a pull request

Commit related source, tests, generated documentation, manifest, and changelog changes together when they apply. Open a pull request against `main`.

The pull request must pass release validation. Documentation changes must also pass the documentation consistency check.
