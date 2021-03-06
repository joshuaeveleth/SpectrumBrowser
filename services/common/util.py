#! /usr/local/bin/python2.7
# -*- coding: utf-8 -*-
#
#This software was developed by employees of the National Institute of
#Standards and Technology (NIST), and others.
#This software has been contributed to the public domain.
#Pursuant to title 15 Untied States Code Section 105, works of NIST
#employees are not subject to copyright protection in the United States
#and are considered to be in the public domain.
#As a result, a formal license is not needed to use this software.
#
#This software is provided "AS IS."
#NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED
#OR STATUTORY, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
#AND DATA ACCURACY.  NIST does not warrant or make any representations
#regarding the use of the software or the results thereof, including but
#not limited to the correctness, accuracy, reliability or usefulness of
#this software.

import os
import DbCollections
from Defines import SENSOR_ID
import logging
import traceback
import StringIO
import Bootstrap
import fcntl
import Log

global launchedFromMain


class pidfile(object):
    """Context manager that locks a pid file.
    http://code.activestate.com/recipes/577911-context-manager-for-a-daemon-pid-file/

    Example usage:
    >>> with PidFile('running.pid'):
    ...     f = open('running.pid', 'r')
    ...     print("This context has lockfile containing pid {}".format(f.read()))
    ...     f.close()
    ...
    This context has lockfile containing pid 31445
    >>> os.path.exists('running.pid')
    False

    """

    def __init__(self, path):
        self.path = path
        self.pidfile = None

    def __enter__(self):
        self.pidfile = open(self.path, "a+")
        try:
            fcntl.flock(self.pidfile.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except IOError:
            raise SystemExit("Already running according to " + self.path)
        self.pidfile.seek(0)
        self.pidfile.truncate()
        self.pidfile.write(str(os.getpid()) + '\n')
        self.pidfile.flush()
        self.pidfile.seek(0)
        return self.pidfile

    def __exit__(self, exc_type=None, exc_value=None, exc_tb=None):
        try:
            self.pidfile.close()
        except IOError as err:
            # ok if file was just closed elsewhere
            if err.errno != 9:
                raise
        os.remove(self.path)


def getPath(x):
    flaskRoot = Bootstrap.getSpectrumBrowserHome() + "/flask/"
    return flaskRoot + x


def debugPrint(string):
    logger = Log.getLogger()
    logger.debug(string)


def logStackTrace(tb):
    tb_output = StringIO.StringIO()
    traceback.print_stack(limit=None, file=tb_output)
    logger = Log.getLogger()
    logging.exception("Exception occured")
    logger.error(tb_output.getvalue())
    tb_output.close()


def errorPrint(string):
    print "ERROR: ", string
    logger = Log.getLogger()
    logger.error(string)


def roundTo1DecimalPlaces(value):
    newVal = int((value + 0.05) * 10)
    return float(newVal) / float(10)


def roundTo2DecimalPlaces(value):
    newVal = int((value + 0.005) * 100)
    return float(newVal) / float(100)


def roundTo3DecimalPlaces(value):
    newVal = int((value + .0005) * 1000)
    return float(newVal) / float(1000)


def getMySensorIds():
    """
    get a collection of sensor IDs that we manage.
    """
    sensorIds = set()
    systemMessages = DbCollections.getSystemMessages().find()
    for systemMessage in systemMessages:
        sid = systemMessage[SENSOR_ID]
        sensorIds.add(sid)
    return sensorIds


def generateUrl(protocol, host, port):
    return protocol + "://" + host + ":" + str(port)
