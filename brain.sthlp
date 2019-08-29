{smcl}
{* 21nov2018}{...}
{hline}
help for {hi:brain}
{hline}

{title:Neural Network}

{p 8}{cmd:brain {ul:de}fine} [{it:if}] [{it:in}], {ul:in}put({it:varlist}) {ul:o}utput({it:varlist}) [{ul:h}idden({it:numlist})] [{ul:s}pread({it:default = 0.25})]

{p 8}{cmd:brain {ul:sa}ve} {it:filename}

{p 8}{cmd:brain {ul:lo}ad} {it:filename}

{p 8}{cmd:brain {ul:si}gnal}, [{ul:raw}] 

{p 8}{cmd:brain {ul:fe}ed} {it:input_signals}, [{ul:raw}] 

{p 8}{cmd:brain {ul:tr}ain} [{it:if}] [{it:in}], {ul:it}er({it:default = 0})  [{ul:e}ta({it:default = 0.25})] [{ul:ba}tch({it:default = 1})] [{ul:r}eport({it:default = 10})] [{ul:be}st] [{ul:n}oshuffle]

{p 8}{cmd:brain {ul:er}ror} [{it:if}] [{it:in}]

{p 8}{cmd:brain {ul:th}ink} {it:output_varlist} [{it:if}] [{it:in}] 

{p 8}{cmd:brain {ul:ma}rgin} [{it:input_varlist}] [{it:if}] [{it:in}] 

{title:Description}

{p}{cmd:brain} implements a backpropagation network based on the following matrices:{p_end}

{p}
{hi:input}{space 2}- defining input variable names, containing the input signal and normalization parameters{break}
{hi:output} - defining output variable names, containing the output signal and normalization parameters{break}
{hi:neuron} - containing neuronal signals{break}
{hi:layer}{space 2}- defining the structure of the network{break}
{hi:brain}{space 2}- containing the synapse weights and bias
{p_end}

{p}{hi:Be aware of potential name conflicts!}{p_end}

{p}Use {cmd:matrix list} {it:matrix_name} to study the content of the network matrices.{p_end}

{title:Commands and Options}

{p 0 4}{cmd:{ul:de}fine}, {ul:in}put({it:varlist}) {ul:o}utput({it:varlist}) [{ul:h}idden({it:numlist})] [{ul:s}pread({it:default = 0.25})]{break}
defines the structure of the neural network. Parameters to normalize the {hi:input} and {hi:output} variables between [0,1] are determined based on the
active data. The {hi:hidden} layers can be omitted, leading to a simple perceptron. If specified, every number defines a hidden layer of the corresponding
size starting at the input layer. The starting values of the synapses are randomly distributed between [-{hi:spread}, +{hi:spread}]. 

{p 0 4}{cmd:{ul:sa}ve} {it:filename}{break}
save the neural network matrizes into a file. Default postfix is ".brn".

{p 0 4}{cmd:{ul:lo}ad} {it:filename}{break}
loads the neural network matrizes from a file. Default postfix is ".brn".

{p 0 4}{cmd:{ul:si}gnal}, [{ul:raw}]{break}
sequentially activates each input signal and reports the difference to the flatline. The signals of the flatline can be found at the bottom of the listing. Specifying {hi:raw} reports signals
in normalized form [0,1].{break}
Stored results:{break}
r({hi:signal}) matrix of input variable on output signals

{p 0 4}{cmd:{ul:fe}ed} {it:input_signals}, [{ul:raw}]{break}
displays the output according to the specified input signals. The option {hi:raw} declares all values as normalized input signals [0,1], otherwise
they will be interpreted according to the respective variable context. The network status can be accessed using {cmd:matrix list} on the following matrices: {hi:input}, {hi:neuron}, {hi:output}{break}
Stored results:{break}
r({hi:output}) matrix of the output signals (de-normalized and raw)

{p 0 4}{cmd:{ul:tr}ain}, {ul:it}er({it:default = 0}) [{ul:e}ta({it:default = 0.25})] [{ul:b}atch({it:default = 1})] [{ul:r}eport({it:default = 10})] [{ul:be}st] [{ul:n}oshuffle]{break}
initiates the backpropagation training for {hi:iter} iterations using a training factor {hi:eta}. If the specified {hi:batch} size is 
larger than 1 stochastic gradient descent (SGD) is applied. All gradients, determined by the backpropagation algorithm, are 
accumulated to a batch gradient, which is applied on the weights. In this case {hi:eta} is divided by the {hi:batch} size. Batch 
training converges faster for deep networks, but may fail if the loss function has multiple global minima (see "sinus" example below). 
The real benefit of batch training, parallelization, is not applicable for Stata, until real multithreading/multipocessing for 
programmers is implemented. In general, the data is reshuffled before an interation. If {hi:noshuffle} is specified, shuffling will be 
omitted. This is useful to hone the network in subsequent trainings, as the gradient decent is more stable along the trodden path and 
the risk of local minima is mitigated by the initial training based on shuffling. A good strategy is to start with shuffling (default) 
and improve the network by subsequent trainings with lower {hi:eta}s and {hi:noshuffle}. The parameter {hi:report} defines the 
interval for the reporting of the average absolute error and the delta to the previously reported error. Especially for large 
{hi:eta}s, the error can fluctuate significantly. The parameter {hi:best} guarantees that the best network according to the 
{hi:report}ed error is used as the final result instead of the last one. This has the benefit of preserving the best network in 
subsequent training sessions but requires enough memory to save a copy of the brain matrix.{break}
Stored results:{break}
r({hi:N}) number used observations{break}
r({hi:iter}) iteration used for the final brain matrix (see {hi:best}){break}
r({hi:err}) final error{break}

{p 0 4}{cmd:{ul:er}ror}{break}
reports the average absolute error, which is the sum of all absolute errors divided by the number of obs and the number of output variables.{break}
Stored results:{break}
r({hi:N}) number used observations{break}
r({hi:err}) average absolute error{break}

{p 0 4}{cmd:{ul:th}ink} {it:output_varlist}{break}
creates or overwrites the specified output variables with the prediction of the network. The number of output variables has to match the number
of output neurons. If an input variable exceeds the limits defined for the network, its signal will get truncated accordingly to stay in the range [0,1].

{p 0 4}{cmd:brain {ul:ma}rgin} [{it:input_varlist}] [{it:if}] [{it:in}]{break}
reports the marginal effect of the selected input variables (default = all) on the output variables by calculating the difference between the estimated output and the
output with a constant zero signal for the respective input variable.{break}
Stored results:{break}
r({hi:margin}) matrix of input variables on marginal output signals

{title:Example 1: OLS vs brain on unobserved interaction and polynomials}
{inp}
    set obs 100
    gen x1 = invnorm(uniform())
    gen x2 = invnorm(uniform())
    gen y = x1 + x2 + x1^2 + x2^2 + x1*x2

    sum y
    scalar ymean = r(mean)
    egen sst = sum((y-ymean)^2)

    reg y x1 x2

    predict yreg
    egen rreg = sum((y-yreg)^2)

    brain define, input(x1 x2) output(y) hidden(10 10)
    brain train, iter(500) eta(1)
    brain think ybrain

    egen rbrain = sum((y-ybrain)^2)

    di "R-squared reg: " 1-rreg/sst
    di "R-sq.   brain: " 1-rbrain/sst
{text}

{title:Example 2: OLS vs brain on non-linear function}
{inp}
    set obs 200
    gen x = 4*_pi/200 *_n
    gen y = sin(x)

    reg y x
    predict yreg

    brain define, input(x) output(y) hidden(20)
    brain train, iter(500) eta(2) // try this with: batch(4)
    brain think ybrain

    twoway (scatter y x, sort) (line yreg x, sort) (line ybrain x, sort)
{text}

{title: Update History}

{p 0 11}{hi:2019.03.22} Implemented {hi:batch} training.{break}
Changed training ouput to interval reports of real absolute errors instead of intermediate errors.{break}
{hi:nosort} is now called {hi:noshuffle} as shuffling is now applied before every iteration.{break}
The {hi:best} option alway picks the best intermediate result in case of alternating errors.{break}
New command {hi:error} reports the overall absolute error instead of using the {hi:train} command with {hi:iter(0)}.{break}
{hi:signal} now works as intended.

{p 0 11}{hi:2018.11.21} Initial version.

{title:Author}

{p 4 4}Thorsten Doherr{break}
Centre for European Economic Research{break}
L7,1{break}
68161 Mannheim{break}
Germany{break}
Phone: +49 621 1235 291{break}
Fax: +49 621 1235 170{break}
E-Mail: doherr@zew.de{break}
Internet: www.zew.de
