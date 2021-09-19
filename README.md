# Parallel and Distributed Computing

This repository contains assignments, implemented as part of the course **Parallel and Distributed Computing**.

See explanatory markdown documents for each of the assignments in the `doc` folder. Assignments are all in *Romanian*.

PR's with grammar corrections, bug fixes, improvement suggestions or translations are very welcome.

Leave a star as a way to say "Thank you". Enjoy!


Bindings: https://github.com/DlangScience/OpenMPI

## Build instructions

1. Create a private-public key pair to be able to log on to server from script without password. See [this](https://docs.oracle.com/cd/E19683-01/806-4078/6jd6cjru7/index.html). Skip the optional passphrase.
2. Log on to the server and do `chmod 600 ~/.ssh/authorized_keys`. Now you should be able to use `ssh` without it prompting for password.
3. The `scripts/setup.bat` should manage to install `dmd` on the remote machine and set up the environment.

The setup script should get you started