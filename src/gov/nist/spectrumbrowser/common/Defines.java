/*
* Conditions Of Use 
* 
* This software was developed by employees of the National Institute of
* Standards and Technology (NIST), and others. 
* This software has been contributed to the public domain. 
* Pursuant to title 15 Untied States Code Section 105, works of NIST
* employees are not subject to copyright protection in the United States
* and are considered to be in the public domain. 
* As a result, a formal license is not needed to use this software.
* 
* This software is provided "AS IS."  
* NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED
* OR STATUTORY, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT
* AND DATA ACCURACY.  NIST does not warrant or make any representations
* regarding the use of the software or the results thereof, including but
* not limited to the correctness, accuracy, reliability or usefulness of
* this software.
*/
package gov.nist.spectrumbrowser.common;

public final class Defines {
	
	public static final String USER_PRIVILEGE = "user";
	public static final String ADMIN_PRIVILEGE = "admin";
	public static final String SENSOR_ID = "SensorID";
	public static final String SENSOR_KEY = "SensorKey";
	public static final String SENSOR_ADMIN_EMAIL = "sensorAdminEmail";
	public static final String SENSOR_STATUS = "sensorStatus";
	public static final String LOCAL_DB_INSERTION_TIME = "_localDbInsertionTime";
	public static final String DATA_RETENTION_DURATION_MONTHS = "dataRetentionDurationMonths";
	public static final String SENSOR_THRESHOLDS = "thresholds";
	public static final String SENSOR_STREAMING_PARAMS = "streaming";
	public static final String STREAMING_SAMPLING_INTERVAL_SECONDS = "streamingSamplingIntervalSeconds";
	public static final String STREAMING_SECONDS_PER_FRAME = "streamingSecondsPerFrame";
	public static final String STREAMING_CAPTURE_SAMPLE_SIZE_SECONDS = "streamingCaptureSampleSizeSeconds";
	public static final String STREAMING_FILTER = "streamingFilter";
	public static final String IS_STREAMING_CAPTURE_ENABLED = "enableStreamingCapture";
	public static final String ACCOUNT_LOCKED_ERROR = "ACCOUNT_LOCKED";

	public static final String LAST_MESSAGE_TYPE = "lastMessageType";
	public static final String LAST_MESSAGE_DATE = "lastMessageDate";
	public static final String ENABLED = "ENABLED";
	public static final String DISABLED = "DISABLED";
	public static final String LAT = "Lat";
	public static final String LON = "Lon";
	public static final String ALT = "Alt";
	public static final String FFT_POWER = "FFT-Power";
	public static final String SWEPT_FREQUENCY = "Swept-frequency";
	public static final String FREQ_RANGE = "freqRange";
	public static final String CHANNEL_COUNT = "channelCount";
	public static final String ACQUISITION_COUNT = "acquisitionCount";
	public static final String SENSOR_MIN_POWER = "sensorMinPower";
	public static final String SENSOR_MAX_POWER = "sensorMaxPower";

	public static final String UNKNOWN = "UNKNOWN";
	public static final String API_KEY = "API_KEY";
	public static final String HOST_NAME = "HOST_NAME";
	public static final String PUBLIC_PORT = "PUBLIC_PORT";
	public static final String PROTOCOL = "PROTOCOL";
	public static final String IS_AUTHENTICATION_REQUIRED = "IS_AUTHENTICATION_REQUIRED";
	public static final String MY_SERVER_ID = "MY_SERVER_ID";
	public static final String MY_SERVER_KEY = "MY_SERVER_KEY";
	public static final String SMTP_PORT = "SMTP_PORT";
	public static final String SMTP_SERVER = "SMTP_SERVER";
	public static final String SMTP_EMAIL_ADDRESS = "SMTP_EMAIL_ADDRESS";
	public static final String STREAMING_SERVER_PORT = "STREAMING_SERVER_PORT";
	public static final String SOFT_STATE_REFRESH_INTERVAL = "SOFT_STATE_REFRESH_INTERVAL";
	public static final String USE_LDAP = "USE_LDAP";
	public static final String ACCOUNT_NUM_FAILED_LOGIN_ATTEMPTS = "ACCOUNT_NUM_FAILED_LOGIN_ATTEMPTS";
	public static final String CHANGE_PASSWORD_INTERVAL_DAYS = "CHANGE_PASSWORD_INTERVAL_DAYS";
	public static final String ACCOUNT_REQUEST_TIMEOUT_HOURS = "ACCOUNT_REQUEST_TIMEOUT_HOURS";
	public static final String ACCOUNT_USER_ACKNOW_HOURS = "ACCOUNT_USER_ACKNOW_HOURS";
	public static final String USER_SESSION_TIMEOUT_MINUTES = "USER_SESSION_TIMEOUT_MINUTES";
	public static final String ADMIN_SESSION_TIMEOUT_MINUTES = "ADMIN_SESSION_TIMEOUT_MINUTES";
	public static final String OCCUPANCY_ALERT_PORT = "OCCUPANCY_ALERT_PORT";
	public static final String MIN_STREAMING_INTER_ARRIVAL_TIME_SECONDS = "MIN_STREAMING_INTER_ARRIVAL_TIME_SECONDS";
	public static final String CERT = "CERT";
	public static final String ADMIN = "admin";
	public static final String USER = "user";

	public static final String ACCOUNT_EMAIL_ADDRESS = "emailAddress";
	public static final String ACCOUNT_FIRST_NAME = "firstName";
	public static final String ACCOUNT_LAST_NAME = "lastName";
	public static final String ACCOUNT_PASSWORD = "password";
	public static final String ACCOUNT_PRIVILEGE = "privilege";
	public static final String ACCOUNT_CREATION_TIME = "timeAccountCreated";
	public static final String ACCOUNT_PASSWORD_EXPIRE_TIME = "timePasswordExpires";
	public static final String ACCOUNT_NUM_FAILED_LOGINS = "numFailedLoginAttempts";
	public static final String ACCOUNT_LOCKED = "accountLocked";
	public static final String TEMP_ACCOUNT_TOKEN = "token";

	public static final String ACCOUNT_OLD_PASSWORD = "oldPassword";
	public static final String ACCOUNT_NEW_PASSWORD = "newPassword";

	public static final String SYS = "Sys";
	public static final String LOC = "Loc";
	public static final String DATA = "Data";
	public static final String CAL = "Cal";
	public static final String DATA_TYPE = "DataType";
	public static final String DATA_KEY = "_dataKey";
	public static final String TYPE = "Type";
	public static final String NOISE_FLOOR = "wnI";
	public static final String SYS_TO_DETECT = "Sys2Detect";
	public static final String THRESHOLD_DBM_PER_HZ = "thresholdDbmPerHz";
	public static final String THRESHOLD_MIN_FREQ_HZ = "minFreqHz";
	public static final String THRESHOLD_MAX_FREQ_HZ = "maxFreqHz";
	public static final String THRESHOLD_SYS_TO_DETECT = "systemToDetect";
	public static final String BINARY_INT8 = "Binary - int8";
	public static final String BINARY_INT16 = "Binary - int16";
	public static final String BINARY_FLOAT32 = "Binary - float32";
	public static final String ASCII = "ASCII";

	public static final String MAX_HOLD = "MAX_HOLD";

	public static final String TIME_ZONE_KEY = "TimeZone";

	public static final int TWO_HOURS = 2 * 60 * 60;
	public static final int FIFTEEN_MINUTES = 15 * 60;
	public static final int SECONDS_PER_HOUR = 60 * 60;
	public static final int HOURS_PER_DAY = 24;
	public static final int MINUTES_PER_DAY = HOURS_PER_DAY * 60;
	public static final int SECONDS_PER_DAY = MINUTES_PER_DAY * 60;
	public static final int MILISECONDS_PER_DAY = SECONDS_PER_DAY * 1000;
	public static final String UNDER_CUTOFF_COLOR = "#D6D6DB";
	public static final String OVER_CUTOFF_COLOR = "#000000";
	
	public static final String MAP_WIDTH = "mapWidth";
	public static final String MAP_HEIGHT = "mapHeight";
	public static final String SPEC_WIDTH = "specWidth";
	public static final String SPEC_HEIGHT = "specHeight";
	public static final String CHART_WIDTH = "chartWidth";
	public static final String CHART_HEIGHT = "chartHeight";
	public static final String CANV_WIDTH = "canvWidth";
	public static final String CANV_HEIGHT = "canvHeight";
	
	public static final String CPU = "CPU";
	public static final String DISK = "Disk";
	public static final String NET_SENT = "NetSent";
	public static final String NET_RECV = "NetRecv";
	public static final String VIRT_MEM = "VirtMem";
	public static final String[] RESOURCE_KEYS = new String []{CPU, VIRT_MEM,  NET_SENT, NET_RECV, DISK}; // this order must match the order in Defines.py
	public static final String[] RESOURCE_UNITS = new String[]{" %"," %", " Bytes/s", " Bytes/s", " %" };
	
	public static final String[] SERVICE_NAMES = new String []{"servicecontrol","admin", "spectrumbrowser", "streaming", "occupancy", "monitoring", "federation","spectrumdb"}; // this order must match the order in Defines.py

	public static final String EXPIRE_TIME = "expireTime";
	public static final String ERROR_MESSAGE = "ErrorMessage";	
	public static final String USER_ACCOUNTS = "userAccounts";
	public static final String STATUS = "status";
	public static final String STATUS_MESSAGE = "statusMessage";

	public static final String USER_NAME = "userName";
	public static final String SESSIONS = "sessions";
	public static final String SESSION_ID = "sessionId";
	public static final String SESSION_TOKEN = "SessionToken";
	public static final String SESSION_LOGIN_TIME = "timeLogin";
	public static final String REMOTE_ADDRESS = "remoteAddress";

	public static final String USER_SESSIONS = "userSessions";
	public static final String ADMIN_SESSIONS = "adminSessions";
	public static final String OK = "OK";
	public static final String NOK = "NOK";
	
	public static final String FROZEN = "FROZEN";
	public static final String FREEZE_REQUESTER = "FREEZE_REQUESTER";
	
	
	public static final String COUNT = "count";
	public static final String MEASUREMENT_TYPE = "measurementType";
	public static final String T_START_READINGS = "tStartReadings";
	public static final String T_END_READINGS = "tEndReadings";
	public static final String MAX_OCCUPANCY = "maxOccupancy";
	public static final String MIN_OCCUPANCY = "minOccupancy";
	public static final String MEAN_OCCUPANCY = "meanOccupancy";
	public static final String MEDIAN_OCCUPANCY = "medianOccupancy";
	public static final String TSTART_LOCAL_FORMATTED_TIMESTAMP = "tStartLocalTimeFormattedTimeStamp";
	public static final String TEND_LOCAL_FORMATTED_TIMESTAMP = "tEndLocalTimeFormattedTimeStamp";
	public static final String TSTART_DAY_BOUNDARY = "tStartDayBoundary";
	public static final String BAND_STATISTICS = "bandStatistics";
	public static final String SYSTEM_TO_DETECT = "systemToDetect";
	public static final String TSTART_LOCAL_TIME = "tStartLocalTime";
	public static final String MAX_FREQ = "maxFreq";
	public static final String T_END_READINGS_LOCAL_TIME = "tEndReadingsLocalTime";
	public static final String MIN_FREQ = "minFreq";
	public static final String T_END_DAY_BOUNDARY = "tEndDayBoundary";
	public static final String T_END_READINGS_DAY_BOUNDARY = "tEndReadingsDayBoundary";
	public static final String COTS_SENSOR = "COTSsensor";
	public static final String MODEL = "Model";
	public static final String ANTENNA = "Antenna";
	public static final String IS_STREAMING_ENABLED = "isStreamingEnabled";
	public static final String STREAMING = "streaming";
	public static final long MILISECONDS_PER_SECOND = 1000;
	public static final String STARTUP_PARAMS = "startupParams";
	public static final String WARNING_TEXT = "WARNING_TEXT";
	
	public static final String PASSWORD_EXPIRED_ERROR = "PASSWORD_EXPIRED_ERROR";
	public static final String ACTIVE = "active";
	public static final String IQ_CAPTURE_ENABLED = "isIqCaptureEnabled";
	public static final String LOCATION_MESSAGE_ID = "locationMessageId";
	public static final String SPECTRUMS_PER_MEASUREMENT = "measurementCount";
	public static final String TIME_PER_SPECTRUM = "timeBetweenMeasurements";
	public static final String SPECTROGRAM_INTERVAL_SECONDS = "spectrogramAggregationSizeSeconds";
}
