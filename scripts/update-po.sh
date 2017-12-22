#!/bin/sh
pybabel extract -F babel.cfg -o h/locale/h.pot h/**/**/*
pybabel update -D h -l zh_TW -d h/locale -i h/locale/h.pot
pybabel compile -D h -f -d h/locale
