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
package gov.nist.spectrumbrowser.admin;

import gov.nist.spectrumbrowser.common.Defines;

import com.google.gwt.json.client.JSONBoolean;
import com.google.gwt.json.client.JSONNumber;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONString;



public class StreamingParams {
	
	private JSONObject jsonObject;
	private JSONObject savedValues;
	
	
	public StreamingParams(JSONObject jsonObject) {
		this.jsonObject = jsonObject;
		this.savedValues = new JSONObject();
		// Populate with default values.
		savedValues.put(Defines.IS_STREAMING_CAPTURE_ENABLED, JSONBoolean.getInstance(getEnableStreamingCapture()));
		savedValues.put(Defines.IQ_CAPTURE_ENABLED, JSONBoolean.getInstance(isIqCaptureEnabled()));

		for (String key : jsonObject.keySet()) {
			savedValues.put(key, jsonObject.get(key));
		}
	}
	
	public void setEnableStreamingCapture(boolean yesNo) {
		jsonObject.put(Defines.IS_STREAMING_CAPTURE_ENABLED, JSONBoolean.getInstance(yesNo));
	}
	
	public boolean getEnableStreamingCapture() {
		if (!jsonObject.containsKey(Defines.IS_STREAMING_CAPTURE_ENABLED)) {
			return false;
		}
		else {
			return jsonObject.get(Defines.IS_STREAMING_CAPTURE_ENABLED).isBoolean().booleanValue();
		}
	}
	public boolean setStreamingCaptureSamplingIntervalSeconds(int interval) {
		if (interval <= 0) return false;
		jsonObject.put(Defines.STREAMING_SAMPLING_INTERVAL_SECONDS, new JSONNumber(interval));
		return true;
	}
	
	public int getStreamingCaptureSamplingIntervalSeconds() {
		if (!jsonObject.containsKey(Defines.STREAMING_SAMPLING_INTERVAL_SECONDS)) return -1;
		return (int) jsonObject.get(Defines.STREAMING_SAMPLING_INTERVAL_SECONDS).isNumber().doubleValue();
	}
	
	public boolean setStreamingSecondsPerFrame(float secondsPerFrame) {
		if (secondsPerFrame <= 0) return false;
		jsonObject.put(Defines.STREAMING_SECONDS_PER_FRAME, new JSONNumber(secondsPerFrame));
		return true;
	}
	public float getStreamingSecondsPerFrame() {
		if (!jsonObject.containsKey(Defines.STREAMING_SECONDS_PER_FRAME)) return -1;
		return (float) jsonObject.get(Defines.STREAMING_SECONDS_PER_FRAME).isNumber().doubleValue();
	}
	public boolean setStreamingCaptureSampleSizeSeconds(int sampleSizeSeconds) {
		if ( sampleSizeSeconds < 0) return false;
		jsonObject.put(Defines.STREAMING_CAPTURE_SAMPLE_SIZE_SECONDS, new JSONNumber(sampleSizeSeconds));
		return true;
	}
	
	
	public boolean setStreamingFilter(String streamingFilter) {
		if (!streamingFilter.equals("MAX_HOLD") && !streamingFilter.equals("MEAN")) {
			return false;
		}
		jsonObject.put(Defines.STREAMING_FILTER,new JSONString(streamingFilter));
		return true;
	}
	
	public float getColorScaleMinPower(int streamingMinPowerDbm) {
		if (!jsonObject.containsKey(Defines.SENSOR_MIN_POWER)) {
			return (float) -80;
		}
		return (float) jsonObject.get(Defines.SENSOR_MIN_POWER).isNumber().doubleValue();
	}
	
	public float getColorScaleMaxPower(int colorScaleMaxPower) {
		if (!jsonObject.containsKey(Defines.SENSOR_MAX_POWER)) {
			return (float) -40;
		}
		return (float) jsonObject.get(Defines.SENSOR_MAX_POWER).isNumber().doubleValue();
	}
	
	public void setColorScaleMinPower(float colorScaleMinPower) {
		jsonObject.put(Defines.SENSOR_MIN_POWER, new JSONNumber(colorScaleMinPower));
	}
	
	public void setColorScaleMaxPower(float colorScaleMaxPower) {
		jsonObject.put(Defines.SENSOR_MAX_POWER, new JSONNumber(colorScaleMaxPower));
	}
	
	public String getStreamingFilter() {
		if (!jsonObject.containsKey(Defines.STREAMING_FILTER)) return "UNKNOWN";
		return jsonObject.get(Defines.STREAMING_FILTER).isString().stringValue();
	}

	public boolean verify() {
		if (getStreamingFilter().equals("UNKNOWN") || 
				getEnableStreamingCapture() && 
				(getStreamingCaptureSamplingIntervalSeconds() == -1 ) || 
				getStreamingSecondsPerFrame() == -1  ||
				getStreamingSecondsPerFrame() >= getStreamingCaptureSamplingIntervalSeconds() ) {
			return false;
		} else {
			return true;
		}
	}
	
	
	public void setIqCaptureEnabled(boolean flag) {
		jsonObject.put(Defines.IQ_CAPTURE_ENABLED, JSONBoolean.getInstance(flag));
	}
	
	public boolean isIqCaptureEnabled() {
		if (! jsonObject.containsKey(Defines.IQ_CAPTURE_ENABLED)) {
			return false;
		} else {
			return jsonObject.get(Defines.IQ_CAPTURE_ENABLED).isBoolean().booleanValue();
		}
	}
	
	
	public void restore() {
		for (String key: jsonObject.keySet()) {
			jsonObject.put(key, null);
		}
		for (String key: savedValues.keySet()) {
			jsonObject.put(key, savedValues.get(key));
		}
	}

	public void clear() {
		for (String key: jsonObject.keySet()) {
			jsonObject.put(key, null);
		}
	}

}
