import json
from fabric.api import sudo,local,env,execute,prompt,roles,put,settings,cd,run
from fabric.contrib.files import exists
import subprocess
import os
import time

env.sudo_user = 'root'

if os.environ.get('MSOD_DB_HOST') == None:
    print('Please set the environment variable MSOD_DB_HOST to the IP address where your DB Server is located.')
    os._exit(1)
if os.environ.get('MSOD_WEB_HOST') == None:
    print('Please set the environment variable MSOD_WEB_HOST to the IP address where your WEB Server is located.')
    os._exit(1)

env.roledefs = {
    'database' : {
        'hosts': [os.environ.get('MSOD_DB_HOST')],
    },
    'spectrumbrowser' : {
        'hosts': [os.environ.get('MSOD_WEB_HOST')]
    }
}

def deploy():
    aideAnswer = prompt('Setup Aide IDS after installation complete (y/n)?')
    amazonAnswer = prompt('Running on Amazon Web Services (y/n)?')
    execute(buildServer)
    if amazonAnswer =='yes' or amazonAnswer == 'y':
        execute(buildDatabaseAmazon)
    else:
        execute(buildDatabase)
    execute(firewallConfig)
    execute(configMSOD)
    if aideAnswer =='yes' or aideAnswer == 'y':
	print "This takes a while..."
    	execute(setupAide)
    execute(startMSOD)

@roles('spectrumbrowser')
def buildServer():
    ''' Set Needed Variables '''
    sbHome = getSbHome()
    localHome = getProjectHome()

    ''' Create Needed Directories '''
    sudo('mkdir -p ' + sbHome + ' /home/' + env.user + '/.msod/ /root/.msod/')
    sudo('mkdir -p ' + sbHome + '/flask/static/spectrumbrowser/generated/')
    sudo('mkdir -p ' + getSbHome() + '/certificates')

    ''' Create Users and Permissions '''
    with settings(warn_only=True):
        sudo('adduser --system spectrumbrowser')
	sudo('chown -R spectrumbrowser ' + sbHome)

    ''' Copy Needed Files '''
    put(localHome + '/devel/requirements/python_pip_requirements.txt', sbHome + '/python_pip_requirements.txt', use_sudo=True)
    put(localHome + '/devel/certificates/privkey.pem' , sbHome + '/certificates/privkey.pem',use_sudo = True )
    put(localHome + '/devel/certificates/cacert.pem' , sbHome + '/certificates/cacert.pem' , use_sudo = True)
    put(localHome + '/devel/certificates/dummy.crt', sbHome + '/certificates/dummy.crt', use_sudo = True)
    put(localHome + '/devel/requirements/install_stack.sh', sbHome + '/install_stack.sh', use_sudo=True)
    put(localHome + '/devel/requirements/redhat_stack.txt', sbHome + '/redhat_stack.txt', use_sudo=True)  
    put('MSODConfig.json.setup', '/root/.msod/MSODConfig.json', use_sudo=True)
    put('MSODConfig.json.setup', sbHome + '/MSODConfig.json', use_sudo=True)
    put('setup-config.py', sbHome + '/setup-config.py', use_sudo=True)
    put(localHome + '/Makefile', sbHome + '/Makefile', use_sudo=True)
    put('nginx.repo', '/etc/yum.repos.d/nginx.repo', use_sudo=True)
    put('Config.gburg.txt', sbHome + '/Config.txt', use_sudo=True) #TODO - customize initial configuration.

    ''' Zip Needed Services '''
    put('/tmp/flask.tar.gz', '/tmp/flask.tar.gz',use_sudo=True)
    put('/tmp/nginx.tar.gz', '/tmp/nginx.tar.gz',use_sudo=True)
    put('/tmp/services.tar.gz', '/tmp/services.tar.gz',use_sudo=True)
    put('/tmp/Python-2.7.6.tgz', '/tmp/Python-2.7.6.tgz',use_sudo=True)
    put('/tmp/distribute-0.6.35.tar.gz' , '/tmp/distribute-0.6.35.tar.gz',use_sudo=True)

    ''' Unzip Needed Services '''
    sudo('tar -xvzf /tmp/flask.tar.gz -C ' + sbHome)
    sudo('tar -xvzf /tmp/nginx.tar.gz -C ' + sbHome)
    sudo('tar -xvzf /tmp/services.tar.gz -C ' + sbHome)
    sudo('tar -xvzf /tmp/Python-2.7.6.tgz -C ' + '/opt')
    sudo('tar -xvzf /tmp/distribute-0.6.35.tar.gz -C ' + '/opt')


    ''' Install All Utilities '''
    DB_HOST = env.roledefs['database']['hosts'][0]
    WEB_HOST = env.roledefs['spectrumbrowser']['hosts'][0]

    # Note : This needs to be there on the web server before python can be built.
    sudo('yum groupinstall -y "Development tools"')
    sudo('yum install -y python-setuptools tk-devel gdbm-devel db4-devel libpcap-devel xz-devel')
    sudo('yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel')
    put('rpmforge.repo', '/etc/yum.repos.d/rpmforge.repo', use_sudo=True)
    sudo('rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt')
    sudo('yum install -y libffi-devel')
    sudo('rm /etc/yum.repos.d/rpmforge.repo')
    with settings(warn_only=True):
    	sudo('setsebool -P httpd_can_network_connect 1')

    ''' Install Python and Distribution Tools '''
    with cd('/opt/Python-2.7.6'):
        if exists('/usr/local/bin/python2.7'):
            run('echo ''python 2.7 found''')
        else:
	    sudo('yum -y install gcc')
            sudo("chown -R " + env.user + " /opt/Python-2.7.6")
            sudo('./configure')
            sudo('make altinstall')
            sudo('chown spectrumbrowser /usr/local/bin/python2.7')
            sudo('chgrp spectrumbrowser /usr/local/bin/python2.7')
	    sudo('yum -y erase gcc')

    with cd('/opt/distribute-0.6.35'):
        if exists('/usr/local/bin/pip'):
            run('echo ''pip  found''')
        else:
            sudo('chown -R ' + env.user + ' /opt/distribute-0.6.35')
            sudo('/usr/local/bin/python2.7 setup.py  install')
            sudo('/usr/local/bin/easy_install-2.7 pip')

    with cd(sbHome):
        sudo('bash install_stack.sh')
        sudo('make REPO_HOME=' + sbHome + ' install')

    ''' Update Users and Permission '''
    sudo('chown -R spectrumbrowser ' + sbHome)
    sudo('chgrp -R spectrumbrowser ' + sbHome)

    ''' Install All Services '''
    sudo('chkconfig --add memcached')
    sudo('chkconfig --add msod')
    sudo('chkconfig --add nginx')
    sudo('chkconfig --level 3 memcached on')
    sudo('chkconfig --level 3 msod on')
    sudo('chkconfig --level 3 nginx on')
    sudo('chkconfig cups off')
    sudo('service cups stop')

@roles('database')
def buildDatabase():
    ''' Set Needed Variables '''
    sbHome = getSbHome()
    localHome = getProjectHome()

    ''' Create Needed Directories '''
    sudo('mkdir -p ' + sbHome + ' /spectrumdb /etc/msod')

    ''' Create Users and Permissions '''
    with settings(warn_only=True):
        sudo('adduser --system spectrumbrowser')
	sudo('chown -R spectrumbrowser ' + sbHome)

    ''' Copy Needed Files '''
    put('MSODConfig.json.setup', '/etc/msod/MSODConfig.json',use_sudo=True)

    answer = prompt('Install Enterprise Mongodb (y/n)?')
    if answer=='yes' or answer == 'y':
        put('mongodb-enterprise.repo', '/etc/yum.repos.d/mongodb-enterprise-2.6.repo', use_sudo=True)
    else:
        put('mongodb-org-2.6.repo', '/etc/yum.repos.d/mongodb-org-2.6.repo', use_sudo=True)

    ''' Zip Needed Services '''
    put('/tmp/services.tar.gz', '/tmp/services.tar.gz',use_sudo=True)
    put('/tmp/Python-2.7.6.tgz', '/tmp/Python-2.7.6.tgz',use_sudo=True)
    put('/tmp/distribute-0.6.35.tar.gz' , '/tmp/distribute-0.6.35.tar.gz',use_sudo=True)

    ''' Unzip Needed Services '''
    sudo('tar -xvzf /tmp/services.tar.gz -C ' + sbHome)
    sudo('tar -xvzf /tmp/Python-2.7.6.tgz -C ' + '/opt')
    sudo('tar -xvzf /tmp/distribute-0.6.35.tar.gz -C ' + '/opt')

    ''' Firewall Rules and Permissions '''
    DB_HOST = env.roledefs['database']['hosts'][0]
    WEB_HOST = env.roledefs['spectrumbrowser']['hosts'][0]
    if  DB_HOST != WEB_HOST:
        sudo('iptables -P INPUT ACCEPT')
        sudo('iptables -F')
        sudo('iptables -A INPUT -i lo -j ACCEPT')
        sudo('iptables -A INPUT -p tcp --dport 22 -j ACCEPT')
        sudo('iptables -A INPUT -s ' + WEB_HOST + ' -p tcp --dport 27017 -j ACCEPT')
        sudo('iptables -A INPUT -m state --state NEW,ESTABLISHED -j ACCEPT')
        sudo('iptables -A OUTPUT -d ' + WEB_HOST + ' -p tcp --sport 27017 -j ACCEPT')
        sudo('iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT')
        sudo('service iptables save')
        sudo('service iptables restart')

        ''' Install All Utilities '''
        with settings(warn_only=True):
            sudo('yum groupinstall -y "Development tools"')
            sudo('yum install -y python-setuptools tk-devel gdbm-devel db4-devel libpcap-devel xz-devel policycoreutils-python lsb')
            sudo('yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel')
	    if answer == 'y' or answer == 'yes':
	    	sudo('yum install mongodb-enterprise')
	    else:
		sudo('yum install mongodb-org')
	    sudo('semanage port -a -t mongod_port_t -p tcp 27017')

        sudo('install -m 755 ' + sbHome + '/services/dbmonitor/ResourceMonitor.py /usr/bin/dbmonitor')
        sudo('install -m 755 ' + sbHome + '/services/dbmonitor/dbmonitoring-init /etc/init.d/dbmonitor')

        ''' Install Python and Distribution Tools '''
        with cd('/opt/Python-2.7.6'):
            if exists('/usr/local/bin/python2.7'):
                run('echo ''python 2.7 found''')
            else:
                sudo("chown -R " + env.user + " /opt/Python-2.7.6")
                sudo('./configure')
                sudo('make altinstall')
                sudo('chown spectrumbrowser /usr/local/bin/python2.7')
        with cd('/opt/distribute-0.6.35'):
            if exists('/usr/local/bin/pip'):
                run('echo ''pip  found''')
            else:
                sudo('chown -R ' + env.user + ' /opt/distribute-0.6.35')
                sudo('/usr/local/bin/python2.7 setup.py  install')
        sudo('/usr/local/bin/easy_install-2.7 pymongo')
        sudo('/usr/local/bin/easy_install-2.7 python-daemon')
    else:
	sudo('yum install mongodb-org')
	sudo('chown -R spectrumbrowser /opt/SpectrumBrowser')


    ''' Copy Needed Files '''
    put('mongod.conf','/etc/mongod.conf',use_sudo=True)

    ''' Update Users and Permission '''
    sudo('chown mongod /etc/mongod.conf')
    sudo('chgrp mongod /etc/mongod.conf')
    sudo('chown mongod /spectrumdb')
    sudo('chgrp mongod /spectrumdb')

    ''' Install All Services '''
    sudo('chkconfig --add mongod')
    sudo('chkconfig dbmonitor off')
    sudo('chkconfig mongod --levels 3')
    sudo('chkconfig dbmonitor --levels 3 on')
    sudo('service mongod restart')
    time.sleep(10)
    sudo('service dbmonitor restart')

def withdraw():
    execute(tearDownServer)
    execute(tearDownDatabase)

@roles('spectrumbrowser')
def tearDownServer():
    ''' Set Needed Variables '''
    sbHome = getSbHome()

    ''' Copy Needed Files '''
    put(getProjectHome() + '/devel/requirements/redhat_unstack.txt', sbHome + '/redhat_unstack.txt', use_sudo=True)
    put(getProjectHome() + '/devel/requirements/uninstall_stack.sh', sbHome + '/uninstall_stack.sh', use_sudo=True)

    ''' Stop All Running Services '''
    sudo('service msod stop')
    sudo('service memcached stop')
    sudo('service nginx stop')

    ''' Remove All Services '''
    sudo('chkconfig --del memcached')
    sudo('chkconfig --del msod')
    sudo('chkconfig --del nginx')

    ''' Uninstall All Installed Utilities '''
    with settings(warn_only=True):
    	with cd(sbHome):
    	    sudo('bash uninstall_stack.sh')
    	    sudo('make REPO_HOME=' + sbHome + ' uninstall')
	    sudo('yum remove -y python-setuptools readline-devel tk-devel gdbm-devel db4-devel libpcap-devel')
            sudo('yum remove -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel xz-devel')

    ''' Remove SPECTRUM_BROWSER_HOME Directory '''
    with settings(warn_only=True):
        sudo('rm -r ' + sbHome + ' /home/' + env.user + '/.msod/ /root/.msod/')
	sudo('userdel -r spectrumbrowser')

    ''' Clean Remaining Files '''
    sudo('rm -rf  /var/log/flask')
    sudo('rm -f /var/log/nginx/* /var/log/gunicorn/* /var/log/admin.log /var/log/federation.log /var/log/servicecontrol.log')
    sudo('rm -f /var/log/occupancy.log /var/log/streaming.log /var/log/monitoring.log /var/log/spectrumdb.log')

@roles('database')
def tearDownDatabase():
    ''' Set Needed Variables '''
    sbHome = getSbHome()

    ''' Stop All Running Services '''
    sudo('service dbmonitor stop')
    sudo('service mongod stop')

    ''' Remove All Services '''
    sudo('chkconfig --del dbmonitor')
    sudo('chkconfig --del mongod')

    ''' Uninstall All Installed Utilities '''
    with settings(warn_only=True):
	sudo('rm /usr/bin/dbmonitor')
    	sudo('rm /etc/init.d/dbmonitor')
	sudo('rm /etc/mongod.conf')
	sudo('yum remove -y python-setuptools readline-devel tk-devel gdbm-devel db4-devel libpcap-devel')
        sudo('yum remove -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel xz-devel policycoreutils-python')
        sudo('yum erase -y $(rpm -qa | grep mongodb-enterprise)')
	sudo('/usr/local/bin/pip uninstall -y pymongo')
	sudo('/usr/local/bin/pip uninstall -y python-daemon')

    ''' Remove SPECTRUM_BROWSER_HOME Directory '''
    with settings(warn_only=True):
        sudo('rm -r ' + sbHome + ' /spectrumdb /etc/msod')
	sudo('userdel -r spectrumbrowser') 
	sudo('userdel -r mongod') 

    ''' Clean Remaining Files '''
    sudo('rm -rf  /var/log/mongodb')
    sudo('rm -f /var/log/dbmonitoring.log')

@roles("spectrumbrowser")
def setupAide():
    put(getProjectHome() + '/aide/aide.conf', "/etc/aide.conf",use_sudo=True)
    put(getProjectHome() + '/aide/runaide.sh', "/opt/SpectrumBrowser/runaide.sh",use_sudo=True)
    put(getProjectHome() + '/aide/swaks', "/opt/SpectrumBrowser/swaks",use_sudo=True)
    sudo("chmod root /etc/aide.conf")
    sudo("chmod 0600 /etc/aide.conf")
    sudo("chmod u+x /opt/SpectrumBrowser/swaks")
    sudo("chown root /opt/SpectrumBrowser/swaks")
    sudo("chmod u+x /opt/SpectrumBrowser/runaide.sh")
    sudo("chown root /opt/SpectrumBrowser/runaide.sh")
    sudo("aide --init")
    sudo("mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz")

def pack():
    local('cp ' + getProjectHome() + '/devel/certificates/cacert.pem ' + getProjectHome() + '/nginx/')
    local('cp ' + getProjectHome() + '/devel/certificates/privkey.pem '  + getProjectHome() + '/nginx/')
    local('tar -cvzf /tmp/flask.tar.gz -C ' + getProjectHome() + ' flask')
    local('tar -cvzf /tmp/nginx.tar.gz -C ' + getProjectHome() + ' nginx')
    local('tar -cvzf /tmp/services.tar.gz -C ' + getProjectHome() + ' services')

    if not os.path.exists('/tmp/Python-2.7.6.tgz'):
        local('wget --no-check-certificate https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz --directory-prefix=/tmp')
    if not os.path.exists('/tmp/distribute-0.6.35.tar.gz'):
        local ('wget --no-check-certificate http://pypi.python.org/packages/source/d/distribute/distribute-0.6.35.tar.gz --directory-prefix=/tmp')

def getSbHome():
    return json.load(open(getProjectHome() + '/MSODConfig.json'))['SPECTRUM_BROWSER_HOME']

def getProjectHome():
    command = ['git', 'rev-parse', '--show-toplevel']
    p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    return out.strip()


@roles('spectrumbrowser')
def firewallConfig():
    ''' Firewall Rules and Permissions '''
    sudo('iptables -P INPUT ACCEPT')
    sudo('iptables -F')
    sudo('iptables -A INPUT -i lo -j ACCEPT')
    sudo('iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT')
    sudo('iptables -A INPUT -p tcp --dport 22 -j ACCEPT')
    sudo('iptables -A INPUT -p tcp --dport 443 -j ACCEPT')
    sudo('iptables -A INPUT -p tcp --dport 8443 -j ACCEPT')
    sudo('iptables -A INPUT -p tcp --dport 9000 -j ACCEPT')
    sudo('iptables -A INPUT -p tcp --dport 9001 -j ACCEPT')
    sudo('iptables -P INPUT DROP')
    sudo('iptables -P FORWARD DROP')
    sudo('iptables -P OUTPUT ACCEPT')
    sudo('iptables -L -v')
    sudo('service iptables save')
    sudo('service iptables restart')

@roles('spectrumbrowser')
def startMSOD():
    ''' Set SELinux: Enforcing --> Permissive '''
    # Note that this returns 1 if successful so we need
    # warn_only = True
    sudo('chown -R spectrumbrowser /opt/SpectrumBrowser/services')
    sudo('chgrp -R spectrumbrowser /opt/SpectrumBrowser/services')
    sudo('chown spectrumbrowser /etc/msod/MSODConfig.json')
    with settings(warn_only=True):
    	sudo('setenforce 0')
    sudo('service nginx restart')
    sudo('service msod stop')
    sudo('service memcached restart')
    time.sleep(5)
    sudo('service msod restart')
    sudo('service msod status')
    ''' Set SELinux: Permissive --> Enforcing '''
    with settings(warn_only=True):
    	sudo('setenforce 1')


@roles('spectrumbrowser')
def configMSOD():
    sudo('PYTHONPATH=/opt/SpectrumBrowser/services/common:/usr/local/lib/python2.7/site-packages /usr/local/bin/python2.7 ' \
    + getSbHome() + '/setup-config.py -host ' + os.environ.get('MSOD_WEB_HOST') + ' -f ' + getSbHome() + '/Config.txt')

@roles('spectrumbrowser')
def deployTests(testDataLocation):
    # Invoke this using 
    # fab deployTests:/path/to/test/data
    # /path/to/test/data is where you put the test data files (see blow)
    local('tar -cvzf /tmp/unit-tests.tar.gz -C ' + getProjectHome() + ' unit-tests')
    put('/tmp/unit-tests.tar.gz', '/tmp/unit-tests.tar.gz',use_sudo=True)
    if testDataLocation == None:
        raise Exception('Need test data')
    sudo('mkdir -p /tests/test-data')
    sudo('tar -xvzf /tmp/unit-tests.tar.gz -C /tests')
    with cd('/tests'):
        for f in ['LTE_UL_DL_bc17_bc13_ts109_p1.dat','LTE_UL_DL_bc17_bc13_ts109_p2.dat','LTE_UL_DL_bc17_bc13_ts109_p3.dat','v14FS0714_173_24243.dat'] :
            put(testDataLocation + '/' + f, '/tests/test-data/'+f,use_sudo = True)

@roles('spectrumbrowser')
def setupTestData():
    with cd('/tests'):
        sudo('PYTHONPATH=/opt/SpectrumBrowser/services/common:/tests/unit-tests:/usr/local/lib/python2.7/site-packages/ /usr/local/bin/python2.7 /tests/unit-tests/setup_test_sensors.py -t /tests/test-data -p /tests/unit-tests')

def checkStatus():
    execute(checkMsodStatus)
    execute(checkDbStatus)

@roles('spectrumbrowser')
def checkMsodStatus():
    sudo('service memcached status')
    sudo('service msod status')

@roles('database')
def checkDbStatus():
    sudo('service mongod status')
    sudo('service dbmonitor status')

'''Amazon Server Host Functions'''
@roles('database')
def buildDatabaseAmazon(): #build process for db server
    sbHome = getSbHome()

    with settings(warn_only=True):
        sudo('rm -f /var/log/dbmonitoring.log')

    sudo('install -m 755 ' + sbHome + '/services/dbmonitor/dbmonitoring-bin /usr/bin/dbmonitor')
    sudo('install -m 755 ' + sbHome + '/services/dbmonitor/dbmonitoring-init /etc/init.d/dbmonitor')

    put('mongodb-org-2.6.repo', '/etc/yum.repos.d/mongodb-org-2.6.repo', use_sudo=True)
    sudo('yum -y install mongodb-org')
    sudo('service mongod stop')
    put('mongod.conf','/etc/mongod.conf',use_sudo=True)
    sudo('chown mongod /etc/mongod.conf')
    sudo('chgrp mongod /etc/mongod.conf')
    #NOTE: SPECIFIC to amazon deployment.
    answer = prompt('Create filesystem for DB and logging (y/n)?')
    if answer == 'y' or answer == 'yes':
        with settings(warn_only=True):
            sudo('umount /spectrumdb')
        # These settings work for amazon. Customize this.
        sudo('mkfs -t ext4 /dev/xvdf')
        sudo('mkfs -t ext4 /dev/xvdj')
	sudo('mkdir /var/log/mongodb')
	sudo('mkdir /var/log/nginx')
	sudo('chown mongod /var/log/mongdb')
	sudo('chgrp mongod /var/log/mongodb')
    #Put all the ebs data on /spectrumdb
    if exists('/spectrumdb'):
        run('echo ''Found /spectrumdb''')
    else:
        sudo('mkdir /spectrumdb')
    sudo('chown  mongod /spectrumdb')
    sudo('chgrp  mongod /spectrumdb')

    with settings(warn_only=True):
        sudo('mount /dev/xvdf /spectrumdb')

    with settings(warn_only=True):
	sudo('mount /dev/xvdj /var/log')

    sudo('chkconfig --del mongod')
    sudo('chkconfig --add mongod')
    sudo('chkconfig --level 3 mongod on')
    sudo('chkconfig --del dbmonitor')
    sudo('chkconfig --add dbmonitor')
    sudo('chkconfig --level 3 dbmonitor on')
    sudo('service mongod restart')
    time.sleep(10)
    sudo('service dbmonitor restart')

