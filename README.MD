[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action)
[![cs](https://img.shields.io/badge/lang-cs-springgreen.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action/blob/main/.language/README.cs.md)



# GitHub Action - Hashing QMLDiff files!
> This is a simple GitHub Action for hashing QMLDiff files.
> <br>
> This GitHub Action automatically processes `.qmd` files, applies QML diff hashing using hashtabs, and then publishes them to a public GitHub repository.
> <br>
> It serves as a bridge between private development and public data distribution.

- On every push to the private repository:
  - iterates through all `.qmd` files
  - finds the corresponding firmware folders
  - applies hashing via hashtab
  - copies the result to the target repository
  - creates a commit with information about the change
  - distinguishes between:
    - created (new file)
    - updated (modified file)

<br>

## Installation

> [!IMPORTANT]
> Before using this GitHub Action you will need:
> * a private repository containing your original `.qmd` files and hashtabs
> * a public repository where the processed files will be published
> * write permission to the public repository

<br>

### Create a `Personal Access Token`:
> [!NOTE]
> 1. Log in to `GitHub`.
> 2. Click on your profile picture.
> 3. Open `Settings`.
> 4. In the left menu select `Developer settings`.
> 5. Open `Personal access tokens`.
> 6. Select `Fine-grained tokens`.
> 7. Click `Generate new token`.
> 8. Enter the token name `qmldiff-hasher-action`.
> 9. Set `Repository access` — select `Only select repositories` and choose your public repository.
> 10. Set `Permissions` — select `+ Add permissions` and set `Contents → Read and write`.
> 11. Click `Generate token` and copy the generated token.

> [!CAUTION]
> GitHub will display the token only once.
> Once you close the page, it will no longer be possible to view it again.

<br>

### Save the token to the private repository:
> [!NOTE]
> 1. Open your private repository and navigate to: `Settings / Secrets and variables / Actions / New repository secret`
> 2. Enter `Name`: `PUBLIC_REPO_TOKEN` and paste the `Secret` (your generated GitHub token).
> 3. Click `Add secret`.

<br>

### Add the workflow:
> [!NOTE]
> 1. In the private repository create the file: `.github/workflows/hash-files.yml`
> 2. Paste the example workflow into it (see below).
> 3. Edit only the following variables:
>   - PATH_FOLDER:
>   - PATH_HASHTABS:
>   - NAME_PUBLIC_REPO:
>   - NAME_TOKEN:
>   - COMMIT_MESSAGE:
>   - IGNORE_HIDDEN:

```yaml
name: 'hash-files'
on:
  push:

env:
  # ======================================
  # CONFIG PRIVATE REPO (editable)
  # PATH_FOLDER = empty or name of folder
  # ======================================
  PATH_FOLDER: ""
  PATH_HASHTABS: .hashtabs

  # ======================================
  # CONFIG PUBLIC REPO (editable)
  # ======================================
  NAME_PUBLIC_REPO: user/repository
  NAME_TOKEN: PUBLIC_REPO_TOKEN

  # ======================================
  # CONFIG (editable)
  # COMMIT_MESSAGE = empty or message
  # ======================================
  COMMIT_MESSAGE: ""
  IGNORE_HIDDEN: true

jobs:
  main:
    name: 'Update the public-facing repo'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 1
          sparse-checkout: ${{ env.PATH_FOLDER || '' }}
          sparse-checkout-cone-mode: true
      - uses: PepikVaio/reMarkable_Qmldiff-hasher-action@main
        name: 'Run the action'
        with:
          source_root: ${{ env.PATH_FOLDER }}
          hashtab_root: ${{ env.PATH_HASHTABS }}
          dest_repo_name: ${{ env.NAME_PUBLIC_REPO }}
          repo_access_token: ${{ secrets[env.NAME_TOKEN] }}
          commit_message: ${{ env.COMMIT_MESSAGE }}
```

> [!TIP]
> `PATH_FOLDER` — folder containing `qmd` files. If left empty (""), the entire repository will be processed.
> <br>
> `PATH_HASHTABS` — path to the folder with hashtabs.
> <br>
> `NAME_PUBLIC_REPO` — name of the target public repository in the format `user/repository`.
> <br>
> `NAME_TOKEN` — name of the `GitHub Secret` containing the `Personal Access Token`.
> <br>
> `COMMIT_MESSAGE` — optional custom message. If left empty, one will be generated automatically.
> <br>
> `IGNORE_HIDDEN` — whether hidden files should also be processed.

<br>

## Usage
> Upload changes to the `qmd` file.
> <br>
> Commit and push any change to the private repository.

<br>

The GitHub Action will start automatically and will:
1. check out the public repository,
2. process all `.qmd` files,
3. apply QMLDiff hashing,
4. create commits for new or changed files,
5. push the changes to the public repository.

<br>

### Recommended repository structure
```text
Private repository
│
├── .github
│   └── workflows
│       └── publish.yml
│
├── .hashtabs
│   ├── <firmware_version>
│   │   └── hashtab
│   └── <firmware_version>
│       └── hashtab
│
├── <extension_name>
│   ├── <firmware_version>
│   │   ├── MainView.qmd
│   │   ├── settings.json
│   │   ├── resources.rcc
│   │   ├── config.json
│   │   ├── helper.js
│   │   │
│   │   ├── .hidden_file
│   │   ├── .hidden_folder/
│   │   │   └── secret.json
│   │   │
│   │   └── ...
│   │
│   ├── <firmware_version>
│   │   ├── MainView.qmd
│   │   ├── settings.json
│   │   ├── resources.rcc
│   │   │
│   │   ├── .hidden_file
│   │   ├── .hidden_folder/
│   │   │   └── secret.json
│   │   │
│   │   └── ...
│   │
│   └── ...
│
├── <extension_name>
│   └── ...
│
└── README.md
```

## Help
Create issues if you find a problem.

> [!NOTE]
> ### Authors
> - **Name:** Wajsar Josef
> - **Email:** [Wajsar.Josef@hotmail.com](mailto:Wajsar.Josef@hotmail.com)
> ### Acknowledgements
> Inspiration, code snippets, etc...
> - [asivery](https://github.com/asivery/qmldiff-hasher-action)
> - [rmitchellscott](https://github.com/rmitchellscott/qmldiff-hasher-action)
