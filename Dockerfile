FROM alpine:3.17.3

LABEL maintainer="ctabone@morgan.harvard.edu"

ENV PERL_MM_USE_DEFAULT=1 \
    PERL_UNICODE=SDL

RUN apk add --update --no-cache \
    python3 \
    python3-dev \
    py3-pip \
    py3-pandas \
    py3-numpy \
    py3-matplotlib \
    perl \
    perl-utils \
    perl-dev \
    perl-dbd-pg \
    perl-db_file \
    perl-net-ssleay \
    perl-crypt-ssleay \
    perl-app-cpanminus \
    # Expat and expat-dev are for XML::DOM.
    curl \
    wget \
    expat \
    expat-dev \
    postgresql-dev \
    git \
    gcc \
    g++ \
    gd-dev \
    vim \
    bash \
    musl-dev \
    build-base \
    libxml2-dev \
    libxslt-dev \
    # tzdata for setting the timezone.
    tzdata \
    gnupg \
    rust \
    cargo \
    zip

# Drop stale distutils egg-info so modern pip can upgrade 'packaging'
# (otherwise pip fails: uninstall-distutils-installed-package).
RUN rm -rf /usr/lib/python3*/site-packages/packaging-*.egg-info

RUN pip install --upgrade pip &&\
    pip install wheel &&\
    pip install "Cython<3.0" pyyaml --no-build-isolation &&\ 
    pip install psycopg2 &&\
    pip install 'sqlalchemy>=1.4,<2.0' &&\
    pip install bioservices &&\
    pip install pubchempy

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone
RUN apk del tzdata

RUN curl -L http://xrl.us/cpanm > /bin/cpanm && chmod +x /bin/cpanm

RUN cpanm --quiet --notest XML::DOM &&\
    cpanm --quiet --notest XML::Parser::PerlSAX &&\
    cpanm --quiet --notest XML::XQL &&\
    cpanm --quiet --notest XML::XPath &&\
    cpanm --quiet --notest DBI &&\
    cpanm --quiet --notest Bio::DB::GenBank &&\
    cpanm --quiet --notest Bio::Tools::Run::StandAloneBlast &&\
    cpanm --quiet --notest DBD::Pg &&\
    cpanm --query --notest Sort::Key::Natural &&\
    cpanm --query --notest LWP::Protocol::https

# Remove CPANM cache.
RUN rm -fr /root/.cpanm/work

# Download and install XML-XORT library from harvdev-XORT repository
# This library provides XML-to-database transformation capabilities for ARGS metrics
RUN wget -q https://github.com/FlyBase/harvdev-XORT/raw/master/XML-XORT-0.010.tar.gz && \
    tar -xzf XML-XORT-0.010.tar.gz && \
    mv XML-XORT-0.010 /usr/local/lib/ && \
    rm XML-XORT-0.010.tar.gz

