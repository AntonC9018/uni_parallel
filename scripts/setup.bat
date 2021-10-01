@echo off
set REMOTE=MI_IA1@hpc.usm.md
set USER_FOLDER=CURMANSCHII

scp setup_remote.sh %REMOTE%:~

:: Install dmd, setup environment, generate mpi.d
ssh %REMOTE% "bash ~/setup_remote.sh %USER_FOLDER%"
scp ..\source\mpihelper.d %REMOTE%:~/%USER_FOLDER%

echo Log in to the server by doing `ssh %REMOTE%`.
echo Copy source files by doing `copy_source lab1.d`
echo Compile files by doing `./compile.sh lab1` on the remote machine
echo Run files by using the typical `mpirun -stuff lab1.out`