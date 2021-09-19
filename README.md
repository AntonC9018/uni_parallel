# Parallel and Distributed Computing

This repository contains assignments, implemented as part of the course **Parallel and Distributed Computing**.

See explanatory markdown documents for each of the assignments in the `doc` folder. Assignments are all in *Romanian*.

PR's with grammar corrections, bug fixes, improvement suggestions or translations are very welcome.

Leave a star as a way to say "Thank you". Enjoy!

## Build instructions

1. Create a private-public key pair to be able to log on to server from script without password. See [this](https://docs.oracle.com/cd/E19683-01/806-4078/6jd6cjru7/index.html). Skip the optional passphrase.
2. Log on to the server and do `chmod 600 ~/.ssh/authorized_keys`. Now you should be able to use `ssh` without it prompting for password.
3. The `scripts/setup.bat` should manage to install `dmd` on the remote machine and set up the environment. 
   
   > Change what the `REMOTE` variable in the setup script is set to if you need to log on as another user.
   > Change the `USER_FOLDER` variable to select which folder to place `dmd.conf` and `compile.sh` into.

4. Compile by doing `./compile.sh x` in your folder on the remote machine, where `x.d` is a D source file in your folder (so drop the extension). The output executable is named `x.out`.

If the server now has a newer version of OpenMPI, feel free to fix [my D bindings fork](https://github.com/AntonC9018/OpenMPI) back.
You will probably just need to rollback a few commits.
Or just use the [initial repo that I forked](https://github.com/DlangScience/OpenMPI) (change the `setup_remote.sh` script), which should update by the time you're reading this.