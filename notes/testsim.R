library(tidyverse)
source("makestuff/makeRfuns.R")
print(commandEnvironments())

## WHICH of these do you want today?
library(devtools); load_all("../")
## library("McMasterPandemic")

params <- (read_params(matchFile(".csv$"))
    %>% fix_pars(target=c(R0=R0, Gbar=Gbar))
    %>% update(
            N=pop
        )
)

paramsw0 <- params[!grepl("^W",names(params))] ## removing all of the regular W-parameters
class(paramsw0) <- "params_pansim"

print(paramsw0)
summary(paramsw0)

simlist <- list()
for(i in W_asymp) {
    for (j in iso_t) {
        for (k in testing_intensity) {
            cat(i,j,k,"\n")
            paramsw0 <- update(paramsw0, W_asymp=i, iso_t = j, testing_intensity=k)
            sims <- (run_sim(params = paramsw0
					, ratemat_args = list(testify=TRUE, testing_time=testing_time)
					, start_date = start
					, end_date = end
					, use_ode = use_ode
					, step_args = list(testwt_scale=testwt_scale)
					##	, condense_args=list(keep_all=TRUE) 
                             )
                %>% mutate(W_asymp = i
                         , iso_t = j
                         , testing_intensity=k
                           )
            )
            simlist <- c(simlist,list(sims))
        } ## loop over testing intensity
    } ## loop over iso_t
} ## loop over W_asymp
simframe <- bind_rows(simlist)

## print(simframe)

simdat <- (simframe
    %>% transmute(date
		 , incidence
		 , postest
		 , total_test = postest + negtest
		 , pos_per_million = 1e6*postest/total_test
		 , report
		 , W_asymp
		 , iso_t
		 , testing_intensity
	)
    %>% gather(key="var",value="value",-c(date, W_asymp, iso_t, testing_intensity))
)

saveVars(simdat, params)
