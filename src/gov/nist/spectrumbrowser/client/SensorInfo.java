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
package gov.nist.spectrumbrowser.client;

import gov.nist.spectrumbrowser.common.Defines;
import gov.nist.spectrumbrowser.common.SpectrumBrowserCallback;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.HashMap;

import com.google.gwt.i18n.client.NumberFormat;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.HTML;

public class SensorInfo {

	private static Logger logger = Logger.getLogger("SpectrumBrowser");
	private HashMap<String, BandInfo> bandInfo = new HashMap<String, BandInfo>();
	private long acquistionCount;
	private SpectrumBrowser spectrumBrowser;
	private String sensorId;
	private double lat;
	private double lng;
	private double alt;
	private long tEndReadings;
	private long tStartDayBoundary;
	private String measurementType;
	private long tStartReadings;
	private SensorInfoDisplay sensorInfoDisplay;
	private String tStartLocalFormattedTimeStamp;
	private String tEndLocalFormattedTimeStamp;
	private JSONObject systemMessageJsonObject;
	private HashSet<FrequencyRange> frequencyRanges = new HashSet<FrequencyRange>();
	private BandInfo selectedBand;
	private boolean isStreamingEnabled;


	public String formatToPrecision(int precision, double value) {
		String format = "00.";
		for (int i = 0; i < precision; i++) {
			format += "0";
		}
		return NumberFormat.getFormat(format).format(value);
	}

	

	public SensorInfo(JSONObject systemMessageObject, String sensorId, double lat, double lon, double alt,
			SpectrumBrowser spectrumBrowser, SensorInfoDisplay sensorInfo) {
		this.systemMessageJsonObject = systemMessageObject;
		this.spectrumBrowser = spectrumBrowser;
		this.sensorId = sensorId;
		this.lat = lat;
		this.lng = lon;
		this.alt = alt;
		this.sensorInfoDisplay = sensorInfo;
		logger.finer("SensorInfo.SensorInfo()");
	}
	
	/**
	 * Get the data summary for all the readings of the sensor.
	 */
	public void updateDataSummary() {
		updateDataSummary(-1,-1,-1,-1);
	}
	
	/**
	 * Get the data summary for a specific start time, day count and freq range.
	 * 
	 * @param startTime
	 * @param dayCount
	 * @param minFreq
	 * @param maxFreq
	 */

	public void updateDataSummary(long startTime, int dayCount, long minFreq,
			long maxFreq) {
		
		spectrumBrowser.getSpectrumBrowserService().getDataSummary(sensorId,
				lat, lng, alt, startTime, dayCount, minFreq, maxFreq,
				new SpectrumBrowserCallback<String>() {


					@Override
					public void onSuccess(String text) {
						try {
							logger.fine(text);
							JSONObject jsonObj = (JSONObject) JSONParser
									.parseLenient(text);
							String status = jsonObj.get(Defines.STATUS)
									.isString().stringValue();
							if (status.equals("NOK")) {
								Window.alert(jsonObj.get(Defines.ERROR_MESSAGE)
										.isString().stringValue());
								return;
							}
							acquistionCount = (long) jsonObj.get(Defines.COUNT)
									.isNumber().doubleValue();

							measurementType = jsonObj
									.get(Defines.MEASUREMENT_TYPE).isString()
									.stringValue();
							logger.finer(measurementType);

							tStartReadings = (long) jsonObj
									.get(Defines.T_START_READINGS).isNumber()
									.doubleValue();

							tEndReadings = (long) jsonObj
									.get(Defines.T_END_READINGS).isNumber()
									.doubleValue();

							tStartDayBoundary = (long) jsonObj
									.get(Defines.TSTART_DAY_BOUNDARY)
									.isNumber().doubleValue();

							sensorInfoDisplay.setSelectedStartTime(tStartDayBoundary);
							sensorInfoDisplay.setDayBoundaryDelta(tStartDayBoundary
									- sensorInfoDisplay
											.getSelectedDayBoundary((long) jsonObj
													.get(Defines.TSTART_DAY_BOUNDARY)
													.isNumber().doubleValue()));

							tStartLocalFormattedTimeStamp = (String) jsonObj
									.get(Defines.TSTART_LOCAL_FORMATTED_TIMESTAMP)
									.isString().stringValue();

							tEndLocalFormattedTimeStamp = jsonObj
									.get(Defines.TEND_LOCAL_FORMATTED_TIMESTAMP)
									.isString().stringValue();
							JSONArray bands = jsonObj.get(
									Defines.BAND_STATISTICS).isArray();
							for (int i = 0; i < bands.size(); i++) {
								
								BandInfo bi = new BandInfo(SensorInfo.this,bands.get(i)
										.isObject(), getSensorId(),lat, lng, alt, spectrumBrowser);
								
								String key = bi.getFreqRange().toString();
								bandInfo.put(key, bi);
								frequencyRanges.add(bi.getFreqRange());
								if (selectedBand == null) {
									selectedBand = bi;
								}
							}
							
							isStreamingEnabled = jsonObj.get(Defines.IS_STREAMING_ENABLED).isBoolean().booleanValue();
							
							sensorInfoDisplay.buildSummary();
						} catch (Throwable ex) {
							logger.log(Level.SEVERE,
									"Error Parsing returned data ", ex);
							Window.alert("Error parsing returned data!");
						} finally {

						}
						// iwo.setPixelOffet(Size.newInstance(0, .1));

					}

					@Override
					public void onFailure(Throwable throwable) {
						logger.log(Level.SEVERE,
								"Error occured in processing request",
								throwable);

						Window.alert("Error in contacting server. Try later");
						return;

					}

				});
	}

	HashMap<String, BandInfo> getBandInfo() {
		return bandInfo;
	}

	Set<String> getBandNames() {
		return bandInfo.keySet();
	}

	BandInfo getBandInfo(String bandName) {
		return bandInfo.get(bandName);
	}

	
	long getAcquistionCount() {
		return acquistionCount;
	}

	long gettEndReadings() {
		return tEndReadings;
	}

	long gettStartDayBoundary() {
		return tStartDayBoundary;
	}

	String getMeasurementType() {
		return measurementType;
	}

	long gettStartReadings() {
		return tStartReadings;
	}

	String gettStartLocalFormattedTimeStamp() {
		return tStartLocalFormattedTimeStamp;
	}

	String gettEndLocalFormattedTimeStamp() {
		return tEndLocalFormattedTimeStamp;
	}

	public String getCotsSensorModel() {
		return systemMessageJsonObject.get(Defines.COTS_SENSOR).isObject()
				.get(Defines.MODEL).isString().stringValue();
	}

	public String getSensorAntennaType() {
		return systemMessageJsonObject.get(Defines.ANTENNA).isObject().get(Defines.MODEL)
				.isString().stringValue();
	}
	
	public boolean isStreamingEnabled() {
		return isStreamingEnabled;
	}

	private String getFormattedFrequencyRanges() {
		StringBuilder retval = new StringBuilder();
		for (String r : this.bandInfo.keySet()) {
			retval.append(r + " <br/>");
		}
		return retval.toString();
	}

	public String getTstartLocalTimeAsString() {
		return this.tStartLocalFormattedTimeStamp;
	}

	public String getTendReadingsLocalTimeAsString() {
		return this.tEndLocalFormattedTimeStamp;
	}
	
	public HashSet<FrequencyRange> getFreqRanges() {
		return this.frequencyRanges;
	}
	
	
	public HTML getBandDescription(String bandName) {
		BandInfo bi = this.bandInfo.get(bandName);
		if (bi == null ) {
			logger.log(Level.SEVERE, "Band  " + bandName + " not found : " + this.getSensorId());
			return null;
		}
		return new HTML(bi.getDescription());
	}
	

	public HTML getSensorDescription() {

		HTML retval =  new HTML( "<b>Sensor Info </b>"
				+ "<div align=\"left\", height=\"300px\">"
				+ "<br/>Sensor ID = "
				+ sensorId
				+ "<br/>Location: Lat = "
				+ NumberFormat.getFormat("00.00").format(lat)
				+ "; Long = "
				+ NumberFormat.getFormat("00.00").format(lng)
				+ "; Alt = "
				+ this.formatToPrecision(2, alt)
				+ " Ft."
				+ "<br/> Sensor ID = "
				+ sensorId
				+ "<br/> Sensor Model = "
				+ getCotsSensorModel()
				+ "<br/>Antenna Type = "
				+ getSensorAntennaType()
				+ "<br/> Measurement Type = "
				+ measurementType
				+ "<br/>Data Start Time = "
				+ this.gettStartLocalFormattedTimeStamp()
				+ "<br/>Data End Time = "
				+ this.gettEndLocalFormattedTimeStamp()
				+ "<br/>Aquisition Count = "
				+ acquistionCount
				+ "<br/>Frequency Bands = " + getFormattedFrequencyRanges() 
				+ "<br/><br/></div>");
		retval.setStyleName("sensorInfo");
		return retval;
	}
	
	public HTML getSensorDescriptionNoBands() {

		HTML retval =  new HTML( 
				 "<div align=\"left\", height=\"300px\">"
				+ "<br/> Sensor ID = "
				+ sensorId
				+ "<br/> Sensor Model = "
				+ getCotsSensorModel()
				+ "<br/>Location: Lat = "
				+ NumberFormat.getFormat("00.00").format(lat)
				+ "; Long = "
				+ NumberFormat.getFormat("00.00").format(lng)
				+ "; Alt = "
				+ this.formatToPrecision(2, alt)
				+ " Ft."
				+ "<br/>Antenna Type = "
				+ getSensorAntennaType()
				+ "<br/> Measurement Type = "
				+ measurementType
				+ "<br/>Data Start Time = "
				+ this.gettStartLocalFormattedTimeStamp()
				+ "<br/>Data End Time = "
				+ this.gettEndLocalFormattedTimeStamp()
				+ "<br/>Aquisition Count = "
				+ acquistionCount
				+ "<br/>"
				+ "<br/><b/>Frequency Bands (Click to select below):" 
				+ "<br/></div>");
		retval.setStyleName("sensorInfo");
		return retval;
	}
	public String getSensorId() {
		return this.sensorId;
	}
	
	public void setSelectedBand(String bandName) {
		this.selectedBand = this.bandInfo.get(bandName);
	}

	public BandInfo getSelectedBand() {
		return this.selectedBand;
	}

	public boolean containsSys2detect(String sys2Detect) {
		for (FrequencyRange range : this.frequencyRanges) {
			if (range.sys2detect.equals(sys2Detect)) {
				return true;
			}
		}
		return false;
	}



	public Collection<BandInfo> getBands() {
		return this.bandInfo.values();
	}

	

}
