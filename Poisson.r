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
# 3. MODELE DE POISSON COMPLET
############################################################

modele_pois <- glm(
  nb_éboulements ~ 
      Taux.de.recul..m.an. +
      moyenne.fracturation.par.cellule.TFT +
      moyenne.fracturation.par.cellule.MFT,
  data = df,
  family = poisson(link = "log")
)

cat("\n==== RÉGRESSION DE POISSON (modèle complet) ====\n")
print(summary(modele_pois))



############################################################
# 4. Tester la surdispersion (Poisson vs quasi-Poisson)
############################################################

disp <- sum(residuals(modele_pois, type="pearson")^2) / modele_pois$df.residual
cat("\nDispersion =", disp, "\n")

if (disp > 2) {
  cat("⚠️ Surdispersion détectée → quasi-Poisson utilisé\n")
  modele_final <- glm(
    nb_éboulements ~ 
      Taux.de.recul..m.an. +
      moyenne.fracturation.par.cellule.TFT +
      moyenne.fracturation.par.cellule.MFT,
    data = df,
    family = quasipoisson(link = "log")
  )
} else {
  cat("✔ Pas de surdispersion → Poisson retenu\n")
  modele_final <- modele_pois
}

cat("\n==== MODÈLE FINAL ====\n")
print(summary(modele_final))



############################################################
# 5. Pseudo-R² de McFadden (modèle complet)
#    (peut être NA car modèle saturé avec 6 points et 3 variables)
############################################################

logLik_mod  <- logLik(modele_final)
logLik_null <- logLik(update(modele_final, . ~ 1))

R2_McFadden <- 1 - as.numeric(logLik_mod / logLik_null)

cat("\nPseudo-R² de McFadden (modèle complet) =", R2_McFadden, "\n")



############################################################
# 6. Corrélations Pearson & Spearman (comme dans la capture)
############################################################

corr_pearson <- data.frame(
  Indicateur = c("Taux de recul", "Fracturation TFT", "Fracturation MFT"),
  Pearson = c(
    cor(df$nb_éboulements, df$Taux.de.recul..m.an., method = "pearson"),
    cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.TFT, method = "pearson"),
    cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.MFT, method = "pearson")
  ),
  Spearman = c(
    cor(df$nb_éboulements, df$Taux.de.recul..m.an., method = "spearman"),
    cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.TFT, method = "spearman"),
    cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.MFT, method = "spearman")
  )
)

cat("\n==== Corrélations (Pearson & Spearman) ====\n")
print(corr_pearson[order(-abs(corr_pearson$Pearson)), ])

# Petit barplot des corrélations de Pearson
barplot(corr_pearson$Pearson,
        names.arg = corr_pearson$Indicateur,
        col = c("steelblue","darkgreen","purple"),
        ylim = c(-1,1),
        main = "Corrélations de Pearson avec les éboulements",
        ylab = "r (Pearson)")
abline(h = 0, col = "red", lty = 2)



############################################################
# 7. RÉGRESSIONS INDICATEUR → NB ÉBOULEMENTS (effet isolé)
#    + β_poisson et IRR_poisson = exp(β1)
############################################################

par(mfrow=c(1,3))

# ---- 7.1 Taux de recul ----
x1 <- seq(min(df$Taux.de.recul..m.an.),
          max(df$Taux.de.recul..m.an.),
          length.out=100)

pred1 <- predict(
  modele_final,
  newdata = data.frame(
    Taux.de.recul..m.an. = x1,
    moyenne.fracturation.par.cellule.TFT = mean(df$moyenne.fracturation.par.cellule.TFT),
    moyenne.fracturation.par.cellule.MFT = mean(df$moyenne.fracturation.par.cellule.MFT)
  ),
  type="response"
)

plot(df$Taux.de.recul..m.an., df$nb_éboulements,
     pch=19, col="blue",
     xlab="Taux de recul (m/an)",
     ylab="Nb éboulements",
     main="Éboulements ~ Taux de recul")
lines(x1, pred1, col="red", lwd=2)


# ---- 7.2 TFT ----
x2 <- seq(min(df$moyenne.fracturation.par.cellule.TFT),
          max(df$moyenne.fracturation.par.cellule.TFT),
          length.out=100)

pred2 <- predict(
  modele_final,
  newdata = data.frame(
    Taux.de.recul..m.an. = mean(df$Taux.de.recul..m.an.),
    moyenne.fracturation.par.cellule.TFT = x2,
    moyenne.fracturation.par.cellule.MFT = mean(df$moyenne.fracturation.par.cellule.MFT)
  ),
  type="response"
)

plot(df$moyenne.fracturation.par.cellule.TFT, df$nb_éboulements,
     pch=19, col="darkgreen",
     xlab="Fracturation TFT",
     ylab="Nb éboulements",
     main="Éboulements ~ TFT")
lines(x2, pred2, col="red", lwd=2)


# ---- 7.3 MFT ----
x3 <- seq(min(df$moyenne.fracturation.par.cellule.MFT),
          max(df$moyenne.fracturation.par.cellule.MFT),
          length.out=100)

pred3 <- predict(
  modele_final,
  newdata = data.frame(
    Taux.de.recul..m.an. = mean(df$Taux.de.recul..m.an.),
    moyenne.fracturation.par.cellule.TFT = mean(df$moyenne.fracturation.par.cellule.TFT),
    moyenne.fracturation.par.cellule.MFT = x3
  ),
  type="response"
)

plot(df$moyenne.fracturation.par.cellule.MFT, df$nb_éboulements,
     pch=19, col="purple",
     xlab="Fracturation MFT",
     ylab="Nb éboulements",
     main="Éboulements ~ MFT")
lines(x3, pred3, col="red", lwd=2)

par(mfrow=c(1,1))



############################################################
# 8. GRAPHIQUES PAR SOUS-CELLULE (secteurs)
############################################################

x <- df$cellule
secteurs <- df$secteur

par(mfrow=c(1,3))

# Nb éboulements
plot(x, df$nb_éboulements, type="b", pch=19,
     xaxt="n", xlab="Sous-cellule", ylab="Nb éboulements",
     main="Éboulements par sous-cellule")
axis(1, at=x, labels=secteurs, las=2)
abline(lm(nb_éboulements ~ x, data=df), col="red", lwd=2, lty=2)

# TFT
plot(x, df$moyenne.fracturation.par.cellule.TFT, type="b", pch=19,
     xaxt="n", xlab="Sous-cellule", ylab="Fracturation TFT",
     main="TFT par sous-cellule")
axis(1, at=x, labels=secteurs, las=2)
abline(lm(moyenne.fracturation.par.cellule.TFT ~ x, data=df), col="red", lwd=2, lty=2)

# Taux de recul
plot(x, df$Taux.de.recul..m.an., type="b", pch=19,
     xaxt="n", xlab="Sous-cellule", ylab="Taux de recul (m/an)",
     main="Taux de recul par sous-cellule")
axis(1, at=x, labels=secteurs, las=2)
abline(lm(Taux.de.recul..m.an. ~ x, data=df), col="red", lwd=2, lty=2)

par(mfrow=c(1,1))



############################################################
# 9. TENDANCES COMBINÉES (normalisées 0–1)
############################################################

scale01 <- function(v) (v - min(v)) / (max(v) - min(v))

plot(x, scale01(df$nb_éboulements), type="b", pch=19,
     ylim=c(0,1), xaxt="n",
     xlab="Sous-cellule", ylab="Valeurs normalisées",
     main="Comparaison normalisée par sous-cellule")
axis(1, at=x, labels=secteurs, las=2)

lines(x, scale01(df$moyenne.fracturation.par.cellule.TFT), type="b", pch=17)
lines(x, scale01(df$Taux.de.recul..m.an.), type="b", pch=15)

legend("topleft",
       legend=c("Éboulements", "TFT", "Taux de recul"),
       pch=c(19,17,15), bty="n")



############################################################
# 10. Fonction R² McFadden "safe" (pour les modèles simples)
############################################################

safe_R2 <- function(model) {
  ll_mod  <- try(logLik(model), silent = TRUE)
  ll_null <- try(logLik(update(model, . ~ 1)), silent = TRUE)
  
  if (inherits(ll_mod, "try-error") || inherits(ll_null, "try-error")) return(NA)
  if (is.na(ll_mod) || is.na(ll_null)) return(NA)
  
  1 - as.numeric(ll_mod / ll_null)
}



############################################################
# 11. Modèles de Poisson univariés
#     + β, IRR, pseudo-R², corrélation Pearson & Spearman
############################################################

formules_simples <- list(
  "Taux de recul"    = nb_éboulements ~ Taux.de.recul..m.an.,
  "Fracturation TFT" = nb_éboulements ~ moyenne.fracturation.par.cellule.TFT,
  "Fracturation MFT" = nb_éboulements ~ moyenne.fracturation.par.cellule.MFT
)

# On récupère les corrélations une fois pour toutes
corr_P <- c(
  "Taux de recul"    = cor(df$nb_éboulements, df$Taux.de.recul..m.an.,                        method = "pearson"),
  "Fracturation TFT" = cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.TFT,        method = "pearson"),
  "Fracturation MFT" = cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.MFT,        method = "pearson")
)

corr_S <- c(
  "Taux de recul"    = cor(df$nb_éboulements, df$Taux.de.recul..m.an.,                        method = "spearman"),
  "Fracturation TFT" = cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.TFT,        method = "spearman"),
  "Fracturation MFT" = cor(df$nb_éboulements, df$moyenne.fracturation.par.cellule.MFT,        method = "spearman")
)

resultats_stats <- data.frame(
  Indicateur     = character(),
  Beta           = numeric(),
  IRR            = numeric(),
  Effet_pct      = numeric(),
  R2_McFadden    = numeric(),
  R2_Deviance    = numeric(),
  Corr_Pearson   = numeric(),
  Corr_Spearman  = numeric(),
  stringsAsFactors = FALSE
)

for (nom in names(formules_simples)) {
  mod <- glm(formules_simples[[nom]], data = df, family = poisson)
  
  beta1 <- coef(mod)[2]              # coefficient de l'indicateur
  IRR   <- exp(beta1)                # IRR = exp(beta1)
  effet <- (IRR - 1) * 100           # effet en %

  R2_MF  <- safe_R2(mod)                            # pseudo-R² McFadden
  R2_dev <- 1 - mod$deviance / mod$null.deviance    # pseudo-R² basé déviance
  
  resultats_stats <- rbind(
    resultats_stats,
    data.frame(
      Indicateur    = nom,
      Beta          = beta1,
      IRR           = IRR,
      Effet_pct     = effet,
      R2_McFadden   = R2_MF,
      R2_Deviance   = R2_dev,
      Corr_Pearson  = corr_P[nom],
      Corr_Spearman = corr_S[nom]
    )
  )
}

cat("\n===== Résumé des modèles de Poisson univariés =====\n")
print(resultats_stats[order(-resultats_stats$R2_McFadden), ])



############################################################
# 12. Afficher les tableaux dans la fenêtre de plots
############################################################

library(gridExtra)
library(grid)

# Tableau des corrélations (Pearson & Spearman)
grid.newpage()
grid.table(corr_pearson)

# Tableau complet Poisson + corrélations
grid.newpage()
grid.table(resultats_stats[order(-resultats_stats$R2_McFadden), ])

############################################################
# TABLEAU 1 : Corrélations (Pearson & Spearman)
############################################################

vars <- c(
  "Taux.de.recul..m.an.",
  "moyenne.fracturation.par.cellule.TFT",
  "moyenne.fracturation.par.cellule.MFT"
)

results_corr <- data.frame(
  variable      = vars,
  corr_pearson  = sapply(vars, function(v)
    cor(df$nb_éboulements, df[[v]], method="pearson")),
  corr_spearman = sapply(vars, function(v)
    cor(df$nb_éboulements, df[[v]], method="spearman"))
)

# arrondir
results_corr$corr_pearson  <- round(results_corr$corr_pearson, 3)
results_corr$corr_spearman <- round(results_corr$corr_spearman, 3)

# trier par corrélation absolue
results_corr <- results_corr[order(-abs(results_corr$corr_pearson)), ]

# afficher tableau
View(results_corr)



############################################################
# TABLEAU 2 : Pseudo-R² (McFadden + Déviance)
############################################################

results_R2 <- data.frame(
  variable      = character(),
  R2_McFadden   = numeric(),
  R2_Deviance   = numeric()
)

for (v in vars) {
  form <- as.formula(paste("nb_éboulements ~", v))
  mod  <- glm(form, data=df, family=poisson)
  
  # McFadden
  ll_mod  <- logLik(mod)
  ll_null <- logLik(update(mod, . ~ 1))
  R2_MF   <- 1 - as.numeric(ll_mod / ll_null)
  
  # basé sur la déviance
  R2_dev  <- 1 - (mod$deviance / mod$null.deviance)
  
  results_R2 <- rbind(
    results_R2,
    data.frame(
      variable    = v,
      R2_McFadden = R2_MF,
      R2_Deviance = R2_dev
    )
  )
}

# arrondir
results_R2$R2_McFadden <- round(results_R2$R2_McFadden, 3)
results_R2$R2_Deviance <- round(results_R2$R2_Deviance, 3)

# trier par R²
results_R2 <- results_R2[order(-results_R2$R2_McFadden), ]

# afficher tableau
View(results_R2)

############################################################
# 14. Barplot des corrélations
############################################################

barplot(
  results_corr$corr_pearson,
  names.arg = results_corr$variable,
  col = c("steelblue","darkred","purple"),
  main = "Corrélations Pearson avec nb éboulements",
  las=2
)
abline(h=0, lwd=2)