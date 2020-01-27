# Create a Quest InTrust lab

## Description

This template deploys the Quest InTrust lab with following configuration: 

* a new AD domain controller. 
* a SQL Server 
* an InTrust Server. 
* a client machine.

Each VM has its own public IP address and is added to a subnet protected with a Network Security Group, which only allows RDP port from Internet. 

Each VM has a private network IP which is for InTrust communication. 

