*** Capitulo 16 ***

clear all
bcuse pension, clear 

describe
tab pctstck
** la variable "pctstck" es la dependiente que es categorica ordenada.
** las covariables son: choice, age, educ, female, black, married, finc25;...; finc101, wealth89, and prftshr.


**# Ordened probit 

global Z1 "age wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr"
oprobit pctstck educ $Z1, vce(robust)

**# APEs
margins, dydx(*) post
estimates store ape_ordprobit





*==============================================================*
* 16.3.3 Endogeneidad (Rivers-Vuong extendido): dos etapas
*==============================================================*

**# Ordened probit - VI

* a efectos del taller, pedagogicos, asumamos que "educ" es endogena.
* y asumamos que "pyears" es un instrumento para ella. (solo a efectos del taller, porque en realidad no lo es)

* Primera etapa (educ aproximadamente continuo):
global Z1 "age wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr"
regress educ $Z1 pyears, vce(robust)
predict vhat, resid

/** (Opcional) estandarizar residual:
sum vhat
gen rhat = vhat / r(sd)
*/

* Segunda etapa: probit ordenado con residual (test de exogeneidad: coef. vhat2):
oprobit pctstck educ $Z1 vhat, vce(robust)

**# APEs
margins, dydx(*) post
estimates store ape_ordprobit_vi_naive

* Bootstrap recomendado para inferencia (incorpora ambas etapas):


*======================================================================
* Control function (endogeneidad aproximada) en dos etapas + bootstrap
*======================================================================

*      Bootstrap correcto (coeficientes de segunda etapa)
*      La corrección concreta que necesitás es: calcular los APE usando las probabilidades predichas del ordened probit
* 		si tuviera un panel, agregaria dummies temporales y pondria vce(cluster id)
 

cap program drop cf16_just
program define cf16_just, rclass
    version 16.0
    tempvar vhat
    tempname B
    local xvars         educ age wealth89
    local xvars_factor  choice female married black finc25 finc35 finc50 finc75 finc100 finc101 prftshr
    * 1ra etapa
    quietly regress educ age wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr pyears, vce(robust)
    quietly predict double `vhat', resid
    return scalar pi_pyears = _b[pyears]

    * 2da etapa (OrdProbit + CF)
    quietly oprobit pctstck  educ age wealth89 i.choice i.female i.married i.black i.finc25 i.finc35 i.finc50 i.finc75 i.finc100 i.finc101 i.prftshr  `vhat', vce(robust)

    * AMEs por outcome: predict(outcome(#))
    foreach j in 0 50 100 {

        quietly margins, dydx(`xvars' `xvars_factor') predict(outcome(`j'))
        matrix `B' = r(b)

        * continuas
        foreach k of local xvars {
            local c = colnumb(`B', "`k'")
            if (`c'==.) {
                di as err "No encuentro `k' en margins outcome(`j'). Revisá colnames: "
                matrix list `B'
                exit 198
            }
            return scalar ape_`k'_out`j' = `B'[1,`c']
        }

		* discretas
        foreach m of local xvars_factor {
            local c = colnumb(`B', "`m'")
			if (`c'==.) local c = colnumb(`B', "1.`m'")
            if (`c'==.) {
                di as err "No encuentro `m' en margins outcome(`j'). Revisá colnames: "
                matrix list `B'
                exit 198
            }
            return scalar ape_`m'_out`j' = `B'[1,`c']
        }
	}		
end


cf16_just
return list



**# Bootstrap (APEs)


bootstrap /// 
     ape_educ_0=r(ape_educ_out0)           ape_educ_50=r(ape_educ_out50)           ape_educ_100=r(ape_educ_out100)          ///
	 ape_age_0=r(ape_age_out0)             ape_age_50=r(ape_age_out50)             ape_age_100=r(ape_age_out100)            ///
	 ape_wealth89_0=r(ape_wealth89_out0)   ape_wealth89_50=r(ape_wealth89_out50)   ape_wealth89_100=r(ape_wealth89_out100)  ///
	 ape_choice_0=r(ape_choice_out0)       ape_choice_50=r(ape_choice_out50)       ape_choice_100=r(ape_choice_out100)      ///
	 ape_female_0=r(ape_female_out0)       ape_female_50=r(ape_female_out50)       ape_female_100=r(ape_female_out100)      ///
	 ape_married_0=r(ape_married_out0)     ape_married_50=r(ape_married_out50)     ape_married_100=r(ape_married_out100)    ///
	 ape_black_0=r(ape_black_out0)         ape_black_50=r(ape_black_out50)         ape_black_100=r(ape_black_out100)        ///
	 ape_finc25_0=r(ape_finc25_out0)       ape_finc25_50=r(ape_finc25_out50)       ape_finc25_100=r(ape_finc25_out100)      ///
	 ape_finc35_0=r(ape_finc35_out0)       ape_finc35_50=r(ape_finc35_out50)       ape_finc35_100=r(ape_finc35_out100)      ///
	 ape_finc50_0=r(ape_finc50_out0)       ape_finc50_50=r(ape_finc50_out50)       ape_finc50_100=r(ape_finc50_out100)      ///
	 ape_finc75_0=r(ape_finc75_out0)       ape_finc75_50=r(ape_finc75_out50)       ape_finc75_100=r(ape_finc75_out100)      ///
	 ape_finc100_0=r(ape_finc100_out0)     ape_finc100_50=r(ape_finc100_out50)     ape_finc100_100=r(ape_finc100_out100)    ///
	 ape_finc101_0=r(ape_finc101_out0)     ape_finc101_50=r(ape_finc101_out50)     ape_finc101_100=r(ape_finc101_out100)    ///
	 ape_prftshr_0=r(ape_prftshr_out0)     ape_prftshr_50=r(ape_prftshr_out50)     ape_prftshr_100=r(ape_prftshr_out100),   ///
    reps(100) seed(12345) cluster(id): cf16_just

	** si tuvier panel, agregaria "cluster(id)" al bootstrap.
	
estimates store ape_ordprobit_vi_bootstrapp


	
*******************************************************************


**# TABLA COMPARATIVA FINAL

*  chequear que estén todas
estimates dir

esttab ape_ordprobit      ape_ordprobit_vi_naive  ape_ordprobit_vi_bootstrapp, ///
    b se nolabel ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("ORDP" "ORDP-VI (naive)" ///
            "ORDP-VI (Bootstrap)") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps
	
	
** el codigo esta barbaro. Lo que sucede es simplemente que este es un pesimo instrumento para educ. Pero la idea aca era mostrar como seria el codigo, con errores estandar por bootstrap.
	
