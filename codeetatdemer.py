import pandas as pd
import numpy as np
from pathlib import Path
import os

CHEMIN_FICHIER = Path.home() / "Downloads" / "167730_20000101_20221231_rc.csv"

# périodes IGN (entre campagnes)
PERIODES = [
    ("1995-01-01", "2000-12-31"),
    ("2001-01-01", "2008-12-31"),
    ("2009-01-01", "2012-12-31"),
    ("2013-01-01", "2015-12-31"),
    ("2016-01-01", "2019-12-31"),
    ("2020-01-01", "2022-12-31"),
]

# constantes 
RHO = 1025   # densité de l’eau (kg/m³)
G = 9.81     # gravité (m/s²)

print(f"Lecture du fichier : {CHEMIN_FICHIER}")

df = pd.read_csv(CHEMIN_FICHIER, sep=",", low_memory=False)
print("\n Fichier chargé avec succès.")
print("Colonnes disponibles :", df.columns.tolist())

# vérification des colonnes essentielles
colonnes_requises = ["time", "hs", "t02", "dp"]
for col in colonnes_requises:
    if col not in df.columns:
        raise ValueError(f"Colonne manquante : {col}")

# conversion du temps
df["time"] = pd.to_datetime(df["time"], errors="coerce")
df = df.dropna(subset=["time"]).sort_values("time")

def calcul_indicateurs(df, debut, fin):
    """Calcule les indicateurs marins expliquant les éboulements sur la période [debut, fin]."""
    subset = df[(df["time"] >= debut) & (df["time"] <= fin)].copy()
    if subset.empty:
        return {"période": f"{debut} → {fin}", "nb_points": 0}

    hs = subset["hs"].astype(float)
    tp = subset["t02"].astype(float)
    dp = subset["dp"].astype(float)


    energie = (1 / 8) * RHO * G * hs**2  # J/m²

    # moyenne vectorielle de direction
    dir_moy = np.rad2deg(
        np.arctan2(np.mean(np.sin(np.deg2rad(dp))), np.mean(np.cos(np.deg2rad(dp))))
    )
    if dir_moy < 0:
        dir_moy += 360

    # % de houles d’Ouest (240–300°)
    pct_houles_ouest = ((dp >= 240) & (dp <= 300)).sum() / len(dp)

    # nombre de jours équivalents de forte houle (données horaires)
    jours_houle3 = (hs > 3).sum() / 24
    jours_houle4 = (hs > 4).sum() / 24

    # indices synthétiques
    IFM = np.log(energie.sum() * (1 + jours_houle3)) if energie.sum() > 0 else np.nan
    indice_extreme = hs.max() / hs.mean() if hs.mean() > 0 else np.nan

 
    return {
        "période": f"{debut} → {fin}",
        "nb_points": len(subset),
        "hs_moy": hs.mean(),
        "hs_max": hs.max(),
        "hs_mediane": hs.median(),
        "t02_moy": tp.mean(),
        "t02_max": tp.max(),
        "energie_moy_Jm2": energie.mean(),
        "energie_cumulee_Jm2": energie.sum(),
        "jours_houle>3m": jours_houle3,
        "jours_houle>4m": jours_houle4,
        "%_houles_ouest": pct_houles_ouest,
        "dir_moy_deg": dir_moy,
        "IFM": IFM,
        "indice_extreme": indice_extreme,
    }

# application à toutes les périodes
resultats = [calcul_indicateurs(df, start, end) for start, end in PERIODES]
res = pd.DataFrame(resultats)


sortie = Path.home() / "Downloads" / "indicateurs_marins_periodiquesbonnedate.xlsx"

if not sortie.parent.exists():
    os.makedirs(sortie.parent, exist_ok=True)

res.to_excel(sortie, index=False, engine="openpyxl")
print(f"\n Résumé exporté dans : {sortie}")
print(res)

print("\n Résumé des tendances clés :")
print("- Hs_max élevé → périodes de tempêtes intenses")
print("- Énergie cumulée → intensité globale du forçage marin (érosion du pied de falaise)")
print("- % houles d’Ouest → exposition directe des falaises")
print("- IFM → indicateur global combinant intensité et fréquence de la houle forte")
