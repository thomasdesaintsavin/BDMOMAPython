############################################################
# 1. Lire le CSV
############################################################

df <- read.csv(
  "indicateurs_pour_R.xlsx - par_cellule.csv",
  header = TRUE,
  stringsAsFactors = FALSE
)

cat("\nAperçu des données :\n")
print(df)
cat("\nStructure initiale :\n")
str(df)



############################################################
# 2. Conversion des colonnes caractère -> numérique
############################################################

colonnes_num_char <- c(
  "Taux.de.recul..m.an.",
  "moyenne.fracturation.par.cellule.TFT",
  "moyenne.fracturation.par.cellule.MFT"
)

for (col in colonnes_num_char) {
  df[[col]] <- as.numeric(gsub(",", ".", df[[col]]))
}

cat("\nStructure après conversion :\n")
str(df)



############################################################
# 3. Corrélations (Tableau 1)
############################################################

vars <- c(
  "Taux.de.recul..m.an.",
  "moyenne.fracturation.par.cellule.TFT",
  "moyenne.fracturation.par.cellule.MFT"
)

results_corr <- data.frame(
  variable      = vars,
  corr_pearson  = sapply(vars, function(v)
    cor(df$nb_éboulements, df[[v]], method = "pearson")),
  corr_spearman = sapply(vars, function(v)
    cor(df$nb_éboulements, df[[v]], method = "spearman"))
)

# Arrondir + trier par corrélation absolue
results_corr$corr_pearson  <- round(results_corr$corr_pearson, 3)
results_corr$corr_spearman <- round(results_corr$corr_spearman, 3)
results_corr <- results_corr[order(-abs(results_corr$corr_pearson)), ]

cat("\n===== TABLEAU 1 : Corrélations (Pearson & Spearman) =====\n")
print(results_corr)

# Affichage style tableur
View(results_corr)



############################################################
# 4. Modèles binomiale négative (MASS::glm.nb)
############################################################

library(MASS)

# Modèle complet (3 indicateurs)
modele_nb_complet <- glm.nb(
  nb_éboulements ~ Taux.de.recul..m.an. +
    moyenne.fracturation.par.cellule.TFT +
    moyenne.fracturation.par.cellule.MFT,
  data = df
)

cat("\n==== RÉGRESSION BINOMIALE NÉGATIVE (modèle complet) ====\n")
print(summary(modele_nb_complet))

# Pseudo-R² de McFadden pour le modèle complet
ll_nb   <- logLik(modele_nb_complet)
ll_null <- logLik(update(modele_nb_complet, . ~ 1))
R2_McFadden_complet <- 1 - as.numeric(ll_nb / ll_null)

cat("\nPseudo-R² de McFadden (modèle complet, NB) =",
    round(R2_McFadden_complet, 3), "\n")



############################################################
# 5. Modèles NB univariés + pseudo-R² (Tableau 2)
############################################################

results_R2_NB <- data.frame(
  variable     = character(),
  beta         = numeric(),
  IRR          = numeric(),
  effet_pct    = numeric(),
  theta        = numeric(),
  R2_McFadden  = numeric(),
  R2_Deviance  = numeric(),
  stringsAsFactors = FALSE
)

for (v in vars) {
  form <- as.formula(paste("nb_éboulements ~", v))
  mod  <- glm.nb(form, data = df)
  s    <- summary(mod)
  
  beta  <- s$coefficients[2, 1]
  IRR   <- exp(beta)
  effet <- (IRR - 1) * 100
  
  # paramètre de dispersion (theta) de la NB
  theta_nb <- mod$theta
  
  # Pseudo-R² McFadden
  ll_mod  <- logLik(mod)
  ll_null <- logLik(update(mod, . ~ 1))
  R2_MF   <- 1 - as.numeric(ll_mod / ll_null)
  
  # Pseudo-R² basé sur la déviance
  R2_dev  <- 1 - (mod$deviance / mod$null.deviance)
  
  results_R2_NB <- rbind(
    results_R2_NB,
    data.frame(
      variable    = v,
      beta        = beta,
      IRR         = IRR,
      effet_pct   = effet,
      theta       = theta_nb,
      R2_McFadden = R2_MF,
      R2_Deviance = R2_dev
    )
  )
}

# Arrondir pour lecture
results_R2_NB$beta        <- round(results_R2_NB$beta, 4)
results_R2_NB$IRR         <- round(results_R2_NB$IRR, 3)
results_R2_NB$effet_pct   <- round(results_R2_NB$effet_pct, 2)
results_R2_NB$theta       <- round(results_R2_NB$theta, 3)
results_R2_NB$R2_McFadden <- round(results_R2_NB$R2_McFadden, 3)
results_R2_NB$R2_Deviance <- round(results_R2_NB$R2_Deviance, 3)

# Trier par R² McFadden décroissant
results_R2_NB <- results_R2_NB[order(-results_R2_NB$R2_McFadden), ]

cat("\n===== TABLEAU 2 : Modèles NB univariés (β, IRR, R²) =====\n")
print(results_R2_NB)

# Affichage style tableur
View(results_R2_NB)