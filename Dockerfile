FROM alpine:3.10.2

LABEL maintainer="ctabone@morgan.harvard.edu"

ENV PERL_MM_USE_DEFAULT=1 \
    PERL_UNICODE=SDL

RUN apk add --update --no-cache \
    python3 \
    python3-dev \
    perl \
    perl-utils \
    perl-dev \
    perl-dbd-pg \
    perl-db_file \
    perl-net-ssleay \
    perl-crypt-ssleay \
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
    gnupg &&\
    pip3 install --upgrade pip &&\
    pip3 install --upgrade cython &&\
    pip3 install numpy &&\
    pip3 install pandas &&\
    pip3 install psycopg2 &&\
    pip3 install sqlalchemy &&\
    pip3 install bioservices &&\
    pip3 install pubchempy

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone
RUN apk del tzdata

RUN curl -L http://xrl.us/cpanm > /bin/cpanm && chmod +x /bin/cpanm

RUN cpanm --quiet --notest XML::DOM &&\
    cpanm --quiet --notest XML::Parser::PerlSAX &&\
    cpanm --quiet --notest DBI &&\
    cpanm --quiet --notest Bio::DB::GenBank &&\
    cpanm --quiet --notest Bio::Tools::Run::StandAloneBlast &&\
    cpanm --quiet --notest DBD::Pg &&\
    cpanm --query --notest Sort::Key::Natural &&\
    cpanm --query --notest LWP::Protocol::https

# Remove CPANM cache. 
RUN rm -fr /root/.cpanm/work

