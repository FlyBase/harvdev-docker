FROM alpine:3.8

LABEL maintainer="ctabone@morgan.harvard.edu"

ENV PERL_MM_USE_DEFAULT=1

RUN apk add --update --no-cache \
    python3 \
    python3-dev \
    perl \
    perl-utils \
    perl-dev \
    perl-dbd-pg \
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
    vim \
    bash \
    build-base \
    # tzdata for setting the timezone.
    tzdata \
    gnupg &&\
    pip3 install --no-cache-dir --upgrade pip &&\
    pip3 install --no-cache-dir psycopg2

RUN cp /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone
RUN apk del tzdata

RUN curl -L http://xrl.us/cpanm > /bin/cpanm && chmod +x /bin/cpanm

RUN cpanm --quiet --notest XML::DOM &&\
    cpanm --quiet --notest XML::Parser::PerlSAX &&\
    cpanm --quiet --notest DBI &&\
    cpanm --quiet --notest Bio::DB::GenBank &&\
    cpanm --quiet --notest DBD::Pg &&\
    cpanm --query --notest Sort::Key::Natural &&\
    cpanm --query --notest LWP::Protocol::https

# Remove CPANM cache. 
RUN rm -fr /root/.cpanm/work
