#!/bin/bash
for service in /etc/init.d/hadoop-hdfs-*
do
sudo $service start
done