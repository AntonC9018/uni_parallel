set -e

USER_FOLDER=$HOME/$1
DMDBIN=$HOME/dmd/usr/bin
PATH=$PATH:$DMDBIN
DFLAGS_TEXT="DFLAGS=-I%HOME%/dmd/usr/include/dmd/phobos -I%HOME%/dmd/usr/include/dmd/druntime/import"
MPI_LFLAGS_TEXT="LFLAGS=$(mpicc --showme:link)"

# Download and unpack dmd
if [ ! -d ~/dmd ];
then
    mkdir dmd
    cd dmd
    package_name=dmd-2.076.0-0.fedora.x86_64.rpm
    if [ -f $package_name ];
    then
        rm $package_name
    fi
    wget http://downloads.dlang.org/releases/2017/dmd-2.076.0-0.fedora.x86_64.rpm
    
    # unpacks the archive
    rpm2cpio $package_name | cpio -idmv
    cd ..
fi

# Download and configure OpenMPI D bindings
if [ ! -d OpenMPI-master ];
then

    archive_name=master.tar.gz
    if [ -f $archive_name ];
    then
        rm $archive_name
    fi
    wget https://github.com/AntonC9018/OpenMPI/archive/master.tar.gz
    tar -xf $archive_name

    cd OpenMPI-master
    echo [Environment] > dmd.conf
    echo $DFLAGS_TEXT >> dmd.conf
    chmod +x gen/setup.sh gen/get_mpi.h.sh
    # This should just work
    bash ./gen/setup.sh
    rm $archive_name
fi

# Configure build environment
mkdir -p $USER_FOLDER
cd $USER_FOLDER

echo [Environment] > dmd.conf  
echo $DFLAGS_TEXT >> dmd.conf  
echo $MPI_LFLAGS_TEXT >> dmd.conf  

if [ -f compile.sh ];
then
    rm compile.sh
fi

echo $DMDBIN/dmd -c \$1.d -of=\$1.o -I$HOME/OpenMPI-master/source -I%HOME%/dmd/usr/include/dmd/phobos -I%HOME%/dmd/usr/include/dmd/druntime/import > compile.sh
echo gcc $(mpicc --showme:link) -L%HOME%/dmd/usr/lib64 \$1.o -o \$1.out >> compile.sh
chmod +x compile.sh 
