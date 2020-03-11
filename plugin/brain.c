#include "stplugin.h"
#include "stata.h"
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

void value2signal(matrix inout)
{	row io = inout[4];
	int cols = *io;
	for (int i = 1; i <= cols; i++)
	{	io[i] = (inout[3][i] - inout[1][i]) * inout[2][i];
		if (io[i] > 1)	io[i] = 1;
		else if (io[i] < 0) io[i] = 0;
	}
}

void signal2value(matrix inout)
{	row io = inout[3];
	int cols = *io;
	for (int i = 1; i <= cols; i++)
	{	if (io[i] > 1)	io[i] = 1;
		else if (io[i] < 0) io[i] = 0;
		io[i] = inout[4][i] / inout[2][i] + inout[1][i];
	}
}

void input2neuron(matrix input, matrix neuron)
{	row inp = input[4];
	row neu = neuron[1];
	int icols = *inp;
	for (int i = 1; i <= icols; i++) 
	{	neu[i] = inp[i];
	}
}

void neuron2output(matrix neuron, matrix output)
{	row out = output[4];
	int ocols = *out;
	double *neu = &neuron[1][matcols(neuron)-ocols];
	for (int i = 1; i <= ocols; i++)
	{	out[i] = neu[i];
	}
}

double errsum(matrix output, matrix neuron)
{	double *O, *N, err;
	int j, ocols;
	ocols = matcols(output);
	O = output[4];
	N = &neuron[1][matcols(neuron) - ocols];
	err = 0;
	for (j = 1; j <= ocols; j++)
	{	err += fabs(O[j]-N[j]);
	}
	return err;
}

void forward(matrix layer, matrix neuron, matrix brain)
{	int layers = matcols(layer);
	double *npos = &neuron[1][(int)layer[1][1]+1];
	double *wpos = &brain[1][1];
	double *feed = &neuron[1][0];
	for (int l = 2; l <= layers; l++)
	{	int neurons = layer[1][l];
		int weights = layer[1][l-1];
		for (int n = 1; n <= neurons; n++)
		{	double net = 0;
			for (int w = 1; w <= weights; w++)
			{	net += feed[w] * (*wpos);
				wpos++;
			}
			net += *wpos;
			*npos = 1 / (1+exp(-net));
			npos++;
			wpos++;
		}
		feed = &feed[weights];
	}
}

void backward(matrix layer, matrix output, matrix neuron, matrix brain, double weight, matrix err, matrix delta)
{	double *w, *e, *d, *nfrom;
	double *estop, *nstop;
	int l, offset, layfrom, layto;
	double *wfrom = &brain[1][matcols(brain)]-1; // skipping bias
	double *efrom = &err[1][matcols(err)];
	double *eto = efrom;
	double *n = &neuron[1][matcols(neuron)];
	layto = matcols(output);
	double *o = &output[4][layto];
	for (nstop = n - layto; n > nstop; n--)
	{	*eto = (*o - *n) * weight * (1 - *n) * *n;
		eto--; o--;
	}
	for (l = matcols(layer)-1; l >= 2; l--)
	{	layfrom = layto;
		layto = layer[1][l];
		offset = layto+1;
		for (nstop = n-layto; n > nstop; n--)
		{	*eto = 0;
			e = efrom;
			w = wfrom; 
			for (estop = e - layfrom; e > estop; e--)
			{	*eto += *e * *w;
				w -= offset;
			}
			*eto *= (1 - *n) * *n;
			eto--; wfrom--;
		}
		efrom = e;
		wfrom = w + (offset - 1);
	}
	e = &err[1][matcols(err)];
	n = &neuron[1][matcols(neuron)-matcols(output)];
	d = &delta[1][matcols(delta)];
	for (l = matcols(layer); l >= 2; l--)
	{	nfrom = n;
		layto = layer[1][l];
		layfrom = layer[1][l-1];
		for (estop = e - layto; e > estop; e--)
		{	*d += *e;
			d--;
			n = nfrom;
			for (nstop = n-layfrom; n > nstop; n--)
			{	*d += *e * *n;
				d--;
			}
		}
	}
}

void brainforward(int raw)
{	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	matrix neuron = allocateMatrix(SF_col("neuron"),1);
	matrix output = allocateStataMatrix("output");
	matrix input = allocateStataMatrix("input");
	if (raw) signal2value(input);
	else value2signal(input);
	input2neuron(input, neuron);
	forward(layer, neuron, brain);
	neuron2output(neuron, output);
	signal2value(output);
	storeStataMatrix(input, "input");
	storeStataMatrix(neuron, "neuron");
	storeStataMatrix(output, "output");
	destroyMatrix(input);
	destroyMatrix(output);
	destroyMatrix(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
}	

void brainsignalSP(char *result, int inp)
{	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	matrix neuron = allocateMatrix(SF_col("neuron"),1);
	matrix output = allocateStataMatrix("output");
	matrix input = allocateStataMatrix("input");
	matrix sel = selectedObs();
	int N = matrows(sel);
	int icols = matcols(input);
	if (inp < 1 || inp > icols) inp = 0;
	for (int i = 1; i <= N; i++)
	{	int obs = sel[i][1];
		loadStataRow(input[3], obs, 1, 0);
		value2signal(input);
		input2neuron(input, neuron);
		if (inp >= 1) neuron[1][inp] = 0;
		forward(layer, neuron, brain);
		neuron2output(neuron, output);
		signal2value(output);
		saveStataRow(output[3], obs, icols+1, 0);
	}
	destroyMatrix(sel);
	destroyMatrix(input);
	destroyMatrix(output);
	destroyMatrix(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%d", N); 
}

void brainsignalMP(char *result, int inp)
{	int i, N, icols, obs, thread;
	int threads = omp_get_num_procs();
	matrix sel = selectedObs();
	N = matrows(sel);
	if (N < threads) threads = N;
	if (threads < 1) threads = 1;
	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	cube neuron = allocateCube(SF_col("neuron"),1,threads);
	cube input = allocateCopyCube(allocateStataMatrix("input"),threads);
	cube output = allocateCopyCube(allocateStataMatrix("output"),threads);
	icols = matcols(input[1]);
	if (inp < 1 || inp > icols) inp = 0;
	#pragma omp parallel for private(thread,obs) num_threads(threads)
	for (i = 1; i <= N; i++)
	{	thread = omp_get_thread_num()+1;
		obs = sel[i][1];
		loadStataRow(input[thread][3], obs, 1, 0);
		value2signal(input[thread]);
		input2neuron(input[thread], neuron[thread]);
		if (inp >= 1) neuron[thread][1][inp] = 0;
		forward(layer, neuron[thread], brain);
		neuron2output(neuron[thread], output[thread]);
		signal2value(output[thread]);
		saveStataRow(output[thread][3], obs, icols+1, 0);
	}
	destroyMatrix(sel);
	destroyCube(input);
	destroyCube(output);
	destroyCube(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%d", N); 
}

void brainerrorSP(char *result)
{	double weight;
	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	matrix neuron = allocateMatrix(SF_col("neuron"),1);
	matrix output = allocateStataMatrix("output");
	matrix input = allocateStataMatrix("input");
	matrix sel = selectedObs();
	int N = matrows(sel);
	int ocols = matcols(output);
	int icols = matcols(input);
	double error = 0;
	double wsum = 0;
	for (int i = 1; i <= N; i++)
	{	int obs = sel[i][1];
		loadStataRow(input[3], obs, 1, 0);
		loadStataRow(output[3], obs, icols+1, 0);
		value2signal(input);
		value2signal(output);
		input2neuron(input, neuron);
		SF_vdata(icols+ocols+1, obs, &weight);
		forward(layer, neuron, brain);
		error += errsum(output, neuron) * weight;
		wsum += weight;
	}
	error = error/wsum/ocols;
	destroyMatrix(sel);
	destroyMatrix(input);
	destroyMatrix(output);
	destroyMatrix(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%.9f %d",error, N);
}

void brainerrorMP(char *result)
{	double weight, err, error, wsum;
	int N, ocols, icols, i, obs, thread;
	int threads = omp_get_num_procs();
	matrix sel = selectedObs();
	N = matrows(sel);
	if (N < threads) threads = N;
	if (threads < 1) threads = 1;
	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	cube neuron = allocateCube(SF_col("neuron"),1,threads);
	cube input = allocateCopyCube(allocateStataMatrix("input"),threads);
	cube output = allocateCopyCube(allocateStataMatrix("output"),threads);
	ocols = matcols(output[1]);
	icols = matcols(input[1]);
	error = 0;
	wsum = 0;
	#pragma omp parallel for private(thread,obs,weight,err) reduction(+:error,wsum) num_threads(threads)
	for (i = 1; i <= N; i++)
	{	thread = omp_get_thread_num()+1;
		obs = sel[i][1];
		loadStataRow(input[thread][3], obs, 1, 0);
		loadStataRow(output[thread][3], obs, icols+1, 0);
		SF_vdata(icols+ocols+1, obs, &weight);
		value2signal(input[thread]);
		value2signal(output[thread]);
		input2neuron(input[thread], neuron[thread]);
		forward(layer, neuron[thread], brain);
		err = errsum(output[thread], neuron[thread]) * weight;
		error += err;
		wsum += weight;
	}
	error = error/wsum/ocols;
	destroyMatrix(sel);
	destroyCube(input);
	destroyCube(output);
	destroyCube(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%.9f %d",error, N);
}

void braintrainSP(char *result, double eta, int batch, int iter, int shuffle)
{	int b, N, icols, ocols, bcols, i, j, k, obs;
	double weight, *D, *B;
	if (batch <= 0) batch = 1;
	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	matrix output = allocateStataMatrix("output");
	matrix input = allocateStataMatrix("input");
	matrix delta = allocateMatrix(matcols(brain),1);
	matrix neuron = allocateMatrix(SF_col("neuron"),1);
	matrix err = allocateMatrix(matcols(neuron)-matcols(input),1);
	matrix sel = selectedObs();
	setMatrix(delta, 0);
	setMatrix(err, 0);
	b = 0;
	N = matrows(sel);
	icols = matcols(input);
	ocols = matcols(output);
	bcols = matcols(brain);
	D = delta[1];
	B = brain[1];
	for (i = 1;  i <= iter; i++)
	{	if (shuffle)
		{	shuffleMatrix(sel);
		}
		for (j = 0; j < N; j += batch)
		{	if (N-j >= batch)
			{	b = batch;
			}
			else
			{	b = N-j;
			}
			setMatrix(delta, 0);
			for (k = 1; k <= b; k++)
			{	obs = sel[j+k][1];
				loadStataRow(input[3], obs, 1, 0);
				loadStataRow(output[3], obs, icols+1, 0);
				SF_vdata(icols+ocols+1, obs, &weight);
				value2signal(input);
				value2signal(output);
				input2neuron(input, neuron);
				forward(layer, neuron, brain);
				backward(layer, output, neuron, brain, weight, err, delta);
			}
			for (k = 1; k <= bcols; k++)
			{	B[k] += D[k] * eta;
			}
		}
	}
	storeStataMatrix(brain, "brain");
	destroyMatrix(sel);
	destroyMatrix(err);
	destroyMatrix(delta);
	destroyMatrix(input);
	destroyMatrix(output);
	destroyMatrix(neuron);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%d", N);
}

void braintrainMP(char *result, double eta, int batch, int iter, int shuffle)
{	int thread, i, j, k, l, b, obs, icols, ocols, bcols, N;
	double weight, *B;
	int threads = omp_get_num_procs();
	if (batch <= 0) batch = 1;
	if (threads > batch) threads = batch;
	matrix sel = selectedObs();
	N = matrows(sel);
	if (N < threads) threads = N;
	if (threads < 1) threads = 1;
	matrix brain = allocateStataMatrix("brain");
	matrix layer = allocateStataMatrix("layer");
	cube input = allocateCopyCube(allocateStataMatrix("input"),threads);
	cube output = allocateCopyCube(allocateStataMatrix("output"),threads);
	cube neuron = allocateCube(SF_col("neuron"),1,threads);
	cube err = allocateCube(matcols(neuron[1])-matcols(input[1]),1,threads);
	icols = matcols(input[1]);
	ocols = matcols(output[1]);
	bcols = matcols(brain);
	cube delta = allocateCube(bcols,1,threads);
	B = brain[1];
	for (i = 1;  i <= iter; i++)
	{	if (shuffle)
		{	shuffleMatrix(sel);
		}
		for (j = 0; j < N; j += batch)
		{	if (N-j >= batch)
			{	b = batch;
			}
			else
			{	b = N-j;
			}
			#pragma omp parallel num_threads(threads)
			{	setMatrix(delta[omp_get_thread_num() + 1], 0);
			}
			#pragma omp parallel for private(thread,obs,weight) num_threads(threads)
			for (k = 1; k <= b; k++)
			{	thread = omp_get_thread_num()+1;
				obs = sel[j+k][1];
				loadStataRow(input[thread][3], obs, 1, 0);
				loadStataRow(output[thread][3], obs, icols+1, 0);
				SF_vdata(icols+ocols+1, obs, &weight);
				value2signal(input[thread]);
				value2signal(output[thread]);
				input2neuron(input[thread], neuron[thread]);
				forward(layer, neuron[thread], brain);
				backward(layer, output[thread], neuron[thread], brain, weight, err[thread], delta[thread]);
			}
			#pragma omp parallel for private(l) num_threads(threads)
			for (k = 1; k <= bcols; k++)
			{	for (l = 1; l <= threads; l++)
				{	B[k] += delta[l][1][k] * eta;
				}
			}
		}
	}
	storeStataMatrix(brain, "brain");
	destroyMatrix(sel);
	destroyCube(delta);
	destroyCube(err);
	destroyCube(neuron);
	destroyCube(output);
	destroyCube(input);
	destroyMatrix(layer);
	destroyMatrix(brain);
	sprintf(result, "%d", N);
}

STDLL stata_call(int argc, char *argv[])
{	char result[254];
	result[0] = '\0';
	if (argc == 0)
	{	sprintf(result, "%s %d", "2020.03.11", omp_get_num_procs());
	}
	else if (strcmp(argv[0],"forward") == 0)
	{	if (argc < 2) brainforward(0);
		else brainforward((int) atof(argv[1]));
	}
	else if (strcmp(argv[0],"thinkSP") == 0)
	{	if (argc < 2) brainsignalSP(result, 0);
		else brainsignalSP(result, (int) atof(argv[1]));
	}
	else if (strcmp(argv[0],"thinkMP") == 0)
	{	if (argc < 2) brainsignalMP(result, 0);
		else brainsignalMP(result, (int) atof(argv[1]));
	}
	else if (strcmp(argv[0],"trainSP") == 0)
	{	braintrainSP(result, atof(argv[1]), (int) atof(argv[2]), (int) atof(argv[3]), (int) atof(argv[4]));
	}
	else if (strcmp(argv[0],"trainMP") == 0)
	{	braintrainMP(result, atof(argv[1]), (int) atof(argv[2]), (int) atof(argv[3]), (int) atof(argv[4]));
	}
	else if (strcmp(argv[0],"errorSP") == 0)
	{	brainerrorSP(result);
	}
	else if (strcmp(argv[0],"errorMP") == 0)
	{	brainerrorMP(result);
	}
	if (result[0] != '\0') SF_macro_save("_plugin", result);
	return(0);
}

