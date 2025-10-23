# Indicateurs Importants à Analyser et Travailler

## 1. Indicateurs de Fracturation

### 1.1 Densité de Fractures
**Définition**: Nombre de fractures par unité de longueur (fractures/mètre)

**Source**: `fracturation - Feuille 1.csv`

**Variables clés**:
- `densité (fract/m)`: Densité calculée par segment
- `fracturation (fract/km)`: Densité normalisée par kilomètre

**Intérêt**: La densité de fractures est directement corrélée à la susceptibilité aux éboulements. Plus la densité est élevée, plus le risque d'instabilité de la falaise est important.

**Valeurs observées**:
- Minimum: 0,0167 fractures/m (16,67 fract/km)
- Maximum: 0,133 fractures/m (133,33 fract/km)

**Analyse recommandée**:
- Cartographie de la densité de fractures par cellule hydrosédimentaire
- Corrélation avec la fréquence des éboulements
- Identification des zones à haute densité nécessitant une surveillance renforcée

### 1.2 Espacement entre Fractures
**Définition**: Distance moyenne entre deux fractures consécutives (mètres)

**Variables clés**:
- `Espacement petit (m)`: Distance minimale observée
- `Espacement grand (m)`: Distance maximale observée

**Intérêt**: L'espacement entre fractures influence la taille potentielle des blocs susceptibles de se détacher. Un espacement plus petit indique une fracturation plus intense et donc une instabilité accrue.

**Valeurs observées**:
- Espacement petit: 5 à 70 mètres
- Espacement grand: 10 à 70 mètres

**Analyse recommandée**:
- Calcul de l'espacement moyen par segment
- Relation entre espacement et volume des éboulements
- Évolution temporelle de l'espacement (si données disponibles)

### 1.3 Type de Fracture
**Définition**: Classification morphologique des fractures

**Types identifiés**:
- **TFT** (Fractures Transversales au Front de Taille): Fractures perpendiculaires au front de falaise
- **MFT** (Fractures Multiples au Front de Taille): Réseau de fractures complexe et multidirectionnel

**Intérêt**: Le type de fracture influence le mécanisme de rupture. Les TFT favorisent les éboulements en blocs, tandis que les MFT peuvent générer des éboulements plus fragmentés.

**Analyse recommandée**:
- Distribution spatiale des types de fractures
- Corrélation type de fracture / type d'éboulement
- Analyse de la dangerosité relative par type

---

## 2. Indicateurs d'Éboulements

### 2.1 Fréquence Temporelle des Éboulements
**Définition**: Nombre d'événements d'éboulement par unité de temps

**Source**: `eboulements.csv` et `resume_Evolution_Cap_Le_Treport_2000-2022.csv`

**Variables clés**:
- `annee`: Année de l'événement
- `annee_dig`: Année de numérisation
- `annee_evac`: Année d'évacuation des matériaux

**Intérêt**: La fréquence des éboulements permet d'identifier les périodes de forte activité érosive et d'établir des tendances temporelles.

**Périodes documentées**:
- Événements historiques: 1947, 1977, 1978, 1982, 1985, 1992
- Période récente: 2000-2022
- Pics d'activité: 2008-2012

**Analyse recommandée**:
- Calcul du taux annuel d'éboulements par cellule
- Identification des tendances (augmentation, stabilisation, diminution)
- Corrélation avec facteurs météorologiques (si données disponibles)
- Analyse de la saisonnalité des événements

### 2.2 Surface Affectée par les Éboulements
**Définition**: Superficie totale des zones d'éboulement (m²)

**Variable clé**:
- `shape_area`: Surface en mètres carrés

**Intérêt**: La surface affectée permet d'évaluer l'ampleur de l'érosion et de calculer les volumes de matériaux mobilisés.

**Analyse recommandée**:
- Calcul de la surface cumulée par cellule et par période
- Évolution temporelle de la surface moyenne par événement
- Identification des événements majeurs (surface > seuil critique)
- Estimation du recul moyen de la falaise

### 2.3 Périmètre d'Éboulement
**Définition**: Longueur du contour de la zone d'éboulement (mètres)

**Variable clé**:
- `shape_leng`: Périmètre en mètres

**Intérêt**: Le périmètre, combiné à la surface, permet de caractériser la forme des éboulements (allongés vs compacts) et d'identifier les mécanismes de rupture.

**Analyse recommandée**:
- Calcul de l'indice de compacité (4π × surface / périmètre²)
- Relation entre forme et type de fracture
- Identification des morphologies caractéristiques

### 2.4 État d'Évacuation
**Définition**: Statut de l'évacuation des matériaux éboulés

**Modalités**:
- "pas encore evacue": Matériaux encore présents au pied de falaise
- Année précise: Année d'évacuation des matériaux
- "impossible a dire car eboulements par dessus": Événements multiples superposés

**Intérêt**: L'état d'évacuation influence la protection naturelle au pied de falaise. Les matériaux non évacués peuvent offrir une protection temporaire contre l'érosion marine.

**Analyse recommandée**:
- Cartographie des zones avec matériaux non évacués
- Analyse du rôle protecteur des éboulis
- Planification des opérations d'évacuation prioritaires

---

## 3. Indicateurs Lithologiques

### 3.1 Type de Formation Géologique
**Définition**: Nature de la roche affleurante

**Source**: `litho-aditional-info.csv`

**Formations identifiées**:
- **Cénomanien** (Crétacé inférieur)
- **Turonien** (Crétacé moyen)
- **Coniacien** (Crétacé moyen)
- **Santonien** (Crétacé supérieur)
- **Campanien** (Crétacé supérieur)

**Intérêt**: Chaque formation a des propriétés mécaniques et une résistance à l'érosion différentes. La lithologie est un facteur déterminant dans la vitesse de recul de la falaise.

**Analyse recommandée**:
- Corrélation lithologie / fréquence d'éboulements
- Corrélation lithologie / densité de fractures
- Identification des formations les plus vulnérables
- Cartographie des zones à risque selon la lithologie

### 3.2 Longueur d'Affleurement
**Définition**: Étendue linéaire de chaque formation le long du littoral (mètres)

**Variable clé**:
- `length`: Longueur en mètres

**Intérêt**: Permet de quantifier l'exposition de chaque formation et de prioriser les zones selon leur vulnérabilité lithologique.

**Distribution observée**:
- Cénomanien: ~26 600 m
- Turonien: ~147 200 m
- Coniacien: ~231 100 m
- Santonien: ~215 700 m
- Campanien: ~36 000 m

**Analyse recommandée**:
- Calcul du ratio surface éboulée / longueur d'affleurement par formation
- Identification des formations prioritaires pour la surveillance

---

## 4. Indicateurs Spatiaux

### 4.1 Cellule Hydrosédimentaire
**Définition**: Découpage du littoral en unités fonctionnelles homogènes

**Source**: `resume_Cellules_Hydrosedimentaires_France.csv`

**Cellules de la zone d'étude**:
1. Cap d'Antifer – Fécamp (29 km)
2. Fécamp – Paluel (22 km)
3. Paluel – St-Valéry-en-Caux (11 km)
4. St-Valéry-en-Caux – Dieppe (36 km)
5. Dieppe – Penly (20 km)
6. Penly – Le Tréport (22 km)

**Longueur totale**: 140 km

**Intérêt**: Les cellules permettent une analyse comparative et une gestion différenciée du risque selon les secteurs.

**Analyse recommandée**:
- Calcul d'indicateurs synthétiques par cellule:
  - Densité moyenne de fractures
  - Fréquence d'éboulements
  - Surface totale érodée
  - Taux de recul annuel moyen
- Classement des cellules par niveau de risque
- Priorisation des actions de surveillance et de protection

### 4.2 Localisation Géographique Précise
**Définition**: Coordonnées planimétriques de chaque événement ou segment

**Variables clés**:
- `x`: Coordonnée X (Lambert 93)
- `y`: Coordonnée Y (Lambert 93)

**Intérêt**: Permet la cartographie fine des phénomènes et l'analyse spatiale (autocorrélation, clusters, etc.)

**Analyse recommandée**:
- Cartographie SIG de tous les événements
- Analyse de l'autocorrélation spatiale des éboulements
- Identification de points chauds (hotspots)
- Création de zones tampons autour des événements majeurs

---

## 5. Indicateurs Composites Recommandés

### 5.1 Indice de Vulnérabilité Multi-critères
**Définition**: Indicateur synthétique combinant plusieurs facteurs de risque

**Composantes suggérées**:
- Densité de fractures (poids: 30%)
- Fréquence d'éboulements (poids: 30%)
- Type de lithologie (poids: 20%)
- Surface moyenne des éboulements (poids: 20%)

**Méthode de calcul**:
```
IVM = 0,30 × Densité_norm + 0,30 × Fréquence_norm + 0,20 × Litho_score + 0,20 × Surface_norm
```

**Intérêt**: Permet un classement objectif des secteurs et une communication efficace du risque.

### 5.2 Taux de Recul de la Falaise
**Définition**: Vitesse moyenne de recul du trait de côte (m/an)

**Méthode de calcul**:
```
Taux_recul = Σ Surface_éboulements / (Longueur_falaise × Période_observation)
```

**Intérêt**: Indicateur essentiel pour les projections à long terme et l'aménagement du territoire.

### 5.3 Indice de Concentration Temporelle
**Définition**: Mesure de la régularité ou de l'irrégularité des événements dans le temps

**Méthode de calcul**: Coefficient de variation de Gini sur la distribution temporelle

**Intérêt**: Permet d'identifier si les éboulements se produisent de manière régulière ou par épisodes concentrés (crises érosives).

---

## 6. Priorités d'Analyse

### Phase 1: Analyse Descriptive
1. Statistiques descriptives par cellule et par indicateur
2. Cartographie thématique de tous les indicateurs
3. Séries temporelles des éboulements (2000-2022)

### Phase 2: Analyse Exploratoire
1. Matrices de corrélation entre indicateurs
2. Analyse de clusters spatiaux (zones homogènes)
3. Tests statistiques de tendances temporelles

### Phase 3: Modélisation
1. Modèle de prédiction de la fréquence d'éboulements
2. Modèle de susceptibilité spatiale
3. Scénarios prospectifs de recul de falaise

### Phase 4: Aide à la Décision
1. Cartographie des zones prioritaires d'intervention
2. Système d'alerte précoce
3. Recommandations pour la gestion du risque

---

## 7. Données Complémentaires Nécessaires

Pour une analyse complète, il serait pertinent d'intégrer:

1. **Données météorologiques**: Précipitations, tempêtes, gel-dégel (influence sur la fracturation)
2. **Données marégraphiques**: Niveaux d'eau, hauteur de houle (érosion marine au pied)
3. **Données démographiques**: Population exposée, infrastructures critiques
4. **Données historiques étendues**: Photographies aériennes anciennes, cartes topographiques
5. **Données géotechniques**: Essais mécaniques sur les roches, propriétés hydrauliques

---

## Conclusion

Les indicateurs présentés constituent une base solide pour l'analyse du risque d'éboulement des falaises normandes. L'approche recommandée combine:

- **Analyse multi-échelle**: du segment local (quelques dizaines de mètres) à la cellule hydrosédimentaire (plusieurs dizaines de kilomètres)
- **Approche multifactorielle**: intégration des facteurs lithologiques, structuraux, morphologiques et temporels
- **Vision dynamique**: prise en compte de l'évolution temporelle des phénomènes

La mise en œuvre de cette analyse permettra d'améliorer significativement la gestion du risque côtier dans cette région à fort enjeu patrimonial et humain.
