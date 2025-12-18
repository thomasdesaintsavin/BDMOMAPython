############################################################
# 0. LIRE LES DONNÉES
############################################################

# Adapter le nom de fichier si besoin
df <- read.csv(
  "indicateurs_pour_R.xlsx - par_cellule.csv",
  header = TRUE,
  stringsAsFactors = FALSE
)

cat("Aperçu :\n")
print(df)

############################################################
# 1. CONVERSION DES VIRGULES -> POINTS POUR LES NUMÉRIQUES
############################################################

# R va renommer automatiquement :
# "Taux de recul (m/an)"                 -> Taux.de.recul..m.an.
# "taille cellule hydrosédimentaire (km)"-> taille.cellule.hydrosédimentaire..km.
# "moyenne fracturation par cellule TFT" -> moyenne.fracturation.par.cellule.TFT
# "moyenne fracturation par cellule MFT" -> moyenne.fracturation.par.cellule.MFT

cols_num_virgule <- c(
  "Taux.de.recul..m.an.",
  "moyenne.fracturation.par.cellule.TFT",
  "moyenne.fracturation.par.cellule.MFT"
)

for (col in cols_num_virgule) {
  df[[col]] <- as.numeric(gsub(",", ".", df[[col]]))
}

cat("\nStructure après conversion :\n")
str(df)


############################################################
# 2. ARBRE CART (REGRESSION TREE)
############################################################

library(rpart)
library(rpart.plot)

mod_cart <- rpart(
  nb_éboulements ~
    Taux.de.recul..m.an. +
    moyenne.fracturation.par.cellule.TFT +
    moyenne.fracturation.par.cellule.MFT,
  data = df,
  method = "anova",  # régression (valeurs numériques)
  control = rpart.control(
    minsplit = 2,  # au moins 2 obs pour tenter un split
    cp       = 0   # pas de pénalisation, avec 6 lignes on laisse l’arbre libre
  )
)

cat("\n=== ARBRE CART ===\n")
print(mod_cart)
cat("\n=== COMPLEXITY PARAMETER TABLE ===\n")
printcp(mod_cart)

# Graphique de l’arbre
rpart.plot(
  mod_cart,
  main = "Arbre CART : nb éboulements ~ indicateurs",
  type = 2,        # boîtes complètes
  extra = 1        # affiche la prédiction dans les noeuds
)

