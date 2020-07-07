*distance matrix test for 100 observations*

cd "‪C:\Users\lsr\Desktop"

use williams_district_key_170_216_dist_results_2008_district_weighting, clear

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

keep title_bare
keep if _n<=100

// stata version

timer on 1

forval j=1/`=_N' {
    gen x`j' = title_bare[`j']
    ustrdist title_bare x`j', gen(d`j')
    drop x`j'
}

timer off 1

// stata & mata combination version

mata: mata clear

timer on 2

mata

dis_matrix2 = J(`=_N', `=_N', 0)

end


forval j=1/`=_N'{
    forval i=`=`j'+1'/`=_N'{
	    local v`j'= title_bare[`j']
		local v`i' = title_bare[`i']
	    quietly ustrdist "`v`j''"  "`v`i''"
		mata: dis_matrix2[`i',`j'] = st_numscalar("r(d)")
		mata: dis_matrix2[`j',`i'] = st_numscalar("r(d)")
		//mata: dis_matrix2[strtoreal(st_local("i")), strtoreal(st_local("j"))] = st_numscalar("r(d)")
	
	}
}

timer off 2

//mata: dis_matrix2


// mata version

mata: mata clear

timer on 3

mata

// function definition taken from ustrdist.ado
real scalar ufastlev(string scalar a, string scalar b, | real scalar maxdist)
{
    real scalar len_a, len_b, i, j, cost
    real vector v0, v1, chars_a, chars_b
	   
	if (args()<3 | maxdist < 1) maxdist = . // Ensure that maxdist is positive or missing
    
	if (a==b) return(0) // Shortcut if strings are the same   
	len_a = ustrlen(a)
    len_b = ustrlen(b)
    if (maxdist < . & abs(len_a - len_b) > maxdist) return(.) // Shortcut if we know we will exceed maxdist
    if (len_a==0 | len_b==0) return(len_a + len_b) // Shortcut if one is empty

    // Code based on:
    // https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
    
    v0 = 0::len_b
    v1 = J(len_b+1, 1, .)
    
	// The usual algorithm in strdist (next two lines) does not give correct
	// results for unicode strings
	// chars_a = ascii(a)
    // chars_b = ascii(b)

	// Adjustment for unicode characters
	// ascii() returns a list of bytes for unicode characters.
	// The code below maps this list of bytes to a single integer. Ideally,
	// there would be a function like ascii() which does this mapping, but I
	// do not know of any. The mapping does not give back the proper unicode
	// value, but at least it is bijective.
	chars_a = J(len_a, 1, .)
	for (i=1; i<=len_a; i++) {
		c = ascii(usubstr(a, i, 1))
		if (length(c) == 1) {
			chars_a[i] = c[1]
		}
		else if (length(c) == 2) {
			chars_a[i] = c[1]*256 + c[2]
		}
		else if (length(c) == 3) {
			chars_a[i] = c[1]*65536 + c[2]*256 + c[3]
		}
		else if (length(c) == 4) {
			chars_a[i] = c[1]*16777216 + c[2]*65536 + c[3]*256 + c[4]
		}
		else {
			printf("Unicode should have 1-4 byte groups, but there are %f. Please contact the authors.\n", length(c))
		}
	}
	
	chars_b = J(len_b, 1, .)
	for (i=1; i<=len_b; i++) {
		c = ascii(usubstr(b, i, 1))
		if (length(c) == 1) {
			chars_b[i] = c
		}
		else if (length(c) == 2) {
			chars_b[i] = c[1]*256 + c[2]
		}
		else if (length(c) == 3) {
			chars_b[i] = c[1]*65536 + c[2]*256 + c[3]
		}
		else if (length(c) == 4) {
			chars_b[i] = c[1]*16777216 + c[2]*65536 + c[3]*256 + c[4]
		}
		else {
			printf("Unicode should have 1-4 byte groups, but there are %f. Please contact the authors.\n", length(c))
		}
	}

	// Algorithm with stopping condition
	if (maxdist < .) {
		for (i=1; i<=len_a; i++) {
			v1[1] = i
			for (j=1; j<=len_b; j++) {
				cost = chars_a[i] != chars_b[j]
				v1[j + 1] = minmax(( v1[j] + 1, v0[j+1] + 1, v0[j] + cost ))[1]
			}
			swap(v0, v1)
			// If the minimum necessary edit distance is exceeded, stop
			if (minmax(v0)[1] > maxdist) return(.)
		}
		// Final check: Is the edit distance really not exceeded?
		if (v0[len_b+1] > maxdist) return(.)
		return(v0[len_b+1])
	}
	// Algorithm without stopping condition
	else {
		for (i=1; i<=len_a; i++) {
			v1[1] = i
			for (j=1; j<=len_b; j++) {
				cost = chars_a[i] != chars_b[j]
				v1[j + 1] = minmax(( v1[j] + 1, v0[j+1] + 1, v0[j] + cost ))[1]
			}
			swap(v0, v1)
		}
		return(v0[len_b+1])
	}
}
end


mata
	dis_matrix3=J(st_nobs(),st_nobs(),.)
	st_sview(title_bare="",.,1)
	
	for (i=1; i<=st_nobs(); i++) {
		for (j=i; j<=st_nobs(); j++) {
			dist=ufastlev(title_bare[i], title_bare[j])	
			dis_matrix3[i,j] = dist
			dis_matrix3[j,i] = dist
		}
	}
end

timer off 3

//mata: dis_matrix3

timer list