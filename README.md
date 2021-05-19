# brain - neural network for STATA
**brain** is a no frills implementation of a backpropagation algorithm designed for a hassle free setup of multi-layered neural networks. After training the whole network can be saved/loaded using so called brain-files (default postfix .brn). The network is represented by a set of reserved matrices to provide transparent access to all components and to support older Stata versions. Additional functions facilitate the calculation of pseudo-marginal effects or signal through-put, but the main utility is of course prediction, i.e. for propensity scores or classification.

## Prerequisites
STATA

## Getting started
* Copy brain.ado, brain.sthlp, brainwin.plugin, brainunix.plugin and brainmac.plugin files into your ADO file directory (typically c:\ado)
* Call the help file within STATA: help brain
* Try out the examples provided by the help document by copying them into do-files

## Unix and Mac plugins
The UNIX and MAC plugins do not support multiprocessing because of the erratic support of **openmp** among the distributions. To activate **openmp** the plugins need to be locally compiled (see: plugin/build.txt for instructions).
The **brain.c** source code contains MP support, while **brainsp.c** renounces any **openmp** references. 

NOTICE: The MAC plugin is not yet tested.

## Version history

2021.05.18
* The new **norm** command allows for specific normalization of groups of variables.
* The **nonorm** option of the **define** command skips normalization and testing.
* New command **reset** re-initilializes the weights without redefining the normalization.
* Default **spread** set from 0.5 to 0.25, as specified in the help file.

2021.02.16
* Recompiled the MAC plugin to exclude **openmp** libraries because of incompatible distributions.

2020.12.08
* Improved compatibility with older STATA versions (below 15) in terms of matrix sizes
* Fixed a bug that prevented random weight initialization 
* Recompiled the UNIX plugin to exclude **openmp** libraries because of incompatible distributions.

2020.11.30
* Fixed a bug that prevented the usage of the **fit** command without a second variable.
* The **fit** function allows the specification of a threshold for binary one.

2020.10.07
* The **define** paramter **raw** prevents automatic normalization for already normalized data.

2020.04.28
* Revised documentation and program in regard of proper usage of weights.

2020.03.11
* All matrices can exceed matsize limitations by taking a detour over mata.
* The brain matrix fragmentation of the former solution (2020.03.02) is obsolete.
* The brain, load and save commands additionally verify the integrity of the matrix structure.

2020.03.02
* Replaced all mata components with C plugins supporting multiprocessing.
* The network can exceed the maximum matrix size of Stata.
* Syntax errors are now more consistent.
* New **sp** option deactivates multiprocessing if necessary.

2019.11.13
* The commands **train** and **error** support weights.
* New command **fit** calculates recall and precision for binary output.

2019.03.28
* Implementation of batch training.
* Changed training ouput to interval reports of real absolute errors instead of intermediate errors.
* **nosort** is now called noshuffle as shuffling is now applied before every iteration.
* The **best** option alway picks the best intermediate result in case of alternating errors.
* New command **error** reports the overall absolute error instead of using the train command with iter(0).
* **signal** now works as intended.

2018.11.21 (scc repository version)
* Initial version

### Author
* **Thorsten Doherr** - [ZEW](https://www.zew.de/en/team/tdo/)
