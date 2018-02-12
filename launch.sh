#!/usr/bin/env bash

rsync -rlzuvh \
    --exclude=launch.sh \
    --exclude=*.Rproj \
    --exclude=*.png \
    --exclude=.* \
    ~/work/github.com/immunogenomics/itcviewer/ ig:/srv/shiny-server/itc/

