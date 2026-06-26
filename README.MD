[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action)
[![cs](https://img.shields.io/badge/lang-cs-springgreen.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action/blob/main/.language_cs/README.cs.md)


# Github akce!
> Toto je jednoduchá akce GitHubu pro hashování souborů QMLDiff.
> <br>
> Tato gitHub akce automaticky zpracovává `.qmd` soubory, aplikuje na ně QML diff hashing pomocí hashtabů a následně je publikuje do veřejného GitHub repozitáře. Slouží jako most mezi privátním vývojem a veřejnou distribucí dat.

- Po každém pushi do privátního repozitáře:
  - projde všechny `.qmd` soubory
  - najde odpovídající firmware složky
  - aplikuje hashování přes hashtab
  - zkopíruje výsledek do cílového repozitáře
  - vytvoří commit s informací o změně
  - rozliší:
    - Vytvořeno (nový soubor)
    - Aktualizováno (změněný soubor)

<br>

## Instalace

> [!IMPORTANT]
> Před použitím této gitHub akce budete potřebovat:
> * privátní repozitář, který obsahuje vaše původní .qmd soubory a hashtaby,
> * veřejný repozitář, do kterého se budou publikovat zpracované soubory,
> * oprávnění zapisovat do veřejného repozitáře.

<br>

> [!NOTE]
> Vytvořte `Personal Access Token`:
> 1. Přihlaste se na GitHub.
> 2. Klikněte na svůj profilový obrázek.
> 3. Otevřete `Settings`.
> 4. V levém menu zvolte `Developer settings`.
> 5. Otevřete `Personal access tokens`.
> 6. Vyberte `Fine-grained tokens`.
> 7. Klikněte na `Generate new token`.
> 8. Nastavte: `Repository access`.
> 9. Vyberte: `Only select repositories`.
> 10. Zvolte: Svůj veřejný repozitář.
> 11. `Repository permissions` Nastavte oprávnění: * Contents → Read and write.
> 12. Klikněte na `Generate token` a zkopírujte si vygenerovaný token.


```
name: 'hash-files'
on:
  push:

env:
  # ======================================
  # CONFIG PRIVATE REPO (editable)
  # PATH_FOLDER = empty or name of folder
  # ======================================
  PATH_FOLDER: Xovi_Extensions
  PATH_HASHTABS: Xovi_Extensions/.hashtabs

  # ======================================
  # CONFIG PUBLIC REPO (editable)
  # ======================================
  NAME_PUBLIC_REPO: PepikVaio/reMarkable_Test
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






[!IMPORTANT]
> GitHub zobrazí token pouze jednou.
> Po zavření stránky jej již nebude možné znovu zobrazit.

> [!NOTE]
> Uložte token do privátního repozitáře:
> Otevřete svůj privátní repozitář a přejděte na:
> - Settings / Secrets and variables / Actions / New repository secret
> Vytvořte nový secret:
> - Název	Hodnota: `PUBLIC_REPO_TOKEN` váš vygenerovaný GitHub token.

> [!NOTE]
> Přidejte workflow:
> V privátním repozitáři vytvořte soubor:
> - `.github/workflows/hash-files.yml`
> Do něj vložte ukázkový workflow z tohoto repozitáře.
> Upravte pouze následující proměnné:
> - NAME_FOLDER:
> - PATH_HASHTABS:
> - NAME_PUBLIC_REPO:
> - NAME_TOKEN:
> - MESSAGE_COMMIT:

Jejich význam:

Proměnná	Popis
NAME_FOLDER	Složka obsahující firmware. Pokud ji necháte prázdnou (""), bude se zpracovávat celý repozitář.
PATH_HASHTABS	Cesta ke složce s hashtaby.
NAME_PUBLIC_REPO	Název cílového veřejného repozitáře ve tvaru uživatel/repozitář.
NAME_TOKEN	Název GitHub Secret obsahující Personal Access Token.
MESSAGE_COMMIT	Volitelná vlastní commit zpráva. Pokud zůstane prázdná, vytvoří se automaticky.

⸻

Krok 5 – Nahrajte změny

Commitněte a odešlete libovolnou změnu do privátního repozitáře.

GitHub Action se automaticky spustí a provede:

1. stažení veřejného repozitáře,
2. zpracování všech .qmd souborů,
3. aplikaci QMLDiff hashování,
4. vytvoření commitů pro nové nebo změněné soubory,
5. odeslání změn do veřejného repozitáře.

⸻

Hotovo

Od této chvíle bude veřejný repozitář automaticky aktualizován při každém pushi do vašeho privátního repozitáře.










### Používání










<br>

## Pomoc
Vytvořte problémy, pokud najdete problém.

> [!NOTE]
> ### Authors
> - **Jméno:** Wajsar Josef  
> - **Email:** [Wajsar.Josef@hotmail.com](mailto:Wajsar.Josef@hotmail.com)
> ### Poděkování
> Inspirace, úryvky kódu atd...
> - [asivery](https://github.com/asivery/qmldiff-hasher-action)
> - [rmitchellscott](https://github.com/rmitchellscott/qmldiff-hasher-action)











---



---

## Jak funguje struktura

Private repo obsahuje zdrojová data:

- složky firmware (např. 3.24.0.149, 3.25.1.0)
- `.qmd` soubory
- hashtaby v `.hashtabs`

Public repo obsahuje pouze výstup:

- zpracované `.qmd` soubory
- zachovanou strukturu
- historii změn

---


---

## Nastavení GitHub tokenu

Pro zápis do veřejného repozitáře je potřeba token.

Vytvoření:

https://github.com/settings/tokens

Zvol:
- Fine-grained token
- Permissions:
  - Contents: Read and write
- Přístup k cílovému repozitáři

Token se uloží do privátního repozitáře:

Settings → Secrets and variables → Actions → New secret

Název:
PUBLIC_REPO_TOKEN

---

## Použití GitHub Actions

V privátním repozitáři vytvoř soubor:

.github/workflows/hash-files.yml

Obsah:

```yaml
name: hash-files

on:
  push:

env:
  NAME_FOLDER: Xovi_Extensions
  PATH_HASHTABS: Xovi_Extensions/.hashtabs
  NAME_PUBLIC_REPO: PepikVaio/reMarkable_Test
  NAME_TOKEN: PUBLIC_REPO_TOKEN
  MESSAGE_COMMIT: ""

jobs:
  main:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: PepikVaio/reMarkable_Qmldiff-hasher-action@main
        name: Run QMLDiff Hasher
        with:
          source_root: ${{ env.NAME_FOLDER }}
          hashtab_root: ${{ env.PATH_HASHTABS }}
          dest_repo_name: ${{ env.NAME_PUBLIC_REPO }}
          repo_access_token: ${{ secrets[env.NAME_TOKEN] }}
          commit_message: ${{ env.MESSAGE_COMMIT }}
          












## Inputs

### `qmd_hash_rules` (required)
The QMD hashing rules. Format consists of one or more hashtab-dependent entries separated with a semicolon. Every entry consists of the path of the hashtab, followed by where the files will be copied to in the dest repo, and then the list of files. All comma-separated.

Example: `'hashtab-file,path-in-destrepo,file1.qmd,file2.qmd;hashtab-file-2,path-in-destrepo-2,file1.qmd,file3.qmd'`

### `dest_repo_name` (required)
The name of the destination, public repo (e.g., `user/repository`)

### `repo_access_token` (required)
The token to use when pushing to the public repo (e.g., a GitHub PAT with write permissions to the destination repo)

### `commit_message` (optional)
Custom commit message for the destination repo. If not provided, defaults to a timestamp-based message.

Examples:
```yaml
# Use a custom static message
commit_message: 'Update hashed QMD files'

# Use the commit message from the triggering commit
commit_message: ${{ github.event.head_commit.message }}

# Combine commit info
commit_message: 'Update from ${{ github.sha }}: ${{ github.event.head_commit.message }}'
```

## Notes

- Don't forget to also add and commit the hashtab files themselves. They are not supplied by this action!
