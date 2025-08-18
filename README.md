# nmr-objects

This repository contains the engine to create the full-flesh CHEMeDATA object classes from the classes in the `src/` folder. It adds the third-party methods for import, export and visualization from CHEMeDATA repositories ending with `reader`,` writer`, `viewer` respectively.

The script [scripts/createListObjects.zsh](scripts/createListObjects.zsh) creates the list of methods that needs addition of methods.

The script [scripts/transform.zsh](scripts/transform.zsh) adds the methods and stores the final classes in the `dist/` folder.

run:


```zsh
scripts/createListObjects.zsh
scripts/transform.zsh
```