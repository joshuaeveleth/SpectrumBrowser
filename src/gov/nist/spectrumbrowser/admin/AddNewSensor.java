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

import java.util.ArrayList;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.event.logical.shared.ValueChangeEvent;
import com.google.gwt.event.logical.shared.ValueChangeHandler;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.CheckBox;
import com.google.gwt.user.client.ui.Grid;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.HorizontalPanel;
import com.google.gwt.user.client.ui.TextBox;
import com.google.gwt.user.client.ui.VerticalPanel;

public class AddNewSensor  {

	private SensorConfig sensorConfig;
	private Sensor sensor;
	private Admin admin;
	private VerticalPanel verticalPanel;
	private static Logger logger = Logger.getLogger("SpectrumBrowser");
    final static boolean passwordCheckingEnabled = false;

	public AddNewSensor(Admin admin, VerticalPanel verticalPanel, SensorConfig sensorConfig) {
		this.sensorConfig = sensorConfig;
		this.sensor = new Sensor();
		this.admin = admin;
		this.verticalPanel = verticalPanel;
	}
	
	public AddNewSensor(Admin admin, VerticalPanel verticalPanel, Sensor existingSensor, SensorConfig sensorConfig){
		this.sensor = Sensor.createNew(existingSensor);
		this.admin = admin;
		this.verticalPanel = verticalPanel;
		this.sensorConfig = sensorConfig;
	}

	public void draw() {
		try {
			logger.finer("AddNewSensor: draw()");
			HTML html = new HTML("<h2>Add New Sensor</h2>");
			verticalPanel.clear();
			verticalPanel.add(html);
			Grid grid = new Grid(7, 2);
			grid.setCellPadding(2);
			grid.setCellSpacing(2);
			grid.setBorderWidth(2);
			int row = 0;
			grid.setText(row, 0, "Sensor ID");
			final TextBox sensorIdTextBox = new TextBox();
			sensorIdTextBox.setText(sensor.getSensorId());
			sensorIdTextBox
					.addValueChangeHandler(new ValueChangeHandler<String>() {

						@Override
						public void onValueChange(ValueChangeEvent<String> event) {
							String sensorId = event.getValue();
							
							if (sensorId == null || sensorId.equals("")
									|| sensorId.equals("UNKNOWN")) {
								Window.alert("Please enter a valid sensor ID");
								return;
							}
							ArrayList<Sensor> sensors = sensorConfig.getSensors();
							for (Sensor sensor : sensors) {
								if (sensorId.equals(sensor.getSensorId())) {
									Window.alert("Please enter a unique sensor ID");
									return;
								}
							}
							sensor.setSensorId(sensorId);

						}
					});
			grid.setWidget(row, 1, sensorIdTextBox);

			row++;
			grid.setText(row, 0, "Sensor Key");
			final TextBox sensorKeyTextBox = new TextBox();

			sensorKeyTextBox
					.addValueChangeHandler(new ValueChangeHandler<String>() {

						@Override
						public void onValueChange(ValueChangeEvent<String> event) {
							String key = event.getValue();
							if (key == null || (passwordCheckingEnabled &&
									 !key.matches("((?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&+=])).{12,}$"))) {
								Window.alert("Please enter a key : "
										+ "\n1) at least 12 characters, "
										+ "\n2) a digit, "
										+ "\n3) an upper case letter, "
										+ "\n4) a lower case letter, and "
										+ "\n5) a special character(!@#$%^&+=).");
								return;
							}
							sensor.setSensorKey(key);

						}
					});

			sensorKeyTextBox.setText(sensor.getSensorKey());
			grid.setWidget(row, 1, sensorKeyTextBox);
			row++;
			
			grid.setText(row,0,"Measurement Type");
			final TextBox measurementTypeTextBox = new TextBox();
			measurementTypeTextBox.setTitle("Enter Swept-frequency or FFT-Power");
			measurementTypeTextBox.addValueChangeHandler( new ValueChangeHandler<String>() {

				@Override
				public void onValueChange(ValueChangeEvent<String> event) {
					String mtype = event.getValue();
					if ( mtype.equals(Defines.FFT_POWER) || mtype.equals(Defines.SWEPT_FREQUENCY)) {
						sensor.setMeasurementType(mtype);
					} else {
						Window.alert("Please enter FFT-Power or Swept-frequency (Case sensitive)");
					}
				}});
			grid.setWidget(row, 1, measurementTypeTextBox);
			row++;
			
			
			grid.setText(row, 0, "Is Streaming Enabled?");
			final CheckBox streamingEnabled = new CheckBox();
			streamingEnabled.setValue(false);
			streamingEnabled.addValueChangeHandler(new ValueChangeHandler<Boolean>() {

				@Override
				public void onValueChange(ValueChangeEvent<Boolean> event) {
					boolean value = event.getValue();
					sensor.setStreamingEnabled(value);
				}});
			grid.setWidget(row, 1, streamingEnabled);
			row++;
			
			
			grid.setText(row, 0, "Data Retention(months)");
			final TextBox dataRetentionTextBox = new TextBox();
			dataRetentionTextBox.setText(Integer.toString(sensor
					.getDataRetentionDurationMonths()));
			dataRetentionTextBox
					.addValueChangeHandler(new ValueChangeHandler<String>() {

						@Override
						public void onValueChange(ValueChangeEvent<String> event) {
							try {
								String valueStr = event.getValue();
								if (valueStr == null) {
									Window.alert("Please enter integer >= 0");
									return;
								}
								int value = Integer.parseInt(valueStr);
								if (value < 0) {
									Window.alert("Please enter integer >= 0");
									return;
								}
								sensor.setDataRetentionDurationMonths(value);
							} catch (NumberFormatException ex) {
								Window.alert("Please enter positive integer");
								return;

							}

						}

					});
			grid.setWidget(row, 1, dataRetentionTextBox);

			row++;
			grid.setText(row, 0, "Sensor Admin Email");
			final TextBox sensorAdminEmailTextBox = new TextBox();
			sensorAdminEmailTextBox.setText(sensor.getSensorAdminEmail());
			sensorAdminEmailTextBox
					.addValueChangeHandler(new ValueChangeHandler<String>() {

						@Override
						public void onValueChange(ValueChangeEvent<String> event) {
							String email = event.getValue();
							if (!email
									.matches("^[_A-Za-z0-9-]+(\\.[_A-Za-z0-9-]+)*@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*(\\.[A-Za-z]{2,})$")) {
								Window.alert("Please enter valid email address");
								return;
							}
							sensor.setSensorAdminEmail(email);
						}
					});
			grid.setWidget(row, 1, sensorAdminEmailTextBox);
			row++;
			
			
			
			grid.setText(row, 0, "Sensor Command Line Startup Params");
			final TextBox startupParamsTextBox = new TextBox();
			startupParamsTextBox.setWidth("200px");
			startupParamsTextBox.setText(sensor.getStartupParams());
			startupParamsTextBox.addValueChangeHandler(new ValueChangeHandler<String> () {

				@Override
				public void onValueChange(ValueChangeEvent<String> event) {
					sensor.setStartupParams(event.getValue());
					
				}});

			Button submitButton = new Button("Apply");
			submitButton.addClickHandler(new ClickHandler() {

				@Override
				public void onClick(ClickEvent event) {
					if (!sensor.validate()) {
						Window.alert("Error in entry - please enter all fields.");
					} else {
						logger.log(Level.FINER, "Adding Sensor " + sensor.getSensorId());
						sensorConfig.setUpdateFlag(true);
						Admin.getAdminService().addSensor(sensor.toString(),
								sensorConfig);
					}

				}
			});
			grid.setWidget(row, 1, startupParamsTextBox);

			verticalPanel.add(grid);
			HorizontalPanel hpanel = new HorizontalPanel();
			hpanel.add(submitButton);

			Button cancelButton = new Button("Cancel");
			cancelButton.addClickHandler(new ClickHandler() {

				@Override
				public void onClick(ClickEvent event) {
					sensorConfig.redraw();
				}
			});
			hpanel.add(cancelButton);
			
			Button logoffButton = new Button("Log Off");
			logoffButton.addClickHandler(new ClickHandler(){

				@Override
				public void onClick(ClickEvent event) {
					admin.logoff();
				}});
			hpanel.add(logoffButton);
			
			verticalPanel.add(hpanel);
		} catch (Throwable th) {
			logger.log(Level.SEVERE, "Problem drawing screen", th);
		}

	}

}
