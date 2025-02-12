library(McMasterPandemic)

#load("ONcalib_2021May07.rda")  ## baseline calibration: ont_cal1 (calibrated object), bd (breakpoint dates)
print(unique(ont_all_sub$var))
print(opt_pars)  ## original parameter settings
opt_pars_2brks <- opt_pars
opt_pars_2brks$logit_rel_beta0 <- rep(-1,2)  ## only two breakpoints (hosp data doesn't even start until after brk 1)
bd2 <- bd[-1]  ## drop first breakpoint
ont_cal_2brks <- update(ont_cal1
                     ,  opt_pars=opt_pars_2brks
                     , time_args=list(break_dates=bd2)
                       )

save("ont_cal_2brks", file=sprintf("ONcalib_2brks_%s.rda",
                              format(Sys.time(),"%Y%b%d")))

# rdsave("ont_cal_2brks", "opt_pars_2brks", "bd2")
