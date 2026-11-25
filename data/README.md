# Data

## `anderssonii_landmarks.tps`

Canonical TPS file with 120 pinnae from 40 specimens (20 from Patagonia and 20 from Shanxi; 3 pinnae per specimen).

- **59 landmarks per pinna**
  - Landmarks 1–4: fixed landmarks (curve endpoints).
  - Landmarks 5–44: 40 outline semilandmarks (curve between landmarks 1 and 2).
  - Landmarks 45–59: 15 midvein semilandmarks (curve between landmarks 3 and 4).
- TPS structure: `LM=4` followed by `CURVES=2` with `POINTS=40` and `POINTS=15`.
- Read with `geomorph::readland.tps(file, specID = "ID", readcurves = TRUE)` to obtain the full 59-landmark configuration.
- Specimen IDs follow the pattern `SPECIMEN_1`, `SPECIMEN_2`, `SPECIMEN_3` (three pinnae per specimen). The base ID before the underscore matches `metadata.csv`.
- Coordinates are in image pixels. Each specimen block includes a `SCALE` value; scale is removed by the Procrustes superimposition. `IMAGE` fields refer to the original photographs, which are not included in this repository.

## `metadata.csv`

One row per specimen (40 rows):

| Column | Description |
|---|---|
| `specimen_id` | Base specimen identifier (matches the TPS ID without the `_1/_2/_3` suffix) |
| `species` | Taxon name; currently empty |
| `state` | Preservation or collection state; currently empty |
| `collection_site` | `Patagonia` or `Shanxi` |
| `notes` | Free-text notes; currently empty |

## Provenance

- Patagonia: La Golondrina Formation (Santa Cruz, Argentina); specimens from LIL-PB, BA-Pb, LP-PB, and MPM-PB.
- Shanxi: upper Shihhotse Formation (Shanxi, China); specimens from S-PB (Swedish Museum of Natural History, Stockholm).

## License

The data in this directory are released under the Creative Commons Attribution 4.0 International License (CC BY 4.0); see `../LICENSE-DATA`.
