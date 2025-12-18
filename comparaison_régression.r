############################################################
# CHARGEMENT DES DONNÉES
############################################################

df <- read.csv("indicateurs_pour_R.xlsx - par_cellule.csv",
               header = TRUE, stringsAsFactors = FALSE)

# Conversion des virgules en points
colonnes <- c("Taux.de.recul..m.an.",
              "moyenne.fracturation.par.cellule.TFT",
              "moyenne.fracturation.par.cellule.MFT")

for (col in colonnes) {
  df[[col]] <- as.numeric(gsub(",", ".", df[[col]]))
}


############################################################
# FONCTIONS MÉTRIQUES + MODELES
############################################################

R2_func <- function(y, pred) {
  1 - sum((y - pred)^2) / sum((y - mean(y))^2)
}

RMSE <- function(y, pred) sqrt(mean((y - pred)^2))
MAE  <- function(y, pred) mean(abs(y - pred))

# Fonction testant trois modèles pour un indicateur donné
eval_models <- function(x, y) {
  
  # ========== 1. Model linéaire ==========
  mod_lin <- lm(y ~ x)
  pred_lin <- predict(mod_lin)
  
  # ========== 2. LOESS ==========
  mod_loess <- loess(y ~ x, span = 0.75)
  pred_loess <- predict(mod_loess)
  
  # ========== 3. Spline ==========
  mod_spline <- smooth.spline(x, y)
  pred_spline <- predict(mod_spline, x)$y
  
  # Tableau résultats
  data.frame(
    modele = c("Linéaire", "LOESS", "Spline"),
    R2     = c(R2_func(y, pred_lin),
               R2_func(y, pred_loess),
               R2_func(y, pred_spline)),
    RMSE   = c(RMSE(y, pred_lin),
               RMSE(y, pred_loess),
               RMSE(y, pred_spline)),
    MAE    = c(MAE(y, pred_lin),
               MAE(y, pred_loess),
               MAE(y, pred_spline))
  )
}


############################################################
# 1️⃣ ANALYSE POUR CHAQUE INDICATEUR
############################################################

res_Taux <- eval_models(df$Taux.de.recul..m.an., df$nb_éboulements)
res_TFT  <- eval_models(df$moyenne.fracturation.par.cellule.TFT, df$nb_éboulements)
res_MFT  <- eval_models(df$moyenne.fracturation.par.cellule.MFT, df$nb_éboulements)

cat("\n===== Taux de recul =====\n")
print(res_Taux)

cat("\n===== Fracturation TFT =====\n")
print(res_TFT)

cat("\n===== Fracturation MFT =====\n")
print(res_MFT)

View(res_Taux)
View(res_TFT)
View(res_MFT)



############################################################
# 2️⃣ TABLEAU GLOBAL RÉCAPITULATIF
############################################################

res_Taux$indicateur <- "Taux de recul"
res_TFT$indicateur  <- "Fracturation TFT"
res_MFT$indicateur  <- "Fracturation MFT"

results_global <- rbind(res_Taux, res_TFT, res_MFT)
results_global <- results_global[, c("indicateur", "modele", "R2", "RMSE", "MAE")]

# Arrondir pour la lecture
results_global$R2   <- round(results_global$R2, 3)
results_global$RMSE <- round(results_global$RMSE, 2)
results_global$MAE  <- round(results_global$MAE, 2)

cat("\n============ TABLEAU GLOBAL ============\n")
print(results_global)

View(results_global)