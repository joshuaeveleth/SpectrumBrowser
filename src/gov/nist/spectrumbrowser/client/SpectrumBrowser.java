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

import gov.nist.spectrumbrowser.admin.Admin;
import gov.nist.spectrumbrowser.admin.ScreenConfig;
import gov.nist.spectrumbrowser.admin.SystemConfig;
import gov.nist.spectrumbrowser.common.AbstractSpectrumBrowser;
import gov.nist.spectrumbrowser.common.AbstractSpectrumBrowserService;
import gov.nist.spectrumbrowser.common.Defines;
import gov.nist.spectrumbrowser.common.SpectrumBrowserCallback;

import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.gwt.core.client.EntryPoint;
import com.google.gwt.core.client.GWT;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.event.dom.client.KeyCodes;
import com.google.gwt.event.dom.client.KeyDownEvent;
import com.google.gwt.event.dom.client.KeyDownHandler;
import com.google.gwt.event.logical.shared.CloseEvent;
import com.google.gwt.event.logical.shared.CloseHandler;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.Window.ClosingEvent;
import com.google.gwt.user.client.Window.ClosingHandler;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.Grid;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.HasHorizontalAlignment;
import com.google.gwt.user.client.ui.HorizontalPanel;
import com.google.gwt.user.client.ui.Image;
import com.google.gwt.user.client.ui.PasswordTextBox;
import com.google.gwt.user.client.ui.RootPanel;
import com.google.gwt.user.client.ui.TextBox;
import com.google.gwt.user.client.ui.VerticalPanel;
import com.reveregroup.gwt.imagepreloader.FitImage;
import com.reveregroup.gwt.imagepreloader.ImageLoadEvent;
import com.reveregroup.gwt.imagepreloader.ImageLoadHandler;
import com.reveregroup.gwt.imagepreloader.ImagePreloader;

/**
 * Entry point classes define <code>onModuleLoad()</code>.
 */
public class SpectrumBrowser extends AbstractSpectrumBrowser implements EntryPoint {

	private Image waitImage;
	private String sessionToken;
	private boolean userLoggedIn;
	public static TextBox emailEntry;
	public static int MAP_WIDTH = 600;
	private static Button confirmButton;
	private String loginEmailAddress = null;
	private MyHandler handler = new MyHandler();
	public static PasswordTextBox passwordEntry;
	public static final String LOGOFF_LABEL = "Logoff";
	public static int SPEC_WIDTH, SPEC_HEIGHT, MAP_HEIGHT;
	public static VerticalPanel rootVerticalPanel, verticalPanel;
	private static Logger logger = Logger.getLogger("SpectrumBrowser");
	private Button sendButton, createButton, forgotButton, changeButton;
	private static HashMap<String,SensorInfoDisplay> sensorInformationTable = new HashMap<String,SensorInfoDisplay>();	
	private static SpectrumBrowserServiceAsync spectrumBrowserService = new SpectrumBrowserServiceAsyncImpl(getBaseUrl());
	private static String systemWarning = "You are accessing a U.S. Government information system, "
			+ "which includes: 1) this computer, 2) this computer network, 3) all computers  "
			+ "connected to this network, and 4) all devices and storage media attached to this "
			+ "network or to a computer on this network. You understand and consent to the following: "
			+ "you may access this information system for authorized use only; "
			+ "you have no reasonable expectation of privacy regarding any communication of "
			+ "data transiting or stored on this information system; at any time and for any "
			+ "lawful Government purpose, the Government may monitor, intercept, and search and "
			+ "seize any communication or data transiting or stored on this information system; "
			+ "and any communications or data transiting or stored on this information system may "
			+ "be disclosed or used for any lawful Government purpose.";
	static {
		GWT.setUncaughtExceptionHandler(new GWT.UncaughtExceptionHandler() {
			public void onUncaughtException(Throwable e) {
				logger.log(Level.SEVERE, "Uncaught Exception", e);
			}
		});
		Window.addWindowClosingHandler(new ClosingHandler() {
			@Override
			public void onWindowClosing(ClosingEvent event) {
				event.setMessage("Spectrum Browser: Close this window?");

			}
		});
		
		// Logoff on close.
		Window.addCloseHandler(new CloseHandler<Window>() {
			@Override
			public void onClose(CloseEvent<Window> event) {
				spectrumBrowserService.logOff(new SpectrumBrowserCallback<String>() {
					@Override
					public void onSuccess(String result) {
						Window.alert("Successfully logged off.");
						
					}

					@Override
					public void onFailure(Throwable throwable) {
						// TODO Auto-generated method stub

					}
				});
			}
		});
	}
	
	@Override
	public void onModuleLoad() {
		logger.fine("onModuleLoad");
		
		spectrumBrowserService.getScreenConfig(new SpectrumBrowserCallback<String>(){
			@Override
			public void onSuccess(String result) {
				try {
					logger.finer("Result: " + result);
					JSONValue jsonValue = JSONParser.parseLenient(result);
	
					SpectrumBrowser.MAP_WIDTH = (int) jsonValue.isObject().get(Defines.MAP_WIDTH).isNumber().doubleValue();
					
					SpectrumBrowser.MAP_HEIGHT = (int) jsonValue.isObject().get(Defines.MAP_HEIGHT).isNumber().doubleValue();
					
					SpectrumBrowser.SPEC_WIDTH = (int) jsonValue.isObject().get(Defines.SPEC_WIDTH).isNumber().doubleValue();
					
					SpectrumBrowser.SPEC_HEIGHT = (int) jsonValue.isObject().get(Defines.SPEC_HEIGHT).isNumber().doubleValue();
					Window.setTitle("MSOD:Login");
					for (int i = 0; i < RootPanel.get().getWidgetCount(); i++) {
						RootPanel.get().remove(i);
					}
					rootVerticalPanel = new VerticalPanel();
					rootVerticalPanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
					rootVerticalPanel.setStyleName("loginPanel");
					RootPanel.get().add(rootVerticalPanel);
					ImagePreloader.load(SpectrumBrowser.getIconsPath() + "ajax-loader.gif", new ImageLoadHandler() {

						@Override
						public void imageLoaded(ImageLoadEvent event) {
							waitImage.setUrl(event.getImageUrl());
						    waitImage.setVisible(false);
						}} );
					
					HorizontalPanel waitImagePanel = new HorizontalPanel();
					waitImagePanel.setHeight(40+ "px");
					waitImage = new FitImage();
				    waitImagePanel.add(waitImage);
				    rootVerticalPanel.add(waitImagePanel);

					
					HorizontalPanel hpanel = new HorizontalPanel();
					int height = 50;
					Image nistLogo = new Image( SpectrumBrowser.getIconsPath() + "nist-logo.png");
					nistLogo.setPixelSize((int)(215.0/95.0)*height, height);
					Image ntiaLogo = new Image(SpectrumBrowser.getIconsPath() +  "ntia-logo.png");
					ntiaLogo.setPixelSize(height, height);
					hpanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_LEFT);
					hpanel.add(nistLogo);
					HTML html = new HTML("<h2>CAC Measured Spectrum Occupancy Database (BETA)</h2>");
					hpanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
					hpanel.add(html);
					hpanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_RIGHT);
					hpanel.add(ntiaLogo);
					
					rootVerticalPanel.add(hpanel);
					verticalPanel = new VerticalPanel();
					verticalPanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
					verticalPanel.setStyleName("loginPanel");
					verticalPanel.setSpacing(20);
					rootVerticalPanel.add(verticalPanel);
					
					if (jsonValue.isObject().get(Defines.WARNING_TEXT) != null) {
						SpectrumBrowser.systemWarning = jsonValue.isObject().get(Defines.WARNING_TEXT).isString().stringValue();
					}
					
					if (systemWarning != null) {
						displayWarning();
					} else {
						draw();
					}
				} catch (Throwable th) {
					logger.log(Level.SEVERE, "Error Parsing JSON", th);
				}
			}

			@Override
			public void onFailure(Throwable throwable) {
				Window.alert("Error contacting server. Please try later");
			}
			
		});
	}
	public void showWaitImage() {
		waitImage.setVisible(true);
	}
	
	public void hideWaitImage() {
		waitImage.setVisible(false);
	}
	
	public void draw() {
		
		
		
		spectrumBrowserService
		.isAuthenticationRequired(new SpectrumBrowserCallback<String>() {

			@Override
			public void onSuccess(String result) {
				try {
					verticalPanel.clear();
					logger.finer("Result: " + result);
					JSONValue jsonValue = JSONParser.parseLenient(result);
					boolean isAuthenticationRequired = jsonValue.isObject().get("AuthenticationRequired").isBoolean().booleanValue();
					if (isAuthenticationRequired) {
						Grid grid = new Grid(2,2);
						
						grid.setText(0, 0, "Email Address");
						emailEntry = new TextBox();
						emailEntry.setWidth("250px");
						emailEntry.addKeyDownHandler(handler);	
						grid.setWidget(0, 1, emailEntry);
						
						grid.setText(1,0, "Password");
						passwordEntry = new PasswordTextBox();
						passwordEntry.setWidth("250px");
						passwordEntry.addKeyDownHandler(handler);
						grid.setWidget(1, 1, passwordEntry);
						
						grid.getCellFormatter().addStyleName(0, 0, "alignMagic");
						grid.getCellFormatter().addStyleName(1, 0, "alignMagic");
						
						verticalPanel.add(grid);	

						Grid buttonGrid = new Grid(1, 4);
						
						sendButton = new Button("Sign in");
						sendButton.addStyleName("sendButton");
						sendButton.addClickHandler(handler);
						buttonGrid.setWidget(0,0,sendButton);
						
						createButton = new Button("Request Account");
						createButton.addClickHandler(handler);
						buttonGrid.setWidget(0, 1, createButton);

						forgotButton = new Button("Reset Password");
						forgotButton.addClickHandler(handler);
						buttonGrid.setWidget(0, 2, forgotButton);

						changeButton = new Button("Change Password");
						changeButton.addClickHandler(handler);
						buttonGrid.setWidget(0, 3, changeButton);

						verticalPanel.add(buttonGrid);
					}else {
						sessionToken = jsonValue.isObject().get(Defines.SESSION_TOKEN).isString().stringValue();						
						setSessionToken(sessionToken);
						SpectrumBrowser.this.showWaitImage();
						new SpectrumBrowserShowDatasets(SpectrumBrowser.this, verticalPanel);
					}
				}catch (Throwable th) {
					logger.log(Level.SEVERE, "Error Parsing JSON", th);
					Window.alert("Error Communicating with server");
					onModuleLoad();
				}
			}

			@Override
			public void onFailure(Throwable throwable) {
				Window.alert("Error contacting server. Please try later");
			}
			
		});
	}
	
	private void displayWarning() {
		verticalPanel.clear();
		
		verticalPanel.add(new HTML(systemWarning));
		confirmButton = new Button("OK");
		verticalPanel.add(confirmButton);
		confirmButton.addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				draw();
			}});
	}
	
	private void loginHandler() {
		String emailAddress, password;
		emailAddress = password = "";
		
		emailAddress = emailEntry.getValue().trim();
		password = passwordEntry.getValue();			

		logger.finer("LogintoServer: " + emailAddress);
		if (emailAddress == null || emailAddress.length() == 0) {
			Window.alert("Email address is required");
			return;
		}
		if (password == null || password.length() == 0) {
			Window.alert("Password is required");
			return;
		}
		JSONObject jsonObject  = new JSONObject();
		jsonObject.put(Defines.ACCOUNT_EMAIL_ADDRESS, new JSONString(emailAddress));
		jsonObject.put(Defines.ACCOUNT_PASSWORD, new JSONString(password));
		jsonObject.put(Defines.ACCOUNT_PRIVILEGE, new JSONString(Defines.USER_PRIVILEGE));
		setLoginEmailAddress(emailAddress);

		getSpectrumBrowserService().authenticate(jsonObject.toString(),	new SpectrumBrowserCallback<String>() {
			@Override
			public void onFailure(Throwable errorTrace) {
				logger.log(Level.SEVERE,"Error sending request to the server", errorTrace);
				Window.alert("Error communicating with the server.");
			}

			@Override
			public void onSuccess(String result) {
				try{
					JSONValue jsonValue = JSONParser.parseStrict(result);
					JSONObject jsonObject = jsonValue.isObject();
					String status = jsonObject.get(Defines.STATUS).isString().stringValue();							
					String statusMessage = jsonObject.get(Defines.STATUS_MESSAGE).isString().stringValue();
					if (status.equals("OK")) {
						sessionToken = jsonObject.get(Defines.SESSION_ID).isString().stringValue();
						setSessionToken(sessionToken);
						setUserLoggedIn(true);
						SpectrumBrowser.this.showWaitImage();
						new SpectrumBrowserShowDatasets(SpectrumBrowser.this, verticalPanel);
					} 
					else {
						Window.alert(statusMessage);
					}
				} catch (Throwable ex) {
					Window.alert("Problem parsing json");
					logger.log(Level.SEVERE, " Problem parsing json",ex);

				}
			}
		});
	}
	
	private class MyHandler implements ClickHandler, KeyDownHandler {

		@Override
		public void onKeyDown(KeyDownEvent event) {
			if (event.getNativeKeyCode() == KeyCodes.KEY_ENTER) {
				loginHandler();
			}
		}

		@Override
		public void onClick(ClickEvent event) {

			if (sendButton == event.getSource()) {
				loginHandler();
			}

			if (createButton == event.getSource()) {
				new UserCreateAccount(verticalPanel,SpectrumBrowser.this).draw();
			}

			if (forgotButton == event.getSource()) {
				new UserForgotPassword(verticalPanel,SpectrumBrowser.this).draw();
			}
			
			if (changeButton == event.getSource()) {
				new UserChangePassword(verticalPanel,Defines.USER_PRIVILEGE, SpectrumBrowser.this).draw();
			}
		}

	}

	public void logoff() {
		spectrumBrowserService.logOff(new SpectrumBrowserCallback<String>() {
					@Override
					public void onFailure(Throwable caught) {
						SpectrumBrowser.clearSessionTokens();
						SpectrumBrowser.destroySessionToken();
						verticalPanel.clear();
						if (systemWarning != null) {
							displayWarning();
						} else {
							draw();
						}
					}

					@Override
					public void onSuccess(String result) {
						SpectrumBrowser.clearSessionTokens();
						SpectrumBrowser.destroySessionToken();
						verticalPanel.clear();
						if (systemWarning != null) {
							displayWarning();
						} else {
							draw();
						}
					}
				});
	}
	
	public SpectrumBrowserServiceAsync getSpectrumBrowserService() {
		return spectrumBrowserService;
	}

	@Override
	public boolean isUserLoggedIn() {
		return userLoggedIn;
	}
	
	public void displayError(String errorMessage) {
		Window.alert(errorMessage);
		if (this.isUserLoggedIn())
			logoff();
	}
	
	public static String getGeneratedDataPath(String sensorId) {
		SensorInfoDisplay si = sensorInformationTable.get(sensorId);
		if ( si == null) {
			logger.severe("getGeneratedDataPath: Null returned from sensorInformationTable for " + sensorId);
			return null;
		} else {
			return si.getBaseUrl() + "/generated/";
		}
	}

	public void setUserLoggedIn(boolean flag) {
		this.userLoggedIn = flag;
	}
	
	public static void addSensor(SensorInfoDisplay sensorInformation) {
		sensorInformationTable.put(sensorInformation.getId(),sensorInformation);
	}
	
	public static String getBaseUrl(String sensorId) {
		SensorInfoDisplay si = sensorInformationTable.get(sensorId);
		if ( si == null) {
			return null;
		} else {
			return si.getBaseUrl() + "/spectrumbrowser/";
		}
	}

	public static void clearSensorInformation() {
		logger.finer("clearSensorInformation");
		String sessionToken = getSessionToken();
		sensorInformationTable.clear();
		clearSessionTokens();
		setSessionToken(sessionToken);
	}

	public static String getSessionTokenForSensor(String sensorId) {
		String url = sensorInformationTable.get(sensorId).getBaseUrl();
		logger.finer("getSessionTokenForSensor: " + sensorId + " / " + url);
		return getSessionToken(url);
	}
	
	public static String getBaseUrlAuthority(String sensorId) {
		SensorInfoDisplay si = sensorInformationTable.get(sensorId);
		if ( si == null) {
			return null;
		} else {
			return si.getBaseUrl();
		}
	}

	public static void logoffAllSensors() {
		spectrumBrowserService.logOff(new SpectrumBrowserCallback<String> () {
			@Override
			public void onSuccess(String result) {
			}

			@Override
			public void onFailure(Throwable throwable) {
				logger.log(Level.SEVERE,"Problem logging off",throwable);
			}});
		for (String sensorId : SpectrumBrowser.sensorInformationTable.keySet())
			spectrumBrowserService.logOff(sensorId,new SpectrumBrowserCallback<String> () {

			@Override
			public void onSuccess(String result) {
			}

			@Override
			public void onFailure(Throwable throwable) {
				logger.log(Level.SEVERE,"Problem logging off",throwable);
				
			}});
	}

	public void setLoginEmailAddress(String emailAddress) {
		 this.loginEmailAddress = emailAddress;	
	}
	
	public String getLoginEmailAddress() {
		return this.loginEmailAddress;
	}




}
