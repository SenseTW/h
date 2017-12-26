# -*- coding: utf-8 -*-
from pyramid.i18n import make_localizer, TranslationString as __

#@FIXME: dirty hack for fixing translation does not  work.
import os
local_dir = os.path.dirname(os.path.abspath(__file__)) + '/locale'
loc = make_localizer('zh_TW', [local_dir])

def TranslationString(msg):
    return loc.translate(__(msg, domain='h'))
