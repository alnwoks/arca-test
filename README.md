** Using Docker and Bash **
---
Using bash script, Write a script that will automatically provision 3 docker containers running kibana version 6.4.2, nginx server, mysql server separately on each container.

Environment:
Docker CE, Ubuntu 18

Write a script, which will:
container A: kibana version 6.4.2
container B: nginx server
container C: mysql 

serverAcceptance criteria: 
Solution should be prepared as only one script, which creates three Docker images, run containers from them, configures Nginx.
The three docker containers should be able to ping each other regardless of there it is being deployed.
Provide a well documented steps for how to reproduce your work.

** Terraform with Python for Infrastructure Automation **
---
Write a CloudFormation Template to provision a server in a default VPC
write a python script to start the provisioned server
write a python script to stop the provisioned server