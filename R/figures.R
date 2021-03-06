
my_co2cols <- function()c("blue","red")
# my_ringcols <- function()rich.colors(6)

my_ringcols <- function(){
  
#   reds <- brewer.pal(5,"Reds")[3:5]
#   blues <- brewer.pal(5,"Blues")[3:5]
#   c(reds[1],blues[1:2],reds[2:3],blues[3])
  
  c("#FB6A4A","#6BAED6","#3182BD","#DE2D26","#A50F15","#08519C")
}

converttoJPEGs <- function(){
  pdfs <- dir("output/figures", pattern="[.]pdf",full.names=TRUE)
  for(i in 1:length(pdfs)){
    fn <- gsub("[.]pdf",".jpg",pdfs[i])
    shell(paste("convert -density 600",pdfs[i],fn))
  }
}

# Smoothed gap fraction raw data
figure1 <- function(df, ramp){
  
  palette(my_co2cols())
  
  l <- layout(matrix(c(1,2), ncol=1), heights=c(0.8,2))
  xl <- c(min(ramp$Date), max(df$Date))
  
  par(mar=c(0.5,5,1,2), cex.axis=0.9, cex.lab=1.1, las=1, yaxs="i", tcl=0.2,
      mgp=c(3,1,0))
  with(ramp, plot(Date, CO2target, type='l', col="dimgrey", lwd=2, axes=FALSE, ylim=c(0,160),
                  xlim=xl,
                  xlab="", ylab=expression(Target~Delta*C[a]~(ppm))))
  timeseries_axis(FALSE)
  segments(x0=max(ramp$Date), x1=xl[2], y0=150, y1=150, col="dimgrey", lwd=2)
  axis(2, at=seq(0,150,by=30))
  box()
  plotlabel("(a)", "topleft", inset.x=0.04)
  
  par(mar=c(3,5,0.5,2), cex.axis=0.9, cex.lab=1.1, yaxs="i")
  
  smoothplot(Date, Gapfraction.mean, g=Ring, data=df, k=18,axes=FALSE,
             ylim=c(0,0.4),
             xlab="",xlim=xl, npred=201,
             ylab=expression(tau[d]~~("-")),
             pointcols=rep("grey",8), linecols=my_ringcols())
  
  timeseries_axis()
  
  axis(2)
  box()
  
  d1 <- as.Date("2013-7-14")
  d2 <- as.Date("2013-11-12")
  Y <- 0.38
  arrows(x0=d1, x1=d2, y0=Y, y1=Y, code=3, length=0.06)
  text(y=Y, x=d2 + 10, "Calibration", pos=4, cex=0.8)
  
  legend("bottomleft", as.character(1:6), lty=1, bty='n',
         col=my_ringcols(), title="Ring", cex=0.8, lwd=2)
  plotlabel("(b)", "topleft", inset.x=0.04)
}


figure2 <- function(df,
                    xlim=NULL, ylim=NULL,
                    legend=TRUE,
                    ylab=expression(italic(L)~~(m^2~m^-2)),
                    cex.lab=1.1, cex.axis=0.8, cex.legend=0.7,
                    legendwhere="topleft",
                    setpar=TRUE,
                    axisline=3,
                    horlines=TRUE,
                    greyrect=FALSE,
                    addpoints=TRUE){
    
  if(setpar)par(cex.axis=cex.axis, mar=c(3,5,2,5), las=1, cex.lab=1.2, yaxs="i", tcl=0.2)
  par(cex.lab=cex.lab)
  
  if(is.null(xlim))xlim <- with(df, c(min(Date)-15, max(Date)+15))
  if(is.null(ylim))ylim <- c(0,2.8)
  
  # switch levels so that ambient will be on top
  df$treatment <- factor(df$treatment, levels=c("elevated","ambient"))
  
  smoothplot(Date, LAI, g=treatment, R="Ring", ylim=ylim, xlim=xlim, 
             ylab=ylab, xlab="",
             data=df, kgam=18, axes=FALSE,
             pointcols=rev(my_co2cols()),
             linecols=rev(my_co2cols()),
             polycolor=rev(c(alpha("royalblue",0.7),alpha("pink",0.7))))
  
  l <- legend("topleft", c("Ambient","Elevated"), title=expression(italic(C)[a]~treatment), 
              fill=my_co2cols(), bty="n", cex=cex.legend)
  axis(2, at=seq(0,2.8,by=0.4))
  box()
  
  timeseries_axis()  
}


figure3 <- function(df){

  Cols <- c("darkorange","forestgreen")
  
  df$Y <- with(df, dLAI * 30.5/ndays)
  df$X <- with(df, dLAIlitter.mean * 30.5/ndays)
  
  dfup <- df[df$LAIchange == "increasing",]
  dfdown <- df[df$LAIchange == "decreasing",]
  
  par(mar=c(5,5,2,2), cex.lab=1.1, cex.axis=0.9, las=1, xaxs="i", yaxs="i", tcl=0.2)
  with(dfup, plot(X, Y, pch=c(19,21)[treatment],
               col=Cols[LAIchange],
               xlab=expression(P[L]~~(m^2~m^-2~mon^-1)),
               xlim=c(0,0.6),
               ylim=c(-0.3,0.5),
               ylab=expression(Delta*italic(L)~~(m^2~m^-2~mon^-1))))
  with(dfdown, points(X, Y, pch=c(17,24)[treatment],
                  col=Cols[LAIchange]))
  
  abline(h=0, lty=5)
  abline(0,-1)
  abline(0,1)
  predline(lm(Y ~ X, data=dfup), col=Cols[2])
  predline(lm(Y ~ X, data=dfdown), col=Cols[1])
  box()
  
  l <- legend("bottomright", c(expression(Delta*italic(L) < 0),
                               expression(Delta*italic(L) > 0)), 
              pt.bg=Cols, bty='n', cex=0.8, pch=c(24,21))
  
  legend(l$rect$left - l$rect$w, l$rect$top, 
         c(expression(a*italic(C)[a]),expression(e*italic(C)[a])), pch=c(19,21), bty='n', cex=0.8, pt.cex=1)
  
}

figure4 <- function(dLAIlitter){
  da <- summaryBy(. ~ Date + treatment, FUN=mean, data=dLAIlitter, keep.names=TRUE)
  
  da$laprod <- with(da, 30.5 * (dLAI+dLAIlitter.mean)/ndays)
  da$lit <- with(da, 30.5 * dLAIlitter.mean/ndays)
  
  par(mar=c(3,5,2,2), cex.lab=1.1,tcl=0.2,las=1)
  with(subset(da, treatment == "ambient"), plot(Date, laprod, type='l', col="blue",
                                                lwd=2,
                                                axes=FALSE,xlab="",
                                                ylab=expression("Leaf or litter production"~(m^2~m^-2~mon^-1)),
                                                ylim=c(-0.05,0.8)))
  with(subset(da, treatment == "elevated"), lines(Date, laprod, col="red", lwd=2))
  
  with(subset(da, treatment == "ambient"), lines(Date, lit, col="blue", lty=5, lwd=2))
  with(subset(da, treatment == "elevated"), lines(Date, lit, col="red", lty=5, lwd=2))
  abline(h=0, col="darkgrey")
  axis(2)
  box()
  timeseries_axis()
  l <- legend("topleft", c("Leaf production","Litter production"), lty=c(1,5), bty='n')
  legend(l$rect$left + l$rect$w, l$rect$top, 
         c(expression(a*italic(C)[a]),expression(e*italic(C)[a])),
         col=my_co2cols(), lty=1, bty='n')
  
}


figure5 <-  function(df){

  par(mar=c(5,5,2,2), cex.lab=1.2, xaxs="i", yaxs="i", mfrow=c(1,2), tcl=0.2)
  
  LLs <- seq(0.8,2,by=0.1)
  
  with(df, plot(LAI.mean.litterperiod, LAIlitter_annual, pch=19, cex=1.2, col=my_ringcols(),
                ylab=expression(Litter~production~~(m^2~m^-2~yr^-1)),
                xlab=expression(bar(italic(L))~~(m^2~m^-2)),
                panel.first={
                  for(z in LLs)abline(0,1/z,col="grey", lty=5)
                },
                xlim=c(1.2,2.2), ylim=c(1.2,2.2)))
  plotlabel("(a)", "topright")
  legend("topleft", as.character(1:6), pch=19, bg="white", box.col="white",
         col=my_ringcols(), title="Ring", cex=0.8)
  box()
  x <- c(2.05, 2.05,2.05,1.965,1.83)
  lls <- seq(1.3,0.9,by=-0.1)
  b1 <- 1/lls
  y <- b1*x
  text(x,y,pos=4, labels=as.character(lls), cex=0.75, col="darkgrey",
       font=3)
  text(1.68, y[length(y)], "LL = ", font=3, cex=0.75, col="darkgrey", pos=4)
  
  with(df, plot(as.numeric(treatment), LL, axes=FALSE, xlim=c(0,3), ylim=c(0.5,1.5),
                pch=19, col=my_ringcols(), xlab="",cex=1.2,
                ylab="Leaf lifespan (yr)"))
  box()
  axis(2)
  axis(1, at=1:2, labels=c(expression(a*C[a]), expression(e*C[a])))
  
  tt <- t.test(LL ~ treatment, data=ba)
  pval <- format(tt$p.value, digits=3)
  legend("topleft", legend=bquote(italic(p) == .(pval)),
         bty="n")
  
  
  plotlabel("(b)", "topright")
}


figure6 <- function(df, simplemet, kgam=18){
    
  xin <- 0.02 # for panel label x inset
  
  dfa <- summaryBy(LAI ~ Date, data=df, FUN=mean, keep.names=TRUE)
  
  xl <- as.Date(c("2012-6-1","2015-3-1"))
  
  par(mfrow=c(4,1), mar=c(0,7,5,6), cex.lab=1.3, las=1, mgp=c(4,1,0),yaxs="i",tcl=0.2)
  
  # panel a (LAI)
  smoothplot(Date, LAI, data=dfa, kgam=kgam, pointcols="dimgrey", linecols="black", 
             xlim=xl,
             ylab=expression(italic(L)~~(m^2~m^-2)),
             ylim=c(1,2.4), axes=FALSE)
  timeseries_axis(FALSE)
  axis(2)
  box()
  plotlabel("(a)","topleft", inset.x=xin)
  
  # panel b (dLAI/dt)
  par(mar=c(0,7,1.5,6), tcl=0.2)
  
  df$Time <- as.numeric(df$Date - min(df$Date))
  g <- gamm(LAI ~ s(Time, k=kgam), random = list(Ring=~1), data=df)
  
  plotCIdate(g, df, axes=FALSE,xlab="",xlim=xl,
       ylim=c(-0.016, 0.016),
       ylab=expression(d*italic(L)/dt~(m^2~m^-2~d^-1)))
  abline(h=0)
  
  timeseries_axis(FALSE)
  axis(2)
  box()
  plotlabel("(b)","topleft", inset.x=xin)

  segments(x0=flushingdates()-10, x1=flushingdates()+7,
           y0=0.014, y1=0.014, lwd=2) 
  
  # panel c
  par(mar=c(1.5,7,1.5,6), tcl=0.2)
  with(subset(simplemet, Date > xl[1]), 
       plot(Date, VWC, type='l', lwd=2, xlim=xl, ylim=c(0,0.4), axes=FALSE,
            col="cornflowerblue",
            ylab=expression(SWC~~(m^3~m^-3))))

  timeseries_axis(FALSE)
  axis(2)
  box()
  par(new=TRUE)
  with(simplemet, plot(Date, Rain_mm_Tot, type='h', ylim=c(0,120), xlim=xl,
                           axes=FALSE, ann=FALSE))
  axis(4)
  mtext(expression(Rain~(mm~day^-1)), line=3, side=4, las=0, cex=0.9)
  plotlabel("(c)","topleft", inset.x=xin)
  
  # panel d
  par(mar=c(5,7,0,6), tcl=0.2)
  smoothplot(Date, Tair, data=subset(simplemet, Date > xl[1]), 
             kgam=25, pointcols=alpha("grey",0.8), linecols="black",axes=FALSE,
             ylab=expression(T[air]~~(degree*C)), 
             xlab="",
             ylim=c(0,30), xlim=xl)
  timeseries_axis(TRUE)
  axis(2)
  box()
  plotlabel("(d)","topleft", inset.x=xin)
  
}



figureSI1 <- function(litring, df){
  
  # Litter fall per ring during 2013 drought with SE
  df2 <- subset(litring, Date >= as.Date("2013-7-8") & Date < as.Date("2013-11-12"))  
  dfa <- summaryBy(dLAIlitter ~ Ring + Trap, FUN=sum, na.rm=TRUE, data=df2)
  se <- function(x)sd(x)/sqrt(length(x))
  dft <- summaryBy(dLAIlitter.sum ~ Ring, FUN=c(mean,se), data=dfa)
  
  # anova(lm(dLAIlitter.sum ~ Ring, data=dfa))
  
  # Change in gap fraction per ring
  df <- facegap_cloudy_byring
  df1 <- subset(df, Date > as.Date("2013-7-14") & Date < as.Date("2013-11-12"))
  
  df1$numDate <- with(df1, as.numeric(Date - min(Date)))
  df1$taud_0 <- with(df1, ave(Gapfraction.mean, Ring, FUN=function(x)x[which.min(Date)]))
  df1$deltagapfrac <- with(df1, Gapfraction.mean - taud_0)
  
  # Get CI on increase in gap fraction from linear regression
  lms <- lapply(split(df1, df1$Ring),
                function(x)lm(Gapfraction.mean ~ as.numeric(Date-min(Date)),
                              data=x))
  
  ndays <- as.numeric(max(df1$Date) - min(df1$Date))
  
  delta_gapfr_mu <- ndays * sapply(lms, coef)[2,]
  cis <- sapply(lms, confint, 2)
  delta_gapfr_ci <- cis*ndays
  
  
  # sort, ambient left, elevated right
  ind <- c(2,3,6,1,4,5)
  
  # plot
  par(mfrow=c(2,1), mar=c(0,0,0,0),
      oma=c(5,5,1,1), cex.lab=1.2, tcl=0.2)
  suppressWarnings(plotCI(1:6, delta_gapfr_mu[ind], 
                          ui=delta_gapfr_ci[2,][ind],
                          li=delta_gapfr_ci[1,][ind],
                          col=my_ringcols()[ind], pch=15,
                          ylim=c(0,0.2), 
                          axes=FALSE))
  abline(h=mean(delta_gapfr_mu), lty=5)
  axis(1, labels=FALSE)
  axis(2)
  box()
  plotlabel("(a)", "topleft", inset.x=0.04)
  
  suppressWarnings(plotCI(1:6, dft$dLAIlitter.sum.mean[ind], 
                          uiw=2*dft$dLAIlitter.sum.se[ind],
                          col=my_ringcols()[ind], pch=15,
                          axes=FALSE,
                          ylim=c(0,1.1)))
  abline(h=mean(dft$dLAIlitter.sum.mean), lty=5)
  axis(1, at=1:6, labels=as.character(ind))
  axis(2)
  plotlabel("(b)", "topleft", inset.x=0.04)
  box()
  mtext(side=2, at=0.75, text=expression(Delta*tau[d]), line=3, outer=TRUE,
        cex=1.2)
  mtext(side=2, at=0.25, text=expression(P[L]~~(m^2~m^-2)),
        line=3, outer=TRUE, cex=1.2)
  mtext(side=1, at=0.5, text="Ring", outer=TRUE, line=3, cex=1.2)
  
}  


figureSI2 <- function(df){
  
  par(mfrow=c(1,2), mar=c(5,5,2,2), cex.axis=0.9, tcl=0.2)
  plotit <- function(df){
    with(df, plot(LAI, LAI.PAR.mean, 
                  ylab=expression(L~from~tau[d]~~(m^2~m^-2)),
                  xlab=expression(L~from~canopy~photos~~(m^2~m^-2)),
                  pch=19, col=my_ringcols()[Ring],
                  panel.first=predline(lm(LAI.PAR.mean ~ LAI, data=df), lty=5),
                  xlim=c(0.8,2.2), ylim=c(0.8,2.2)))
    abline(0,1)
    
    ds <- split(df, df$Ring)
    for(i in 1:6)predline(lm(LAI.PAR.mean ~ LAI, data=ds[[i]]), 
                          col=my_ringcols()[i], poly=FALSE)

    box()
  }
  
  plotit(df)
  plotlabel("(a)", "topleft")
  
  legend("bottomright", as.character(1:6), lty=1, bty='n', pch=19,
         col=my_ringcols(), title="Ring", cex=0.8, lwd=1)
  
  # Panel b : optimized
  df <- agg_flatcan(flatcan, by="Ring", k=kopt)
  df <- add_PARLAI_to_flatcan(facegap_cloudy_byring,df)
  
  plotit(df)
  plotlabel("(b)", "topleft")
  
}


figureSI3 <- function(df1, df2){
  
  Cols <- c("grey49","black")
  
  dfa1 <- summaryBy(Gapfraction.mean ~ Date, data=df1, FUN=mean, keep.names=TRUE)
  dfa2 <- summaryBy(Gapfraction.mean ~ Date, data=df2, FUN=mean, keep.names=TRUE)
  
  par(mar=c(3,5,2,2), tcl=0.2, cex.lab=1.1, mar=c(3,5,2,2))
  smoothplot(Date, Gapfraction.mean, data=df2, kgam=18, 
             pointcols=alpha(Cols[1],0.5), linecols=Cols[1],
             ylim=c(0,0.4), axes=FALSE,
             xlab="", ylab=expression(tau~~("-")))
  smoothplot(Date, Gapfraction.mean, data=df1, kgam=18, 
             add=TRUE, pointcols=alpha(Cols[2],0.5),
             linecols=Cols[2])
  timeseries_axis(TRUE)
  axis(2)
  box()
  legend("bottomleft", c(expression("Diffuse only"~(tau[d])),"All data"), 
         pch=19, col=rev(Cols), bty='n')
  
}


figureSI4 <- function(df){
  
  par(mar=c(5,5,2,2), cex.lab=1.2,xaxs="i", yaxs="i", tcl=0.2, las=1)
  with(df, plot(BA, LAI.mean, pch=19, cex=1.2, col=my_ringcols(),
                xlab=expression(Basal~area~~(m^2~ha^-1)),
                ylab=expression(bar(italic(L))~~(m^2~m^-2)),
                panel.first=predline(lm(LAI.mean ~ BA, data=ba)),
                ylim=c(1.2,2.4), xlim=c(18,40)))
  legend("bottomright", as.character(1:6), pch=19, bty='n',
         col=my_ringcols(), title="Ring", cex=0.6, pt.cex=1)
  
}

figureSI5 <- function(df, ba){
  
  df$Date <- as.numeric(df$Date) # for gamm
  df <- merge(df, ba)
  
  # Fit full model
  g <- gamm(LAI ~ treatment + BA + s(Date, k=18), random = list(Ring=~1), data=df)
  
  
  # Now predict from model at mean basal area.
  nd <- expand.grid(Date=seq(min(df$Date), max(df$Date), by=1),
                    treatment=c("ambient","elevated"))
  nd$BA <- mean(ba$BA)
  
  p <- predict(g[[2]], nd, se.fit=TRUE)
  nd$LAIpred <- p$fit
  nd$LAIse <- p$se.fit
  
  # minimum observable difference
  halfci <- mean(2 * nd$LAIse)
  minobsdiff <- 2 *mean(2 * nd$LAIse)/mean(nd$LAIpred)
  
  # Make figure
  nd$Date <- as.Date(nd$Date, origin="1970-1-1")
  da <- subset(nd, treatment == "ambient")
  de <- subset(nd, treatment == "elevated")
  
  
  palette(my_co2cols())
  linecols <- palette()
  polycolors <- c(alpha("royalblue",0.7),alpha("pink",0.7))
  
  par(mar=c(3,5,2,2), yaxs="i")
  with(df, plot(Date, LAI, pch=19, col=treatment,
                ylim=c(0,2.8), 
                ylab=expression(italic(L)~~(m^2~m^-2)),
                xlab="",
                axes=FALSE))
  
  addpoly(da$Date, da$LAIpred-2*da$LAIse, da$LAIpred + 2*da$LAIse, col=polycolors[1])
  addpoly(de$Date, de$LAIpred-2*de$LAIse, de$LAIpred + 2*de$LAIse, col=polycolors[2])
  
  lines(da$Date, da$LAIpred, col=linecols[1], lwd=2)
  lines(de$Date, de$LAIpred, col=linecols[2], lwd=2)
  
  l <- legend("topleft", c("Ambient","Elevated"), title=expression(italic(C)[a]~treatment), 
              fill=my_co2cols(), bty="n", cex=0.8)
  axis(2, at=seq(0,2.8,by=0.4))
  box()
  
  timeseries_axis()

  
return(invisible(list(minobsdiff=minobsdiff, halfci=halfci)))
}



