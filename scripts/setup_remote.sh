if [ ! -f ~/dmd/usr/bin/dmd ];
then
    mkdir dmd
    cd dmd
    wget http://downloads.dlang.org/releases/2017/dmd-2.076.0-0.fedora.x86_64.rpm
    rpm2cpio dmd-2.076.0-0.fedora.x86_64.rpm | cpio -idmv
    cd ..
fi
