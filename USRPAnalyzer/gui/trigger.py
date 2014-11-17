#!/usr/bin/env python

# USRPAnalyzer - spectrum sweep functionality for USRP and GNURadio
# Copyright (C) Douglas Anderson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


import wx


class continuous_run_btn(wx.Button):
    """A button to run the flowgraph continuously."""
    def __init__(self, frame):
        wx.Button.__init__(
            self, frame, wx.ID_ANY, label="Continuous"#, style=wx.BU_EXACTFIT
        )
        self.Bind(wx.EVT_BUTTON, frame.set_run_continuous)


class single_run_btn(wx.Button):
    """A button to run the flowgraph once and pause."""
    def __init__(self, frame):
        wx.Button.__init__(
            self, frame, wx.ID_ANY, label="Single"#, style=wx.BU_EXACTFIT
        )
        self.Bind(wx.EVT_BUTTON, frame.set_run_single)


def init_ctrls(frame):
    """Initialize gui controls for triggering the flowgraph"""
    ctrl_label = wx.StaticBox(frame, wx.ID_ANY, "Trigger")
    ctrls = wx.StaticBoxSizer(ctrl_label, wx.VERTICAL)
    grid = wx.GridSizer(rows=2, cols=1)
    grid.Add(single_run_btn(frame))
    grid.Add(continuous_run_btn(frame))
    ctrls.Add(grid, flag=wx.ALL, border=5)

    return ctrls