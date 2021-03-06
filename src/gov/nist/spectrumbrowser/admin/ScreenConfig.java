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

import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.event.logical.shared.ValueChangeEvent;
import com.google.gwt.event.logical.shared.ValueChangeHandler;
import com.google.gwt.json.client.JSONNumber;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.Grid;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.HasHorizontalAlignment;
import com.google.gwt.user.client.ui.HasVerticalAlignment;
import com.google.gwt.user.client.ui.HorizontalPanel;
import com.google.gwt.user.client.ui.TextBox;

import gov.nist.spectrumbrowser.common.AbstractSpectrumBrowserWidget;
import gov.nist.spectrumbrowser.common.Defines;
import gov.nist.spectrumbrowser.common.SpectrumBrowserCallback;
import gov.nist.spectrumbrowser.common.SpectrumBrowserScreen;

public class ScreenConfig extends AbstractSpectrumBrowserWidget implements
		SpectrumBrowserScreen, SpectrumBrowserCallback<String> {

	private Admin admin;
	private static Logger logger = Logger.getLogger("SpectrumBrowser");
	private Grid grid;
	
	private JSONValue jsonValue;
	private JSONObject jsonObject;
	private Button logoutButton;
	private Button applyButton;
	private Button cancelButton;
	private boolean redraw = false;
	
	private HorizontalPanel titlePanel;


	public ScreenConfig(Admin admin) {
		super();
		try {
			this.admin = admin;
			Admin.getAdminService().getScreenConfig(this);
		} catch (Throwable th) {
			logger.log(Level.SEVERE, "Problem contacting server", th);
			Window.alert("Problem contacting server");
			admin.logoff();
		}

	}

	@Override
	public void onSuccess(String jsonString) {
		try {
			jsonValue = JSONParser.parseLenient(jsonString);
			jsonObject = jsonValue.isObject();
			if (redraw) {
				draw();
			}
		} catch (Throwable th) {
			logger.log(Level.SEVERE, "Error Parsing JSON message", th);
			admin.logoff();
		}

	}

	@Override
	public void onFailure(Throwable throwable) {
		logger.log(Level.SEVERE, "Error Communicating with server message",
				throwable);
		admin.logoff();
	}
	
	private void setInteger(int row, String key, String fieldName, TextBox widget) {
		grid.setText(row, 0, fieldName);
		int value = super.getAsInt(jsonValue, key);
		widget.setText(Integer.toString(value));
		grid.setWidget(row, 1, widget);
	}
	
	private void setText(int row, String key, String fieldName, TextBox widget) {
		grid.setText(row, 0,fieldName);
		String value = super.getAsString(jsonValue, key);
		widget.setText(value);
		grid.setWidget(row, 1, widget);
	}


	@Override
	public void draw() {
		verticalPanel.clear();
		HTML title;
		title = new HTML("<h3>Specify screen configuration parameters.</h3>");
		
		titlePanel = new HorizontalPanel();
		titlePanel.add(title);
		verticalPanel.add(titlePanel);
		
		grid = new Grid(7, 2);
		grid.setCellSpacing(4);
		grid.setBorderWidth(2);
		verticalPanel.add(grid);

		for (int i = 0; i < grid.getRowCount(); i++) {
			for (int j = 0; j < grid.getColumnCount(); j++) {
				grid.getCellFormatter().setHorizontalAlignment(i, j,
						HasHorizontalAlignment.ALIGN_CENTER);
				grid.getCellFormatter().setVerticalAlignment(i, j,
						HasVerticalAlignment.ALIGN_MIDDLE);
			}
		}
		grid.setCellPadding(2);
		grid.setCellSpacing(2);
		grid.setBorderWidth(2);

		int index = 0;
		
		TextBox mapWidth = new TextBox();
		mapWidth.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 400)
						newVal = 400;
					else if (newVal > 1600)
						newVal = 1600;
					
					jsonObject.put(Defines.MAP_WIDTH, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 400 and 1600");
				}
			}});
		setInteger(index++,Defines.MAP_WIDTH,"Map Width (pixels)",mapWidth);
		
		
		TextBox mapHeight = new TextBox();
		mapHeight.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 400)
						newVal = 400;
					else if (newVal > 1600)
						newVal = 1600;
					
					jsonObject.put(Defines.MAP_HEIGHT, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 400 and 1600");
				}
			}});
		setInteger(index++,Defines.MAP_HEIGHT,"Map Height (pixels)",mapHeight);
		
		
		TextBox specWidth = new TextBox();
		specWidth.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 400)
						newVal = 400;
					else if (newVal > 1600)
						newVal = 1600;
					
					jsonObject.put(Defines.SPEC_WIDTH, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 400 and 1600");
				}
			}});
		setInteger(index++,Defines.SPEC_WIDTH,"Chart Width (pixels) for client side charts",specWidth);
		
		
		TextBox specHeight = new TextBox();
		specHeight.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 400)
						newVal = 400;
					else if (newVal > 1600)
						newVal = 1600;
					
					jsonObject.put(Defines.SPEC_HEIGHT, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 400 and 1600");
				}
			}});
		setInteger(index++,Defines.SPEC_HEIGHT,"Chart Height (pixels) for client side charts",specHeight);
		
		
		TextBox chartWidth = new TextBox();
		chartWidth.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 1)
						newVal = 1;
					else if (newVal > 10)
						newVal = 10;
					
					jsonObject.put(Defines.CHART_WIDTH, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 1 and 10");
				}
			}});
		setInteger(index++,Defines.CHART_WIDTH, "Aspect ratio (width) for server generated charts", chartWidth);
		
		
		TextBox chartHeight = new TextBox();
		chartHeight.addValueChangeHandler(new ValueChangeHandler<String>() {
			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				String str = event.getValue();
				try {
					int newVal = Integer.parseInt(str);
					
					if (newVal < 1)
						newVal = 1;
					else if (newVal > 10)
						newVal = 10;
					
					jsonObject.put(Defines.CHART_HEIGHT, new JSONNumber(newVal));
				} catch (NumberFormatException nfe) {
					Window.alert("Please enter a valid integer between 1 and 10");
				}
			}});
		setInteger(index++,Defines.CHART_HEIGHT, "Aspect ratio (height) for server generated charts", chartHeight);
		
		TextBox warningText = new TextBox();
		warningText.addValueChangeHandler(new ValueChangeHandler<String>(){

			@Override
			public void onValueChange(ValueChangeEvent<String> event) {
				jsonObject.put(Defines.WARNING_TEXT, new JSONString(event.getValue()));
				
			}});
		
		warningText.setTitle("Absolute server path to file containing HTML to be displayed on user access to the system. Blank if no warning");
		setText(index++,Defines.WARNING_TEXT, "Path to Warning Text displayed on first access to system", warningText);

		for (int i = 0; i < grid.getRowCount(); i++) {
			grid.getCellFormatter().setStyleName(i, 0, "textLabelStyle");
		}
		
		applyButton = new Button("Apply Changes");
		cancelButton = new Button("Cancel Changes");
		logoutButton = new Button("Log Out");

		applyButton.addClickHandler(new ClickHandler() {

			@Override
			public void onClick(ClickEvent event) {
				
				Admin.getAdminService().setScreenConfig(jsonObject.toString(),
						new SpectrumBrowserCallback<String>() {

							@Override
							public void onSuccess(String result) {
								JSONObject jsonObj = JSONParser.parseLenient(result).isObject();
								if (jsonObj.get("status").isString().stringValue().equals("OK")) {
									Window.alert("Configuration successfully updated");
								} else {
									String errorMessage = jsonObj.get("ErrorMessage").isString().stringValue();
									Window.alert("Error in updating config - please re-enter. Error Message : "+errorMessage);
								}
							}

							@Override
							public void onFailure(Throwable throwable) {
								Window.alert("Error communicating with server");
								admin.logoff();
							}
						});
			}
		});

		cancelButton.addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				redraw = true;
				Admin.getAdminService().getScreenConfig(ScreenConfig.this);
			}
		});

		logoutButton.addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				admin.logoff();
			}
		});

		HorizontalPanel buttonPanel = new HorizontalPanel();
		buttonPanel.add(applyButton);
		buttonPanel.add(cancelButton);
		buttonPanel.add(logoutButton);
		verticalPanel.add(buttonPanel);
	
	}
	
	@Override
	public String getLabel() {
		return null;
	}
	
	@Override
	public String toString() {
		return null;
	}

	@Override
	public String getEndLabel() {
		return "Screen Config";
	}

}