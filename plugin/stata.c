#include "stplugin.h"
#include "stata.h"
#include <stdio.h>
#include <stdlib.h>

int matrows(matrix M)
{	return M[0][1];
}

int matcols(matrix M)
{	return M[0][0];
}

int rowcols(row R)
{	return *R;
}

int matcount(cube C)
{	return C[0][0][0];
}

row allocateRow(int cols)
{	row R = (row) malloc(sizeof(double) * (cols+1));
	R[0] = cols;
	return R;
}

void destroyRow(row R)
{	free(R);
}

matrix allocateMatrix(int cols, int rows)
{	matrix M = (matrix) malloc(sizeof(row) * (rows+1));
	M[0] = (row) malloc(sizeof(double) * 2);
	M[0][0] = cols;
	M[0][1] = rows;
	int size = cols+1;
	for (int i = 1; i <= rows; i++)
	{	M[i] = (row) malloc(sizeof(double) * size);
		M[i][0] = cols;
	}
	return M;
}

matrix allocateStataMatrix(char *matrixname)
{	int rows = SF_row(matrixname);
	int cols = SF_col(matrixname);
	matrix M = allocateMatrix(cols, rows);
	for (int i = 1; i <= rows; i++)
	{	for (int j = 1; j <= cols; j++)
		{	SF_mat_el(matrixname,i,j,&M[i][j]);
		}
	}
	return M;
}

void storeStataMatrix(matrix M, char *matrixname)
{	int rows = SF_row(matrixname);
	int cols = SF_col(matrixname);
	if (rows < matrows(M)) rows = matrows(M);
	if (cols < matcols(M)) cols = matcols(M);
	for (int i = 1; i <= rows; i++)
	{	for (int j = 1; j <= cols; j++)
		{	SF_mat_store(matrixname,i,j,M[i][j]);
		}
	}
}

void destroyMatrix(matrix M)
{	int rows = matrows(M);
	for (int i = 0; i <= rows; i++)
	{	free(M[i]);
	}
	free(M);
}

matrix copyMatrix(matrix M)
{	int cols = matcols(M);
	int rows = matrows(M);
	matrix C = allocateMatrix(cols, rows);
	for (int i = 1; i <= rows; i++)
	{	for (int j = 1; j <= cols; j++)
		{	C[i][j] = M[i][j];
		}
	}
	return C;
}

cube allocateCube(int cols, int rows, int count)
{	cube C = allocateEmptyCube(count);
	for (int i = 1; i <= count; i++)
	{	C[i] = allocateMatrix(cols, rows);
	}
	return C;
}

cube allocateEmptyCube(int count)
{	cube C = (cube) malloc(sizeof(matrix) * count+1);
	C[0] = allocateMatrix(0,0);
	C[0][0][0] = count;
	return C;
}

cube allocateCopyCube(matrix M, int count)
{	cube C = allocateEmptyCube(count);
	if (count > 0) C[1] = M;
	for (int i = 2; i <= count; i++)
	{	C[i] = copyMatrix(M);
	}
	return C;
}

void destroyCube(cube C)
{	int count = matcount(C);
	for (int i = 0; i <= count; i++)
	{	destroyMatrix(C[i]);
	}
	free(C);
}

void loadStataRow(row R, int obs, int from, int cols)
{	from--;
	if (cols <= 0) cols = *R;
	for (int i = 1; i <= cols; i++)
	{	SF_vdata(from+i, obs, &R[i]);
	}
}

void saveStataRow(row R, int obs, int from, int cols)
{	from--;
	if (cols <= 0) cols = *R;
	for (int i = 1; i <= cols; i++)
	{	SF_vstore(from+i, obs, R[i]);
	}
}

void setMatrix(matrix M, double value)
{	int rows = matrows(M);
	for (int i = 1; i <= rows; i++)
	{	setRow(M[i], value);
	}
}

void setRow(row R, double value)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = value;
	}
}

void mulRow(row R, double value)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R[i]*value;
	}
}

void divRow(row R, double value)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R[i]/value;
	}
}

void addRow(row R, double value)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R[i]+value;
	}
}

void subRow(row R, double value)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R[i]-value;
	}
}

void mulRows(row R, row R1, row R2)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R1[i]*R2[i];
	}
}

void divRows(row R, row R1, row R2)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R1[i]/R2[i];
	}
}

void addRows(row R, row R1, row R2)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R1[i]+R2[i];
	}
}

void subRows(row R, row R1, row R2)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R1[i]-R2[i];
	}
}

void copyRows(row R, row R1)
{	int cols = *R;
	for (int i = 1; i <= cols; i++)
	{	R[i] = R1[i];
	}
}

void swapRows(matrix M1, int row1, matrix M2, int row2)
{	row swap = M1[row1];
	M1[row1] = M2[row2];
	M2[row2] = swap;
}

void showMatrix(matrix M)
{	char buf[80];
	for (int i = 1; i <= M[0][1]; i++)
	{	for (int j = 1; j <= M[0][0]; j++)
		{	sprintf(buf, "[%d][%d]%.9f ", i, j, M[i][j]);
			SF_display(buf);
		}
		SF_display("\n");
	}
}

matrix selectedObs()
{	int from = SF_in1();
	int to = SF_in2();
	int N = 0;
	for (int obs = from; obs <= to; obs++)
	{	if (SF_ifobs(obs) > 0) N++;
	}
	matrix M = allocateMatrix(1,N);
	int i = 1;
	for (int obs = from; obs <= to; obs++)
	{	if (SF_ifobs(obs) <= 0) continue;
		M[i][1] = obs;
		i++;
	}
	return M;
}

void swaprow(matrix M, int row1, int row2)
{	row swap = M[row1];
	M[row1] = M[row2];
	M[row2] = swap;
}

int pivotasc(matrix M, int top, int bot, int col)
{	int mid = top+(bot-top)/2;
	if (M[mid][col] < M[top][col]) swaprow(M, top, mid);
	if (M[bot][col] < M[top][col]) swaprow(M, top, bot);
	if (M[bot][col] < M[mid][col]) swaprow(M, mid, bot);
	double pivot = M[mid][col];
	top--;
	bot++;
	while (1)
	{	do { top++; } while (M[top][col] < pivot);
		do { bot--; } while (M[bot][col] > pivot);
		if (top >= bot) return bot;
		swaprow(M, top, bot);
	}
}

int pivotdesc(matrix M, int top, int bot, int col)
{	int mid = top+(bot-top)/2;
	if (M[mid][col] > M[top][col]) swaprow(M, top, mid);
	if (M[bot][col] > M[top][col]) swaprow(M, top, bot);
	if (M[bot][col] > M[mid][col]) swaprow(M, mid, bot);
	double pivot = M[mid][col];
	top--;
	bot++;
	while (1)
	{	do { top++; } while (M[top][col] > pivot);
		do { bot--; } while (M[bot][col] < pivot);
		if (top >= bot) return bot;
		swaprow(M, top, bot);
	}
}

void quicksortasc(matrix M, int top, int bot, int col)
{	if (top >= bot) return;
	long pivot = pivotasc(M, top, bot, col);
	quicksortasc(M, top, pivot, col);
	quicksortasc(M, pivot+1, bot, col);
	
}

void quicksortdesc(matrix M, int top, int bot, int col)
{	if (top >= bot) return;
	long pivot = pivotdesc(M, top, bot, col);
	quicksortdesc(M, top, pivot, col);
	quicksortdesc(M, pivot+1, bot, col);
	
}

void sortMatrixAsc(matrix M, int col)
{	quicksortasc(M, 1, matrows(M), col);
}

void sortMatrixDesc(matrix M, int col)
{	quicksortdesc(M, 1, matrows(M), col);
}

void shuffleMatrix(matrix M)
{	int cols = matcols(M);
	int rows = matrows(M);
	for (int i = 1; i <= rows; i++)
	{	M[i][0] = (double) rand();
	}
	sortMatrixAsc(M, 0);
	for (int i = 1; i <= rows; i++)
	{	M[i][0] = cols;
	}
}
