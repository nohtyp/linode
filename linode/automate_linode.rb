#!/usr/bin/env ruby
require 'slop'
require 'linode'
#
if ARGV.any?
  opts = Slop.parse(help: true, strict: true) do
    on '-v', 'Print the version' do
      puts 'Version 1.0'
      exit
    end
  command 'search (not fully implemented)' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n,  :name=, 'Set server name (required)', argument: :optional
    on :d,  :dcenter=, 'Datacenter to build server (default: Texas=2) ', argument: :optional
    on      :distroid=, 'Distro for server (default: CentOS) ', argument: :optional
    on      :disksize=, 'Disk size for server (default: entire disk) ', argument: :optional
    on :p,  :plan=, 'Plan of server (default: planid=1)', argument: :optional
    on :n,  :network=, 'Use internal network (default: false)', argument: :optional
    on :k,  :kernel=, 'Kernel to use on linode server(default: 138)', argument: :optional
    on :v,  :verbose=, 'Verbose mode', argument: :optional
    
    run do |opts, _args|
      mytoken = Linode.new(api_key: "#{apikey}")
      server = opts[:n]
      mytoken.linode.list("#{servers}")
    end
  end
  command 'build' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n,  :name=, 'Set server name (required)', required: true, argument: true
    on :d,  :dcenter=, 'Datacenter to build server (default: Texas=2) ', argument: :optional
    on :distroid=, 'Distro for server (default: CentOS) ', argument: :optional
    on :disksize=, 'Disk size for server (default: entire disk) ', argument: :optional
    on :p,  :plan=, 'Plan of server (default: planid=1)', argument: :optional
    on :n,  :network=, 'Use internal network (default: false)', argument: :optional
    on :k,  :kernel=, 'Kernel to use on linode server(default: 138)', argument: :optional
    on :b,  :boot=, 'Boot server after building (default: false)', argument: :optional
    on :l,  :label=, 'Label for server disk (default: automated build)', argument: :optional
    on :r,  :rpasswd=, 'Default root password set for system (default: L1n0d3S3rver!)', argument: :optional
    on :s,  :swap=, 'Swap size in MB (default: 256)', argument: :optional
    on :swaplabel=, 'Swap label (default: automated swap)', argument: :optional
    on :v, :verbose=, 'Verbose mode', argument: :optional
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
      
      # Turn on verbosity
      keys = "#{opts.to_hash}"
      if "#{keys}".include?(":verbose")
        enabled = 'true'
      else
        enabled = 'false'
      end

      mytoken = Linode.new(api_key: "#{apikey}")
      mynode =  mytoken.linode.create(datacenterid: "#{datacenter}", planid: "#{plan}")

      if "#{enabled}" == 'true'
        puts "List of servers #{mynode}"
      end

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

      if "#{enabled}" == 'true'
        puts "List of servers #{disklist}"
      end


      mydisk = (0..(disklist.count - 1)).each.map { |n| disklist[n]['diskid'] }

      if "#{enabled}" == 'true'
        puts "List disks #{mydisk}"
      end
      joineddisk = mydisk.join(',')

      config = mytoken.linode.config.create(linodeid: "#{mynode['linodeid']}",
                                            kernelid: "#{kernel}",
                                            label: "#{name}",
                                            rootdevicenum: 1,
                                            disklist: "#{joineddisk}",
                                            rootdevicero: true)
   
      if "#{enabled}" == 'true'
        puts "Configfile #{config}"
      end

      if opts[:b] == 'true'
        puts "Booting system #{name}"
        mytoken.linode.boot(linodeid: "#{mynode['linodeid']}",
                            configid: "#{config['configid']}")
      else
        puts "Server #{name} will not be booted after configuration"
      end
    end
  end
  command 'destroy' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n, :sname=, 'Server name to destroy (required)', required: true, argument: true
    on :v, :verbose=, 'Verbose mode', argument: :optional
    run do |opts, _args|
      apikey     = opts[:a]
      sname      = opts[:n]

      keys = "#{opts.to_hash}"
      if "#{keys}".include?(":verbose")
        enabled = 'true'
      else
        enabled = 'false'
      end

      mytoken    = Linode.new(api_key: "#{apikey}")
      serverlist = mytoken.linode.list
      
      if "#{enabled}" == 'true'
        puts "List of servers #{serverlist}"
      end

      serverid   = (0..(serverlist.count - 1)).each.map { |n| serverlist[n]['linodeid'] if serverlist[n]['label'].include?("#{sname}") }
      removenil  = serverid.compact[0]

      if "#{enabled}" == 'true'
        puts "Server linodeid to check #{removenil}"
      end
      
      serverdisklist = mytoken.linode.disk.list(linodeid: "#{removenil}".to_i)
      if "#{enabled}" == 'true'
        puts "#{serverdisklist}"
      end

      mydisk = (0..(serverdisklist.count - 1)).each.map { |n| serverdisklist[n]['diskid'] }
      if "#{enabled}" == 'true'
        puts "#{mydisk}"
      end

      puts "Deleting disks #{mydisk} before removing server."
      mydisk.each { |d| mytoken.linode.disk.delete(linodeid: "#{removenil}".to_i, diskid: d) }

      puts "Destroying server #{sname}"
      if mytoken.linode.list(linodeid: "#{removenil}".to_i)[0]['status'] == 0
        mytoken.linode.delete(linodeid: "#{removenil}".to_i, skipchecks: true)
      end
    end
  end
  command 'shutdown' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n, :sname=, 'Server name to poweroff (required)', required: true, argument: true
    on :v, :verbose=, 'Verbose mode', argument: :optional
    run do |opts, _args|
      apikey     = opts[:a]
      sname      = opts[:n]

      keys = "#{opts.to_hash}"
      if "#{keys}".include?(":verbose")
        enabled = 'true'
      else
        enabled = 'false'
      end

      mytoken    = Linode.new(api_key: "#{apikey}")
      serverlist = mytoken.linode.list

      if "#{enabled}" == 'true'
        puts "List of servers #{serverlist}"
      end
      serverid   = (0..(serverlist.count - 1)).each.map { |n| serverlist[n]['linodeid'] if serverlist[n]['label'].include?("#{sname}") }
      removenil  = serverid.compact

      if "#{enabled}" == 'true'
        puts "Server linodeid to check #{removenil}"
      end

      puts "Shutting down server #{sname}"
      removenil.each { |x| mytoken.linode.shutdown(linodeid: x) if mytoken.linode.list(linodeid: x)[0]['status'] != 0 }
    end
  end
  command 'poweron' do
    on :a,  :apikey=, 'Linode apikey (required)', required: true, argument: true
    on :n,  :sname=, 'Server name to poweron (required)', required: true, argument: true
    on :v, :verbose=, 'Verbose mode', argument: :optional
    run do |opts, _args|
      apikey     = opts[:a]
      sname      = opts[:n]

      keys = "#{opts.to_hash}"
      if "#{keys}".include?(":verbose")
        enabled = 'true'
      else
        enabled = 'false'
      end

      mytoken    = Linode.new(api_key: "#{apikey}")
      serverlist = mytoken.linode.list

      if "#{enabled}" == 'true'
        puts "List of servers #{serverlist}"
      end
      serverid   = (0..(serverlist.count - 1)).each.map { |n| serverlist[n]['linodeid'] if serverlist[n]['label'].include?("#{sname}") }
      removenil  = serverid.compact

      if "#{enabled}" == 'true'
        puts "Server linodeid to check #{removenil}"
      end

      puts "Starting server #{sname}"
      removenil.each { |x| mytoken.linode.boot(linodeid: x) if mytoken.linode.list(linodeid: x)[0]['status'] != 0 }
    end
  end
  end
else
  Slop.parse do
    on :h, :help, 'Print this help message'
    puts help
    exit
  end
end
