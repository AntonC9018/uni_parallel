set REMOTE=MI_IA1@hpc.usm.md
set USER_FOLDER=CURMANSCHII

scp setup_remote.sh %REMOTE%:~

:: Intall dmd
ssh %REMOTE% "chmod +x ~/setup_remote.sh; ~/setup_remote.sh"

scp -r dmd.conf ../source/mpi.d compile.sh %REMOTE%:~/%USER_FOLDER%
ssh %REMOTE% "chmod +x ~/%USER_FOLDER%/compile.sh"

echo Log in to the server by doing `ssh %REMOTE%`.
echo Copy source files by doing `copy_source lab1.d`
