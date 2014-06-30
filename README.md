Use this repository to build servers on the linode platform.
This script will allow you to build systems by creating an API and using
this API to create systems.  You can do several options including: 

tfoster@petergriffin:~/linode_scripts/linode$ ./automate_linode.rb -h
Usage: automate_linode [command] [options]
    -v,             Print the version
    -h, --help      Display this help message.

Available commands:

  search     
  build      
  destroy    
  shutdown   
  poweron    

See `<command> --help` for more information on a specific command.


I wrote this to just learn how to use the linode ruby gem.  There is an api for
linode using fog.
https://github.com/fog/fog/tree/master/lib/fog/linode
