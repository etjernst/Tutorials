* Project: Arrested Development
* Created:
* Last modified: Oct 28 by ET
* Stata v.16

* Note: file directory is set in section 0
* users only need to change the location of their path there

* does
	* Basic data cleaning

* assumes
	* Add any dependencies here
	* for packages, make a local with the packages
	local userpack ""

* TO DO:
	* You can add next steps here if useful (or things that need to be done before code is useful)

*******************************************
* 0 - General setup
*******************************************
* Users can change these two filepaths
* All subsequent files are referred to using dynamic, absolute filepaths
	global myDocs "Z:/"
	global mainFolder "$myDocs/Various/R to Stata first part"

* Check if the required packages are installed:
	foreach package in `userpack' {
		capture : which `package'
		if (_rc) {
			display as result in smcl `"Please install package {it:`package'} from SSC in order to run this do-file."' _newline `"You can do so by clicking this link: {stata "ssc install `package'":auto-install `package'}"'
			exit 199
		}
	}

* cd "D:\文件\uw-madison master\my interest\Emilia\R to Stata\materials working on"
* Setting the working directory to your folder is ok, but it is less tidy
* than dynamic absolute filepaths
* You can delete the below, it's just for instruction
* **********************************************************************
* 	After this, please refer to all files throughout the code accordingly.
* 	Include all files in " " in case other users have spaces in filepath.
* 	For example
* 	use "$mainFolder/Input/raw_data/coolnewdata.dta", clear
* **********************************************************************

* **********************************************************************
* 	Every time you save a data set, label it and add a note
* 	The most important part is the "created by [current-do-file]
*
* 	label data "Short description \ $S_DATE"
* 	note: data_name.dta \ Short description \ created using current-do-file.do \ your initials \ $S_DATE
* 	save "$mainFolder/Input/raw_data/data_name", replace
* **********************************************************************

* Set graph and Stata preferences
	set scheme plotplain
	set more off

* Start a log file
	cap: log close
	log using "$mainFolder/code/logs/siru_code", replace
	* log using "$mainFolder/code/logs/same_name_as_do_file", replace

*******************************************
* 1 - Descriptive section headers
*******************************************
clear all
* Import data
import delimited "month_data_1.csv"

gen rownumber = _n

gen start_date_w_na = start_date_txt
replace start_date_w_na = "." if start_date_txt == ""
replace start_date_w_na = "2007-12-03" if start_date_w_na == "3007-12-03"
gen award_date_w_na = award_date_txt
replace award_date_w_na = "." if award_date_w_na == ""
gen start_or_award_txt = start_date_w_na
replace start_or_award_txt = award_date_w_na if start_date_w_na == "."
gen completion_date_w_na = completion_date
replace completion_date_w_na = "." if completion_date == ""
gen start_or_award_date = date(start_or_award_txt, "YMD")
format start_or_award_date %td
gen completion_date_final = date(completion_date_w_na, "MDY")
format completion_date_final %td
gen start_date_final = date(start_date_w_na,"YMD")
format start_date_final %td
gen award_date_final = date(award_date_w_na, "YMD")
format award_date_final %td
gen start_to_award = start_date_final - award_date_final //start_to_award is the days between start_date and award_date

gen obs_id = _n

save month_only_cleaning

clear all

import delimited "williams.csv"
*work on williams.csv*

gen rownumber = _n
sort year district_label_post, stable

gen obs_id = _n

*clean q4projtitle, to lowercase, no double or more spaces, no leading and trailing spaces, no punctuations*
gen title_bare = strtrim((ustrregexra(strlower(q4projtitle), "[ ]{2,}", " ")))
replace title_bare = ustrregexra(title_bare, "[^a-z^0-9^  ]","")

merge 1:1 obs_id using month_only_cleaning, keepusing(start_date_final award_date_final completion_date_final start_or_award_date)
drop _merge

gen fundsource_det_fix1 = fundsource_pie
//recode in R not done, when we do regression or future analysis, if error occurs, check recode
gen ndcvs_100 = ecpres2008_voteshare_ndc * 100
replace fundsource_det_fix1 = "." if fundsource_pie == "other/unknown"
gen district_216 = district_label_post_agg
replace district_216 = ustrregexra(strlower(district_216), "[^a-z^0-9]"," ") //no punctuations
replace district_216 = ustrregexra(district_216, "district|municipal|metropolitan|assembly|assemby", "")
replace district_216 = strtrim(ustrregexra(district_216, "[ ]{2,}", " ")) //remove double or more spaces, leading and trailing spaces

replace district_216 = "ajumako enyan esiam" if district_216 == "ajumako enyan essiam"
replace district_216 = "akwapem north" if district_216 == "akuapim north"
replace district_216 = "akwapem south" if district_216 == "akuapim south"
replace district_216 = "akyem mansa" if district_216 == "akyemansa"
replace district_216 = "ellembelle" if district_216 == "ellembele"
replace district_216 = "afadzato south" if district_216 == "afadjato south"
replace district_216 = "wassa amenfi central" if district_216 == "amenfi central"
replace district_216 = "gushiegu" if district_216 == "gushegu"
replace district_216 = "twifo heman lower denkyira" if district_216 == "heman lower denkyira"
replace district_216 = "juabeso" if district_216 == "juaboso"
replace district_216 = "kasena nankana east" if district_216 == "kassena nankana east"
replace district_216 = "kasena nankana west" if district_216 == "kassena nankana west"
replace district_216 = "krachi nchumuru" if district_216 == "krachi ntsumuru"
replace district_216 = "ledzokuku krowor" if district_216 == "ledzekuku krowor"
replace district_216 = "upper denkyira east" if district_216 == "upper dekyira east"

drop if year == 2010
drop if title_bare == ""

save williams_cleaning

clear all

*merge wiliams.csv, district_key_170_216.csv and dist_results_2008.csv*

import delimited "district_key_170_216.csv", varnames(1)
save district_key_170_216

clear all

import delimited "dist_results_2008.csv"
save dist_results_2008

clear all

use williams_cleaning

merge m:1 district_216 using "district_key_170_216.dta"
drop if _merge <3
drop _merge
sort obs_id

merge m:1 district_170 using "dist_results_2008.dta"
drop if _merge <3
drop _merge
sort obs_id

save williams_district_key_170_216_dist_results_2008

*merge three files finished*

clear all

*create district weighting*

use williams_district_key_170_216_dist_results_2008

keep district_170 district_216 phc_pop_total_ln
duplicates drop district_216, force

gen pop_total_216 = exp(phc_pop_total_ln)
bysort district_170: egen total_pop_170 = total(pop_total_216)

gen split_district = 1
replace split_district = 0 if district_170 == district_216
gen pop_wt = pop_total_216 / total_pop_170

drop phc_pop_total_ln district_170

save district_weighting

clear all

use williams_district_key_170_216_dist_results_2008

merge m:1 district_216 using "district_weighting.dta"
drop if _merge <3
drop _merge
sort obs_id

save williams_district_key_170_216_dist_results_2008_district_weighting

*merge four dataset finished*

clear all

use williams_district_key_170_216_dist_results_2008_district_weighting

destring q8contsumorig, generate(cont_sum_negs) force
gen cont_sum = cont_sum_negs
replace cont_sum = . if cont_sum_negs < 1
gen cont_sum_num_raw = cont_sum
gen cont_sum_num = cont_sum_num_raw
replace cont_sum_num = . if cont_sum_num_raw < 1
gen cont_sum_thous = cont_sum_num/1000
gen logcontsum = log(cont_sum_num)
gen roundcontthous = round(cont_sum_thous)
gen logroundcontthous = log(roundcontthous)
gen roundconthun = round(cont_sum_num/100)
gen logroundconthun = log(roundconthun)
tostring award_date, generate(award_date_txt)
gen fundsource_det_fix1_txt = fundsource_det_fix1 //fundsource_det_fix1 is factor and fundsource_det_fix1_txt is charater in R, no difference in stata

bysort district_170: gen nprojdist = _N
sort obs_id
gen nchartitle = length(title_bare)

keep if _n >= 400 & _n <= 500

forval j=1/`=_N' {

                gen x`j' = title_bare[`j']

                ustrdist title_bare x`j', gen(d`j')

                drop x`j'

               // replace d`j' = 0 if _n<`j' // to make the upper triangle zero, in R I think they are missing value, but cluster command cannot recogonise missing value.

}

*problems*
//1. the matrix in stata and R are not exactly the same, some has 1 difference
//2. row 92 93 94 96 97 101 are in the same cluster group though they're different;
//3. generate scalars then put in matrix, but how cluster works on it?
//4. in R it takes like 20 minutes to do the matrix and cluster, but in stata.....

*next to do*
// cluster cannot be used with by, but need to do so by district_170 -sscc
// mata learing....


sort district_170

by district_170: cluster completelinkage d1 - d101 //??

cluster generate cluster_group_new = cut(3), ties(skip)

cluster dendrogram d1 - d100, cutvalue(3)

*here is the old question part*

/*
ustrdist title_bare, gen(string_distance) // ustring command in stata calculate the Levenshtein distance,
while in R stringdistmatrix() [line 131 in R script] creates a matrix using euclidean method(it's actually dist() because only one argument in our case).

cluster completelinkage string_distance, generate(clustergroup)
cluster generate gruop_new = cut(3) // wrong


gen clust_group = "."
replace clust_group = ..... if nchartitle > 2 & nprojdist > 1
*/


*the following code are tested, maybe minor mistakes because the variables generated by cluster are not done*

egen dist_cl_group = concat(district_170 clust_group), punct(_)
rename (year q4projtitle) (report_tear title)
sort district_170 dist_cl_group, stable

save matched3

clear all

use matched3

gen na_award = 0
replace na_award = 1 if award_date == "."
gen na_fs = 0
replace na_fs = 1 if fundsource_det_fix1 == "."
gen na_contract = 0
replace na_contract= 1 if cont_sum_num == "."
gen na_loc = 0
replace na_loc = 1 if location_num == "."
//rowwise before we did cluster, now generate variables by row

egen sum_nas = rowtotal(na_award na_fs na_contract na_loc)
egen titlefz_projtype = concat(dist_cl_group projtype), punct(_)
//replace titlefz_projtype = "." if clust_group == "NA" | projtype == "NA" //uneccesary because neither is NA
//the following omit the origin R-code to test if cluster_group is missing value because no missing value

*the following two passages are paste variables together according to different conditions*

egen allid = concat(dist_cl_group projtype award_date fundsource_det_fix1 roundconthun location_num) if sum_nas == 0, punct(_)
egen allbutaward = concat(dist_cl_group projtype fundsource_det_fix1 roundconthun location_num) if sum_nas == 1 & na_award == 1, punct(_)
egen allbutfs = concat(dist_cl_group projtype award_date roundconthun location_num) if sum_nas == 1 & na_fs == 1, punct(_)
egen allbutcont = concat(dist_cl_group projtype award_date fundsource_det_fix1 roundconthun location_num) if sum_nas == 1 & na_contract == 1, punct(_)
egen allbutloc = concat(dist_cl_group projtype award_date fundsource_det_fix1 roundconthun) if sum_nas == 1 & na_loc == 1, punct(_)
gen allid_or_one_na = allbutloc
replace allid_or_one_na == allbutaward if allbutaward != "."
replace allid_or_one_na ==allbutfs if allbutfs != "."
replace allid_or_one_na ==allbutcont if allbutcont != "."
egen allbutcontloc = concat(dist_cl_group projtype award_date fundsource_det_fix1) if sum_nas == 2 & (na_contract + na_loc == 2), punct(_)
egen allbutcontfs = concat(dist_cl_group projtype award_date location_num) if sum_nas == 2 & (na_contract + na_fs == 2), punct(_)
egen allbutcontaward = concat(dist_cl_group projtype fundsource_det_fix1 location_num) if sum_nas == 2 & (na_contract + na_award == 2), punct(_)
egen allbutlocfs = concat(dist_cl_group projtype award_date roundconthun) if sum_nas == 2 & (na_loc + na_fs == 2), punct(_)
egen allbutlocaward = concat(dist_cl_group projtype fundsource_det_fix1 roundconthun) if sum_nas == 2 & (na_loc + na_award == 2), punct(_)
egen allbutawardfs = concat(dist_cl_group projtype location_num roundconthun) if sum_nas == 2 & (na_award + na_fs == 2), punct(_)
gen allbutoneortwo = allbutawardfs
replace allbutoneortwo = allid_or_one_na if allid_or_one_na != "."
replace allbutoneortwo = allbutcontloc if allbutcontloc != "."
replace allbutoneortwo = allbutcontfs if allbutcontfs != "."
replace allbutoneortwo = allbutcontaward if allbutcontaward != "."
replace allbutoneortwo = allbutlocfs if allbutlocfs != "."
replace allbutoneortwo = allbutlocaward if allbutlocaward != "."

egen titleex = concat(district_label_post_agg title_bare), punct(_)
egen titleex_award_date = concat(district_label_post_agg title_bare award_date), punct(_)
replace titleex_award_date = "." if award_date == "."
egen titleex_date_loc = concat(district_label_post_agg title_bare award_date location_num), punct(_)
replace titleex_date_loc = "." if award_date == "." | location_num == "."
egen titleex_contex = concat(district_label_post_agg title_bare cont_sum_num), punct(_)
replace titleex_contex = "." if cont_sum_num == "."
egen titleex_loc = concat(district_label_post_agg title_bare location_num),punct(_)
replace titleex_loc = "." if location_num == "."
egen titleex_contex_loc = concat(district_label_post_agg title_bare cont_sum_num location_num), punct(_)
replace titleex_contex_loc = "." if cont_sum_num == "."
egen titleex_contfz_loc = concat(district_label_post_agg title_bare roundcontthous location_num),punct(_)
replace titleex_contfz_loc = "." if roundcontthous == "." | location_num == "."
egen titleex_fs = concat(district_label_post_agg title_bare fundsource_det_fix1), punct(_)
replace titleex_fs = "." if fundsource_det_fix1 =="."
egen titleex_loc_fs = concat(district_label_post_agg title_bare location_num fundsource_det_fix1), punct(_)
replace titleex_loc_fs = "." if location_num == "." | fundsource_det_fix1 == "."
gen titlefz = dist_cl_group
egen titlefz_date = concat(dist_cl_group award_date), punct(_)
replace titlefz_date = "." if award_date == "."
egen titlefz_date_loc = concat(dist_cl_group award_date location_num), punct(_)
replace titlefz_date_loc = "." if award_date == "." | location_num == "."
egen titlefz_contex = concat(dist_cl_group cont_sum_num), punct(_)
replace titlefz_contex = "." if cont_sum_num == "."
egen titlefz_contfz = concat(dist_cl_group roundcontthous), punct(_)
replace titlefz_contfz = "." if roundcontthous == "."
egen titlefz_loc = concat(dist_cl_group location_num), punct(_)
replace titlefz_loc = "." if location_num == "."
egen titlefz_contex_loc = concat(dist_cl_group cont_sum_num location_num), punct(_)
replace titlefz_contex_loc = "." if cont_sum_num == "." | location_num == "."
egen titlefz_contfz_loc = concat(dist_cl_group roundcontthous location_num), punct(_)
replace titlefz_contfz_loc = "." if roundcontthous == "." | location_num == "."
egen titlefz_fs = concat(dist_cl_group fundsource_det_fix1), punct(_)
replace titlefz_fs = "." if fundsource_det_fix1 == "."
egen titlefz_loc_fs = concat(dist_cl_group location_num fundsource_det_fix1), punct(_)
replace titlefz_loc_fs = "." if location_num == "." | fundsource_det_fix1 == "."

save idcreation
