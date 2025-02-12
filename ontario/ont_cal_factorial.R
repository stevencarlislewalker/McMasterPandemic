library(McMasterPandemic)
library(splines)
library(dplyr)
library(parallel)

## load(".ont_keep.RData")
print(unique(ont_all_sub$var))
ont_noICU <- dplyr::filter(ont_all_sub, var != "ICU")

dat <- ont_noICU

## subset mobility data to bounds of data
comb_sub2 <- (comb_sub
    %>% right_join(dat %>% select(date) %>% unique(),by="date")
    %>% na.omit()
    %>% mutate_at("rel_activity",pmin,1) ## cap relative mobility at 1
)

X_date <- unique(dat$date)

## extend data set to full extent of data set
comb_sub3 <- (full_join(unique(select(dat,date)),comb_sub2,by="date")
    ## assume missing data = constant at last value
    %>% mutate_at("rel_activity",zoo::na.locf)
    %>% mutate(t_vec=as.numeric(date-min(date)))
)

# plot(rel_activity~date,data=comb_sub3)

opt_pars <- list(
    ## these params are part of the main parameter vector: go to run_sim()
    params=c(log_E0=4      ## initial exposed
           , log_beta0=-1  ## initial baseline transmission
             ## fraction of mild (non-hosp) cases
           , log_mu=log(params[["mu"]])
             ## fraction of incidence reported
             ## logit_c_prop=qlogis(params[["c_prop"]]),
             ## fraction of hosp to acute (non-ICU)
           , logit_phi1=qlogis(params[["phi1"]])
             )
  , log_nb_disp=NULL
)


run_cali <- function(flags, spline_days=14, knot_quantile_var=NULL,
                     maxit=10000, ...) {

    cat(flags, spline_days, knot_quantile_var,"\n",sep="\n")

    ss <- function(flags,i) as.logical(as.numeric(substr(flags,i,i)))
    ## flags
    use_DEoptim  <-ss(flags,1)
    use_mobility <- ss(flags,2)
    use_spline   <- ss(flags,3)
    use_zeta     <- ss(flags,4)

    ## now modify opt_pars according to flags
    if (use_zeta) opt_pars$params <- c(opt_pars$params,log_zeta=1)
    loglin_terms <- "-1"
    if (use_mobility) loglin_terms <- c(loglin_terms, "log(rel_activity)")
    ## need tmp_dat ouside use_spline for non-spline, non-mob cases
    tmp_dat <- (dat
        %>% select(date)
        %>% distinct()
        %>% mutate(t_vec=as.numeric(date-min(date)))
    )
    if (use_spline) {
        spline_df <- round(length(comb_sub3$t_vec)/spline_days)
        if (length(knot_quantile_var)==0) {
            spline_term <- sprintf("bs(t_vec,df=spline_df)")
        } else {
            ## df specified: pick (df-degree) knots
            tmp_dat <- (filter(dat,var==knot_quantile_var)
                %>% na.omit()
                %>% mutate(cum=cumsum(value),t_vec=as.numeric(date-min(date)))
            )
            q_vec <- quantile(tmp_dat$cum,seq(1,spline_df-3)/(spline_df-2))
            ## find closest dates to times with these cum sums
            knot_t_vec <- with(tmp_dat,approx(cum,t_vec,xout=q_vec,ties=mean))$y
            cat("knots:",knot_t_vec,sep="\n","\n")
            spline_term <- sprintf("bs(t_vec,knots=knot_t_vec)")
        }
        loglin_terms <- c(loglin_terms, spline_term)
    }
    form <- reformulate(loglin_terms)
    X_dat <- if (use_mobility) comb_sub3 else tmp_dat
    X <- model.matrix(form, data = X_dat)

    matplot(X_dat$t_vec,X,type="l",lwd=2)
    opt_pars$time_beta <- rep(0,ncol(X))  ## mob-power is incorporated (param 1)
    time_args <- nlist(X,X_date=X_dat$date)

    if (FALSE) {
        ## testing
        ## n.b. single brackets below are on purpose
        r0 <- run_sim_loglin(params=params, extra_pars=opt_pars["time_beta"] 
                           , time_args=time_args
                           , sim_args=list(start_date=min(dat$date)-15
                                         , end_date=max(dat$date)))
        plot(r0,break_dates=NULL,log=TRUE)
    }
    ## do the calibration
    ## debug <- use_DEoptim
    debug <- FALSE

    t_ont_cal_fac <- system.time(ont_cal_fac <-
                                     calibrate(data=dat
                                             , use_DEoptim=use_DEoptim
                                             , DE_cores = 1
                                             , debug_plot = interactive()
                                             , debug = debug
                                             , base_params=params
                                             , mle2_control = list(maxit=maxit)
                                             , opt_pars = opt_pars
                                             , time_args=time_args
                                             , sim_fun = run_sim_loglin
                                             , ...
                                               )
                                 ) ## system.time

    
    res <- list(mod = flags, time = t_ont_cal_fac, fit = ont_cal_fac, data=dat)
    ## checkpoint
    saveRDS(res,file=sprintf("ont_fac_%s_fit.rds",flags))
    return(res)  ## return *after* saving!!!!
}

## TEST of spline options
## should be VERY short run (with maxit=5) - although we do have a high dimension/
##  lots of vertices to compute per iteration
##  (also computing hessian!)
if (FALSE) {
    r1 <- run_cali("0010",knot_quantile_var="report", spline_days=21, maxit=2)
    r2 <- run_cali("0010", spline_days=21, maxit=2)
    r3 <- run_cali("0010",knot_quantile_var="report", maxit=2)

    load("ont_cal_factorial.RData")
    names(res_list) <- purrr:::map_chr(res_list, ~.$mod)
    rr <- res_list[["0111"]]
    coef(rr$fit,"fitted")
    OP <- rr$fit$forecast_args$opt_pars
    DE_lims <- McMasterPandemic:::get_DE_lims(OP)
    ## restrict limits some more
    DE_lims$lwr[grepl("time_beta",names(DE_lims$lwr))] <- -1
    DE_lims$upr[grepl("time_beta",names(DE_lims$upr))] <- 1
    rr <- run_cali("1111",
             DE_lwr=DE_lims$lwr,
             DE_upr=DE_lims$upr)
}

factorial_combos <- apply(expand.grid(replicate(4,0:1,simplify=FALSE)),
                1,paste,collapse="")
res_list <- mclapply(factorial_combos, run_cali, mc.cores=5)

## run_cali("1111")
#rdsave(res_list, factorial_combos)
