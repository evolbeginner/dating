uniformMCMCtree <- function (xRange = c(0, 4), tL, tU, minProb, maxProb) 
{
    omega <- ((1 - maxProb - minProb) * tL)/(minProb * (tU - tL))
    omegaTwo <- (1 - maxProb - minProb)/(maxProb * (tU - tL))
    xx <- seq(xRange[1], xRange[2], by = 0.001)
    numero <- c()
    rc <- 1
    for (x in xx) {
        time <- x
        if (time <= tL) 
            numero[rc] <- minProb * (omega/tL) * (time/tL)^(omega - 
                1)
        if (tL < time && time <= tU) 
            numero[rc] <- (1 - maxProb)/(tU - tL)
        if (time > tU) 
            numero[rc] <- maxProb * omegaTwo * exp(-omegaTwo * 
                (time - tU))
        rc <- rc + 1
    }
    time <- xx
    density <- numero
    return(cbind(time, density))
}
