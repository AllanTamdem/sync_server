FROM        ruby:2.1.5

RUN         apt-get update -qq && apt-get install -y build-essential libpq-dev

RUN         mkdir /geniacs-gui

WORKDIR     /geniacs-gui

RUN         git clone https://github.com/zaidka/genieacs-gui.git /geniacs-gui \
            ; cd /geniacs-gui \
            ; git reset --hard 85f3e0dfca100ebd8121b4e3f9beb67722c25940 \
            ; git pull

ADD         config/* /geniacs-gui/config/

RUN         bundle

EXPOSE      3000

CMD         ["rails", "s"]