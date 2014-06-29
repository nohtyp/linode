#!/usr/bin/env ruby
require 'slop'
require 'linode'

if ARGV.any?
  opts = Slop.parse(help: true, strict: true) do
    on '-v', 'Print the version' do
    puts 'Version 1.0'
    exit
  end
  command 'build' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n,  :name=, 'Set server name (required)',required: true, argument: true
    on :d,  :dcenter=, 'Datacenter to build server (default: Texas=2) ',argument: :optional
    on :distroid=, 'Distro for server (default: CentOS) ',argument: :optional
    on :disksize=, 'Disk size for server (default: entire disk) ',argument: :optional
    on :p,  :plan=, 'Plan of server (default: planid=1)', argument: :optional
    on :n,  :network=, 'Use internal network (default: false)', argument: :optional
    on :k,  :kernel=, 'Kernel to use on linode server(default: 138)', argument: :optional
    on :b,  :boot=, 'Boot server after building (default: false)', argument: :optional
    on :l,  :label=, 'Label for server disk (default: automated build)',argument: :optional
    on :r,  :rpasswd=, 'Default root password set for system (default: L1n0d3S3rver!)',argument: :optional
    on :s,  :swap=, 'Swap size in MB (default: 256)', argument: :optional
    on :swaplabel=, 'Swap label (default: automated swap)', argument: :optional
    run do |opts, _args|

      apikey     = opts[:a]
      name       = opts[:n]
      datacenter = opts[:d].nil?  ? 2 : opts[:d]
      distroid   = opts[:distroid].nil? ? 127 : opts[:distroid]
      disksize   = opts[:disksize].nil? ? 10240 : opts[:disksize]
      plan       = opts[:p].nil?  ? 1 : opts[:p]
      network    = opts[:n].nil?  ? 'false' : opts[:n]
      kernel     = opts[:k].nil?  ? 138 : opts[:k]
      boot       = opts[:b].nil?  ? 'false' : opts[:b]
      dlabel     = opts[:l].nil?  ? 'automated build' : opts[:l]
      rpass      = opts[:r].nil?  ? 'L1n0d3S3rver!' : opts[:r]
      swap       = opts[:s].nil?  ? 256 : opts[:s]
      slabel     = opts[:swaplabel].nil? ? 'automated swap' : opts[:swaplabel]

      mytoken = Linode.new(api_key: "#{apikey}")
      mynode =  mytoken.linode.create(datacenterid: "#{datacenter}", planid: "#{plan}")

      _updatename = mytoken.linode.update(linodeid: "#{mynode['linodeid']}",
                                          label: "#{name}")

      _newdisk1 = mytoken.linode.disk.createfromdistribution(linodeid: "#{mynode['linodeid']}",
                                                             kernelid: "#{kernel}",
                                                             label: "#{dlabel}",
                                                             distributionid: "#{distroid}",
                                                             size: "#{disksize}",
                                                             rootpass: "#{rpass}")

      _newdisk2 = mytoken.linode.disk.create(linodeid: "#{mynode['linodeid']}",
                                             label: "#{slabel}",
                                             type: 'swap',
                                             size: "#{swap}",
                                             rootpass: "#{rpass}")

      disklist = mytoken.linode.disk.list(linodeid: "#{mynode['linodeid']}")

      mydisk = (0..(disklist.count - 1)).each.map { |n| disklist[n]['diskid'] }
      joineddisk = mydisk.join(',')

      config = mytoken.linode.config.create(linodeid: "#{mynode['linodeid']}",
                                            kernelid: "#{kernel}",
                                            label: "#{name}",
                                            rootdevicenum: 1,
                                            disklist: "#{joineddisk}",
                                            rootdevicero: true)

      if opts[:b] == 'true'
        puts "Booting system #{name}"
        mytoken.linode.boot(linodeid: "#{mynode['linodeid']}",
                            configid: "#{config['configid']}") 
      else
        puts "Server #{name} will not be booted after configuration"
      end
       
    end
  end
  # command 'destroy' do
  #  on :n, :sname=, 'Server name to destroy (required)', required: true, argument: true
  #  run do |opts, _args|
  #  end
  # end
  # command 'poweroff' do
  #  on :n, :sname=, 'Server name to poweroff (required)', required: true, argument: true
  #  run do |opts, _args|
  #  end
  # end
  # command 'poweron' do
  #  on :n, :sname=, 'Server name to poweron (required)', required: true, argument: true
  #  run do |opts, _args|
  #  end
  # end
  end
else
  Slop.parse do
    on :h, :help, 'Print this help message'
    puts help
    exit
  end
end
