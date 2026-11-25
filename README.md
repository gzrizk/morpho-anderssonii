# Geometric morphometrics of Permian ferns: Patagonia vs. Shanxi

This repository contains the landmark data, derived results, and figure code for a geometric morphometric comparison of Permian fern pinnae from the La Golondrina Formation (Santa Cruz, Argentina) and the upper Shihhotse Formation (Shanxi, China).

The material was previously assigned to *Asterotheca anderssonii* (Patagonia) and *Pecopteris anderssonii* (Shanxi). The analyses test whether the two populations differ in pinna shape and size.

## Data

- **120 pinnae** from **40 specimens** (20 per site; 3 pinnae per specimen).
- **59 landmarks** per pinna: 4 fixed landmarks, 40 outline semilandmarks, and 15 midvein semilandmarks.
- Specimens are housed in LIL-PB, BA-Pb, LP-PB, MPM-PB (Argentina) and S-PB (Swedish Museum of Natural History, Stockholm).
- The canonical landmark file is `data/anderssonii_landmarks.tps`; see `data/README.md` for the landmark scheme and metadata.

## Key results

| Analysis | Result |
|---|---|
| PCA | PC1 = 50.3 %, PC2 = 30.9 % (81.2 % combined) |
| Centroid size | Patagonia 31.0 ± 7.6; Shanxi 23.3 ± 3.4; Patagonia ≈33 % larger (t = 4.12, p = 0.0003), with substantial overlap |
| MANCOVA (shape ~ size × site) | Site: F = 22.45, p = 0.001, R² = 0.368; size: p = 0.352; interaction: p = 0.219 |
| Permutation test | Observed Procrustes distance D = 0.099; p < 0.001 (10,000 permutations) |
| Between-group analysis | p = 0.0001; Δ = 0 % |
| LOOCV | 35/40 specimens correctly classified (87.5 %); the three pinnae of a specimen are held out together |

Shape differs between sites independently of size; size also differs but overlaps broadly and is not diagnostic on its own.

## Repository structure

```
.
├── data/
│   ├── anderssonii_landmarks.tps   # canonical TPS file (120 pinnae)
│   ├── metadata.csv                # specimen-level metadata
│   └── README.md                   # data description and landmark scheme
├── results/
│   ├── arrays/mean_shapes_tagged.rds
│   └── tables/                     # MANCOVA, permutation, LOOCV and related tables
├── scripts/
│   └── make_poster_figures.R       # PCA, size, shape, permutation and LOOCV figures
└── figures/                        # generated figures (PDF)
```

## Reproducing the figures

Run from the repository root:

```bash
Rscript scripts/make_poster_figures.R
```

Requirements: R (>= 4.1) with `ggplot2`, `dplyr`, and `cowplot`.

The script reads `results/arrays/mean_shapes_tagged.rds` and the tables in `results/tables/`, and writes the figures to `figures/`. The output directories can be overridden with the environment variables `RESULTS_DIR` and `FIG_DIR`.

## Methods

Landmark coordinates were superimposed with a Generalized Procrustes Analysis (GPA), and semilandmarks were slid along their curves. Shape variation was explored with PCA. Shape differences between sites were tested with a MANCOVA (shape ~ centroid size × site), a permutation test on Procrustes distances between site means, and a between-group analysis. Classification accuracy was assessed with leave-one-specimen-out cross-validation (all three pinnae of a specimen were held out together).

The statistical analyses were performed in R with `geomorph` and `RRPP`; this repository contains the canonical data, the derived result tables, and the code needed to regenerate the figures.

## Data and code availability

- Landmark data and derived tables: `data/` and `results/`.
- Figure code: `scripts/make_poster_figures.R`.
- Poster source will be added to this repository when finalized.

## License

- **Code**: MIT License; see `LICENSE`.
- **Data and derived tables**: Creative Commons Attribution 4.0 International (CC BY 4.0); see `LICENSE-DATA`.

## Citation

If you use these data, please cite:

> Rodriguez Rizk, G., Cariglino, B., & Yañez, A. (2026). *Geometric morphometrics of Permian ferns: Patagonia vs. Shanxi* [Data set]. GitHub. https://github.com/gzrizk/morpho-anderssonii

## Contact

Gonzalo Rodriguez Rizk — gonzalorizk@gmail.com
Museo Argentino de Ciencias Naturales "Bernardino Rivadavia" (MACN–CONICET), Buenos Aires, Argentina.

## Acknowledgments

Curators and technical staff of the LIL-PB, BA-Pb, LP-PB, MPM-PB, and S-PB collections. Funding: APA–Fundación Azara (Graduate Student Grant).
