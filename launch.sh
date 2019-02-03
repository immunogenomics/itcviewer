#!/usr/bin/env bash

rsync -rlzuvh \
    --exclude=launch.sh \
    --exclude=*.Rproj \
    --exclude=*.png \
    --exclude=*.pdf\
    --exclude=www/figures \
    --exclude=.* \
    ~/work/github.com/immunogenomics/itcviewer/ ig:/srv/shiny-server/itc/

