
get_zipdata <- function(){
  
  zipfn <- "cache/EucFACE_DUURSMA_GCB_LEAFAREAINDEX.zip"
  
  url <- "http://research-data.westernsydney.edu.au/redbox/verNum1.8-SNAPSHOT/default/detail/52ed5b8c7bd75b71f6e489a1f4b73e8e/EucFACE_DUURSMA_GCB_LEAFAREAINDEX.zip"
  
  if(!file.exists(zipfn)){
    download.file(url, zipfn, mode="wb")
  }
  
  # URL to RDA will go here
  unzip(zipfn, exdir="data", overwrite=TRUE)
  
  # Check if files not corrupted
  md5 <- read.table("data/manifest-md5.txt",stringsAsFactors = FALSE)
  mymd5 <- tools::md5sum(file.path("data", md5[[2]]))
  targetmd5 <- md5[[1]]
  
  if(!all(targetmd5 == mymd5))stop("At least one file was corrupted during download, please redownload!")
  
}



get_facepar <- function(){
  
  facepar <- read.csv("data/data/FACE_RA_P0037_PARAGG_20121016-20150301_L2.csv")
  facepar$DateTime <- as.POSIXct(facepar$DateTime, tz="UTC")
  facepar$Date <- as.Date(facepar$Date)
  
  return(facepar)
}

make_raindaily <- function(df){
  sum6 <- function(x,...)sum(x,...)/6
  summaryBy(Rain_mm_Tot ~ Date, FUN=sum6, na.rm=TRUE, data=df, keep.names=TRUE)
}

# pers. comm. David Ellsworth.
get_sla <- function()52.6

get_ramp <- function(){
  ramp <- read.csv("data/ramp_co2-data.csv", stringsAsFactors = FALSE)
  ramp$DateTime <- as.POSIXct(ramp$Date.time, format="%d/%m/%Y %H:%M", tz="UTC")
  ramp$CO2target <- as.numeric(str_extract(ramp$CO2.target, "[0-9]{2,3}"))
  ramp$Date <- as.Date(ramp$DateTime)
  ramp <- summaryBy(. ~ Date, FUN=mean, na.rm=TRUE, keep.names=TRUE, data=ramp)
return(ramp)
}

get_solvars <- function(){
  
 df <- read.csv("data/data/FACE_RA_P0037_SOLVARS_20120601-20200101_L2.csv")
 df$DateTime <- as.POSIXct(df$DateTime, tz="UTC")

return(df)
}

get_litring <- function(){
  df <- read.csv("data/data/FACE_RA_P0037_LEAFLITTER_20121009-20140814_L2.csv")
  df$Date <- as.Date(df$Date)
  
return(df)
}

get_simplemet <- function(){
  
  df <- read.csv("data/data/FACE_RA_P0037_DAILYMET_20110619-20151026_L2.csv")
  df$Date <- as.Date(df$Date)
  
return(df)
}

get_flatcan <- function(){
  
  df <- read.csv("data/data/FACE_RA_P0037_PHOTOGAPFRAC_20121020-20131022_L2.csv")
  df$Date <- as.Date(df$Date)
  
return(df)
}


agg_flatcan <- function(dfr, by=c("Ring","CO2"), k=0.5, ...){
  
  
  dfr$Date <- as.Date(dfr$Date)
  names(dfr)[names(dfr) == "gapfraction"] <- "Gapfraction"
  
  n <- length
  flatagg <- summaryBy(Gapfraction ~ Ring + Date, data=dfr,
                       FUN=c(mean,sd,n), id=~treatment)
  flatagg$Gapfraction.SE <- with(flatagg, Gapfraction.sd/sqrt(Gapfraction.n))
  
  # Add LAI
  flatagg$LAI <- -log(flatagg$Gapfraction.mean) / k
  
  
  if(by == "Ring")return(flatagg)
  
  if(by == "CO2"){
    dfr <- flatagg[,c("Date","treatment","Gapfraction.mean","LAI")]
    names(dfr)[3] <- "Gapfraction"
    flatagg2 <- summaryBy(Gapfraction + LAI ~ treatment + Date, data=dfr,
                          FUN=c(mean,sd,n))  
    flatagg2$Gapfraction.SE <- with(flatagg2, Gapfraction.sd/sqrt(Gapfraction.n))
    flatagg2$LAI.SE <- with(flatagg2, LAI.sd/sqrt(LAI.n))
    
    return(flatagg2)
  }
  
  
}



add_PARLAI_to_flatcan <- function(df1, df2){
  
  x1 <- split(df1, df1$Ring)
  x2 <- split(df2, df2$Ring)
  
  for(i in 1:length(x2)){
    
    ap <- approxExtrap(x=as.numeric(x1[[i]]$Date),
                       y=x1[[i]]$Gapfraction.mean,
                       xout=as.numeric(x2[[i]]$Date))
    x2[[i]]$Gapfraction.PAR.mean <- ap$y
    
    ap <- approxExtrap(x=as.numeric(x1[[i]]$Date),
                       y=x1[[i]]$LAI,
                       xout=as.numeric(x2[[i]]$Date))
    x2[[i]]$LAI.PAR.mean <- ap$y
  }
  
  df2 <- bind_rows(x2)
return(df2)
}



aggfacegapbyCO2 <- function(df){
  
  SE <- function(x)sd(x)/sqrt(length(x))
  names(df)[names(df) == "Gapfraction.mean"] <- "Gapfraction"
  
  if("LAIanomaly" %in% names(df)){
    dfa <- summaryBy(Gapfraction + LAI  + LAIanomaly ~ Date + treatment, FUN=c(mean,SE), data=df)
  } else {
    dfa <- summaryBy(Gapfraction + LAI ~ Date + treatment, FUN=c(mean,SE), data=df)
  }
  return(dfa)
}


aggFACEPARbyring <- function(df, x=1){
  
  n <- function(x,...)length(x[!is.na(x)])
  facegap <- summaryBy(Gapfraction + Rain_mm_Tot ~ Date + Ring, data=df, FUN=c(mean,sd,n), na.rm=TRUE)
  
  facegap <- facegap[!is.na(facegap$Gapfraction.mean),]
  
  facegap <- merge(facegap, eucface(), by="Ring")
  
  return(facegap)
}



subsetFACEPARbyring <- function(df, minnrHH=4, maxSD=0.05){
  
  # All rings have some observations
  tab <- table(df$Date, df$Ring)
  dats <- as.Date(rownames(tab)[rowSums(tab) == 6])
  
  df$minn <- ave(df$Gapfraction.n, df$Date, FUN=min)
  dats2 <- unique(df$Date[df$minn >= minnrHH])
  
  dats <- as.Date(intersect(dats, dats2), origin="1970-1-1")
  df <- subset(df, Date %in% dats)
  df$minn <- NULL
  
  # find max SD by date
  df$maxSDring <- ave(df$Gapfraction.sd, df$Date, FUN=max, na.rm=TRUE)
  
  # discard days where at least one ring has excessive within-day variance.
  df <- subset(df, maxSDring < maxSD)
  
  # Order
  df <- df[order(df$Date, df$Ring),]
  return(df)
}

make_ba <- function(gapdf, litdf){
  
  lai <- summaryBy(LAI ~ Ring, data=gapdf, FUN=mean, na.rm=T)
  ba <- eucfaceBA()
  ba <- merge(ba,lai)
  ba <- merge(ba, eucface())
  
  # mean LAI for comparison to litter (same Date range)
  lai2 <- summaryBy(LAI ~ Ring, data=subset(gapdf, Date < max(litdf$Date)), na.rm=TRUE, FUN=mean)
  names(lai2)[2] <- "LAI.mean.litterperiod"
  ba <- merge(ba, lai2)
  
  # Litter
  lit <- subset(litdf, !is.na(ndays))
  lagg <- summaryBy(Leaf.mean + dLAIlitter.mean + ndays ~ Ring, FUN=sum, keep.names=TRUE,
                    data=lit)
  trapArea <- 0.1979
  # g m-2 year-1
  lagg$Litter_annual <- (lagg$Leaf.mean / trapArea) * 365.25 / lagg$ndays
  lagg$LAIlitter_annual <- lagg$dLAIlitter.mean * 365.25 / lagg$ndays 
  ba <- merge(ba, lagg[,c("Ring","LAIlitter_annual")])
  
  lmBALAI <- lm(LAI.mean ~ BA, data=ba)
  ba$LAIfromBA <- predict(lmBALAI, ba)
  
  # Leaf lifespan
  ba$LL <- with(ba, LAI.mean.litterperiod / LAIlitter_annual)
  
  return(ba)
}


aggFACEPARbysensor <- function(df, minnrHH=4){
  
  tab <- table(df$Date, df$Ring)
  dats <- as.Date(rownames(tab)[apply(tab,1,function(x)all(x>minnrHH))])
  
  df <- subset(df, Date %in% dats)
  
  facegap <- summaryBy(Gapfraction1 + Gapfraction2 + Gapfraction3 ~ Date + Ring, 
                       data=df, FUN=c(mean,length,sd))
  
  facegap <- merge(facegap, eucface, by="Ring")
  return(facegap)
}




calibrateToDrought <- function(df){
  
  r <- make_dLAI_drought2013(df)
  
  lmfit <- lm(dLAI_litter ~ dLAI_PAR-1, data=r)
  
  return(list(calib=coef(lmfit)[[1]], lmfit=lmfit))
  
}



make_dLAI_drought2013 <- function(df, calib=1){
  
  # Calculate LAI.
  df <- df[!is.na(df$Gapfraction.mean),]
  df$LAI <- calib * with(df, mapply(LAI_Tdiff, Td=Gapfraction.mean))
  
  # diffuse transmittance after mid-July (data two weeks before stable and a bit noisy)
  df1 <- subset(df, Date > as.Date("2013-7-14") & Date < as.Date("2013-11-12"))
  
  # litter fall since early july
  df2 <- subset(litter, Date >= as.Date("2013-7-8") & Date < as.Date("2013-11-12"))

  fits <- smoothplot(Date, LAI, Ring, data=df1, plotit=FALSE)
  
  dats <- range(df1$Date)
  dLAIsm <- c()
  for(i in 1:6){
    dLAIsm[i] <- abs(diff(predict(fits[[i]], data.frame(X=as.numeric(dats), R=paste0("R",i)))))
  }
  
  lit <- subset(df2, Date  > min(Date))
  dLAIlit <- with(lit, tapply(dLAIlitter.mean, Ring, sum))
  return(data.frame(Ring=names(dLAIlit), dLAI_litter=dLAIlit, dLAI_PAR=dLAIsm))
}



calculate_LAI <- function(df,x=1, calib=1){
  
  # Add LAI estimate
  df$LAI <- calib * with(df, mapply(LAI_Tdiff, Td=Gapfraction.mean, x=x))
  
  return(df)
}



splitbydate <- function(dfr, datevec){
  
  datevec <- as.Date(datevec)
  
  l <- list()
  for(i in 2:length(datevec)){
    l[[i]] <- subset(dfr, Date >= datevec[i-1] & Date < datevec[i])
  }
  l[[1]] <- NULL
  
  return(l)
}


make_dLAI_litter <- function(dat, litter, simplemet, kgam=15){
  
  # LAI by ring with smoother
  dat <- makesmoothLAI(dat, kgam=kgam, timestep="1 day")
  
  # Make LAI change, combine with litter fall
  litterDates <- sort(unique(litter$Date))
  dat <- lapply(dat, splitbydate, litterDates)
  
  # Get change in LAI for each inter-litter interval.
  getdlai <- function(x){
    do.call(rbind,lapply(x, function(z){
      n <- nrow(z)
      dLAI <- z$LAIsm[n] - z$LAIsm[1]
      d <- diff(z$LAIsm)
      dnegLAI <- sum(d[d < 0])
      dposLAI <- sum(d[d > 0])
      return(data.frame(dLAI=dLAI, dnegLAI=dnegLAI, dposLAI=dposLAI, LAI=mean(z$LAIsm)))
    }))
  }
  
  soilwater <- simplemet[,c("Date","VWC")]
  soilsp <- splitbydate(soilwater, litterDates) 
  meansw <- data.frame(Date=litterDates[1:(length(litterDates)-1)], 
                       VWC=sapply(soilsp, function(x)mean(x$VWC, na.rm=TRUE)))
  
  
  # r will be a dataframe with litterfall and change in LAI
  r <- list()
  for(i in 1:6){
    r[[i]] <- cbind(data.frame(Date=litterDates[2:length(litterDates)]), getdlai(dat[[i]]))
    r[[i]] <- merge(r[[i]], subset(litter, Ring == paste0("R",i)), by=c("Date"))
  }
  r <- do.call(rbind,r)
  
  # Absolute change in LAI
  r$absdLAI <- with(r, -dnegLAI + dposLAI)
  r$LAIchange <- as.factor(r$dLAI > 0)
  levels(r$LAIchange) <- c("decreasing","increasing")
  r <- merge(r, meansw)
  return(r)
}



analyzeFlat <- function(path, Date, pathout="", reProcess=FALSE, suffix="", ...){
  
  o <- getwd()
  on.exit(setwd(o))
  setwd(path)
  
  
  fk <- paste0("Filekey_",format(Date,"%Y_%m_%d"),".csv")
  fnout <- paste0(pathout, "FACE_flatcan_gapfraction_",format(Date,"%Y_%m_%d"),suffix,".csv")
  if(file.exists(fnout) && !reProcess){
    warning("Output file already exists; data not reanalyzed.")
    return(NULL)
  }
  
  if(!file.exists(fk))
    stop("Filekey does not exist (or wrong filename).")
  
  filekey <- read.csv(fk, stringsAsFactors=FALSE)
  names(filekey) <- tolower(names(filekey))
  
  filekey$filename <- paste0(filekey$file.name, ".JPG")
  ex <- file.exists(filekey$filename)
  
  if(sum(!ex) > 0){
    message("The following files do not exist:")
    print(filekey$filename[!ex])
  }
  
  filekey <- filekey[ex,]
  
  jpgfiles <- filekey$filename
  
  th <- gf <- c()
  
  for(j in 1:length(jpgfiles)){
    im <- readCanPhoto(jpgfiles[j])
    imt <- findThreshold(im, ...)
    
    th[j] <- imt$thresh
    gf[j] <- gapfraction(imt)
    message(j," of ",length(jpgfiles)," : ",round(gf[j],3))
  }
  filekey$threshold <- th
  filekey$gapfraction <- gf
  
  
  setwd(o)
  write.csv(filekey, fnout, row.names=FALSE)
  
  return(invisible(fnout))
}




get_rain <- function(how=c("daily", "raw", "rawmean")){
  
  how <- match.arg(how)
  
  # Rain.
  R1 <- downloadTOA5(filename="FACE_R1_T1_Rain", tryoffline=TRUE)
  R3 <- downloadTOA5(filename="FACE_R3_T1_Rain", tryoffline=TRUE)
  R4 <- downloadTOA5(filename="FACE_R4_T1_Rain", tryoffline=TRUE)
  R1$Ring <- "R1"
  R3$Ring <- "R3"
  R4$Ring <- "R4"
  names(R3)[3] <- "Rain_mm_Tot"
  rain <- rbind(R1, R3, R4)

  # Data is 15-minutely, make 30min.
  rain <- as.data.frame(dplyr::summarize(group_by(rain,DateTime=nearestTimeStep(DateTime,30),Ring),
                                         Rain_mm_Tot=sum(Rain_mm_Tot),
                                         Source_rain=first(Source)))
  
  if(how == "daily"){
    rain$Date <- as.Date(rain$DateTime)
    rainagg <- summaryBy(Rain_mm_Tot ~ Ring + Date, FUN=sum, data=rain, keep.names=TRUE)
    names(rainagg)[3] <-"Rain"
    rainw <- reshape(rainagg, direction="wide", timevar="Ring", idvar="Date")
    
    ros <- downloadTOA5("ROS_WS_Table15", tryoffline=TRUE)
    rosrain <- summaryBy(Rain_mm_Tot ~ Date, FUN=sum, data=ros, keep.names=TRUE)
    names(rosrain)[2] <- "Rain.ROS"
    
    rain <- merge(rosrain, rainw, all=TRUE)
  }
  
  if(how == "rawmean"){
    
    # Average across the three rings.
    rain <- as.data.frame(dplyr::summarize(group_by(rain, DateTime),
                                           Rain_mm_Tot = mean(Rain_mm_Tot, na.rm=TRUE)))
    
  }
  
  return(rain)
}


get_rosTair <- function(){
  
  d <- downloadTOA5(c("ROS_WS","Table05min"), maxnfiles=500, tryoffline=TRUE)
  
  d <- as.data.frame(dplyr::summarize(group_by(d, Date),
                                      Tair=mean(AirTC_Avg, na.rm=TRUE),
                                      Tmin=min(AirTC_Avg, na.rm=TRUE),
                                      Tmax=max(AirTC_Avg, na.rm=TRUE),
                                      RH=mean(RH, na.rm=TRUE),
                                      RHmin=min(RH, na.rm=TRUE),
                                      RHmax=max(RH, na.rm=TRUE)
                                      ))
return(d)  
}

get_soilwater <- function(how=c("mean","byring")){
  
  how <- match.arg(how)
  
  meanVWC <- function(dfr){
    vwccols <- grep("VWC_",names(dfr))
    dfr <- dfr[,vwccols]
    dfr[dfr > 1] <- NA
    rowMeans(dfr, na.rm=TRUE)
  }
  
  soilw <- downloadTOA5("SoilVars", maxnfiles=500, tryoffline=TRUE)
  soilw$Ring <- as.factor(paste0("R",  str_extract(soilw$Source, "[0-9]")))
  
  if(how == "mean"){
    soilwd <- summaryBy(. ~ Date, FUN=mean, keep.names=TRUE, data=soilw, na.rm=TRUE)
    soilwd <- data.frame(Date=soilwd[,c("Date")], VWC=meanVWC(soilwd))
  } 
  if(how == "byring"){
  
    soilwd <- summaryBy(. ~ Ring + Date, FUN=mean, keep.names=TRUE, data=soilw, na.rm=TRUE)
    soilwd <- data.frame(Date=soilwd$Date, Ring=soilwd$Ring, VWC=meanVWC(soilwd))
    soilwd <- merge(soilwd, eucface())
  }
  
  return(soilwd)
}


getROSrain <- function(getnewdata=TRUE,
                       filename="output/data/ROS_rain_daily_all.csv"){
  
  if(getnewdata){
    
    rosmet <- downloadTOA5("ROS_WS_Table15min", maxnfiles=200, tryoffline=TRUE)
    rosmet <- rosmet[!duplicated(rosmet$DateTime),]
    
    rosmet$Date <- as.Date(rosmet$DateTime)
    rosmet <- aggregate(Rain_mm_Tot ~ Date, FUN=sum, data=rosmet, na.rm=TRUE)
    names(rosmet)[2] <- "Rain_daily"
    
    write.csv(rosmet,filename,row.names=FALSE)
    
  } else {
    if(file.exists(filename)){
      rosmet <- read.csv(filename)
      rosmet$Date <- as.Date(rosmet$Date)
    } else {
      stop("File does not exist - first run with newdata=TRUE")
    }
  }
  return(rosmet)
}




makeCloudy <- function(df,
                       Fdiff_cutoff = 0.95,   # minimum diffuse fraction to include a halfhour
                       PARabovecutoff = 10,
                       PARbelowcutoff = 1400, # cannot have very high PAR when it is very cloudy
                       minSolarElevation = 10,
                       bysensor=FALSE,
                       addManualCloudyDays=TRUE,
                       PAR0varname = "LI190SB_PAR_Den_Avg"){  
  
  
  
  # Add solar vars
  solVars <- get_solvars()
  
  df <- merge(df, solVars[,c("DateTime","sunelevation")], all.x=TRUE, all.y=FALSE)
  
  # Toss nighttime data. 
  df <- subset(df, sunelevation > minSolarElevation)
    
  # Fdiff , fraction diffuse radiation.
  df$Fdiff <- with(df, DiffuseSS / TotalSS)
  
  if(addManualCloudyDays){
    
    # 1. Make Fdiff for manually selected cloudydays, for period before eddy was recording data.
    addManualClouddays <- function(df,cd){
      
      df$hourtime <- hour(df$DateTime) + minute(df$DateTime)/60
      for(i in 1:nrow(cd)){
        cloudy <- df$Date == cd$Date[i] & df$hourtime >= cd$starthour[i] & df$hourtime <= cd$endhour[i]
        df$Fdiff[cloudy] <- 0.9999
      }
      return(df)
    }
    df <- addManualClouddays(df, cloudydays())
  }
  
  #2. Select all half hours that are cloudy.
  df <- subset(df, Fdiff > Fdiff_cutoff)
  df <- df[df[,PAR0varname] > PARabovecutoff & 
            df[,PAR0varname] < PARbelowcutoff,]
  
  # Subset where PARbelow is not zero (small subset, must be bad values)
  notneg <- function(x)is.na(x) || x > 0
  df <- subset(df, notneg(PAR_Den_1_Avg) & notneg(PAR_Den_2_Avg) & notneg(PAR_Den_3_Avg))
  
  if(!bysensor){
    # Calculate gapfraction
    df$PARbelow <- rowMeans(df[,c("PAR_Den_1_Avg","PAR_Den_2_Avg","PAR_Den_3_Avg")],
                                   na.rm=TRUE)
    df$Gapfraction <- df$PARbelow / df[,PAR0varname]
    
  } else {
    df$Gapfraction1 <- df$PAR_Den_1_Avg / df[,PAR0varname]
    df$Gapfraction2 <- df$PAR_Den_2_Avg / df[,PAR0varname]
    df$Gapfraction3 <- df$PAR_Den_3_Avg / df[,PAR0varname]
  }
  
  
  return(df)
}


make_litter <- function(trapArea=0.1979,  # m2
                       SLA=43,    # cm2 g-1
                       what=c("agg","byring")
                       
){
  
  what <- match.arg(what)
  
  
  dfr1 <- downloadCSV("FACE_P0017_RA_Litter_20121001-20131231-R.csv")[,1:9]
  
  #dfr1 <- read.csv("cache/FACE_P0017_RA_Litter_20121001-20131231-R.csv")[,1:9]
  dfr1$Date <- as.character(dfr1$Date)
  dfr1$Date <- as.Date(dfr1$Date)
  
  # Part 2 - not on HIEv just yet.
  # dfr2 <- read.csv("data/FACE_P0017_RA_Litter_20140101-20140228-R.csv")[,1:9]
  dfr2 <- read.csv("data/FACE_P0017_RA_Litter_20140101-20140814-R.csv", 
                   stringsAsFactors=FALSE)[,1:9]
  names(dfr2) <- gsub("..g.","",names(dfr2))
  
  dfr2$Leaf[which(dfr2$Leaf == "82,784")] <- "82.784"
  dfr2$Leaf <- as.numeric(as.character(dfr2$Leaf))
  dfr2$Date <- as.Date(dfr2$Date, format = "%d/%m/%Y")
  
  
  names(dfr1) <- names(dfr2)
  dfr <- rbind(dfr1,dfr2)
  
  names(dfr)[1] <- "Ring"
  dfr$Ring <- paste0("R", dfr$Ring)
  
  dfr$Date <- as.Date(dfr$Date)
  dfr <- merge(dfr, eucface())
  
  dfr$dLAIlitter <- with(dfr, (Leaf / trapArea) * SLA * 10^-4)
  
  if(what == "byring"){
    
    return(dfr[,c("Date","Ring","Trap","Leaf","dLAIlitter","treatment")])
    
  } else {
    
    # Average
    n <- function(x,...)length(x[!is.na(x)])
    litagg <- summaryBy(Leaf + dLAIlitter ~ Ring + Date, FUN=c(mean,sd,n),na.rm=TRUE, 
                        data=dfr, id=~treatment)
    
    litagg$n <- litagg$LEAF.n
    litagg$LEAF.n <- litagg$dLAIlitter.n <- NULL
    
    dats <- sort(unique(litagg$Date))
    datdf <- data.frame(Date=dats, ndays=c(NA,diff(dats)))
    litagg <- merge(litagg, datdf)
    
    return(litagg)
  }
}


litterbyring <- function(dfr){
  
  n <- function(x,...)length(x[!is.na(x)])
  litagg <- summaryBy(Leaf + dLAIlitter ~ Ring + Date, FUN=c(mean,sd,n),na.rm=TRUE, 
                      data=dfr, id=~treatment)
  
  litagg$n <- litagg$LEAF.n
  litagg$LEAF.n <- litagg$dLAIlitter.n <- NULL
  
  dats <- sort(unique(litagg$Date))
  datdf <- data.frame(Date=dats, ndays=c(NA,diff(dats)))
  litagg <- merge(litagg, datdf)
 
return(litagg) 
}


agglitter <- function(dfr){
  
  names(dfr) <- gsub(".mean","",names(dfr))
  se <- function(x)sd(x, na.rm=TRUE)/sqrt(length(x[!is.na(x)]))
  
  dfra <- summaryBy(Leaf + dLAIlitter ~ treatment + Date, FUN=c(mean,se), data=dfr)
  
  return(dfra)
}





makeFACEPAR <- function(endDate){

  # Get previously compiled PARAGG from HIEv
  PARAGG <- downloadCSV("P0037_RA_PARAGG", tryoffline=TRUE)
  # Delete _v1
  PARAGG <- PARAGG[!grepl("_v1", PARAGG$Source),]
  
  # Date
  PARAGG$Date <- as.Date(PARAGG$DateTime)
  
  # One bad row
  PARAGG$PAR_Den_2_Avg[PARAGG$Ring == "R4" & PARAGG$Date == as.Date("2013-9-8")] <- NA
  
  PARAGG <- subset(PARAGG, Date <= endDate)
  
  return(PARAGG)
}




makesmoothLAI <- function(dat, timestep="3 days", kgam=15, how=c("byring","mean")){
  
  how <- match.arg(how)
  
  if(how == "mean"){
    
    x <- dat
    x <- x[order(x$Date),]
    gamfit <- smoothplot(as.numeric(Date),LAI,data=x,kgam=kgam, plotit=FALSE)
    
    dfr <- data.frame(X=as.numeric(seq.Date(min(x$Date), max(x$Date), by=timestep)))
    dfr$LAIsmooth <- predict(gamfit[[1]],dfr)
    names(dfr)[1] <- "Date"
    dfr$Date <- as.Date(dfr$Date, origin="1970-1-1")
    
    dfr$dLAI <- c(NA, diff(dfr$LAIsmooth))
    dfr$ndays <- c(NA, diff(dfr$Date))
    return(dfr)
    
  }
  
  if(how == "byring"){
    rings <- split(dat, dat$Ring)
    smoothlai <- lapply(rings, function(x){
      
      x <- x[order(x$Date),]
      
      gamfit <- smoothplot(as.numeric(Date),LAI,data=x,kgam=kgam, plotit=FALSE)
      
      dfr <- data.frame(X=as.numeric(seq.Date(min(x$Date), max(x$Date), by=timestep)))
      dfr$LAIsmooth <- predict(gamfit[[1]],dfr)
      names(dfr)[1] <- "Date"
      dfr$Date <- as.Date(dfr$Date, origin="1970-1-1")
      
      dfr$dLAI <- c(NA, diff(dfr$LAIsmooth))
      dfr$ndays <- c(NA, diff(dfr$Date))
      return(dfr)
    })
  }
  
  return(smoothlai)
}



get_hawkrain <- function(){
  
  rain <- read.csv("data/IDCJAC0009_067021_1800_Data.csv")[,3:6]
  rain$Date <- as.Date(with(rain, ISOdate(Year,Month,Day)))
  
  names(rain)[4] <- "Rain"
return(rain)
}


read_pook1984 <- function(){
  
  dat <- read.csv("data/pook1984_figure5.csv")
  
  loss <- dat[seq(1,(nrow(dat)-1),by=2),]
  prod <- dat[seq(2,nrow(dat),by=2),]
  names(loss)[3] <- "loss"
  dat <- cbind(loss, prod[,3])
  names(dat)[4] <- "prod"
  
  # calibration to paper
  cal <- 0.3 / 91
  dat$prod <- cal * dat$prod
  dat$loss <- cal * dat$loss
  
  dat$dLAI <- with(dat, prod - loss)
  
return(dat)
}



