#' Rechargement des donnees IFN
#'
#' @encoding UTF-8
#'
#' @description Cette fonction permet de télécharger les données brutes de l'IFN à partir du site
#' https://inventaire-forestier.ign.fr/IMG/zip/. Elle charge les données de 2005 à 2018.
#'
#' @return Cette fonction enregistre dans le dossier data les deux tables IFNarbres.rda et IFNplacettes.rda.
#'
#' @param enrg = si TRUE les 2 tables Arbres et Placettes sont enregistrées sous forme d'archives rda.
#' Sinon la fonction renvoie les deux tables.
#'
#' @import tidyverse
#' @import data.table
#'
#' @examples
#' IFNdata()
#' # ou bien
#' res <- IFNdata(FALSE)
#' IFNarbres <- res$IFNarbres
#' IFNplacettes <- res$IFNplacettes
#'
#'@author BRUCIAMACCHIE Max

#' @export IFNdata
#'

IFNdata <- function (enrg = TRUE) {

  IFNarbres <- data.table()
  IFNplacettes <- data.table()

  # --------- Boucle Import par annee
  rep <- "https://inventaire-forestier.ign.fr/IMG/zip/"
  dates <- c(as.character(2018:2005))

  for (i in 1:length(dates)){
    an = as.integer(substr(dates[i], 1, 4))
    # --------- Telecharger et decompacter
    tempRep <- tempdir()
    temp <- tempfile()
    repTour <- paste0(rep,dates[i],".zip")
    download.file(repTour, temp)
    liste <- unzip(temp, exdir=tempRep)
    if(sum(grepl("/trees_forest", liste))>0) {
      tabArbres <- read.csv2(liste[grepl(paste("/trees_forest",an,sep="_"), liste)])
      tabArbres$Annee <- an
      tabPlacettes <- read.csv2(liste[grepl(paste("plots_forest_",an,sep=""), liste)])
      tabPlacettes$Annee <- an
      OK = TRUE
    }
    if(sum(grepl("/arbres_foret", liste))>0) {
      tabArbres <- read.csv2(liste[grepl("arbres_foret", liste)])
      tabArbres$Annee <- an
      tabPlacettes <- read.csv2(liste[grepl(paste("placettes_foret_",an,sep=""), liste)])
      tabPlacettes$Annee <- an
      OK = TRUE
    }

    # --------- Agregation
    if(OK) {
      IFNarbres <- rbindlist(list(IFNarbres, tabArbres), use.names=T, fill=T)
      IFNplacettes <- rbindlist(list(IFNplacettes, tabPlacettes), use.names=T, fill=T)
      # --------- supression fichier et dossier temporaires
      unlink(temp); unlink(tempRep)
    }

  }
  # --------- Nettoyage
  IFNarbres$ir5 <- as.numeric(as.character(IFNarbres$ir5))
  IFNarbres$v   <- as.numeric(as.character(IFNarbres$v))
  IFNarbres$w   <- as.numeric(as.character(IFNarbres$w))
  # --------- Selection colonnes
  IFNarbres <- IFNarbres %>%
    dplyr::select(idp,a,espar,veget,mortb,acci,ori,mortb,c13,ir5,htot,hdec,v,w,Annee)
  IFNplacettes <- IFNplacettes %>%
    dplyr::select(idp,xl93,yl93,ser,csa,dc,dist,Annee)
  # --------- Creation archive ou return
  if(enrg) {
    usethis::use_data(IFNarbres, overwrite = T)
    usethis::use_data(IFNplacettes, overwrite = T)
  } else {
    out = list(IFNarbres, IFNplacettes)
    names(out) <- c("IFNarbres", "IFNplacettes")
    return(out)
  }
}