*** Capitulo 16 ***

clear all
bcuse keane, clear 
describe

* Implementamos una estrategia de VI en modelo de multiples categorias.
* requisito: la variable endogena debe ser aproximadamente continua.




**# MNL-VI: sin bootstrap


*==============================================================*
* Control function (endogeneidad aproximada) en dos etapas
*==============================================================*

tabulate status

** sch=1, 
** home=2,
** work=5

** Como vemos, las 3 opciones son: escuela, casa, trabajo

mdesc 
misstable summarize 

* Suponga que "educ" es endógena (y que es al menos, es aproximadamente continua, lo cual se cumple aqui) y 
*           "z_excl" es el (o los) instrumento excluido de la ecuación de elección (entra en la forma reducida de y2 pero no directamente en la elección).


* primero estimamos asumiendo exogeneidad a efectos de posterior comparacion:
mlogit status educ exper expersq i.black y82-y87, baseoutcome(1) vce(cluster id)
margins, dydx(educ exper expersq black) post
estimates store apes_mln_exo

** Ahora si: MLN-VI
* educ como endogena: enfoque de control function.
* instrumentamos educ con "numyrs": es decir z_excl=numyrs.

** ACLARACION: aca usamos este instrumento solamente con fines didacticos. No necesariamente es un buen instrumento.
/* En ese keane.dta, si la endógena es "educ", la verdad es que no hay un candidato "clásico" que tenga buena pinta como instrumento
 (tipo educación de padres, QOB, distancia a college, leyes de escolaridad obligatoria, etc.). Esos son los que suelen usarse para educ, y no están en la base.
 -Leyes de escolaridad obligatoria por estado/año de nacimiento
 -Quarter-of-birth (Angrist–Krueger)
 -Distancia a college / oferta educativa local
 -Educación de padres

Si el objetivo es taller didáctico,  numyrs como IV de educ puede servir porque es un "shifter" de cosas de capital humano/exposición al mercado.
Pero ojo: porque numyrs captura selección/attrition y "estabilidad" del individuo (no observado), que también afecta directamente la elección status.
Cómo presentarlo honestamente en el taller:
"Usamos numyrs como instrumento pedagógico de educación: es relevante por selección/exposición, pero su exclusión es debatible porque está ligado a attrition y heterogeneidad no observada."
*/

** (1) Primera etapa
regress educ exper expersq i.black y82-y87 numyrs, vce(cluster id)
predict vhat, resid
// vhat aproxima el componente no observado que genera la endogeneidad
** prueba de relevancia del instrumento:
test numyrs   // relevancia (Wald robust)
* Relevancia: la 1ra etapa muestra instrumentos fuertes: F(1,1880)=139.97 (p<0.000) con numyrs solo


** (2) Segunda etapa: estimo y me guardo los APEs
mlogit status educ exper expersq i.black y82-y87 vhat, baseoutcome(1) vce(cluster id)

margins, dydx(educ exper expersq black) post
estimates store apes_mln_vi_naive
**# **#  APEs (naives)
mlogit status educ exper expersq i.black y82-y87 vhat, baseoutcome(1) vce(cluster id)
test vhat // exogeneidad: H0 gamma=0 (OJO: SE/p-value "oficial" => usar bootstrap)

**# **#  PCP

* Predicción por máxima probabilidad:
predict phat1 phat2 phat3, pr
gen psum = phat1+phat2+phat3
summ psum

** o sea: son probabilidades predichas por alternativa, tal como queríamos.
** el PCP no cambiará aunque luego ajustemos los SE por bootstrap.

* Categoría predicha = argmax
gen yhat = 1
replace yhat = 2 if phat2>phat1 & phat2>=phat3 
replace yhat = 3 if phat3>phat1 & phat3>phat2 

gen correct = (status==yhat) if !missing(status)
summ correct
display "Porcentaje correctamente predicho (VI) = " 100*r(mean) "%"


* Matriz de clasificación (real vs predicho)
tab status yhat, row




*======================================================================
* Control function (endogeneidad aproximada) en dos etapas + bootstrap
*======================================================================


*      Bootstrap correcto (coeficientes de segunda etapa)
*      Si ahora tu 2da etapa es mlogit, entonces:
*      Vía A (del caso probit, capitulo 15) ya no existe así en multinomial logit. En MNL el marginal depende de todas las probabilidades Pm, no solo de la distribucion "pdf en xb".
*      Vía B (rescatar b1 con ese "scale" (cap 15)) tampoco vale: esa fórmula de re-escalado es probit-specific. En logit no hay esa corrección cerrada con τ2 de esa forma.

*      La corrección concreta que necesitás es: calcular los APE usando las probabilidades predichas del MNL.



cap program drop cf16_just
program define cf16_just, rclass
    version 16.0
    tempvar vhat
    tempname B
    local xvars educ exper expersq y82 y83 y84 y85 y86 y87

    * 1ra etapa
    quietly regress educ exper expersq i.black y82-y87 numyrs, vce(cluster id)
    quietly predict double `vhat', resid
    return scalar pi_numyrs = _b[numyrs]

    * 2da etapa (MNL + CF)
    quietly mlogit status educ exper expersq i.black y82-y87 `vhat', baseoutcome(1) vce(cluster id)

    * AMEs por outcome: predict(outcome(#))
    foreach j in 1 2 3 {

        quietly margins, dydx(`xvars' black) predict(outcome(`j'))
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

        * black discreto: a veces aparece como "black" o como "1.black"
        local c = colnumb(`B', "black")
        if (`c'==.) local c = colnumb(`B', "1.black")
        if (`c'==.) {
            di as err "No encuentro black en margins outcome(`j'). Revisá colnames: "
            matrix list `B'
            exit 198
        }
        return scalar aped_black_out`j' = `B'[1,`c']
    }
end


cf16_just
return list

**# Bootstrap (APEs)


bootstrap ///
    ape_educ1=r(ape_educ_out1)   ape_educ2=r(ape_educ_out2)     ape_educ3=r(ape_educ_out3) ///
    ape_exper1=r(ape_exper_out1)   ape_exper2=r(ape_exper_out2)     ape_exper3=r(ape_exper_out3) ///
    ape_expersq1=r(ape_expersq_out1)   ape_expersq2=r(ape_expersq_out2)     ape_expersq3=r(ape_expersq_out3) ///
    ape_black1=r(aped_black_out1)   ape_black2=r(aped_black_out2)     ape_black3=r(aped_black_out3), ///
    reps(100) seed(12345) cluster(id): cf16_just

	


* --- venís de: bootstrap ... : cf16_just

estimates store apes_mln_vi_bostrapp

matrix B = e(b)
matrix V = e(V)
scalar N0 = e(N)

* Queremos guardar APE como coeficientes "limpios"

local apes_list  "ape_educ1 ape_educ2 ape_educ3 ape_exper1 ape_exper2 ape_exper3 ape_expersq1 ape_expersq2 ape_expersq3 ape_black1 ape_black2 ape_black3"
local clean_list "educ1 educ2 educ3 exper1 exper2 exper3 expersq1 expersq2 expersq3 black1 black2 black3"
local K : word count `apes_list'

matrix b_cf = J(1, `K', .)
matrix V_cf = J(`K', `K', .)

forvalues i = 1/`K' {
    local nm_i : word `i' of `apes_list'
    local ciB  = colnumb(B, "`nm_i'")
    local ciV  = colnumb(V, "`nm_i'")
    if (`ciB'==0 | `ciV'==0) continue
	
    matrix b_cf[1,`i'] = B[1,`ciB']

    forvalues j = 1/`K' {
        local nm_j : word `j' of `apes_list'
        local cjV  = colnumb(V, "`nm_j'")
        if (`cjV'==0) continue
        matrix V_cf[`i',`j'] = V[`ciV',`cjV']
    }
}

matrix colnames b_cf = `clean_list'
matrix colnames V_cf = `clean_list'
matrix rownames V_cf = `clean_list'

* ---- posteamos como e() "de verdad" (para poder estimates store)
capture program drop _post_bv
program define _post_bv, eclass
    args bmat vmat nobs
    ereturn post `bmat' `vmat', obs(`nobs')
    ereturn local cmd "cf_apes_mlnvi_boot"
end

_post_bv b_cf V_cf `=N0'
estimates store cf_just_ape

estimates restore cf_just_ape
ereturn list


* volver a resultados del bootstrap para seguir usando B y V originales
estimates restore apes_mln_vi_bostrapp

	
*******************************************************************


**# TABLA COMPARATIVA FINAL

*  chequear que estén todas
estimates dir

esttab apes_mln_exo apes_mln_vi_naive  apes_mln_vi_bostrapp, ///
    b se nolabel ///
    b(%9.4f) se(%9.4f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("MLN" "MLN-VI (naive)" ///
            "MLN-VI (Bootstrap)") ///
    stats(N, fmt(%9.0g) labels("N")) ///
    compress nogaps


*******************************************************************

