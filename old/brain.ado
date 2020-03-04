cap program drop brain
program define brain, rclass
	version 10.0
	syntax anything(id="command") [pweight fweight aweight iweight/] [if] [in], [Hidden(numlist)] [INput(varlist)] [Output(varlist)] [ITer(integer 0)] [Eta(real 0.25)] [Spread(real 0.5)] [BAtch(integer 1)] [Report(integer 10)] [BEst] [RAW] [Noshuffle]
	token `"`anything'"'
	local raw = "`raw'" != ""
	local noshuffle = "`noshuffle'" != ""
	local best = "`best'" != ""
	if `"`weight'"' != "" {
		local weight = `"`exp'"'
	}
	if length(`"`1'"') < 2 {
		di as error "invalid brain command"
		error 999
	}
	if `"`1'"' == substr("fit",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "fit does not allow weights"
			error 999
		}
		tempvar touse pred
		macro shift
		local wc = wordcount(`"`*'"')
		if `wc' > 2 {
			di as error "too many variables"
			error 999
		}
		if `wc' < 1 {
			di as error "specify at least the original variable"
			error 999
		}
		forvalues i = 1/`wc' {
			confirm var ``i''
		}
		marksample touse
		local true = `"`1'"'
		if `wc' == 1 {
			if colsof(output) != 1 {
				di as error "predicted variable can only be omitted for univariate output"
				error 999
			}
			brain think `pred' if `touse'
		}
		else {
			local pred = `"`2'"'
		}
		markout `touse' `true' `pred'
		qui sum `true' if `touse'
		if r(min) < 0 | r(max) > 1 {
			di as error "invalid original variable"
			error 999
		}
		qui sum `pred' if `touse'
		if r(min) < 0 | r(max) > 1 {
			di as error "invalid predicted variable"
			error 999
		}
		qui count if `touse'
		local N = r(N)
		qui count if `touse' & `pred' >= 0.5 & `true' >= 0.5
		local TP = r(N)
		qui count if `touse' & `pred' >= 0.5 & `true' < 0.5
		local FP = r(N)
		qui count if `touse' & `pred' < 0.5 & `true' < 0.5
		local TN = r(N)
		qui count if `touse' & `pred' < 0.5 & `true' >= 0.5
		local FN = r(N)
		local Trecall = `TP'/(`TP'+`FN') * 100
		local Frecall = `TN'/(`TN'+`FP') * 100
		local Tprecision = `TP'/(`TP'+`FP') * 100
		local Fprecision = `TN'/(`TN'+`FN') * 100
		local accuracy = (`TP'+`TN')/(`TP'+`TN'+`FP'+`FN') * 100
		local fit = string(`accuracy',"%6.2f")
		local len = 7-length("`fit'")
		di as text "{hline 11}{c TT}{hline 26}
		di as text "Acc " as result "`fit'" as text "{dup `len': }{c |}         True        False"
		di as text "{hline 11}{c +}{hline 26}
		di as text "Positive   {c |} " as result %12.0f `TP' " " %12.0f `FP'
		di as text "Negative   {c |} " as result %12.0f `TN' " " %12.0f `FN'
		di as text "{hline 11}{c +}{hline 26}
		di as text "Recall     {c |} " as result %12.2fc `Trecall' " " %12.2fc `Frecall' 
		di as text "Precision  {c |} " as result %12.2fc `Tprecision' " " %12.2fc `Fprecision' 
		di as text "{hline 11}{c BT}{hline 26}
		return scalar accuracy = `accuracy'
		return scalar Fprecision = `Fprecision'
		return scalar Tprecision = `Tprecision'
		return scalar Frecall = `Frecall'
		return scalar Trecall = `Trecall'
		return scalar FN = `FN'
		return scalar TN = `TN'
		return scalar FP = `FP'
		return scalar TP = `TP'
		return scalar N = `N'
		exit
	}
	if `"`1'"' == substr("define",1,length(`"`1'"')) {
		if `"`weight'"' != "" {
			di as error "define does not allow weights"
			error 999
		}
		if `"`input'"' == "" {
			di as error "no input variables specified"
			error 999
		}
		if `"`output'"' == "" {
			di as error "no output variables specified"
			error 999
		}
		local inp = wordcount(`"`input'"')
		local out = wordcount(`"`output'"')
		local hidden = `"`inp' `hidden' `out'"'
		token `"`hidden'"'
		local layer = ""
		local i = 1
		while "``i''" != "" {
			cap confirm integer number ``i''
			if _rc > 0 {
				di as error "invalid layer number"
				error 999
			}
			if ``i'' <= 0 {
				di as error "invalid layer definition"
				error 999
			}
			local layer = `"`layer',``i''"'
			local i = `i' + 1 
		}
		local layer = "("+substr(`"`layer'"',2,.)+")"
		matrix layer = `layer'
		if wordcount(`"`input'"') != layer[1,1] {
			di as error "invalid number of input variables, " layer[1,1] " required"
			matrix drop layer
			error 999
		}
		if wordcount(`"`output'"') != layer[1,colsof(layer)] {
			di as error "invalid number of output variables, " layer[1,colsof(layer)] " required"
			matrix drop layer
			error 999
		}
		matrix input = J(4,layer[1,1],0)
		local i = 1
		foreach v of varlist `input' {
			qui sum `v' `if' `in'
			matrix input[1,`i'] = r(min)
			matrix input[2,`i'] = 1 / (r(max) - r(min))
			if input[2,`i'] == . {
				matrix input[2,`i'] = 1
			}
			local i = `i'+1
		}
		matrix colnames input = `input'
		matrix rownames input = min norm value signal
		matrix output = J(4,layer[1,colsof(layer)],0)
		local i = 1
		foreach v of varlist `output' {
			qui sum `v' `if' `in'
			matrix output[1,`i'] = r(min)
			matrix output[2,`i'] = 1 / (r(max) - r(min))
			if output[2,`i'] == . {
				matrix output[2,`i'] = 1
			}
			local i = `i'+1
		}
		matrix colnames output = `output'
		matrix rownames output = min norm value signal
		braincreate
		braininit `spread'
		di as text "Defined matrices:"
		braindir
		exit
	}
	if `"`1'"' == substr("save",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "save does not allow weights"
			error 999
		}
		if `"`2'"' == "" {
			di as error "no file specified"
			error 999
		}
		local using = `"`2'"'
		tempname save
		cap local layer = colsof(layer)
		if _rc > 0 {
			di as error "no network defined"
			error 999
		}
		cap local size = colsof(brain)
		if _rc > 0 {
			di as error "no network defined"
			error 999
		}
		cap local isize = colsof(input)
		if _rc > 0 {
			di as error "no network defined"
			error 999
		}
		cap local osize = colsof(output)
		if _rc > 0 {
			di as error "no network defined"
			error 999
		}
		local using = subinstr(trim(`"`using'"'),"\","/",.)
		if regex(`"`using'?"',"\.[^/]*\?") == 0 {
			local using = `"`using'.brn"'
		}
		qui file open `save' using `"`using'"', write binary replace
		file write `save' %9s `"braindead"'
		file write `save' %4bu (`layer')
		forvalue i = 1/`layer' {
			file write `save' %4bu (layer[1,`i'])
		}
		local names : colnames input
		local len = length(`"`names'"')
		file write `save' %4bu (`len')
		file write `save' %`len's `"`names'"'
		local isize = layer[1,1]
		forvalue i = 1/`isize' {
			file write `save' %8z (input[1,`i'])
			file write `save' %8z (input[2,`i'])
		}
		local names : colnames output
		local len = length(`"`names'"')
		file write `save' %4bu (`len')
		file write `save' %`len's `"`names'"'
		local osize = layer[1,colsof(layer)]
		forvalue i = 1/`osize' {
			file write `save' %8z (output[1,`i'])
			file write `save' %8z (output[2,`i'])
		}
		forvalue i = 1/`size' {
			file write `save' %8z (brain[1,`i'])
		}
		file close `save'
		exit
	}
	if "`1'" == substr("load",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "load does not allow weights"
			error 999
		}
		if `"`2'"' == "" {
			di as error "no file specified"
			error 999
		}
		local using = `"`2'"'
		tempname load bin
		local using = subinstr(trim(`"`using'"'),"\","/",.)
		if regex(`"`using'?"',"\.[^/]*\?") == 0 {
			local using = "`using'.brn"
		}
		file open `load' using `"`using'"', read binary
		file read `load' %9s str
		if `"`str'"' != "braindead" {
			di as error "invalid file format"
			file close `load'
			error 999
		}		
		file read `load' %4bu `bin'
		local layer = `bin'
		matrix layer = J(1,`layer',0)
		forvalue i = 1/`layer' {
			file read `load' %4bu `bin'
			if r(eof) {
				di as error "invalid file format"
				file close `load'
				error 999
			}
			matrix layer[1,`i'] = `bin'
		}
		file read `load' %4bu `bin'
		local len = `bin'
		file read `load' %`len's str
		local layer = layer[1,1]
		matrix input = J(4,`layer',0)
		matrix colnames input = `str'
		matrix rownames input = min norm value signal
		forvalue i = 1/`layer' {
			file read `load' %8z `bin'
			matrix input[1,`i'] = `bin'
			file read `load' %8z `bin'
			matrix input[2,`i'] = `bin'
		}
		file read `load' %4bu `bin'
		local len = `bin'
		file read `load' %`len's str
		local layer = layer[1,colsof(layer)]
		matrix output = J(4,`layer',0)
		matrix colnames output = `str'
		matrix rownames output = min norm value signal
		forvalue i = 1/`layer' {
			file read `load' %8z `bin'
			matrix output[1,`i'] = `bin'
			file read `load' %8z `bin'
			matrix output[2,`i'] = `bin'
		}
		braincreate
		local size = colsof(brain)
		local i = 0
		while 1 {
			file read `load' %8z `bin'
			if r(eof) {
				continue, break
			}
			local i = `i'+1
			if `i' > `size' {
				di as error "invalid file format"
				file close `load'
				error 999
			}
			matrix brain[1,`i'] = `bin'
		}
		if `i' < `size' {
			di as error "invalid file format"
			file close `load'
			error 999
		}
		file close `load'
		di as text "Loaded matrices:"
		braindir
		exit
	}
	if `"`1'"' == substr("feed",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "feed does not allow weights"
			error 999
		}
		macro shift
		tempname output
		local isize = colsof(input)
		local osize = colsof(output)
		local ostart = colsof(neuron)-`osize'+1
		local wc = wordcount(`"`*'"')
		if `wc' != `isize' {
			di as error "number of values does not match input neurons (`wc' <> `isize')"
			error 999
		}
		foreach v in `*' {
			cap confirm number `v'
			if _rc != 0 {
				di as error "invalid value: `v'"
				error 999
			}
		}
		local i = 1
		if `raw' {
			while `"``i''"' != "" {
				matrix input[4,`i'] = max(min(``i'',1),0)
				local i = `i'+1
			}
			forvalue i = 1/`isize' {
				matrix input[3,`i'] = input[4,`i'] / input[2,`i'] + input[1,`i']
				matrix neuron[1,`i'] = input[4,`i']
			}
		}
		else {
			while `"``i''"' != "" {
				matrix input[3,`i'] = ``i''
				local i = `i'+1
			}
			forvalue i = 1/`isize' {
				matrix input[4,`i'] = max(min((input[3,`i']-input[1,`i']) * input[2,`i'],1),0)
				matrix neuron[1,`i'] = input[4,`i']
			}
		}
		mata: brainforward()
		matrix `output' = output[3..4,1...]
		matrix list `output', noheader format(%18.9f)
		return matrix output = `output'
		exit
	}
	if `"`1'"' == substr("signal",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "signal does not allow weights"
			error 999
		}
		macro shift
		tempname signal
		local isize = colsof(input)
		local osize = colsof(output)
		local ostart = colsof(neuron)-`osize'+1
		local nsize = colsof(neuron)
		local raw = 3+`raw' // 3 = value, 4 = signal
		local inames : colnames input
		local onames : colnames output
		matrix `signal' = J(`isize'+1, `osize', 0)
		matrix colnames `signal' = `onames'
		matrix rownames `signal' = `inames' flatline
		matrix neuron[1,1] = J(1,`isize', 0)
		mata: brainforward()
		matrix `signal'[`isize'+1,1] = output[`raw',1...]
		forvalue i = 1/`isize' {
			matrix neuron[1, 1] = J(1,`isize', 0)
			matrix neuron[1, `i'] = 1
			mata: brainforward()
			matrix `signal'[`i',1] = output[`raw',1]-`signal'[`isize'+1,1]
		}
		matrix list `signal', noheader format(%18.9f)
		return matrix signal = `signal'
		exit
	}
	if `"`1'"' == substr("margin",1,length("`1'")) {
		tempname signal 
		tempvar delta touse w
		macro shift
		local inames : colnames input
		local onames : colnames output
		local mnames = "`inames'"
		local osize = colsof(output)
		local isize = colsof(input)
		local msize = `isize'
		if `"`*'"' != "" {
			local mnames = ""
			local msize = 0
			foreach v of varlist `*' {
				if index(" `inames' ", " `v' ") == 0 {
					di as error "invalid input variable `v'"
					error 999
				}
				if index(" `mnames' "," `v' ") > 0 {
					di as error "input variable `v' already defined"
					error 999
				}
				local mnames = "`mnames' `v'"
				local msize = `msize'+1
			}
		}
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		markout `touse' `inames' `onames'
		brainweight `w' `touse' `weight'
		local bnames = ""
		forvalue o = 1/`osize' {
			tempvar signal`o' base`o'
			qui gen double `signal`o'' = .
			qui gen double `base`o'' = .
			local snames = "`snames' `signal`o''"
			local bnames = "`bnames' `base`o''"
		}
		qui gen double `delta' = .
		matrix `signal' = J(`msize',`osize', 0)
		matrix rownames `signal' = `mnames'
		local cnames = ""
		forvalue o = 1/`osize' {
			local oname = word("`onames'", `o')
			local cnames = "`cnames' `oname'"
		}
		di as text "unrestricted " _continue
		matrix colnames `signal' = `cnames'
		order `inames' `bnames' `touse'
		mata: brainsignal(0)
		order `inames' `snames' `touse'
		local ind = 0
		foreach v of varlist `mnames' {
			forvalue i = 1/`isize' {
				local iname = word("`inames'", `i')
				if "`v'" == "`iname'" {
					di as result "`iname' " _continue
					mata: brainsignal(`i')
					local ind = `ind' + 1
					forvalue o = 1/`osize' {
						local oname = word("`onames'", `o')
						qui replace `delta' = `base`o''-`signal`o'' if `touse'
						qui sum `delta' [aweight=`w'] if `touse'
						matrix `signal'[`ind',`o'] = r(mean)
					}
					continue, break
				}
			}
		}
		di ""
		matrix list `signal', noheader format(%18.9f)
		return matrix margin = `signal'
		order `names'
		exit
	}
	if `"`1'"' == substr("think",1,length("`1'")) {
		if `"`weight'"' != "" {
			di as error "think does not allow weights"
			error 999
		}
		tempvar touse
		macro shift
		local wc = wordcount(`"`*'"')
		local osize = colsof(output)
		if `wc' != `osize' {
			di as error "number of target variables does not match output neurons (`wc' <> `osize')"
			error 999
		}
		foreach v in `*' {
			cap drop `v'
			qui gen double `v' = .
		}
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		local inames : colnames input
		markout `touse' `inames' 
		order `inames' `*' `touse'
		mata: brainthink()
		order `names'
		exit
	}
	if `"`1'"' == substr("error",1,length("`1'")) {
		tempvar touse w
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		local inames : colnames input
		local onames : colnames output
		markout `touse' `inames' `onames'
		brainweight `w' `touse' `weight'
		order `inames' `onames' `w'
		mata: brainerror()
		local err = r(error)
		local N = r(N)
		di as text "Number of obs = " as result %12.0fc `N'
		di as text "Error         = " as result %12.9f `err'
		return scalar N = `N'
		return scalar err = `err'
		order `names'
		exit
	}
	if `"`1'"' == substr("train",1,length("`1'")) {
		tempvar touse w
		tempname bestbrain
		if `eta' <= 0 {
			di as error "eta has to be a number larger than zero"
			error 999
		}
		if `iter' <= 0 {
			di as error "number of iterations has to be larger than zero"
			error 999
		}
		if `batch' < 1 {
			di as error "batch size has to be larger than zero"
			error 999
		}
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		local inames : colnames input
		local onames : colnames output
		markout `touse' `inames' `onames'
		brainweight `w' `touse' `weight'
		qui count if `touse'
		local N = r(N)
		order `inames' `onames' `w' `touse'
		local err = 0
		local prev = .
		di as text "{hline 40}" 
		di as text "Brain{dup 7: }Number of obs = " as result %12.0fc `N'
		di as text "Train{dup 17: }eta = " as result %12.6f `eta'
		di as text "{hline 10}{c TT}{hline 14}{c TT}{hline 14}"
		di as text "Iteration {c |}        Error {c |}        Delta"
		di as text "{hline 10}{c +}{hline 14}{c +}{hline 14}"
		local miniter = 0
		if `best' {
			mata: brainerror()
			local minerr = r(error)
			matrix `bestbrain' = brain
			di as result %9.0f 0 as text " {c |} " as result %12.9f `minerr' as text " {c |} " as result %12.9f .
			local prev = `minerr'
		}
		else {
			local minerr = -1
		}
		local i = 0
		while `i' < `iter' {
			local epoch = cond(`i'+`report' <= `iter',`report',`iter'-`i') 
			mata: braintrain(`eta', `batch', `epoch', `noshuffle' != 1)
			mata: brainerror()
			local err = r(error)
			local delta = `err'-`prev'
			local prev = `err'
			local i = `i'+`epoch'
			di as result %9.0f `i' as text " {c |} " as result %12.9f `err' as text " {c |} " as result %12.9f `delta'
			if `err' < `minerr' {
				matrix `bestbrain' = brain
				local miniter = `i'
				local minerr = `err'
			}
		}
		if `best' & `err' > `minerr' {
			matrix brain = `bestbrain'
			local delta = `minerr'-`prev'
			local err = `minerr'
			local iter = `miniter'
		}
		di as text "{hline 10}{c +}{hline 14}{c +}{hline 14}"
		di as result %9.0f `iter' as text " {c |} " as result %12.9f `err' as text " {c |} " as result %12.9f `delta'
		di as text "{hline 10}{c BT}{hline 14}{c BT}{hline 14}"
		return scalar N = `N'
		return scalar iter = `iter'
		return scalar err = `err'
		order `names'
		exit
	}
	di as error "invalid brain command"
	error 999
end

cap program drop braindir
program define braindir
	di as result "   input[" rowsof(input) ","  colsof(input) "]"
	di as result "  output[" rowsof(output) "," colsof(output) "]"
	di as result "  neuron[" rowsof(neuron) "," colsof(neuron) "]"
	di as result "   layer[" rowsof(layer) "," colsof(layer) "]"
	di as result "   brain[" rowsof(brain) "," colsof(brain) "]"
end

cap program drop braincreate
program define braincreate
	local names = ""
	local size = 0
	local layer = colsof(layer)
	forvalue l = 2/`layer' {
		local p = `l'-1
		local neurons = layer[1,`l']
		local weights = layer[1,`p']
		local size = `size' + `neurons' * (`weights'+1)
		if `l' < `layer' {
			local prefix = "h`p'n"
		}
		else {
			local prefix = "o"
		}
		forvalue n = 1/`neurons' {
			forvalue w = 1/`weights' {
				local names = "`names' `prefix'`n'w`w'"
			}
			local names = "`names' `prefix'`n'b"
		}
	}
	cap matrix brain = J(1,`size',0)
	if _rc > 0 {
		local matsize = int(`size'*1.1)
		set matsize `matsize'
		matrix brain = J(1,`size',0)
	}
	matrix colnames brain = `names'
	matrix rownames brain = weight
	local names = "in"
	local layer = `layer'-2
	forvalue l = 1/`layer' {
		local names = "`names' hid`l'"
	}
	local names = "`names' out"
	matrix colnames layer = `names'
	matrix rownames layer = neurons
	local layer = colsof(layer)
	local names = ""
	local size = 0
	forvalue i = 1/`layer' {
		local neurons = layer[1,`i']
		local size = `size'+`neurons'
		if `i' == 1 {
			local prefix = "in"
		}
		else if `i' == `layer' {
			local prefix = "out"
		}
		else {
			local j = `i'-1
			local prefix = "h`j'n"
		}
		forvalue j = 1/`neurons' {
			local names = "`names' `prefix'`j'"
		}
	}
	matrix neuron = J(1,`size',0)
	matrix colnames neuron = `names'
	matrix rownames neuron = signal
end	

cap program drop braininit
program define braininit
	local spread = abs(`1')
	local range = `spread'*2
	local size = colsof(brain)
	forvalue i = 1/`size' {
		matrix brain[1,`i'] = uniform()*`range'-`spread'
	}
end	

cap program drop brainweight
program define brainweight
	local w = "`1'"
	local touse = "`2'"
	local exp = "`3'"
	if `"`exp'"' == "" {
		qui gen byte `w' = 1
	}
	else {
		qui gen `w' = `exp' if `touse'
		qui sum `w'
		local min = r(min)
		local max = r(max)
		if r(min) < 0 {
			di as error "negative weights not allowed"
			error 999
		}
		qui replace `w' = `w'/`max'
	}
end

mata:

void input2neuron(real matrix input, real matrix neuron)
{	real matrix sel
	input[4,.] = (input[3,.] - input[1,.]) :* input[2,.]
	sel = selectindex(input[4,.] :< 0)
	if (cols(sel) > 0) input[4,sel] = J(1,cols(sel),0)
	sel = selectindex(input[4,.] :> 1)
	if (cols(sel) > 0) input[4,sel] = J(1,cols(sel),1)
	neuron[1,1..cols(input)] = input[4,.]
}

void output2neuron(real matrix output)
{	real matrix sel
	output[4,.] = (output[3,.] - output[1,.]) :* output[2,.]
	sel = selectindex(output[4,.] :< 0)
	if (cols(sel) > 0) output[4,sel] = J(1,cols(sel),0)
	sel = selectindex(output[4,.] :> 1)
	if (cols(sel) > 0) output[4,sel] = J(1,cols(sel),1)
}

void neuron2output(real matrix neuron, real matrix output)
{	real scalar ocol, ostart
	ocol = cols(output)
	ostart = cols(neuron) - ocol + 1
	output[4,.] = neuron[1, ostart..ostart+ocol-1]
	output[3,.] = output[4,.] :/ output[2,.] + output[1,.]
}

void brainforward()
{	real matrix neuron, layer, output
	output = st_matrix("output")
	neuron = st_matrix("neuron")
	brainforw(st_matrix("layer"), neuron, st_matrix("brain"))
	neuron2output(neuron, output)
	st_replacematrix("neuron", neuron)
	st_replacematrix("output", output)
}

void brainforw(layer, neuron, brain)
{	real scalar layers, neurons, npos, wpos
	real scalar l, n, start, weights, net
	real matrix feed
	layers = cols(layer)
	npos = layer[1,1]+1
	wpos = 1
	start = 1
	for (l = 2; l <= layers; l++)
	{	neurons = layer[1,l]
		weights = layer[1,l-1]
		feed = neuron[1, start..start+weights-1], 1
		start = start+weights
		for (n = 1; n <= neurons; n++)
		{	net = sum(feed :* brain[1,wpos..wpos+weights])
			neuron[1,npos] = 1/(1+exp(-net))
			wpos = wpos + weights + 1
			npos++
		}
	}
}

void brainsignal(real scalar inp)
{	real matrix neuron, layer, brain, input, output
	real matrix D
	real scalar obs, icol, ocol, ncol, N
	layer = st_matrix("layer")
	neuron = st_matrix("neuron")
	brain = st_matrix("brain")
	output = st_matrix("output")
	input = st_matrix("input")
	icol = cols(input)
	ocol = cols(output)
	ncol = cols(neuron)
	if (inp < 1 | inp > icol) inp = 0
	st_view(D=.,.,(1..icol+ocol),st_varname(icol+ocol+1)[1])
	for (obs = 1; obs <= rows(D); obs++)
	{	input[3,.] = D[obs,1..icol]
		input2neuron(input, neuron)
		if (inp >= 1) neuron[1,inp] = 0
		brainforw(layer, neuron, brain)
		neuron2output(neuron, output)
		D[obs,icol+1..icol+ocol] = output[3,.]
	}
	st_rclear()
	st_numscalar("r(N)", obs)
}

void brainthink()
{	brainsignal(0)
}

void brainerror()
{	real matrix neuron, layer, brain, input, output
	real matrix D
	real scalar obs, ncol, ocol, icol, error, N, weight, wsum
	layer = st_matrix("layer")
	neuron = st_matrix("neuron")
	brain = st_matrix("brain")
	output = st_matrix("output")
	input = st_matrix("input")
	ncol = cols(neuron)
	ocol = cols(output)	
	icol = cols(input)
	st_view(D=.,.,(1..icol+ocol+1),st_varname(icol+ocol+2)[1])
	N = rows(D)
	error = 0
	wsum = 0
	for (obs = 1; obs <= N; obs++)
	{	input[3,.] = D[obs,1..icol]
		output[3,.] = D[obs,icol+1..icol+ocol]
		weight = D[obs,icol+ocol+1]
		input2neuron(input, neuron)
		output2neuron(output)
		brainforw(layer, neuron, brain)
		error = error + sum(abs(output[4, .] :- neuron[1, ncol-ocol+1..ncol])) * weight
		wsum = wsum + weight
	}
	error = error/wsum/ocol
	st_rclear()
	st_numscalar("r(error)", error)
	st_numscalar("r(N)", N)
}

real matrix brainbackw(real matrix output, real matrix layer, real matrix neuron, real matrix brain, real scalar weight)
{	real matrix delta, err, diff, sub
	real scalar dpos, wpos, npos, lay, sum
	real scalar n, l
	real scalar ncol, ocol, dcol
	ncol = cols(neuron)
	ocol = cols(output)
	npos = ncol-ocol
	err = (output[4, .] :- neuron[1, npos+1..ncol]) :* weight
	diff = (J(1, ncol-layer[1,1],1) :- neuron[1, layer[1,1]+1..ncol]) :* neuron[1, layer[1,1]+1..ncol]
	dcol = cols(diff)
	delta = err :* diff[1, dcol-ocol+1..dcol]
	wpos = cols(brain)+1
	dpos = dcol-ocol+1
	for (l = cols(layer)-1; l >= 2; l--)
	{	lay = layer[1, l]
		err = J(1, lay, 0)
		dcol = dpos-1
		dpos = dpos-lay
		sub = diff[1, dpos..dcol]
		for (n = layer[1, l+1]; n >= 1; n--)
		{	wpos = wpos - lay - 1
			err = err :+ delta[1, n] :* brain[1, wpos..wpos+lay-1] :* sub
		}
		delta = err, delta
	}
	npos = 1
	dpos = 1
	for (l = 2; l <= cols(layer); l++)
	{	lay = layer[1, l-1]
		sub = (neuron[1, npos..npos+lay-1], 1)
		if (l == 2)
		{	err = delta[1, dpos] :* sub
			dpos++
			for (n = 2; n <= layer[1, l]; n++)
			{	err = err, (delta[1, dpos] :* sub)
				dpos++	
			}
		}
		else
		{	for (n = 1; n <= layer[1, l]; n++)
			{	err = err, (delta[1, dpos] :* sub)
				dpos++
			}
		}
		npos = npos + lay
	}
	return(err)
}

void braintrain(real scalar eta, real scalar batch, real scalar iter, real scalar shuffle)
{	real matrix neuron, layer, brain, input, output, err
	real matrix touse, D
	real scalar obs, icol, ocol, b, i, N, weight
	layer = st_matrix("layer")
	neuron = st_matrix("neuron")
	brain = st_matrix("brain")
	output = st_matrix("output")
	input = st_matrix("input")
	icol = cols(input)
	ocol = cols(output)
	st_view(D=.,.,(1..icol+ocol+1),st_varname(icol+ocol+2)[1])
	N = rows(D)
	b = 0
	for (i = 1; i <= iter; i++)
	{	if (shuffle)
		{	D = jumble(D)
		}
		for (obs = 1; obs <= N; obs++)
		{	input[3,.] = D[obs,1..icol]
			output[3,.] = D[obs,icol+1..icol+ocol]
			weight = D[obs,icol+ocol+1]
			input2neuron(input, neuron)
			output2neuron(output)
			brainforw(layer, neuron, brain)
			if (b == 0)
			{	err = brainbackw(output, layer, neuron, brain, weight)
			}
			else
			{	err = err :+ brainbackw(output, layer, neuron, brain, weight)
			}
			b++
			if (b >= batch | obs == N)
			{	err = (eta/b) :* err 
				brain = brain :+ err
				b = 0
			}
		}
	}
	st_replacematrix("brain",brain)
	st_rclear()
	st_numscalar("r(N)", N)
}

void printm(real matrix m, string scalar name)
{	printf("\n%s",name)
	for (i = 1; i <= rows(m); i++)
	{	printf("\n%f: ",i)
		for (j = 1; j <= cols(m); j++)
		{	printf("[%f]", m[i,j])
		}
	}
}
end	
