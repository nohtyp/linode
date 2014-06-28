#/usr/bin/env ruby
require 'linode'

#######################################
### This script will build a linode ###
### server using the linode api     ###
### wrapper.                        ###
#######################################

myapi_key = ''

mytoken = Linode.new(api_key: "#{myapi_key}")

datacenterlist = mytoken.avail.datacenters

linodedatacenter = datacenterlist.each.select {|x| x['datacenterid'] if x['location'] == "Dallas, TX, USA"}

# This is for troubleshooting
# puts "My datacenterid is: #{linodedatacenter[0]['datacenterid']}"

linodeplan = mytoken.avail.linodeplans

myplan = linodeplan.each.select {|y| y['price'].to_i == 10.0}

# This is for pricing and plan id
#puts "The plan you have used #{myplan[0]['planid']}"

linodekernels = mytoken.avail.kernels
#linodekernels.each {|z| puts z}

mykernelid = linodekernels.each.select {|z| z['label'].match("Latest 64 bit")}

#puts "KernelId: #{mykernelid[0]['kernelid']}"

mynode = mytoken.linode.create(datacenterid: "#{linodedatacenter[0]['datacenterid']}", planid: "#{myplan[0]['planid']}") 
#puts "#{mynode['linodeid']}"
_newdisk1 = mytoken.linode.disk.createfromdistribution(linodeid: "#{mynode['linodeid']}", kernelid: "#{mykernelid[0]['kernelid']}", label: "automated build", distributionid: 127, size: 10240, rootpass: 'Purple80!')

_newdisk2 = mytoken.linode.disk.create(linodeid: "#{mynode['linodeid']}", label: "automated swap", type: 'swap',size: 512, rootpass: 'Purple80!')

disklist = mytoken.linode.disk.list(linodeid: "#{mynode['linodeid']}")

mydisk = (0..(disklist.count - 1)).each.collect {|n| disklist[n]['diskid']}
joineddisk = mydisk.join(',')

config = mytoken.linode.config.create(linodeid: "#{mynode['linodeid']}", kernelid: "#{mykernelid[0]['kernelid']}", label: "mylinode#{mynode['linodeid']}", rootdevicenum: 1, disklist: "#{joineddisk},,,,,,,", rootdevicero: true)

#puts "Config return: #{config['configid']}"

mytoken.linode.boot(linodeid: "#{mynode['linodeid']}", configid: "#{config['configid']}")
