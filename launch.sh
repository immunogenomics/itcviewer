#!/usr/bin/env bash

rsync -avh \
    --exclude=launch.sh \
    --exclude=*.Rproj \
    --exclude=*.png \
    --exclude=.* \
    ~/work/github.com/immunogenomics/itcviewer/ ig:/srv/shiny-server/itc/

