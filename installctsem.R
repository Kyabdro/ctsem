#unload packages
message('This is best run from a fresh R / Rstudio session, with no other R sessions running')
go<-readline('Continue? Y/N: ')
if(go %in% c('Y','y')){
packs <- c(names(sessionInfo()$otherPkgs), names(sessionInfo()$loadedOnly))
packs <- packs[!packs%in% c("stats","graphics","grDevices","utils","datasets","methods","base",'remotes','tools','glue')]
if(length(packs) > 0){ 
  message('Unloading packages -- if any problems occur, please try this from a fresh R session')
  trycount <- 0
  while(length(packs)  > 0){
    trycount <- trycount + 1
    if(trycount > 100) {
      message('Unable to unload all packages, trying to continue...')
      break
    }
    newpacks <- c()
    for(packi in 1:length(packs)){
      u=try(unloadNamespace(packs[packi]),silent = TRUE)
      if(class(u) %in% 'try-error') newpacks <- c(newpacks,packs[packi])
    }
    packs <- newpacks
    Sys.sleep(.1)
  }
}

# detachAllPackages <- function() {
#   
#   basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
#   
#   package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
#   
#   package.list <- setdiff(package.list,basic.packages)
#   
#   if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
#   
# }
# 
# detachAllPackages()


#install / load build packages
buildpacks <- c('devtools','pkgbuild','remotes')
for(bi in buildpacks){
  if(!requireNamespace(bi)) install.packages(bi)
}
require(pkgbuild)
try(pkgbuild::check_build_tools())

#create / update makevars if needed
if(.Platform$OS.type == "windows"){
cat('Do you already have a MAKEVARS file configured for rstan usage? If unsure, type N')
mv <- readline('Y / N ?')
while(!mv %in% c('Y','N','y','n')) {
  cat('Do you already have a MAKEVARS file configured for rstan usage? If unsure, type N')
  mv <- readline('Y / N ?')
}
if(mv == 'N' || mv =='n'){ #create makevars
  dotR <- file.path(Sys.getenv("HOME"), ".R")
  if (!file.exists(dotR)) dir.create(dotR)
  M <- file.path(dotR, ifelse(.Platform$OS.type == "windows", "Makevars.win", "Makevars"))
  if (!file.exists(M)) file.create(M)
  cat("\nCXX14FLAGS = -mtune=native -O1 -Wno-ignored-attributes -Wno-deprecated-declarations",
    if( grepl("^darwin", R.version$os)) "CXX14FLAGS += -arch x86_64 -ftemplate-depth-256" else
      if (.Platform$OS.type == "windows") "CXX14FLAGS+= -Wno-ignored-attributes -Wno-deprecated-declarations" else
  "CXX14FLAGS += -fPIC",
    file = M, sep = "\n", append = TRUE)
}
}

if(.Platform$OS.type == "windows"){
  if(!suppressMessages(pkgbuild::has_rtools())) message('Waiting for Rtools installation to complete...')
  while(! suppressMessages(pkgbuild::has_rtools())){
    Sys.sleep(.1)
  }
}

#check for new versions of critical packages
old = old.packages()
for(importantpack in c('StanHeaders','rstan')){
  if(importantpack %in% old)  message('Updating ',importantpack)
    install.packages(importantpack,dependencies = TRUE)
}

#install ctsem from github
Sys.setenv(R_REMOTES_NO_ERRORS_FROM_WARNINGS='true')
remotes::install_github('cdriveraus/ctsem', upgrade='never',INSTALL_opts = "--no-multiarch", 
  dependencies = c("Depends", "Imports"))
}
