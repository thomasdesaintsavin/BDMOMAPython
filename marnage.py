import pandas as pd
import numpy as np
from pathlib import Path
from io import StringIO


DOSSIER = Path.home() / "Downloads" / "dieppe"  # dossier où sont les fichiers .txt
PERIODES = [
    ("1995-01-01", "2000-12-31"),
    ("2001-01-01", "2008-12-31"),
    ("2009-01-01", "2012-12-31"),
    ("2013-01-01", "2015-12-31"),
    ("2016-01-01", "2019-12-31"),
    ("2020-01-01", "2022-12-31"),
]
SORTIE = Path.home() / "Downloads" / "indicateurs_marnagebonnedate.xlsx"

# lecture fichier shom

def lire_fichier(f: Path) -> pd.DataFrame:
    """
    Lit un fichier SHOM (format RAM).
    Garde uniquement les lignes non commentées et les sources 4 et 5.
    """
    lignes = []
    try:
        with open(f, "r", encoding="utf-8-sig") as file:
            for line in file:
                if not line.startswith("#") and ";" in line:
                    lignes.append(line.strip())
    except UnicodeDecodeError:
        with open(f, "r", encoding="latin-1") as file:
            for line in file:
                if not line.startswith("#") and ";" in line:
                    lignes.append(line.strip())

    if not lignes:
        print(f"Fichier vide ou illisible : {f.name}")
        return pd.DataFrame(columns=["Date", "Valeur"])

    df = pd.read_csv(StringIO("\n".join(lignes)), sep=";", names=["Date", "Valeur", "Source"], header=None)
    df["Date"] = pd.to_datetime(df["Date"], format="%d/%m/%Y %H:%M:%S", errors="coerce")
    df["Valeur"] = pd.to_numeric(df["Valeur"], errors="coerce")
    df["Source"] = pd.to_numeric(df["Source"], errors="coerce")

    # garder seulement les sources 4 et 5 (horaires validées/brutes)
    df = df[df["Source"].isin([4, 5])]

    df = df.dropna(subset=["Date", "Valeur"])
    print(f"{f.name} : {len(df)} mesures horaires")
    return df[["Date", "Valeur"]]


# charge fichiers

def charger_donnees(dossier: Path) -> pd.DataFrame:
    fichiers = sorted(dossier.rglob("*.txt"))
    print(f"{len(fichiers)} fichiers trouvés sous {dossier}")
    frames = [lire_fichier(f) for f in fichiers if any(ch.isdigit() for ch in f.stem)]
    frames = [df for df in frames if not df.empty]
    if not frames:
        raise RuntimeError("Aucune donnée valide n’a été trouvée.")
    df = pd.concat(frames, ignore_index=True).sort_values("Date")
    print(f"Données totales : {len(df)} points de marée ({df['Date'].min().date()} → {df['Date'].max().date()})")
    return df


# calcul des indicateurs 

def indicateurs(df: pd.DataFrame, start: str, end: str) -> dict:
    subset = df[(df["Date"] >= start) & (df["Date"] <= end)]
    if subset.empty:
        return {"période": f"{start} → {end}", "nb_points": 0}

    daily = subset.set_index("Date").resample("D")["Valeur"].agg(["max", "min"])
    daily["marnage"] = daily["max"] - daily["min"]
    daily = daily.dropna()

    return {
        "période": f"{start} → {end}",
        "nb_points": len(subset),
        "jours_disponibles": len(daily),
        "marnage_moy_m": daily["marnage"].mean(),
        "marnage_max_m": daily["marnage"].max(),
        "marnage_min_m": daily["marnage"].min(),
        "marnage_std_m": daily["marnage"].std(),
        "jours_marnage>8m": (daily["marnage"] > 8).sum(),
        "jours_marnage>9m": (daily["marnage"] > 9).sum(),
        "IAI": daily["marnage"].mean() * (daily["marnage"] > 8).sum(),
    }

# exécution

if __name__ == "__main__":
    df = charger_donnees(DOSSIER)
    res = pd.DataFrame([indicateurs(df, a, b) for a, b in PERIODES])

    print("\n Résumé :")
    print(res)

    res.to_excel(SORTIE, index=False, engine="openpyxl")
    print(f"\n Exporté : {SORTIE}")
