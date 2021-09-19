@echo off
if exist %1 (
    scp %1 MI_IA1@hpc.usm.md:~/CURMANSCHII/%1
    goto end
)

echo %1 missing

:end
