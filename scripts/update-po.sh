#!/bin/sh
pybabel extract -F babel.cfg -o locale/messages.pot h/**/**/*
msgmerge --update locale/zh-Hant-TW/LC_MESSAGES/messages.po locale/messages.pot
