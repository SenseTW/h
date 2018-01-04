# -*- coding: utf-8 -*-

"""Guideline page view."""

from __future__ import unicode_literals

from pyramid.view import view_config
from pyramid.view import view_defaults


@view_defaults(route_name='guideline',
               renderer='h:templates/guideline.html.jinja2')
class GuidelineController(object):
    """Guideline view for the "guideline" route."""

    def __init__(self, request):
        self.request = request

    @view_config(request_method='GET')
    def guideline(self):
        return {}
