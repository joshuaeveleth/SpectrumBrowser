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
import gov.nist.spectrumbrowser.common.SpectrumBrowserScreen;

import java.util.logging.Level;
import java.util.logging.Logger;

import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Button;
import com.google.gwt.user.client.ui.Grid;
import com.google.gwt.user.client.ui.HTML;
import com.google.gwt.user.client.ui.HasHorizontalAlignment;
import com.google.gwt.user.client.ui.HorizontalPanel;
import com.google.gwt.user.client.ui.Image;
import com.google.gwt.user.client.ui.PasswordTextBox;
import com.google.gwt.user.client.ui.PopupPanel;
import com.google.gwt.user.client.ui.RootPanel;
import com.google.gwt.user.client.ui.TextBox;
import com.google.gwt.user.client.ui.VerticalPanel;


public class LoginScreen implements SpectrumBrowserScreen {
	VerticalPanel verticalPanel;
	static Logger logger = Logger.getLogger("SpectrumBrowser");
	PasswordTextBox passwordEntry;
	TextBox emailEntry;
	PopupPanel popupPanel = new PopupPanel();
	String sessionToken;
	private String LABEL = "Login >>";
	private String END_LABEL = "Login";

	/**
	 * Create a remote service proxy to talk to the server-side Greeting
	 * service.
	 */
	private SpectrumBrowser spectrumBrowser;

	
	
	class SendNamePasswordToServer implements ClickHandler {

		@Override
		public void onClick(ClickEvent clickEvent) {
			String password = "";
			String emailAddress = "";
			try {
				password = passwordEntry.getValue();
				emailAddress = emailEntry.getValue().trim();					
			}
			catch (Throwable th) {
				//not a problem, since we will check for null's below.
			}			
			
			logger.finer("SendNamePasswordToServer: " + emailAddress);
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
			spectrumBrowser.setLoginEmailAddress(emailAddress);


			getSpectrumBrowserService().authenticate(jsonObject.toString(),
					new SpectrumBrowserCallback<String>() {

						@Override
						public void onFailure(Throwable errorTrace) {
							logger.log(Level.SEVERE,
									"Error sending request to the server",
									errorTrace);
							Window.alert("Error communicating with the server.");

						}

						@Override
						public void onSuccess(String result) {
							try{
								JSONValue jsonValue = JSONParser.parseStrict(result);
								JSONObject jsonObject = jsonValue.isObject();
								String status = jsonObject.get(Defines.STATUS).isString().stringValue();							
								if (status.equals("OK")) {
									sessionToken = jsonObject.get(Defines.SESSION_ID).isString().stringValue();
									SpectrumBrowser.setSessionToken(sessionToken);
									spectrumBrowser.setUserLoggedIn(true);
									spectrumBrowser.showWaitImage();
									new SpectrumBrowserShowDatasets(spectrumBrowser, verticalPanel);
								} 
								else {
									String statusMessage = jsonObject.get(Defines.STATUS_MESSAGE).isString().stringValue();
									Window.alert(statusMessage);
								}
							} catch (Throwable ex) {
								Window.alert("Problem parsing json");
								logger.log(Level.SEVERE, " Problem parsing json",ex);
								
							}
						}
					});

		}

	}

	public String getLabel() {
		return LABEL;
	}

	public String getEndLabel() {
		return END_LABEL;
	}

	/**
	 * Display the error message and put up the login screen again.
	 * 
	 * @param errorMessage
	 */
	public void displayError(String errorMessage) {
		Window.alert(errorMessage);
		// logoff();

	}

	SpectrumBrowserServiceAsync getSpectrumBrowserService() {
		return spectrumBrowser.getSpectrumBrowserService();
	}



	/**
	 * This is the entry point method.
	 */
	public void draw() {
		verticalPanel.clear();
		logger.log(Level.INFO, "Base URL " + SpectrumBrowser.getBaseUrl());
		verticalPanel
				.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
		verticalPanel.setStyleName("loginPanel");
		verticalPanel.setSpacing(20);
		//HTML headingText = new HTML("<H1>" + HEADING_TEXT + "<H1>");
		//verticalPanel.add(headingText);
		
		Grid grid = new Grid(2,2);
		grid.setText(0, 0, "Email Address");
		emailEntry = new TextBox();
		emailEntry.setWidth("250px");
		emailEntry.setFocus(true);
		grid.setWidget(0, 1, emailEntry);
		grid.setText(1,0, "Password");
		passwordEntry = new PasswordTextBox();
		grid.setWidget(1, 1, passwordEntry);
		verticalPanel.add(grid);	

		// Add the nameField and sendButton to the RootPanel
		// Use RootPanel.get() to get the entire body element


		Grid buttonGrid = new Grid(1, 4);
		Button sendButton = new Button("Sign in");
		// We can add style names to widgets
		verticalPanel
				.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
		sendButton.addStyleName("sendButton");
		sendButton.addClickHandler(new SendNamePasswordToServer());
		buttonGrid.setWidget(0,0,sendButton);
		Button createAccount = new Button("Request Account");
		createAccount.addClickHandler(new ClickHandler() {

			@Override
			public void onClick(ClickEvent event) {
				new UserCreateAccount(verticalPanel,LoginScreen.this.spectrumBrowser).draw();
			}
		});

		buttonGrid.setWidget(0, 1, createAccount);

		Button forgotPasswordButton = new Button("Reset Password");
		forgotPasswordButton.addClickHandler(new ClickHandler() {

			@Override
			public void onClick(ClickEvent event) {
				new UserForgotPassword(verticalPanel,LoginScreen.this.spectrumBrowser).draw();
			}
		});
		buttonGrid.setWidget(0, 2, forgotPasswordButton);

		Button changePasswordButton = new Button("Change Password");
		changePasswordButton.addClickHandler(new ClickHandler() {

			@Override
			public void onClick(ClickEvent event) {
				new UserChangePassword(verticalPanel,Defines.USER_PRIVILEGE, LoginScreen.this.spectrumBrowser).draw();
			}
		});
		buttonGrid.setWidget(0, 3, changePasswordButton);

		verticalPanel.add(buttonGrid);
	}

	public void logoff() {
		SpectrumBrowser.destroySessionToken();
		getSpectrumBrowserService().logOff(
				new SpectrumBrowserCallback<String>() {

					@Override
					public void onFailure(Throwable caught) {
						draw();
					}

					@Override
					public void onSuccess(String result) { 
						draw();
					}
				});
	}

	public LoginScreen(SpectrumBrowser spectrumBrowser) {
		verticalPanel = new VerticalPanel();
		RootPanel rootPanel = RootPanel.get();
		VerticalPanel rootVerticalPanel = new VerticalPanel();
		rootPanel.add(rootVerticalPanel);
		rootVerticalPanel.setHorizontalAlignment(HasHorizontalAlignment.ALIGN_CENTER);
		rootVerticalPanel.setWidth(Window.getClientWidth() + "px");		
		
		HorizontalPanel hpanel = new HorizontalPanel();
		int height = 50;
		hpanel.setWidth(SpectrumBrowser.MAP_WIDTH  + "px");
		Image nistLogo = new Image( SpectrumBrowser.getIconsPath() + "nist-logo.png");
		nistLogo.setPixelSize((int)(215.0/95.0*height), height);
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
		
		rootVerticalPanel.add(verticalPanel);
		this.spectrumBrowser = spectrumBrowser;
	}

}
