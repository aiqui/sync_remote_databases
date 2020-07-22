# Sync Remote Databases

This is a simple tool for securely downloading remote databases.

## How this works

This tool should be installed on both the client and server.  The 
server side is configured to dump certain databases.  The 
client is configured to access the server.  There are configuration
files on both sides.

The client will access the server using SSH.  The server is configured
to run a forced SSH command for the server script, preventing any 
attacks.

## Installation



## Client-side installation

The steps for installaing on your local machine (the client):
* Clone this repository
* Create an SSH key pair
* Copy `sync_remote_db.config.template` to `sync_remote_db.config`
* Edit the configuration file, adding the databases, server hostname, 
user and any other SSH options

#### Create an SSH key pair

You can create a SSH key pair with or without a passphrase.  To do 
this:
```
ssh-keygen -f sync_remote_db_key
```

The private key `sync_remote_db_key` should be carefully protected
and never passed around.  The public key `sync_remote_db_key.pub` can be transferred openly
as needed.

## Server-side installation

The steps for installing on the server:
* Clone this repository on a server that has access to your databases.
* Copy the _public_ SSH key from your machine to the server
* Install the SSH key as shown below

## MORE TBD

