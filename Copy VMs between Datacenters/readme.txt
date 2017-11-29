					         Cross vCenter VM Mobility - CLI Tool
							 
https://labs.vmware.com/flings/xvc-mobility-cli?download_url=https%3A%2F%2Fdownload3.vmware.com%2Fsoftware%2Fvmw-tools%2Fxvc-mobility-cli%2Fxvc-mobility-cli_1.0.zip

What is it?
-----------
Cross vCenter VM Mobility - CLI is a command line tool used to migrate/clone a VM from one host to another host managed by different VCs which can be linked or isolated. It has been built using vSphere Java based SDK APIs. Currently vSphere web client doesn't support migrate or clone operations when the two VCs are not linked.

Download the xvc-mobility-cli.zip tool and extract it to any folder in local machine.
        
How to run
----------
1. Set JAVA_HOME (preferably jdk1.7 or above) 

2. Run the below command from extracted folder,
     
	Linux : /home/user1/xvc-mobility-cli>sh xvc-mobility.sh

	Windows : C:\xvc-mobility-cli>xvc-mobility.bat

Command:
xvc-mobility -svc <source-vc-ip> -su <source-vc-username> -dvc <destination-vc-ip> -du <destination-vc-username> -vms <vm-names> -dh <destination-host> -dds <destination-datastore> -op relocate

Note :- VC Passwords will be asked on the prompt. Don't use this tool to migrate linked clones between VCs.

Parameters:
-op  : operation - <required> {relocate, clone}
-svc : source vc ip/dns name/url - <required>
-su  : source vc username - <required>
-dvc : destination vc ip/dns name/url - <required>
-du  : destination vc username - <required>
-vms : one or more vm names separated by comma - <required>
-cln : clone vm name - [required for clone operation]
-dcl : destination drs cluster - [required when dest host is not given]
-dh  : destination host - [required when dest drs-cluster is not given]
-dds : destination datastore - [optional but required for multiple vms to relocate]

Note:
1. Arguments can be specified either through command line  or config/config.properties, command line arguments take precedence
2. -dcl or -dh must be provided.
     if -dh is provided and -dds is not provided 
	    then vm's datastore is assumed to be shared between source and destination hosts and migrate happens only at host level.
3. both -dh and -dds are mandatory for multiple vms to relocate.
4. if -op is clone, then -cln(clone vm name) is mandatory
5. only one vm can be cloned at a time
6. special characters must be enclosed in double quotes.

Supported Operations
--------------------
 - Migrate one or more VMs by specifying destination host and datastore
 - Migrate a VM by specifying destination DRS enabled cluster and/or datastore(Cluster Placement)
 - Migrate a VM by specifying only destination  host (Shared vMotion)
 - Clone a VM by specifying destination host and datastore
 - Clone a VM by specifying destination DRS enabled cluster and/or datastore
 - Clone a VM by specifying only destination  host

Notice
------
This distribution may include software that has been designed for use
with VMware software Private Ltd only.

Contacts
--------
For any questions or issues, please write to us @ 

jkrishnamoorthy@vmware.com
manikandank@vmware.com
gkrishna@vmware.com
mkhadar@vmware.com

Copyright (C) 2016-2017 VMware Software India Pvt Ltd.
------------------------------------------------------
This tool is a free software; you should not redistribute it and/or modify it under the
terms of the VMware Software India Pvt ltd.