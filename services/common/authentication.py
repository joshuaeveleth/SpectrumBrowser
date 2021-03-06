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

import random
import util
import Config
import time
import Accounts
import AccountsManagement
import sys
import AccountLock
import DbCollections
import DebugFlags
import traceback
import SessionLock
from flask import request
from Defines import EXPIRE_TIME
from Defines import USER_NAME
from Defines import ACCOUNT_NUM_FAILED_LOGINS
from Defines import ACCOUNT_LOCKED
from Defines import ACCOUNT_EMAIL_ADDRESS
from Defines import ACCOUNT_PASSWORD
from Defines import ACCOUNT_PRIVILEGE
from Defines import ACCOUNT_PASSWORD_EXPIRE_TIME
from Defines import PASSWORD_EXPIRED_ERROR
from Defines import USER
from Defines import ADMIN
from Defines import STATUS
from Defines import STATUS_MESSAGE
from Defines import SENSOR_ID
from Defines import SENSOR_KEY
from Defines import ENABLED
from Defines import SENSOR_STATUS
from Defines import REMOTE_ADDRESS
from Defines import SESSION_ID
from Defines import SESSION_LOGIN_TIME
from Defines import ACCOUNT_LOCKED_ERROR


# TODO -- figure out how to get the remote IP address from a web socket.
def checkSessionId(sessionId, privilege, updateSessionTimer=True):
    util.debugPrint("sessionId: " + sessionId + " privilege: " + privilege)
    try:
        remoteAddress = request.environ.get('HTTP_X_REAL_IP',
                                            request.remote_addr)
        util.debugPrint("remoteAddress = " + remoteAddress)
    except:
        remoteAddress = None
    # Check privilege of the session ID being used.
    if not sessionId.startswith(privilege):
        return False
    sessionFound = False
    if DebugFlags.getDisableSessionIdCheckFlag():
        sessionFound = True
    else:
        SessionLock.acquire()
        try:
            session = SessionLock.getSession(sessionId)
            if session is not None and (
                    remoteAddress is None or
                    session[REMOTE_ADDRESS] == remoteAddress):
                sessionFound = True
                if sessionId.startswith(USER):
                    delta = Config.getUserSessionTimeoutMinutes() * 60
                else:
                    delta = Config.getAdminSessionTimeoutMinutes() * 60
                if updateSessionTimer:
                    expireTime = time.time() + delta
                    session[EXPIRE_TIME] = expireTime
                    SessionLock.updateSession(session)
                    util.debugPrint("updated session ID expireTime")
        except:
            traceback.print_exc()
            util.debugPrint("Problem checking sessionKey " + sessionId)
        finally:
            SessionLock.release()
    return sessionFound


def authenticateSensor(sensorId, sensorKey):
    record = DbCollections.getSensors().find_one({SENSOR_ID: sensorId,
                                                  SENSOR_KEY: sensorKey})
    if record is not None and record[SENSOR_STATUS] == ENABLED:
        return True
    else:
        return False


def logOut(sessionId):
    SessionLock.acquire()
    logOutSuccessful = False
    try:
        util.debugPrint("Logging off " + sessionId)
        session = SessionLock.getSession(sessionId)
        if session is None:
            util.debugPrint(
                "When logging off could not find the following session key to delete:" +
                sessionId)
        else:
            SessionLock.removeSession(session[SESSION_ID])
            logOutSuccessful = True
    except:
        util.debugPrint("Problem logging off " + sessionId)
    finally:
        SessionLock.release()
    return logOutSuccessful


def authenticatePeer(peerServerId, password):
    peerRecord = Config.findInboundPeer(peerServerId)
    if peerRecord is None:
        return False
    else:
        return password == peerRecord["key"]


def generateGuestToken():
    sessionId = generateSessionKey(USER)
    addedSuccessfully = addSessionKey(sessionId, "guest", USER)
    if addedSuccessfully:
        return sessionId
    else:
        return "0"


def generateSessionKey(privilege):
    util.debugPrint("generateSessionKey ")
    try:
        sessionId = -1
        uniqueSessionId = False
        num = 0
        SessionLock.acquire()
        # try 5 times to get a unique session id
        if DebugFlags.getDisableSessionIdCheckFlag():
            return privilege + "-" + str(123)
        else:
            while (not uniqueSessionId) and (num < 5):
                # JEK: I used time.time() as my random number so that if a user wants to create
                # DbCollections.getSessions() from 2 browsers on the same machine, the time should ensure uniqueness
                # especially since time goes down to msecs.
                # JEK I am thinking that we do not need to add remote_address to the sessionId to get uniqueness,
                # so I took out +request.remote_addr
                sessionId = privilege + "-" + str("{0:.6f}".format(time.time(
                ))).replace(".", "") + str(random.randint(1, 100000))
                util.debugPrint("SessionKey in loop = " + str(sessionId))
                session = SessionLock.getSession(sessionId)
                if session is None:
                    uniqueSessionId = True
                else:
                    num = num + 1
            if num == 5:
                util.debugPrint(
                    "Fix unique session key generation code. We tried 5 times to get a unique session key and then we gave up.")
                sessionId = -1
    except:
        util.debugPrint("Problem generating sessionKey " + str(sessionId))
        traceback.print_exc()
        sessionId = -1
    finally:
        SessionLock.release()
    util.debugPrint("SessionKey = " + str(sessionId))
    return sessionId


def addSessionKey(sessionId, userName, privilege):
    util.debugPrint("addSessionKey")
    if privilege == USER and SessionLock.isFrozen(None):
        util.debugPrint("addSessionKey: sessionLock is frozen")
        return False
    remoteAddress = request.environ.get('HTTP_X_REAL_IP', request.remote_addr)
    if sessionId != -1:
        SessionLock.acquire()
        try:
            util.debugPrint("getSession")
            session = SessionLock.getSession(sessionId)
            util.debugPrint("gotSession")
            if session is None:
                # expiry time for Admin is 15 minutes.
                if sessionId.startswith(ADMIN):
                    delta = Config.getUserSessionTimeoutMinutes() * 60
                else:
                    delta = Config.getAdminSessionTimeoutMinutes() * 60
                util.debugPrint("newSession")
                newSession = {SESSION_ID:sessionId, USER_NAME:userName,
                              REMOTE_ADDRESS: remoteAddress, SESSION_LOGIN_TIME:time.time(),
                              EXPIRE_TIME:time.time() + delta}
                SessionLock.addSession(newSession)
                return True
            else:
                util.debugPrint(
                    "session key already exists, we should never reach since only should generate unique session keys")
                return False
        except:
            util.debugPrint("Problem adding sessionKey " + sessionId)
            return False
        finally:
            SessionLock.release()
    else:
        return False


def IsAccountLocked(userName):
    accountLocked = False
    if Config.isAuthenticationRequired():
        AccountLock.acquire()
        try:
            existingAccount = DbCollections.getAccounts().find_one(
                {ACCOUNT_EMAIL_ADDRESS: userName})
            if existingAccount is not None:
                accountLocked = existingAccount[ACCOUNT_LOCKED]
        except:
            util.debugPrint("Problem authenticating user " + userName)
        finally:
            AccountLock.release()
    return accountLocked


def authenticate(privilege, userName, password):
    authenicationSuccessful = False
    reasonCode = "Invalid email, password, or account privilege. Please try again."
    util.debugPrint("authenticate check database")
    if not Config.isAuthenticationRequired() and privilege == USER:

        authenicationSuccessful = True

    elif AccountsManagement.numAdminAccounts() == 0 and privilege == ADMIN:

        util.debugPrint("No admin accounts, using default email and password")

        if userName == AccountsManagement.getDefaultAdminEmailAddress(
        ) and password == AccountsManagement.getDefaultAdminPassword():
            util.debugPrint("Default admin authenticated")
            authenicationSuccessful = True
        else:
            util.debugPrint("Default admin not authenticated")
            authenicationSuccessful = False

    elif AccountsManagement.numAdminAccounts(
    ) == 0 and userName == AccountsManagement.getDefaultAdminEmailAddress(
    ) and password == AccountsManagement.getDefaultAdminPassword():

        util.debugPrint("Default admin authenticated")
        authenicationSuccessful = True

    else:
        passwordHash = Accounts.computeMD5hash(password)
        AccountLock.acquire()
        try:
            util.debugPrint("finding existing account")
            # if we only need 'user' or higher privilege, then we only need to look for email & password, not privilege:
            if privilege == USER:
                existingAccount = DbCollections.getAccounts().find_one(
                    {ACCOUNT_EMAIL_ADDRESS: userName,
                     ACCOUNT_PASSWORD: passwordHash})
            else:
                # otherwise, we need to look for 'admin' privilege in addition to email & password:
                existingAccount = DbCollections.getAccounts().find_one({ACCOUNT_EMAIL_ADDRESS:userName,
                                                                        ACCOUNT_PASSWORD:passwordHash,
                                                                        ACCOUNT_PRIVILEGE:privilege})
            if existingAccount is None:
                util.debugPrint("did not find email and password ")
                existingAccount = DbCollections.getAccounts().find_one(
                    {ACCOUNT_EMAIL_ADDRESS: userName})
                if existingAccount is not None:
                    util.debugPrint("account exists, but user entered wrong password or attempted admin log in")
                    numFailedLoginAttempts = existingAccount[
                        ACCOUNT_NUM_FAILED_LOGINS] + 1
                    existingAccount[
                        ACCOUNT_NUM_FAILED_LOGINS] = numFailedLoginAttempts
                    util.debugPrint("numFailedLoginAttempts: " + str(
                        numFailedLoginAttempts) + " limit = " + str(
                            Config.getNumFailedLoginAttempts()))
                    if numFailedLoginAttempts == Config.getNumFailedLoginAttempts():
                        existingAccount[ACCOUNT_LOCKED] = True
                        reasonCode = ACCOUNT_LOCKED_ERROR + ": Please mail the Administrator <" + Config.getSmtpEmail(
                        ) + "> to unlock."
                        util.debugPrint(reasonCode)
                    DbCollections.getAccounts().update(
                        {"_id": existingAccount["_id"]},
                        {"$set": existingAccount},
                        upsert=False)
            else:
                util.debugPrint("found email and password ")
                if not existingAccount[ACCOUNT_LOCKED]:
                    currentTime = time.time()
                    # Check for password expiry time.
                    if currentTime >= existingAccount[
                            ACCOUNT_PASSWORD_EXPIRE_TIME]:
                        reasonCode = PASSWORD_EXPIRED_ERROR + ": Please reset your password on login screen"
                    else:
                        util.debugPrint("user passed login authentication.")
                        existingAccount[ACCOUNT_NUM_FAILED_LOGINS] = 0
                        # Place-holder. We need to access LDAP (or whatever) here.
                        DbCollections.getAccounts().update(
                            {"_id": existingAccount["_id"]},
                            {"$set": existingAccount},
                            upsert=False)
                        util.debugPrint("user login info updated.")
                        authenicationSuccessful = True
                else:
                    reasonCode = ACCOUNT_LOCKED_ERROR + ": Please email the Administrator <" + Config.getSmtpEmail(
                    ) + "> to unlock."

        except:
            util.debugPrint("Problem authenticating user " + userName +
                            " password: " + password)
            print "Unexpected error:", sys.exc_info()[0]
            print sys.exc_info()
            traceback.print_exc()
        finally:
            AccountLock.release()
    return authenicationSuccessful, reasonCode


def authenticateUser(accountData):
    """
     Authenticate a user given a requested privilege, userName and password.
    """
    userName = accountData[ACCOUNT_EMAIL_ADDRESS].strip()
    password = accountData[ACCOUNT_PASSWORD]
    privilege = accountData[ACCOUNT_PRIVILEGE]
    remoteAddr = request.remote_addr
    if privilege == ADMIN or privilege == USER:
        if IsAccountLocked(userName):
            return {STATUS:"ACCLOCKED", SESSION_ID:"0",
                    STATUS_MESSAGE: ACCOUNT_LOCKED_ERROR +
                    ": Please email the Administrator <" +
                    Config.getSmtpEmail() + "> to unlock."}
        else:
            # Authenticate will will work whether passwords are required or not (authenticate = true if no pwd req'd)
            # Only one admin login allowed at a given time.
            if privilege == ADMIN:
                SessionLock.removeSessionByAddr(userName, remoteAddr)
                if SessionLock.getAdminSessionCount() != 0:
                    return {STATUS: "NOSESSIONS",
                            SESSION_ID: "0",
                            STATUS_MESSAGE: "No admin sessions available."}
            result, statusMessage = authenticate(privilege, userName, password)
            if result:
                sessionId = generateSessionKey(privilege)
                addedSuccessfully = addSessionKey(sessionId, userName,
                                                  privilege)
                if addedSuccessfully:
                    return {STATUS: "OK",
                            SESSION_ID: sessionId,
                            STATUS_MESSAGE: "Authentication successful."}
                else:
                    return {STATUS: "INVALSESSION",
                            SESSION_ID: "0",
                            STATUS_MESSAGE:
                            "Failed to generate a valid session key."}
            else:
                return {STATUS: "INVALUSER",
                        SESSION_ID: "0",
                        STATUS_MESSAGE: statusMessage}
    else:
        return {STATUS: "NOK",
                SESSION_ID: "0",
                STATUS_MESSAGE: "Invalid privilege"}


def authenticateSensorAgent(accountData):
    agentName = accountData["agentName"]
    agentKey = accountData["key"]
    esAgents = Config.getESAgents()
    for agent in esAgents:
        if agentName == agent["agentName"] and agentKey == agent["key"]:
            return True
    return False


def removeAdminSessions():
    SessionLock.removeSessionsByPrivilege(ADMIN)


def isUserRegistered(emailAddress):
    UserRegistered = False
    if Config.isAuthenticationRequired():
        AccountLock.acquire()
        try:
            existingAccount = DbCollections.getAccounts().find_one(
                {ACCOUNT_EMAIL_ADDRESS: emailAddress})
            if existingAccount is not None:
                UserRegistered = True
        except:
            util.debugPrint("Problem checking if user is registered " +
                            emailAddress)
        finally:
            AccountLock.release()
    return UserRegistered
