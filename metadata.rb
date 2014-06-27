name              "cloudera"
maintainer        "Daniel P."
description       "Installs Cloudera for Ubuntu only"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.5.5"

recipe "cloudera", "Installs Cloudera Pseudo (all on one node)"
recipe "cloudera::flume", "Installs Apache Flume"

%w{ ubuntu debian }.each do |os|
  supports os
end
