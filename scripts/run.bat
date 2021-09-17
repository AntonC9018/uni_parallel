@REM scp ../source/%1 MI_IA1@hpc.usm.md:~/CURMANSCHII

ssh MI_IA1@hpc.usm.md ARG1="FILENAME" "bash -s" < cat compile_and_run_d.sh