[![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action)
[![cs](https://img.shields.io/badge/lang-cs-springgreen.svg)](https://github.com/PepikVaio/reMarkable_Qmldiff-hasher-action/blob/main/.language_cs/README.cs.md)


# Github akce!
> Toto je jednoduchá akce GitHubu pro hashování souborů QMLDiff.
> <br>
> Tato Github akce automaticky zpracovává `.qmd` soubory, aplikuje na ně QML diff hashing pomocí hashtabů a následně je publikuje do veřejného GitHub repozitáře.
> <br>
> Slouží jako most mezi privátním vývojem a veřejnou distribucí dat.

- Po každém pushi do privátního repozitáře:
  - projde všechny `.qmd` soubory
  - najde odpovídající firmware složky
  - aplikuje hashování přes hashtab
  - zkopíruje výsledek do cílového repozitáře
  - vytvoří commit s informací o změně
  - rozliší:
    - vytvořeno (nový soubor)
    - aktualizováno (změněný soubor)

<br>

## Instalace

> [!IMPORTANT]
> Před použitím této Github akce budete potřebovat:
> * privátní repozitář, který obsahuje vaše původní `.qmd` soubory a hashtaby
> * veřejný repozitář, do kterého se budou publikovat zpracované soubory
> * oprávnění zapisovat do veřejného repozitáře

<br>

> [!NOTE]
> Vytvořte `Personal Access Token`:
> 1. Přihlaste se na `GitHub`.
> 2. Klikněte na svůj profilový obrázek.
> 3. Otevřete `Settings`.
> 4. V levém menu zvolte `Developer settings`.
> 5. Otevřete `Personal access tokens`.
> 6. Vyberte `Fine-grained tokens`.
> 7. Klikněte na `Generate new token`.
> 8. Zapište název tokenu `qmldiff-hasher-action`.
> 9. Nastavte `Repository access` - Vyberte `Only select repositories` a zvolte svůj veřejný repozitář.
> 10. Nastavte `Repository permissions` - Vyberte `+ Add permissions` a nastavte oprávnění `Contents → Read and write`.
> 11. Klikněte na `Generate token` a zkopírujte si vygenerovaný token.

> [!CAUTION]
> GitHub zobrazí token pouze jednou.
> Po zavření stránky jej již nebude možné znovu zobrazit.

<br>

> [!NOTE]
> Uložte token do privátního repozitáře:
> 1. Otevřete svůj privátní repozitář a přejděte na: `Settings / Secrets and variables / Actions / New repository secret`
> 2. Zapište `Name`: `PUBLIC_REPO_TOKEN` a vložte `Secret` (váš vygenerovaný GitHub token).
> 3. Klikněte na `Add secret`.

<br>

> [!NOTE]
> Přidejte workflow:
> 1. V privátním repozitáři vytvořte soubor: `.github/workflows/hash-files.yml`
> 2. Do něj vložte ukázkový workflow (viz níže).
> 3. Upravte pouze následující proměnné:
>   - PATH_FOLDER:
>   - PATH_HASHTABS:
>   - NAME_PUBLIC_REPO:
>   - NAME_TOKEN:
>   - COMMIT_MESSAGE:
>   - IGNORE_HIDDEN:

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

> [!TIP]
> Význam proměnných:
> - `PATH_FOLDER`	složka obsahující `qmd` soubory. Pokud ji necháte prázdnou (""), bude se zpracovávat celý repozitář.
> - `PATH_HASHTABS` cesta ke složce s hashtaby.
> - `NAME_PUBLIC_REPO` název cílového veřejného repozitáře ve tvaru uživatel/repozitář.
> - `NAME_TOKEN`	název `GitHub Secret Name` obsahující `Personal Access Token`.
> - `COMMIT_MESSAGE` volitelná vlastní zpráva. Pokud zůstane prázdná, vytvoří se automaticky.
> - `IGNORE_HIDDEN` volba zda se mají zpracovat i skryté soubory.

<br>

### Používání
> Nahrajte změny v souboru `qmd`.
<br>
> Commitněte a odešlete libovolnou změnu do privátního repozitáře.

<br>

GitHub Action se automaticky spustí a provede:
1. stažení veřejného repozitáře,
2. zpracování všech .qmd souborů,
3. aplikaci QMLDiff hashování,
4. vytvoření commitů pro nové nebo změněné soubory,
5. odeslání změn do veřejného repozitáře.

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
