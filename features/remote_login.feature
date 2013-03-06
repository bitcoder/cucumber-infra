Feature: Remote Login
In order to execute remote commands
As a remote user
I want to be able to connect to a remote host

Background: 
	Given a redhat system
	Given a ssh connection to "localhost", using "root" and "123qwe"

Scenario: SSH login
	When I connect
	Then I should be able to execute commands

Scenario: SSH command execution
	When I connect
	And I run "uname -n"
	Then the return code should be 0
	Then I should see "redhat5-x86-64" 

Scenario: SSH RPM query package existence
	When I connect
	And I query for package "kernel"
	Then the package "kernel" should exist
	Then the package "kernel" version should be "2.6.18"

Scenario: SSH RPM query package existence
	When I connect
	And I query for package "kernel"
	Then the package "kernel" should exist
	Then the package "kernel" version should be "2.6.18"
	And the package "httpd" should be running



Scenario: service exists
	When I connect
	And I query for package "httpd"
	Then the package "httpd" should exist
	Then the package "httpd2" should not exist
	And the service "httpd" exists

Scenario: service start
	When I connect
	And the service "httpd" is started
	Then the service "httpd" should be running

Scenario: service stop
	When I connect
	And the service "httpd" is stopped
	Then the service "httpd" should not be running

Scenario: service reload
	When I connect
	And the service "httpd" is started
	And the service "httpd" is reloaded
	Then the service "httpd" should be running



Scenario: exists in repository
	When I connect
	Then the package "httpd" is available
	And the package "httpd" most recent version should be "2.2.3-76.el5_9"

Scenario: repository installed
	When I connect
	Then the repository "epel" should be installed

Scenario: repository enabled
	When I connect
	Then the repository "ext-generic" should be enabled

Scenario: repository disabled
	When I connect
	Then the repository "epel" should be disabled

Scenario: sw found due to repository enabled
	When I connect
	When the repository "epel" is enabled
	Then the package "clamav" is available

Scenario: sw not found due to repository disabled
	When I connect
	When the repository "epel" is disabled
	Then the package "clamav" is not available

