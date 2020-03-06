cap program drop brain
program define brain, rclass
	version 10.0
	local cmd = word(subinstr(`"`1'"',","," ",1),1)
	local cmdlen = length(`"`cmd'"')
	if strpos(lower("`c(os)'"),"mac") {
		local os = "mac"
	}
	else if strpos(lower("`c(os)'"),"win") {
		local os = "win"
	}
	else {
		local os = "unix"
	}
	local plugin = ""
	cap plugin call brainiac  // check plugin
	if "`plugin'" == "" {
		if "`os'" == "win" {
			cap program brainiac, plugin using("brainwin.plugin")
			if _rc != 0 { // fallback in case of non-native compiler
				qui findfile "brainwin.plugin"
				local brainpath = substr(r(fn),1,length(r(fn))-15)
				local workpath = "`c(pwd)'"
				qui cd "`brainpath'"  // required to load dlls
				cap program brainiac, plugin using("`brainpath'brainwin.plugin")
				if _rc != 0 {
					qui cd "`workpath'"
					di as error "non-natively compiled windows plugin detected, e.g. cygwin/mingw"
					di as error "unable to load " as result "brainwin.plugin" as error " from directory " as result "`brainpath'"
					di as error "perhaps, additional dlls are required in that directory, e.g.:" _newline as result "brain`os'.plugin" _newline "libgomp-1.dll" _newline "libwinpthread-1.dll" _newline "libgcc_s_seh-1.dll"
					error 999
				}
				qui cd "`workpath'"
			}
		}
		else {
			program brainiac, plugin using("brain`os'.plugin")
		}
		plugin call brainiac
	}
	local version = word("`plugin'",1)
	local procs = word("`plugin'",2)
	if `cmdlen' == 0 {
		di as txt "brain`os'.plugin " as result "`version'"
		di as text "brain uses " as result "`procs'" as txt " processors" 
		return local plugin = "brain`os'.plugin"
		return local version = "`version'"
		return scalar mp = `procs'
		exit
	}
	if `cmdlen' < 2 {
		di as error "invalid brain command"
		error 999
	}
	if `"`cmd'"' == substr("fit",1,`cmdlen') {
		syntax [anything(id=command)] [pweight fweight aweight iweight/] [if] [in], [SP]
		token `"`anything'"'
		macro shift
		local mp = cond("`sp'" == "", "MP", "SP")
		tempvar touse pred
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
			plugin call brainiac `pred' if `touse', think`mp'
		}
		else {
			local pred = `"`2'"'
		}
		markout `touse' `true' `pred'
		qui sum `true' if `touse'
		if r(N) == 0 {
			di as error "no observations"
			error 999
		}
		if r(min) < 0 | r(max) > 1 {
			di as error "invalid original variable"
			error 999
		}
		qui sum `pred' if `touse'
		if r(N) == 0 {
			di as error "no observations"
			error 999
		}
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
	if `"`cmd'"' == substr("define",1,`cmdlen') {
		syntax anything(id=command) [if] [in], INput(varlist) Output(varlist) [Hidden(numlist)] [Spread(real 0.5)]
		token `"`anything'"'
		macro shift
		if `"`1'"' != "" {
			di error 198
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
	if `"`cmd'"' == substr("save",1,`cmdlen') {
		syntax anything(id=command)
		token `"`anything'"'
		macro shift
		if `"`1'"' == "" {
			di as error "no file specified"
			error 999
		}
		if `"`2'"' != "" {
			di error 198
		}
		local using = `"`1'"'
		tempname save
		cap local layer = colsof(layer)
		if _rc > 0 {
			di as error "no network defined"
			error 999
		}
		cap local size = colsof(brain1)
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
		local b = 1
		cap local size = colsof(brain`b')
		while _rc == 0 {
			forvalue i = 1/`size' {
				file write `save' %8z (brain`b'[1,`i'])
			}
			local b = `b'+1
			cap local size = colsof(brain`b')
		}
		file close `save'
		exit
	}
	if `"`cmd'"' == substr("load",1,`cmdlen') {
		syntax anything(id=command)
		token `"`anything'"'
		macro shift
		if `"`1'"' == "" {
			di as error "no file specified"
			error 999
		}
		if `"`2'"' != "" {
			di error 198
		}
		local using = `"`1'"'
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
		local b = 1
		cap local size = colsof(brain`b')
		while _rc == 0 {
			forvalue i = 1/`size' {
				file read `load' %8z `bin'
				if r(eof) {
					di as error "invalid file format"
					file close `load'
					error 999
				}
				matrix brain`b'[1,`i'] = `bin'
			}
			local b = `b'+1
			cap local size = colsof(brain`b')
		}
		file read `load' %8z `bin'
		if r(eof) == 0 {
			di as error "invalid file format"
			file close `load'
			error 999
		}
		file close `load'
		di as text "Loaded matrices:"
		braindir
		exit
	}
	if `"`cmd'"' == substr("feed",1,`cmdlen') {
		syntax anything(id=command), [RAW]
		token `"`anything'"'
		macro shift
		local raw = "`raw'" != ""
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
		if `raw' {
			forvalue i = 1/`isize' {
				matrix input[4,`i'] = ``i''
			}
		}
		else {
			forvalue i = 1/`isize' {
				matrix input[3,`i'] = ``i''
			}
		}
		plugin call brainiac, forward `raw'
		matrix `output' = output[3..4,1...]
		matrix list `output', noheader format(%18.9f)
		return matrix output = `output'
		exit
	}
	if `"`cmd'"' == substr("signal",1,`cmdlen') {
		syntax anything(id=command), [RAW]
		token `"`anything'"'
		macro shift
		if "`1'" != "" {
			error 198
		}
		local raw = "`raw'" != ""
		tempname signal
		local isize = colsof(input)
		local osize = colsof(output)
		local nsize = colsof(neuron)
		local ostart = `nsize'-`osize'+1
		local raw = 3+`raw' // 3 = value, 4 = signal
		local inames : colnames input
		local onames : colnames output
		matrix `signal' = J(`isize'+1, `osize', 0)
		matrix colnames `signal' = `onames'
		matrix rownames `signal' = `inames' flatline
		matrix input[4,1] = J(1,`isize', 0)
		plugin call brainiac, forward 1
		matrix `signal'[`isize'+1,1] = output[`raw',1...]
		forvalue i = 1/`isize' {
			matrix input[4,1] = J(1,`isize', 0)
			matrix input[4,`i'] = 1
			plugin call brainiac, forward 1
			matrix `signal'[`i',1] = output[`raw',1]-`signal'[`isize'+1,1]
		}
		matrix list `signal', noheader format(%18.9f)
		return matrix signal = `signal'
		exit
	}
	if `"`cmd'"' == substr("margin",1,`cmdlen') {
		syntax anything(id=command) [pweight fweight aweight iweight/] [if] [in], [SP]
		token `"`anything'"'
		macro shift
		local mp = cond("`sp'" == "", "MP", "SP")
		tempname signal 
		tempvar delta touse w
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
		brainweight `w' `touse' `exp'
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
		plugin call brainiac `inames' `bnames' if `touse', think`mp'
		local ind = 0
		foreach v of varlist `mnames' {
			forvalue i = 1/`isize' {
				local iname = word("`inames'", `i')
				if "`v'" == "`iname'" {
					di as result "`iname' " _continue
					plugin call brainiac `inames' `snames' if `touse', think`mp' `i'
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
		exit
	}
	if `"`cmd'"' == substr("think",1,`cmdlen') {
		syntax anything(id=command) [if] [in], [SP]
		token `"`anything'"'
		macro shift
		local mp = cond("`sp'" == "", "MP", "SP")
		tempvar touse
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
		plugin call brainiac `inames' `*' if `touse', think`mp'
		return scalar N = `plugin'
		exit
	}
	if `"`cmd'"' == substr("error",1,`cmdlen') {
		syntax anything(id=command) [pweight fweight aweight iweight/] [if] [in], [SP]
		token `"`anything'"'
		macro shift
		if "`1'" != "" {
			error 198
		}
		local mp = cond("`sp'" == "", "MP", "SP")
		tempvar touse w
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		local inames : colnames input
		local onames : colnames output
		markout `touse' `inames' `onames'
		brainweight `w' `touse' `exp'
		plugin call brainiac `inames' `onames' `w' if `touse', error`mp'
		local err = word("`plugin'", 1)
		local N = word("`plugin'", 2)
		di as text "Number of obs = " as result %12.0fc `N'
		di as text "Error         = " as result %12.9f `err'
		return scalar N = `N'
		return scalar err = `err'
		exit
	}
	if `"`cmd'"' == substr("train",1,`cmdlen') {
		syntax anything(id=command) [pweight fweight aweight iweight/] [if] [in], [ITer(integer 0)] [Eta(real 0.25)] [BAtch(integer 1)] [Report(integer 10)] [BEst] [SP] [Noshuffle]
		token `"`anything'"'
		macro shift
		if "`1'" != "" {
			error 198
		}
		local mp = cond("`sp'" == "", "MP", "SP")
		local shuffle = "`noshuffle'" == ""
		local best = "`best'" != ""
		tempvar touse w
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
		local mptrain = "`mp'"
		if `batch' <= 1 {
			local mptrain = "SP"  // multiprocessing only works with mini-batches
		}
		if `best' {
			local b = 1
			cap local row = rowsof(brain`b')
			while _rc == 0 {
				tempname best`b'
				local b = `b'+1
				cap local row = rowsof(brain`b')
			}
		}
		marksample touse    
		qui des, varlist
		local names = r(varlist)
		local inames : colnames input
		local onames : colnames output
		markout `touse' `inames' `onames'
		brainweight `w' `touse' `exp'
		qui count if `touse'
		local N = r(N)
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
			plugin call brainiac `inames' `onames' `w' if `touse', error`mp'
			local minerr = word("`plugin'",1)
			local b = 1
			cap local row = rowsof(brain`b')
			while _rc == 0 {
				matrix `best`b'' = brain`b'
				local b = `b'+1
				cap local row = rowsof(brain`b')
			}
			di as result %9.0f 0 as text " {c |} " as result %12.9f `minerr' as text " {c |} " as result %12.9f .
			local prev = `minerr'
		}
		else {
			local minerr = -1
		}
		local i = 0
		while `i' < `iter' {
			local epoch = cond(`i'+`report' <= `iter',`report',`iter'-`i') 
			plugin call brainiac `inames' `onames' `w' if `touse', train`mptrain' `eta' `batch' `epoch' `shuffle'
			plugin call brainiac `inames' `onames' `w' if `touse', error`mp'
			local err = word("`plugin'",1)
			local delta = `err'-`prev'
			local prev = `err'
			local i = `i'+`epoch'
			di as result %9.0f `i' as text " {c |} " as result %12.9f `err' as text " {c |} " as result %12.9f `delta'
			if `err' < `minerr' {
				local b = 1
				cap local row = rowsof(brain`b')
				while _rc == 0 {
					matrix `best`b'' = brain`b'
					local b = `b'+1
					cap local row = rowsof(brain`b')
				}
				local miniter = `i'
				local minerr = `err'
			}
		}
		if `best' & `err' >= `minerr' {
			local b = 1
			cap local row = rowsof(brain`b')
			while _rc == 0 {
				matrix brain`b' = `best`b''
				local b = `b'+1
				cap local row = rowsof(brain`b')
			}
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
	local b = 1
	cap local row = rowsof(brain`b')
	while _rc == 0 {
		di as result "  brain`b'[" `row' "," colsof(brain`b') "]"
		local b = `b'+1
		cap local row = rowsof(brain`b')
	}
end

cap program drop braincreate
program define braincreate
	set matsize 10000
	local size = 0
	local layer = colsof(layer)
	local b = 0
	local c = 10000
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
				local c = `c'+1
				if `c' > 10000 {
					local b = `b'+1
					tempname names`b'
					scalar `names`b'' = ""
					local c = 1
				}
				scalar `names`b'' = `names`b'' + " `prefix'`n'w`w'"
			}
			local c = `c'+1
			if `c' > 10000 {
				local b = `b'+1
				tempname names`b'
				scalar `names`b'' = ""
				local c = 1
			}
			scalar `names`b'' = `names`b'' + " `prefix'`n'b"
		}
	}
	local b = 1
	forvalue i = 1(10000)`size' {
		local rest = `size'-`i'+1
		if `rest' > 10000 {
			local rest = 10000
		}
		matrix brain`b' = J(1,`rest',0)
		local names = scalar(`names`b'')
		matrix colnames brain`b' = `names'
		matrix rownames brain`b' = weight
		local b = `b'+1
	}
	cap matrix drop brain`b' // dropping follow-up matrices
	while _rc == 0 {
		local b = `b'+1
		cap matrix drop brain`b' 
	}
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
	local b = 1
	cap local size = colsof(brain`b')
	while _rc == 0 {
		forvalue i = 1/`size' {
			matrix brain`b'[1,`i'] = uniform()*`range'-`spread'
		}
		local b = `b'+1
		cap local size = colsof(brain`b')
	}
end	

cap program drop brainweight
program define brainweight
	local w = "`1'"
	local touse = "`2'"
	local exp = "`3'"
	if `"`exp'"' == "" {
		qui gen double `w' = 1
	}
	else {
		qui gen `w' = `exp' if `touse'
		qui sum `w'
		if r(min) < 0 {
			di as error "negative weights encountered"
			error 999
		}
		qui replace `w' = `w'/r(max)
	}
end
