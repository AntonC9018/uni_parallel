@echo off
if exist ..\source\%1 (
    scp ..\source\%1 MI_IA1@hpc.usm.md:~/CURMANSCHII/$1
    goto end
)

echo ..\source\%1 missing

:end