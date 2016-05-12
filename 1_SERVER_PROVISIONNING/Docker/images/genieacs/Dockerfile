FROM        ubuntu:14.04

RUN         apt-get update

RUN         apt-get install -y git-core curl zlib1g-dev build-essential \
            libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
            libxml2-dev libxslt1-dev libcurl4-openssl-dev \
            python-software-properties libffi-dev

RUN         curl -sL https://deb.nodesource.com/setup_0.10 | sudo bash -
RUN         apt-get install -y nodejs
RUN         apt-get install -y build-essential

RUN         npm install -g node-gyp

RUN         git clone https://github.com/Kalagan/genieacs.git /usr/bin/genieacs

RUN         cd /usr/bin/genieacs ; npm install --unsafe-perm

RUN         apt-get install -y supervisor
RUN         mkdir -p /var/log/supervisor

COPY        supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE      7547 7557

CMD         ["/usr/bin/supervisord"]