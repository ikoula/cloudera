# PSEUDEO INSTALL:
# https://ccp.cloudera.com/display/CDH4DOC/Installing+CDH4+on+a+Single+Linux+Node+in+Pseudo-distributed+Mode#InstallingCDH4onaSingleLinuxNodeinPseudo-distributedMode-InstallingCDH4withYARNonaSingleLinuxNodeinPseudodistributedmode

if node[:platform] == "ubuntu"
    execute "apt-get update"
end

# Install required base packages
package "curl" do
    action :install
end

package "wget" do
    action :install
end

# Install Cloudera Basic:
case node[:platform]
    when "ubuntu"
        case node[:lsb][:codename]
            when "precise"
                execute "curl -s http://archive.cloudera.com/cdh4/ubuntu/precise/amd64/cdh/archive.key | sudo apt-key add -"
                execute "wget http://archive.cloudera.com/cdh4/one-click-install/precise/amd64/cdh4-repository_1.0_all.deb"
            when "lucid"
                execute "curl -s http://archive.cloudera.com/cdh4/ubuntu/lucid/amd64/cdh/archive.key | sudo apt-key add -"
                execute "wget http://archive.cloudera.com/cdh4/one-click-install/lucid/amd64/cdh4-repository_1.0_all.deb"
             when "squeeze"
                execute "curl -s http://archive.cloudera.com/cdh4/ubuntu/squeeze/amd64/cdh/archive.key | sudo apt-key add -"
                execute "wget http://archive.cloudera.com/cdh4/one-click-install/squeeze/amd64/cdh4-repository_1.0_all.deb"
        end
        execute "dpkg -i cdh4-repository_1.0_all.deb"
        execute "apt-get update"
    when "debian"
	 case node[:lsb][:codename]
		when "wheezy"
		# wheezy still not supported by chd4 !
		# ref : https://groups.google.com/a/cloudera.org/forum/#!topic/cdh-user/MOSaRLMTQ3U
		execute "wget http://ftp.pl.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
		execute "dpkg -i libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
	 end
	 execute "curl -s http://archive.cloudera.com/cdh4/debian/squeeze/amd64/cdh/archive.key | apt-key add -"
	 execute "wget http://archive.cloudera.com/cdh4/one-click-install/squeeze/amd64/cdh4-repository_1.0_all.deb"
	 execute "dpkg -i cdh4-repository_1.0_all.deb"
	 execute "apt-get update"
end




if node['cloudera']['installyarn'] == true
    package "hadoop-conf-pseudo" do
      action :install
    end
else
    package "hadoop-0.20-conf-pseudo" do
      action :install
    end
end


# copy over helper script to start hdfs
cookbook_file "/tmp/hadoop-hdfs-start.sh" do
    source "hadoop-hdfs-start.sh"
    mode "0744"
end
cookbook_file "/tmp/hadoop-hdfs-stop.sh" do
    source "hadoop-hdfs-stop.sh"
    mode "0744"
end
cookbook_file "/tmp/hadoop-0.20-mapreduce-start.sh" do
    source "hadoop-0.20-mapreduce-start.sh"
    mode "0744"
end
cookbook_file "/tmp/hadoop-0.20-mapreduce-stop.sh" do
    source "hadoop-0.20-mapreduce-stop.sh"
    mode "0744"
end
# helper to prepare folder structure for first time
cookbook_file "/tmp/prepare-yarn.sh" do
    source "prepare-yarn.sh"
    mode "0777"
end
cookbook_file "/tmp/prepare-0.20-mapreduce.sh" do
    source "prepare-0.20-mapreduce.sh"
    mode "0777"
end


# only for the first run we need to format as hdfs (we pass input "N" to answer the reformat question with No )
################
execute "format namenode" do
    command 'echo "N" | hdfs namenode -format'
    user "hdfs"
    returns [0,1]
end


# Jobtracker repeats - was the only way to get both together
%w{jobtracker tasktracker}.each { |name|
  service "hadoop-0.20-mapreduce-#{name}" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
} if !node['cloudera']['installyarn']

# now hadopp should run and this should work: http://localhost:50070:
%w(datanode namenode secondarynamenode).each { |name|
  service "hadoop-hdfs-#{name}" do
    supports :status => true, :restart => true, :reload => true
    action [ :enable, :start ]
  end
}

# Prepare folders (only first run)
# TODO: only do this if "hadoop fs -ls /tmp" return "No such file or directory"
################

if node['cloudera']['installyarn'] == true
    execute "/tmp/prepare-yarn.sh" do
     user "hdfs"
     not_if 'hadoop fs -ls -R / | grep "/tmp/hadoop-yarn"'
    end
else
    execute "/tmp/prepare-0.20-mapreduce.sh" do
     user "hdfs"
     not_if 'hadoop fs -ls -R / | grep "/var/lib/hadoop-hdfs/cache/mapred"'
    end
end






