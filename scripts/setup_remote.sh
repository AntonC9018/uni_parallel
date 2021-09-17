mkdir dmd
cd dmd
wget http://downloads.dlang.org/releases/2017/dmd-2.076.0-0.fedora.x86_64.rpm
rpm2cpio dmd-2.076.0-0.fedora.x86_64.rpm | cpio -idmv
cd ..

mkdir CURMANSCHII
cd CURMANSCHII
echo [Environment] > dmd.conf
echo DFLAGS=-I~/dmd/usr/include/dmd/phobos -I~/dmd/usr/include/dmd/druntime/import -L-L../dmd/usr/lib64 >> dmd.conf