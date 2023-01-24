Bootstrap: library
From: ubuntu:20.04

%environment
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

%post
    ln -fns /usr/share/zoneinfo/Europe/Paris /etc/localtime
    echo Europe/Paris > /etc/timezone
    apt-get update
    apt-get install -y python3 python3-pip curl default-jre tzdata git bedtools gcc \
    vcftools tabix bcftools r-base
    pip3 install --upgrade pip
    pip3 install multiprocess==0.70.14 pandas==1.3.5 
    curl -s https://get.nextflow.io | bash
    mv nextflow /usr/local/bin/
    dpkg-reconfigure --frontend noninteractive tzdata

    R -e "install.packages('ggplot2', repos='http://cran.rstudio.com/')"
    R -e "install.packages('optparse', repos='http://cran.rstudio.com/')"

    git clone --branch v0.8 --depth 1 https://github.com/sdjebali/Scripts.git /usr/local/src/Scripts
    ln -s /usr/local/src/Scripts/* /usr/local/bin

    git clone --depth 1 https://github.com/gkichaev/PAINTOR_V3.0.git /usr/local/src/PAINTOR
    cd /usr/local/src/PAINTOR
    bash install.sh
    ln -s /usr/local/src/PAINTOR/PAINTOR /usr/local/bin/PAINTOR
    printf "#!/usr/bin/env python3\n\n" > header

    cat header /usr/local/src/PAINTOR/CANVIS/CANVIS.py > /usr/local/bin/CANVIS.py
    chmod 775 /usr/local/bin/CANVIS.py
    
    cat header /usr/local/src/PAINTOR/PAINTOR_Utilities/CalcLD_1KG_VCF.py > /usr/local/bin/CalcLD_1KG_VCF.py
    chmod 775 /usr/local/bin/CalcLD_1KG_VCF.py


%runscript
    exec "$@"
    