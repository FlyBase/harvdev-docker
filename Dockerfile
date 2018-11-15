FROM alpine:3.8

LABEL maintainer="ctabone@morgan.harvard.edu"

RUN apk add --update --no-cache \
    python3 \
    python3-dev \
    perl \
    perl-utils \
    perl-dev \
    # Expat and expat-dev are for XML::DOM.
    expat \
    expat-dev \
    postgresql-dev \
    git \
    gcc \
    g++ \
    build-base \
    tzdata \
    && pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir psycopg2

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone
RUN apk del tzdata

RUN cpan inc::latest XML::DOM XML::Parsers::PerlSAX DBI \
    && cpan Bio::DB::GenBank DBD::Pg \
    && git clone https://github.com/FlyBase/harvdev-XORT.git \
    && cd harvdev-XORT \
    && tar -zxvf XML-XORT-0.010.tar.gz \
    && cd XML-XORT-0.010 \
    && perl Makefile.PL \
    && make \
    && make install \
    && make clean \
    # Remove CPAN cache.
    && rm -rf ~/.cpan/{build,sources}/*
