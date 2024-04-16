*initalize 
clear
clear mata
clear matrix
ssc install tabout

cd "\\Client\H$\manav-workspace\clean_cooking\Zambia STATA DHS"

set maxvar 10000

**merging Household Member (PR) and Individual (Women's) Recode (IR) **

use "\\Client\H$\manav-workspace\clean_cooking\Zambia STATA DHS\Household Member Recode\ZMPR71FL.DTA"

*provides variables ha1 hvidx hv241 hv104 hhid

generate v001 = hv001
generate v002 = hv002
generate v003 = hvidx

merge 1:1 v001 v002 v003 using "\\Client\H$\manav-workspace\clean_cooking\Zambia STATA DHS\Women's Recode\ZMIR71FL.DTA"

*keeps only women*
keep if _merge==3 

*convert from byte to string
tostring hvidx, replace

*append dataset with all children
append using "\\Client\H$\manav-workspace\clean_cooking\Zambia STATA DHS\Children's Recode\ZMKR71FL.DTA"

*keep variables of interest
keep v024 ha1 v457 hvidx hv241 hv104 hv106 v228 v233 hhid v419 v453 v455 v456 s1110a _merge v151 h31 hw3 hw4 hw5 caseid v228 b19 v025 m19 m19a v122 v161 v119 v040 b4 b5 b6 hw53 hw55 hw56 hw57 hv252 hv270 v106 hb35

*fill in missing hhid values for children, needed to fill in household characteristics later
replace hhid = substr(caseid, 1, 12)

*DO NOT MOVE VERY IMPORTANT FOR FUNCTION TO WORK*
sort hhid

local a hv241 hv270 hv252

*use hv241 data from womens recode to fill in household characteristics for children
foreach v of local a {
	forval i = 1/10 {
		replace `v' = cond(missing(`v'), cond(hhid == hhid[_n+1], `v'[_n+1], `v'), `v')
		replace `v' = cond(missing(`v'), cond(hhid == hhid[_n-1], `v'[_n-1], `v'), `v')
}
}


*combine gender of women and children into one column
gen gender = max(b4, hv104)
drop hv104 b4

*age child in years
gen child_year = b19/12
*combine women and children age
gen age = max(child_year, ha1)

								*independent variables*
*clean fuel defined as solar, electric, biogas, natural gas, liquefied petroleum gas (LPG), and alcohol fuels including ethanol (FROM WHO)
gen dirtyfuel = .
replace dirtyfuel = 0 if (v161 == 1 | v161 == 2 | v161 == 3 | v161 == 4 | v161 == 12)
replace dirtyfuel = 1 if (v161 == 5 | v161 == 6 | v161 == 7 | v161 == 8 | v161 == 9 | v161 == 10 | v161 == 11)

							*potential EMM or Confounders*
gen fridge = .
replace fridge = 1 if v122 == 1
replace fridge = 0 if v122 == 0

gen elec = .
replace elec = 1 if v119 == 1
replace elec = 0 if v119 == 0

gen noed = 0
replace noed = 1 if hv106 == 0
replace noed = . if missing(hv106)

gen primed = 0
replace primed = 1 if hv106 == 1
replace primed = . if missing(hv106)

gen seced = 0
replace seced = 1 if hv106 == 2
replace seced = . if missing(hv106)

gen highed = 0
replace highed = 1 if hv106 == 3
replace highed = . if missing(hv106)

*dichotomize fuel cooking location (separate room 3 outdoors 2 in house 1 other 6)
gen outsidecook = .
replace outsidecook = 1 if (hv241 == 2)
replace outsidecook = 0 if (hv241 == 1 | hv241 == 3)

								*outcome variables*
gen cough = .
replace cough = 1 if (h31 == 1 | h31 == 2)
replace cough = 0 if h31 == 0

gen pregterm = .
replace pregterm = 1 if v228 == 1
replace pregterm = 0 if v228 == 0

gen anemia = .
replace anemia = cond(missing(ha1), hw57, v457)

gen dicot_anemia = .
replace dicot_anemia = 0 if anemia == 4
replace dicot_anemia = 1 if (anemia == 3 | anemia == 2 | anemia == 1)

gen blood_pressure = .
replace blood_pressure = 1 if s1110a == 1
replace blood_pressure = 0 if s1110a == 0

gen weight_card = .
replace weight_card = m19 if m19a == 1

*weight 3 decimal places, WHO underweight is < 2.5kg
gen dicot_underweight = .
replace dicot_underweight = cond(weight_card >= 2500, 0, 1)
replace dicot_underweight = cond(missing(weight_card), ., dicot_underweight)

gen dicot_smoking = .
replace dicot_smoking = 1 if (hv252 == 1 | hv252 == 2 | hv252 == 3)
replace dicot_smoking = 0 if (hv252 == 0 | hv252 == 4)
								*tabulations*
*recode women ages into subgroups
recode ha1 15/19 = 1 20/24 = 2 25/34 = 3 35/49 = 4, gen(womenage)
recode child_year 0/1 = 1 1/2 = 2 2/3 = 3 3/4 = 4 4/5 = 5, gen(childage)

*1 "Urban" 2 "Rural"*
recode v025 (1 = 1) (2 = 0)
rename v025 urbanrural
rename v024 region
rename hv270 wealth
rename hv252 smoking

replace v151 = 0 if v151 == 2
rename v151 household_sex

generate dhsclusttemp = substr(hhid, 1, 9)
replace dhsclusttemp = (subinstr(dhsclust, " ", "", .))
generate dhsclust = real(dhsclusttemp)
drop dhsclusttemp

rename _merge _merge1

merge m:1 dhsclust using "\\Client\H$\manav-workspace\clean_cooking\Zambia STATA DHS\distance2.dta"

recode wealth (1 = 1) (3 = 0) (2 = .) (4 = .) (5 = .), gen(dicot_poor)
recode wealth (5 = 1) (3 = 0) (1 = .) (2 = .) (4 = .), gen(dicot_rich)

*pwcorr dirtyfuel elec outsidecook dicot_smoking dicot_poor household_sex urbanrural gender fridge 

 
*export regression to excel
putexcel set resultmarch, sheet(regressions) replace


local x dicot_anemia cough pregterm blood_pressure dicot_underweight 
local y dirtyfuel elec outsidecook dicot_smoking dicot_poor household_sex urbanrural gender

*tabulations
foreach v of local y {
	tabulate `v'
}
local row = 1

*logistic regressions and export to excel
foreach v of local x {
	local  var_count = `:word count `y''
	logistic `v' `y'
	putexcel a`row' = etable
	local row = `row' + `var_count' + 4
	di `row'
}
 
local z region gender urbanrural wealth
local x dicot_anemia cough pregterm blood_pressure dicot_underweight 

foreach v1 of local x {
	foreach v of local z {
 	tabout `v' `v1' using cough.xls, append
 }
}

putexcel set dirtyfuelanalys, sheet(regressions) replace

local x  dirtyfuel
local y  elec urbanrural outsidecook dicot_smoking dicot_poor household_sex gender noed primed seced highed

foreach v of local y {
	tabulate `v'
}
local row = 1

foreach v of local x {
	local  var_count = `:word count `y''
	logistic `v' `y'
	putexcel a`row' = etable
	local row = `row' + `var_count' + 4
	di `row'
}
