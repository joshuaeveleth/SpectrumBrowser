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
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
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
import gov.nist.spectrumbrowser.common.SpectrumBrowserCallback;
import gov.nist.spectrumbrowser.common.SpectrumBrowserScreen;

public class InboundPeers extends AbstractSpectrumBrowserWidget implements
		SpectrumBrowserCallback<String>, SpectrumBrowserScreen {

	private Admin admin;
	private JSONArray peers;
	private static Logger logger = Logger.getLogger("SpectrumBrowser");
	private Grid grid;
	private boolean redraw;
	
	private class DeleteClickHandler implements ClickHandler {
		String peerId;

		public DeleteClickHandler( String peerId) {
			this.peerId = peerId;
		}
		
		@Override
		public void onClick(ClickEvent event) {
			redraw = true;
			try {
				Admin.getAdminService().deleteInboundPeer(peerId,InboundPeers.this);
			} catch ( Throwable th) {
				logger.log(Level.SEVERE, "Error communicating with server",th);
				Window.alert("error communicating with server");
				admin.logoff();
			}
		}}

	public InboundPeers(Admin admin) {
		try {
			this.admin = admin;
			logger.log(Level.FINER, "InboundPeers: InboundPeers");
			Admin.getAdminService().getInboundPeers(this);
		} catch (Throwable th) {
			Window.alert("Problem contacting server");
			logger.log(Level.SEVERE,"Problem contacting server", th);
			admin.logoff();
		}
	}

	@Override
	public void draw() {
		verticalPanel.clear();
		HTML html = new HTML("<h3>Inbound Peer Identites</h3>");
		HTML helpText = new HTML("<p>Specifes the identity of federated "
				+ "peers that are allowed to send data to this server instance</p>");
		logger.log(Level.FINER, "InboundPeers:draw()");
		if (peers == null) {
			return;
		}
		int rows = peers.size();
		verticalPanel.add(html);
		verticalPanel.add(helpText);
		grid = new Grid(rows+1,4);
		grid.setText(0, 0, "Peer ID");
		grid.setText(0, 1, "Peer Key");
		grid.setText(0, 2, "Comment");
		grid.setText(0, 3, "Delete");
		grid.setBorderWidth(2);
		grid.setCellPadding(2);
		grid.setCellPadding(2);
		for (int i = 1; i < rows+1; i++) {
			JSONObject peer = peers.get(i-1).isObject();
			grid.setText(i, 0, peer.get("PeerId").isString().stringValue());
			grid.setText(i, 1, peer.get("key").isString().stringValue());
			if ( peer.get("comment") != null) {
				TextBox commentBox = new TextBox();
				commentBox.setText(peer.get("comment").isString().stringValue());
				grid.setWidget(i, 2, commentBox);
				commentBox.setEnabled(false);
			}
			Button delete = new Button("Delete");
			grid.setWidget(i, 3, delete);
			delete.addClickHandler( new DeleteClickHandler(peer.get("PeerId").isString().stringValue()));
		}
		
		for (int i = 0; i < grid.getColumnCount(); i++) {
			grid.getCellFormatter().setStyleName(0, i, "textLabelStyle");
		}
		
		
		for (int i = 0; i < grid.getRowCount(); i++) {
			for (int j = 0; j < grid.getColumnCount(); j++) {
				grid.getCellFormatter().setHorizontalAlignment(i, j,
						HasHorizontalAlignment.ALIGN_CENTER);
				grid.getCellFormatter().setVerticalAlignment(i, j,
						HasVerticalAlignment.ALIGN_MIDDLE);
			}
		}
		verticalPanel.add(grid);
		HorizontalPanel buttonPanel = new HorizontalPanel();
		Button addPeerButton = new Button ("Add");
		addPeerButton.addClickHandler(new ClickHandler() {
			@Override
			public void onClick(ClickEvent event) {
				redraw = true;
				new AddInboundPeer(admin, InboundPeers.this,verticalPanel).draw();
			}});
		buttonPanel.add(addPeerButton);
		Button logoffButton = new Button("Log Off");
		
		logoffButton.addClickHandler(new ClickHandler() {

			@Override
			public void onClick(ClickEvent event) {
				admin.logoff();
			}});
		buttonPanel.add(logoffButton);
		verticalPanel.add(buttonPanel);
	
	}

	@Override
	public String getLabel() {
		return null;
	}

	@Override
	public String getEndLabel() {
		return "Inbound Peers";
	}

	@Override
	public void onSuccess(String result) {
		try {
			JSONValue jsonValue = JSONParser.parseLenient(result);
			String status = jsonValue.isObject().get("status").isString().stringValue();
			if (! status.equals("OK")) {
				String errorMessage = jsonValue.isObject().get("ErrorMessage").isString().stringValue();
				Window.alert("Error in adding peer " + errorMessage);
				return;
			}
			peers = jsonValue.isObject().get("inboundPeers").isArray();	
			logger.finer("Returned " + peers.size());
			if (redraw) {
				this.draw();
			}
		} catch (Throwable th) {
			Window.alert("Error parsing returned JSON");
			logger.log(Level.SEVERE, "Problem parsing JSON", th);
		}
	}

	@Override
	public void onFailure(Throwable throwable) {
		Window.alert("Error communicating with server");
		logger.log(Level.SEVERE, "Error communicating with server", throwable);
		admin.logoff();
	}

}
