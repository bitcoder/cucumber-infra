require 'net/ssh'
require 'rspec'
#require 'rspec/spec/matchers'


Given /^a redhat system$/ do
  @SYSTEM_TYPE=:redhat
end

Given /^a ssh connection to "(\w+)", using "(\w+)" and "(\w+)"$/ do |host,username,password|
  @host=host
  @username=username
  @password=password
end

When /^I connect$/ do
  @ssh=Net::SSH.start(@host, @username, :password => @password)
end

Then /^I should be able to execute commands$/ do
  @ssh.exec!('whoami').should_not be_nil
end

When /^I run "(.*?)"$/ do |arg1|
#  @last_output = @ssh.exec!(arg1).chomp!
  output = @ssh.exec!( "a=$(#{arg1});r=$?;echo $r,$a").chomp!
#puts output
  @last_error = @ssh.exec!("echo #{output}| cut -d ',' -f 1 ").chomp!.to_i
  @last_output = @ssh.exec!("echo #{output}| cut -d ',' -f 2- ").chomp!
end

Then /^I should see "(.*?)"$/ do |arg1|
  arg1.should eq(@last_output)
end

Then /^the return code should be (\d+)$/ do |arg1|
  arg1.should be(arg1)
end


When /^I query for package "(.*?)"$/ do |arg1|
  #@last_output = @ssh.exec!("rpm -q #{arg1}").chomp!
  output = @ssh.exec!( "a=$(rpm -q #{arg1});r=$?;echo $r,$a").chomp!
  @last_error = @ssh.exec!("echo #{output}| cut -d ',' -f 1 ")
  @last_output = @ssh.exec!("echo #{output}| cut -d ',' -f 2- ").chomp!
end

Then /^the package "(.*?)" should( not)? exist$/ do |pkg,negate|
  steps %Q{
	When I run "rpm -q #{pkg}"
	}

	if negate
  		@last_output.should match(/not installed/)
	else
  		@last_output.should_not match(/not installed/)
	end
end

Then /^the package "(.*?)" version should be "(.*?)"$/ do |pkg,arg1|
  steps %Q{
	When I run "rpm -q --qf '%{VERSION}-%{RELEASE}' #{pkg}"
	}

	@last_error.should be(0)
  	@last_output.should eq(arg1)
end

Then /^the package "(.*?)" should be running$/ do |arg1|
  steps %Q{
	When I run "for n in `rpm -ql #{arg1}`;  do lsof $n > /dev/null 2>&1 ; if [ $? -eq 0 ]; then echo running; break; fi; done"
	}
  @last_output.should eq("running")
end





Then /^the service "(.*?)" exists$/ do |arg1|
  steps %Q{
	When I run "ls /etc/init.d/#{arg1}"
	}
	@last_error.should be(0)
end

Then /^the service "(.*?)" is (started|stopped)$/ do |service,cmd|
	command=""
	if cmd == "started"
		command="start"
	elsif cmd == "stopped"
		command="stop"
	else
		fail("valid commands: started|stopped")
		#assert(a==b,"valid commands: started|stopped")
	end


  steps %Q{
	When I run "service #{service} #{command}"
	}
	@last_error.should be(0)
end

Then /^the service "(.*?)" should( not)? be running$/ do |arg1,negate|
  steps %Q{
	When I run "service #{arg1} status"
	}

	if negate
		@last_error.should_not be(0)
	else
		@last_error.should be(0)
	end
end

When /^the service "(.*?)" is reloaded$/ do |arg1|
  steps %Q{
	When I run "service #{arg1} reload"
	}

	@last_error.should be(0)
end


Then /^the package "(.*?)" is( not)? available$/ do |pkg,negate|
  steps %Q{
	When I run "yum info #{pkg} 2>&1"
	}

	if negate
		@last_error.should_not be(0)
	else
		@last_error.should be(0)
	end
puts pkg,"last_error: ",@last_error

end


Then /^the package "(.*?)" most recent version should be "(.*?)"$/ do |pkg,arg1|
#egrep -E "^(Version|Release)"| tr -d " "| tr "\n" " " | sed -r 's/ Release:/-/g' | sed 's/Version://g'|tr " " "\n" | sort -r | head -n 1
# cmd=%q{yum info #{pkg} 2> /dev/null | egrep -E '^(Version|Release)'| cut -d ':' -f 2| tr -d ' '| tr '\n' '-'}
 cmd="yum info #{pkg} 2> /dev/null | egrep -E '^(Version|Release)'| cut -d ':' -f 2| tr -d ' '| tr '\\n' '-' | rev|cut -c 2- | rev"
  steps %Q{
	When I run "#{cmd}"
	}

	@last_error.should be(0)
	@last_output.should eq(arg1)
end

Then /^the repository "(.*?)" should be (installed|disabled|enabled)$/ do |repo,query|
	cmd=""
	if query == "installed"
		cmd='yum repolist 2> /dev/null all |egrep -E "repo id[ ]+repo name" -A 100  | sed -e "1 d;$ d" | cut -d " " -f 1'
	elsif query == "disabled"
		cmd='yum repolist 2> /dev/null disabled |egrep -E "repo id[ ]+repo name" -A 100  | sed -e "1 d;$ d" | cut -d " " -f 1'
	elsif query == "enabled"
		cmd='yum repolist 2> /dev/null enabled |egrep -E "repo id[ ]+repo name" -A 100  | sed -e "1 d;$ d" | cut -d " " -f 1'
	end

	steps %Q{
        When I run "#{cmd}"
        }
	@last_error.should be(0)
#	@last_output.should match(/^#{repo}$/)
	@last_output.split("\s").should include(repo)
end

When /the repository "(.*?)" is (disabled|enabled)$/ do |repo,action|
	flag=""
	if action == 'enabled'
		flag=1
	else
		flag=0
	end

	cmd="repofile=$(grep -x '\\[#{repo}\\]' /etc/yum.repos.d/*.repo| cut -d ':' -f 1| sort|uniq);  if [ $? ]; then sed -i '/\\[#{repo}\\]/,/\\[/ s/enabled\s*=.*/enabled=#{flag}/' $repofile; else exit 1;fi"

	steps %Q{
        When I run "#{cmd}"
        }
	@last_error.should be(0)
end


