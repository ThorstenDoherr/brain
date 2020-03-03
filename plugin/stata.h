#ifndef __STATA

#define __STATA

#include "stplugin.h"

typedef double* row;
typedef row* matrix;
typedef matrix* cube;

int matrows(matrix M);
int matcols(matrix M);
int rowcols(row R);
int matcount(cube C);
row allocateRow(int cols);
void destroyRow(row R);
matrix allocateMatrix(int rows, int cols);
matrix allocateStataMatrix(char *matrixname);
void storeStataMatrix(matrix M, char *matrixname);
void destroyMatrix(matrix M);
matrix copyMatrix(matrix M);
cube allocateCube(int rows, int cols, int count);
cube allocateEmptyCube(int count);
cube allocateCopyCube(matrix M, int count);
void destroyCube(cube C);
void loadStataRow(row R, int obs, int from, int cols);
void saveStataRow(row R, int obs, int from, int cols);
void setMatrix(matrix M, double value);
void setRow(row R, double value);
void mulRow(row R, double value);
void mulRowMP(row R, double value);
void addRow(row R, double value);
void subRow(row R, double value);
void mulRows(row R, row R1, row R2);
void addRows(row R, row R1, row R2);
void addRowsMP(row R, row R1, row R2);
void subRows(row R, row R1, row R2);
void copyRows(row R1, row R2);
void swapRows(matrix M1, int row1, matrix M2, int row2);
void showMatrix(matrix mat);
matrix selectedObs();
void sortMatrixAsc(matrix M, int col);
void sortMatrixDesc(matrix M, int col);
void shuffleMatrix(matrix M);

#endif
