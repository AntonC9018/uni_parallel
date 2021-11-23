module atestare_2_simple;

/*
==========================================================================
|                       Sarcina 8 (L11Ex3)                               |
==========================================================================
| Să se elaboreze un program în care se construieşte o matrice transpusă |
| utilizând proceduri de generare a tipurilor de date.                   |
==========================================================================
*/

immutable height = 4;
immutable width = 5;
int[height * width] createMatrix()
{
    typeof(return) result;
    size_t index = 0;
    foreach (rowIndex; 0..height)
    foreach (colIndex; 0..width)
    {
        result[index++] = rowIndex * 10 + colIndex;
    }
    return result;
}
immutable MatrixData = createMatrix();

void main()
{
    import mpi;
    import std.stdio;
    static import mh = mpihelper;
    
    auto info = mh.initialize();
    scope(exit) mh.finalize();

    mh.abortIf(info.size != 1, "The program must be run with 1 processes");
    
    writeln("Initial matrix:");
    mh.printAsMatrix(MatrixData, width);

    // MPI_Type_vector(blockLength = 1, blockCount = height, stride = width)
    auto singleColumnType = mh.createVectorDatatype!int(1, height, width);
    // MPI_Type_create_resized()
    auto singleColumnTypeOfSize1 = mh.resizeDatatype(singleColumnType, 1);
    // MPI_Type_contiguous(lungimea = width)
    auto allColumnsType = mh.createDynamicArrayDatatype(singleColumnTypeOfSize1, width);
    
    int[] rootReceiveBuffer = new int[](width * height);

    MPI_Sendrecv(
        cast(void*) MatrixData.ptr, 1, allColumnsType, 
        0, 1, 
        rootReceiveBuffer.ptr, width * height, MPI_INT,
        0, 1,
        MPI_COMM_WORLD, MPI_STATUS_IGNORE);

    writeln("Final matrix:");
    mh.printAsMatrix(rootReceiveBuffer, height);
}

/*

$ ./compile.sh Curmanschii_L11Ex3_simple
$ mpirun -host compute-0-0 Curmanschii_L11Ex3_simple.out
Initial matrix: 
  0  1  2  3  4 
 10 11 12 13 14 
 20 21 22 23 24 
 30 31 32 33 34 
Final matrix:   
  0 10 20 30    
  1 11 21 31    
  2 12 22 32    
  3 13 23 33    
  4 14 24 34    

*/