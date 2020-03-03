# brain - neural network
**brain** is a no frills implementation of a backpropagation algorithm designed for a hassle free setup of multi-layered neural networks. After training the whole network can be saved/loaded using so called brain-files (default postfix .brn). The network is represented by a set of reserved matrices to provide transparent access to all components and to support older Stata versions. Additional functions facilitate the calculation of pseudo-marginal effects or signal through-put, but the main utility is of course prediction, i.e. for propensity scores or classification.

## Prerequisites
STATA

## Getting started
* Copy brain.ado and brain.sthlp into your ADO file directory (typically c:\ado)
* Call the help file within STATA: help brain
* Copy the provided examples from the help document into do-files and run them

## Version history
2020.03.02
* Replaced all mata components with C plugins supporting multiprocessing.
* The network can exceed the maximum matrix size of Stata.
* Syntax errors are now more consistent.

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
