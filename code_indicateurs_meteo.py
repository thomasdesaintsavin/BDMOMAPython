
import re
from pathlib import Path
from typing import List, Tuple, Dict
import pandas as pd
import numpy as np

# Dossier contenant les CSV Météo-France
CHEMIN_DOSSIER = r"C:\Users\kweez\Documents\IMT\Projet command entreprise\Donnees\Donnees\data_MeteoFrance_horaire_observations_stat_Dieppe_1995_2022"

# Périodes d'analyse 
PERIODES: List[Tuple[str, str]] = [
    ("1995-01-01", "2000-12-31"),
    ("2001-01-01", "2008-12-31"),
    ("2009-01-01", "2012-12-31"),
    ("2013-01-01", "2015-12-31"),
    ("2016-01-01", "2019-12-31"),
    ("2020-01-01", "2022-12-31"),
]

# Seuils 
PLUIE_JOUR_MM = 0.1
FORTE_PLUIE_JOUR_MM = 10.0
VENT_FORT_KMH = 60.0
TEMPETE_KMH = 80.0
BASSE_PRESSION_HPA = 1000.0
TRES_BASSE_PRESSION_HPA = 985.0
SEUIL_JOUR_TRES_CHAUD = 25.0



def _to_float_series(s: pd.Series) -> pd.Series:
    """
    Convertit une série de strings en float de manière robuste :
    - remplace les virgules par des points
    - remplace les motifs "digit espace digit" par "digit.point.digit"
    - supprime les espaces parasites
    """
    if s.dtype.kind in "biufc":
        return s.astype(float)

    s = s.astype(str)
    # Remplacer les virgules en points
    s = s.str.replace(",", ".", regex=False)

    # Motifs du style "5 5" ou "-0 7" => "5.5" / "-0.7"
    s = s.str.replace(r"(?<=\d)\s+(?=\d)", ".", regex=True)
    s = s.str.replace(r"(?<=-)\s+(?=\d)", "", regex=True)  # "- 1" -> "-1"

    # Supprimer espaces en trop aux extrémités
    s = s.str.strip()
    # Dernière tentative de conversion
    with np.errstate(all='ignore'):
        out = pd.to_numeric(s, errors="coerce")
    return out

def _col(df: pd.DataFrame, candidates: List[str]) -> str:
    """Retourne le nom de la première colonne existante parmi candidates."""
    for c in candidates:
        if c in df.columns:
            return c
    return None

def lire_csv_meteo(path: Path) -> pd.DataFrame:
    """
    Lit un CSV Météo-France avec séparateur ';' et parse la date.
    La colonne DATE est au format YYYYMMDDHH .
    """
    df = pd.read_csv(path, sep=';', low_memory=False)
    # Normalisation noms colonnes 
    df.columns = [c.strip() for c in df.columns]

    # Parsing DATE
    date_col = _col(df, ["DATE", "Date", "date"])
    if date_col is None:
        raise ValueError(f"Aucune colonne DATE trouvée dans {path.name}")

    df[date_col] = df[date_col].astype(str).str.strip()
    # Support YYYYMMDDHH ou YYYYMMDD
    df["datetime"] = pd.to_datetime(df[date_col].str.slice(0, 10), format="%Y%m%d%H", errors="coerce")
    # fallback si pas d'heure
    mask_na = df["datetime"].isna()
    if mask_na.any():
        fallback = pd.to_datetime(df.loc[mask_na, date_col].str.slice(0, 8), format="%Y%m%d", errors="coerce")
        df.loc[mask_na, "datetime"] = fallback

    # Index temps + colonne date
    df["date"] = df["datetime"].dt.date
    df = df.set_index("datetime").sort_index()

    # Conversion robuste des variables utiles si présentes
    numeric_candidates = [
        # précipitations / neige
        "RR1","DRR1","NEIGETOT","HNEIGEF",
        # températures
        "T","TN","TX","TNSOL","T10","T20","T50","T100",
        # vent
        "FF","FF2","FXI","FXI2","FXI3S","DD","DXI","DXY",
        # pression
        "PMER","PMERMIN",
        # humidité
        "U","UX",
        # rayonnement
        "GLO","DIR","DIF","INS","UV"
    ]
    for c in numeric_candidates:
        if c in df.columns:
            df[c] = _to_float_series(df[c])

    return df

def charger_dossier(chemin_dossier: str) -> pd.DataFrame:
    """
    Charge et concatène tous les CSV d'un dossier.
    """
    p = Path(chemin_dossier)
    files = sorted(list(p.glob("*.csv")))
    if not files:
        raise FileNotFoundError(f"Aucun CSV trouvé dans {chemin_dossier}")
    frames = []
    for f in files:
        try:
            frames.append(lire_csv_meteo(f))
        except Exception as e:
            print(f"Fichier ignoré ({f.name}) : {e}")
    df = pd.concat(frames, axis=0).sort_index()
    return df

# -----------------------------
# Calculs d'indicateurs
# -----------------------------

def resumer_journalier(df: pd.DataFrame) -> pd.DataFrame:
    """
    Agrège à J+1 :
    - RR1 : cumul/jour
    - TN/TX : min/max journaliers si existent, sinon à partir de T
    - Vent : moyennes & max rafales
    - Pression, humidité, rayonnement : moyennes
    """
    # Création du dictionnaire d'agrégation
    agg: Dict[str, str] = {}

    agg["RR1"] = "sum"

    # Températures
    agg["TN"] = "min"
    agg["TX"] = "max"
    agg["T"] = "mean"  # moyenne journalière

    # Vent
    agg["FF"] = "mean"   # vent moyen journalier
    agg["FXI"] = "max"   # rafale max du jour
    agg["DD"] = "mean"   # direction moyenne du vent sur la journée

    # Pression
    agg["PMER"] = "mean"
    agg["PMERMIN"] = "min"

    # Humidité
    agg["U"] = "mean"

    daily = df.resample("D").agg(agg)

    # Amplitude journalière
    daily["AMPLI"] = daily["TX"] - daily["TN"]

    return daily

def cycles_gel_degel(daily: pd.DataFrame) -> int:
    """
    Compte le nombre de jours où TN<0 et TX>0 (jour de gel-dégel).
    """
    if "TN" not in daily.columns or "TX" not in daily.columns:
        return np.nan 
    cond = (daily["TN"] < 0) & (daily["TX"] > 1)
    return int(cond.sum())

def jours_condition(daily: pd.DataFrame, col: str, op, seuil: float) -> int:
    if col not in daily.columns:
        return np.nan
    return int(op(daily[col], seuil).sum())

def vent_kmh(series: pd.Series) -> pd.Series:
    """
    Si les vitesses sont en m/s, les convertir en km/h (x3.6).
    Heuristique : si max<70, on suppose m/s et on convertit.
    """
    if series.dropna().max() is None:
        return series
    s = series.copy()
    try:
        if s.max() < 70:  # très probablement m/s
            s = s * 3.6
    except Exception:
        pass
    return s

def indicateurs_periode(daily: pd.DataFrame, start: str, end: str) -> Dict[str, float]:
    """
    Calcule les indicateurs sur la sous-période [start, end].
    """
    period = daily.loc[start:end].copy()
    out = {
        "periode_debut": start,
        "periode_fin": end,
        "nb_jours": int(len(period)),
    }

    # PRECIPITATIONS
    if "RR1" in period.columns:
        pluie = period["RR1"].fillna(0)

        # Cumul total sur la période
        out["pluie_cum_mm"] = float(pluie.sum())

        # Nombre de jours de pluie et forte pluie
        out["jours_pluie"] = int((pluie > PLUIE_JOUR_MM).sum())
        out["jours_forte_pluie"] = int((pluie > FORTE_PLUIE_JOUR_MM).sum())
        out["max_pluie_jour"] = float(pluie.max())

        # Nombre de séquences ≥3 jours avec pluie > 1 mm
        pluie_bool = (pluie > 1).astype(int)
        groupes = (pluie_bool != pluie_bool.shift()).cumsum()
        longueurs = pluie_bool.groupby(groupes).sum()
        out["nb_seq_pluie_3j"] = int((longueurs >= 3).sum())

        # max_cum_pluie_5j — Cumul maximum sur 5 jours glissants
        out["max_cum_pluie_5j"] = float(pluie.rolling(5, min_periods=1).sum().max())

        # nb_seq_seche_10j — Nb séquences ≥10 jours sans pluie
        seche = (pluie <= 1).astype(int)
        grp_seche = (seche != seche.shift()).cumsum()
        longueurs_seche = seche.groupby(grp_seche).sum()
        out["nb_seq_seche_10j"] = int((longueurs_seche >= 10).sum())

        # pluie_95p — 95e percentile des pluies journalières
        out["pluie_95p"] = float(pluie.quantile(0.95))

        # pluie_extreme_ratio — part de la pluie due aux 5 % de jours les plus pluvieux
        top5 = pluie.quantile(0.95)
        somme_top5 = pluie[pluie >= top5].sum()
        out["pluie_extreme_ratio"] = float(somme_top5 / pluie.sum()) if pluie.sum() > 0 else np.nan

    else:
        out["pluie_cum_mm"] = np.nan
        out["jours_pluie"] = np.nan
        out["jours_forte_pluie"] = np.nan
        out["max_pluie_jour"] = np.nan
        out["nb_seq_pluie_3j"] = np.nan
        out["max_cum_pluie_5j"] = np.nan
        out["nb_seq_seche_10j"] = np.nan
        out["pluie_95p"] = np.nan
        out["pluie_extreme_ratio"] = np.nan


    # TEMPERATURES

    out["jours_gel"] = (
        int((period["TN"] < 0).sum()) if "TN" in period.columns else np.nan
    )
    out["jours_tres_chauds"] = (
        int((period["TX"] > SEUIL_JOUR_TRES_CHAUD).sum()) if "TX" in period.columns else np.nan
    )
    out["jours_gel_degel"] = cycles_gel_degel(period)

    if "TN" in period.columns:
        # Séquences de ≥3 jours consécutifs de gel
        gel = (period["TN"] < 0).astype(int)
        grp = (gel != gel.shift()).cumsum()
        seq = gel.groupby(grp).sum()
        out["nb_seq_gel_3j"] = int((seq >= 3).sum())
        out["plus_longue_serie_gel_consecutif"] = int(seq.max())

    else:
        out["nb_seq_gel_3j"] = np.nan
        out["plus_longue_serie_gel_consecutif"] = np.nan

    if "TN" in period.columns and "TX" in period.columns:
        # Cycles gel-dégel rapides : TN < 0 et TX > +5 °C
        cond = (period["TN"] < 0) & (period["TX"] > 5)
        out["nb_seq_gel_degel_rapide"] = int(cond.sum())
    else:
        out["nb_seq_gel_degel_rapide"] = np.nan

    if "AMPLI" in period.columns:
        # 95e percentile de l’amplitude thermique journalière
        out["T_ampli_95p"] = float(period["AMPLI"].quantile(0.95))
        # Nombre de jours avec amplitude > 10°C
        out["nb_jours_ampli_sup_10"] = int((period["AMPLI"] > 10).sum())
    else:
        out["T_ampli_95p"] = np.nan
        out["nb_jours_ampli_sup_10"] = np.nan

    # VENT
    if "FF" in period.columns:
        ff_kmh = vent_kmh(period["FF"])
        out["vent_moy_kmh"] = float(ff_kmh.mean(skipna=True))
    else:
        out["vent_moy_kmh"] = np.nan

    
    if "FXI" in period.columns:
        fxi_kmh = vent_kmh(period["FXI"].fillna(0))

        out["jours_vent_fort_60"] = int((fxi_kmh > VENT_FORT_KMH).sum())
        out["jours_tempete_80"] = int((fxi_kmh > TEMPETE_KMH).sum())
        out["rafale_max_kmh"] = float(fxi_kmh.max(skipna=True))

        # Séquences de ≥2 jours consécutifs de tempête
        temp = (fxi_kmh > 80).astype(int)
        grp = (temp != temp.shift()).cumsum()
        seq = temp.groupby(grp).sum()
        out["nb_tempetes_consecutives"] = int((seq >= 2).sum())

        out["plus_longue_serie_tempete_consecutive"] = int(seq.max())
        out["max_rafale_3j"] = float(fxi_kmh.rolling(3, min_periods=1).max().max()) # Rafale maximale sur 3 jours glissants
        out["energie_vent_cumulee"] = float((fxi_kmh ** 2).sum(skipna=True)) # Énergie mécanique cumulée (FXI²)

    else:
        out["jours_vent_fort_60"] = np.nan
        out["jours_tempete_80"] = np.nan
        out["rafale_max_kmh"] = np.nan
        out["jours_tempete_80"] = np.nan
        out["nb_tempetes_consecutives"] = np.nan
        out["plus_longue_serie_tempete_consecutive"] = np.nan
        out["max_rafale_3j"] = np.nan
        out["energie_vent_cumulee"] = np.nan

    # Direction du vent
    if "DD" in period.columns:
        out["nb_jours_vent_dir_Ouest"] = float(((period["DD"] > 225) & (period["DD"] < 315)).mean(skipna=True))
    else:
        out["nb_jours_vent_dir_Ouest"] = np.nan

    # PRESSION
    if "PMER" in period.columns:
        p = period["PMER"].dropna()

        out["pression_moy_hpa"] = float(p.mean()) if not p.empty else np.nan
        out["jours_basse_pression"] = int((p < BASSE_PRESSION_HPA).sum()) if not p.empty else np.nan
        out["pression_min_hpa"] = float(p.min()) if not p.empty else np.nan

        # Chute max sur 24 h (différence négative la plus forte)
        if len(p) > 1:
            dp = p.diff()  # PMER[j] - PMER[j-1]
            out["max_drop_pression_24h"] = float((-dp).max()) if not dp.dropna().empty else np.nan
        else:
            out["max_drop_pression_24h"] = np.nan

        # Variabilité barométrique
        out["pression_std_hpa"] = float(p.std()) if not p.empty else np.nan

        # Jours très dépressionnaires (seuil plus strict)
        out["nb_jours_depression"] = int((p < TRES_BASSE_PRESSION_HPA).sum()) if not p.empty else np.nan

        # Séquences ≥3 jours sous 1000 hPa
        dep = (p < BASSE_PRESSION_HPA).astype(int)
        if not dep.empty:
            grp = (dep != dep.shift()).cumsum()
            longueurs = dep.groupby(grp).sum()
            out["nb_seq_depression_3j"] = int((longueurs >= 3).sum())
        else:
            out["nb_seq_depression_3j"] = np.nan

        # Jours très creux
        if "PMERMIN" in period.columns:
            pmin = period["PMERMIN"].dropna()
            out["nb_jours_pmermin"] = int((pmin < TRES_BASSE_PRESSION_HPA).sum()) if not pmin.empty else np.nan
        else:
            out["nb_jours_pmermin"] = np.nan

    else:
        out["pression_moy_hpa"] = np.nan
        out["jours_basse_pression"] = np.nan
        out["pression_min_hpa"] = np.nan
        out["max_drop_pression_24h"] = np.nan
        out["pression_std_hpa"] = np.nan
        out["nb_jours_depression"] = np.nan
        out["nb_seq_depression_3j"] = np.nan
        out["nb_jours_pmermin"] = np.nan


    # HUMIDITE
    if "U" in period.columns:
        U = period["U"].dropna()

        out["humidite_moy_pct"] = float(U.mean()) if not U.empty else np.nan
        out["jours_humide_90"] = int((U > 90).sum()) if not U.empty else np.nan

        # Séquences de ≥3 jours consécutifs avec humidité > 90 %
        if not U.empty:
            humide = (U > 90).astype(int)
            grp = (humide != humide.shift()).cumsum()
            longueurs = humide.groupby(grp).sum()
            out["nb_seq_humide_3j"] = int((longueurs >= 3).sum())
        else:
            out["nb_seq_humide_3j"] = np.nan

        # 95ᵉ percentile de l’humidité (jours très humides)
        out["U_95p"] = float(U.quantile(0.95)) if not U.empty else np.nan

    else:
        out["humidite_moy_pct"] = np.nan
        out["jours_humide_90"] = np.nan
        out["nb_seq_humide_3j"] = np.nan
        out["U_95p"] = np.nan

    # COMBINAISONS CRITIQUES

    if all(col in period.columns for col in ["RR1", "FXI"]):
        pluie = period["RR1"].fillna(0)
        vent = vent_kmh(period["FXI"].fillna(0))

        # Jours avec pluie >5 mm ET rafales >60 km/h
        cond_pluie_vent = (pluie > 5) & (vent > 60)
        out["jours_pluie_et_vent_fort"] = int(cond_pluie_vent.sum())

        # Jours de pluie suivant un jour de gel (TN < 0)
        if "TN" in period.columns:
            gel = (period["TN"] < 0)
            pluie_apres_gel = (pluie > 1) & gel.shift(1)
            out["pluie_apres_gel"] = int(pluie_apres_gel.sum())
        else:
            out["pluie_apres_gel"] = np.nan

        # Jours de vent fort suivant 3 jours de pluie cumulée élevée (>10 mm) Cas où le sol est déjà saturé en eau puis subit une tempête.
        pluie_cum3 = pluie.rolling(3, min_periods=1).sum()
        tempete_apres_pluie = (vent > 80) & (pluie_cum3.shift(1) > 10)
        out["tempete_apres_pluie"] = int(tempete_apres_pluie.sum())

        # Indice global des combinaisons extrêmes / Nombre total de jours où au moins une situation extrême s’est produite.
        combis = cond_pluie_vent.astype(int)
        if "TN" in period.columns:
            combis += pluie_apres_gel.astype(int)
        combis += tempete_apres_pluie.astype(int)
        out["nb_combinaisons_critiques"] = int((combis > 0).sum())

    else:
        out["jours_pluie_et_vent_fort"] = np.nan
        out["pluie_apres_gel"] = np.nan
        out["tempete_apres_pluie"] = np.nan
        out["nb_combinaisons_critiques"] = np.nan
    
    return out


def calculer_indicateurs(chemin_dossier: str, periodes: List[Tuple[str, str]]) -> pd.DataFrame:
    df = charger_dossier(chemin_dossier)
    daily = resumer_journalier(df)

    lignes = []
    for start, end in periodes:
        lignes.append(indicateurs_periode(daily, start, end))
    res = pd.DataFrame(lignes)
    return res

def main():

    res = calculer_indicateurs(CHEMIN_DOSSIER, PERIODES)
    out_path = Path(CHEMIN_DOSSIER) / "indicateurs_meteo.xlsx"
    res.to_excel(out_path, index=False)
    print(f"Fichier exporté : {out_path}")

if __name__ == "__main__":
    main()
