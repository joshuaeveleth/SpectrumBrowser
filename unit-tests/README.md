<h2>Unit Tests</h2>

<h3>Setup for local development and testing</h3>
I will assume you are familiar with using a unix shell. Feel free to update the instructions.

Copy this MSODConfig.json file to $HOME/.mosod to modify your own configuration.

Start the mongo database server
(wait till it initializes and announces that it is ready for accepting connections)

    sh start-db.sh 

Populate the DB with test data (I am using the LTE data as an example for test purposes)
TEST_DATA_LOCATION is the directory where you have put the test data.
Put the following files in $TEST_DATA_LOCATION:

     FS0714_173_7236.dat  
     LTE_UL_DL_bc17_bc13_ts109_p1.dat  
     LTE_UL_DL_bc17_bc13_ts109_p2.dat  
     LTE_UL_DL_bc17_bc13_ts109_p3.dat
     LTE_UL_bc17_ts109_stream_30m.dat

These files are not on github (too big). Ask mranga@nist.gov for data files when you are ready for this step.
Now run a script to load up the test data:

   python setup-test-sensors.py -t $TEST_DATA_LOCATION

This will run for a while ( about 5 minutes)

To test the server, you can use provided scripts (easier than starting services for development purposes), All scripts are in the scripts directory.
First start the required processes.

   bash start-msod.sh

Configure the system for the first time:

    Point your browser at http://localhost:8001/admin
    The default admin user name is admin@nist.gov password is Administrator12!

Restart the system after the first configuration.

    bash scripts/restart-msod.sh

Configure the system  and restart:

   point your browser at http://localhost:8001/admin

Browse the data

   point your browser at http://localhost:8000/spectrumbrowser

<h3> Stopping the system</h3>

To stop the database

   bash scripts/stop-db.sh

To stop flask

   bash scripts/stop-msod.sh


   
<h3>Deployment of test cases on a remote host</h3>

From the devel/deploy directory

    fab deployTests:$TEST_DATA_LOCATION -u user-name
    
(Note: See the devel/deploy/README.md for details).
    
Deploys the test data and test cases on your remote host.

</h3>Unit Tests</h3>

Description of unit test scripts goes here.
