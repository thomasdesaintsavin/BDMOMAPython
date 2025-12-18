############################################################
# 1. LIRE LE CSV DES PÉRIODES
############################################################
# -> adapte le nom du fichier à ton cas, par ex :
# "indicateurs_pour_R - par_periode.csv"
############################################################

dfp <- read.csv(
  "indicateurs_pour_R.xlsx - par_periode.csv",   # <--- ton fichier .csv des périodes
  header = TRUE,
  stringsAsFactors = FALSE
)

cat("Aperçu des données par période :\n")
print(dfp)


############################################################
# 2. CONVERSION DES VIRGULES EN POINTS POUR LES NUMÉRIQUES
############################################################
# On garde periode_code en texte, et on convertit tout le reste
############################################################

cols_num <- setdiff(names(dfp), "periode_code")

for (col in cols_num) {
  dfp[[col]] <- as.numeric(gsub(",", ".", dfp[[col]]))
}

cat("\nStructure après conversion :\n")
str(dfp)


############################################################
# 3. ARBRE CART : nb_eboulements ~ indicateurs
############################################################

library(rpart)
library(rpart.plot)

# ---- Choisis ici les indicateurs que tu veux tester ----
# Exemple : un mélange marée / houle / pluie / vent / run-up
vars_cart <- c(
  "marnage_moy_m",
  "IAI",
  "hs_moy",
  "energie_cumulee_Jm2",
  "pluie_cum_mm",
  "jours_vent_fort_60",
  "Run.up.moyen..m.",   # "Run up moyen (m)" dans le CSV
  "TWL.moyen"           # "TWL moyen" dans le CSV
)

# On s'assure de ne garder que ceux qui existent vraiment
vars_cart <- intersect(vars_cart, names(dfp))

# On construit la formule automatiquement :
formule_cart <- as.formula(
  paste("nb_eboulements ~", paste(vars_cart, collapse = " + "))
)

cat("\nFormule CART utilisée :\n")
print(formule_cart)

# ---- Modèle CART ----
mod_cart_periode <- rpart(
  formule_cart,
  data   = dfp,
  method = "anova",    # régression (nb_eboulements numérique)
  control = rpart.control(
    minsplit = 2,      # au moins 2 périodes pour tenter un split
    cp       = 0       # pas de pénalisation (peu de périodes)
  )
)

cat("\n=== ARBRE CART (périodes) ===\n")
print(mod_cart_periode)
cat("\n=== TABLE CP ===\n")
printcp(mod_cart_periode)

# ---- Graphique de l'arbre ----
rpart.plot(
  mod_cart_periode,
  main = "CART par période : nb d'éboulements ~ indicateurs",
  type = 2,      # boîtes complètes
  extra = 1      # affiche la prédiction dans les nœuds
)