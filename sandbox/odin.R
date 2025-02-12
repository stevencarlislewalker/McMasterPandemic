library(McMasterPandemic)
pars <- read_params("ICU1.csv")
state <- make_state(param=pars)
M <- make_ratemat(state, pars)
odin_gradfun <- odin::odin({
    s_init[] <- user()
    initial(s) <- s_init
    dim(s) <- 14
    m0 <- user()
    M[,] <- m0
    beta0 <- user()
    Ca <- user()
    Cp <- user()
    iso_m <- user()
    Cm <- user()
    iso_s <- user()
    Cs <- user()
    oN <- user()
    M[2,1] <- beta0/N*(Ca*s[3]+Cp*s[4]+(1-iso_m)*Cm*s[5]+(1-iso_s)*Cs*s[6])
    dim(M) <- c(14,14)
    flows <- M[i,j]*s[j]
    deriv(s) <- sum(M[i,])-sum(M[,j])
})
