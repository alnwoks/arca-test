# ARCA Payments DevOps Interview Assessment

<!--- These are examples. See https://shields.io for others or to customize this set of shields. You might want to include dependencies, project status and licence info here --->
![GitHub repo size](https://img.shields.io/github/repo-size/alnwoks/arca-test)
![GitHub contributors](https://img.shields.io/github/contributors/alnwoks/arca-test)

Using bash script, Write a script that will automatically provision 3 docker containers running kibana version 6.4.2, nginx server, mysql server separately on each container.

Environment:
Docker CE, Ubuntu 18

Write a script, which will:
container A: kibana version 6.4.2
container B: nginx server
container C: mysql server

Acceptance criteria: 
* Solution should be prepared as only one script, which creates three Docker images, run containers from them, configures Nginx.
The three docker containers should be able to ping each other regardless of there it is being deployed.
* Provide a well documented steps for how to reproduce your work.

** Terraform with Python for Infrastructure Automation **
```
Write a CloudFormation Template to provision a server in a default VPC
write a python script to start the provisioned server
write a python script to stop the provisioned server
```

This project contains a `docker-compose.yaml` file that deploys:
* kibana
* mysql
* nginx

## Prerequisites
    
Before you begin, ensure you have met the following requirements:
<!--- These are just example requirements. Add, duplicate or remove as required --->
* You have installed the latest version of `docker` and `python3`
* You have a `Linux` machine. Preferably Ubuntu CE 18.04
<!-- * You have read `<guide/link/documentation_related_to_project>`. -->

<!-- The project needs a server running Ubuntu 18.04 and above with Docker installed.
In the event you need to provision a new server, this project contains a `main.tf` file which can be used to provision a Linux instance on AWS. -->

## Reproducing the Steps
---
This project is basically an illustration of a single script that when executed builds three corresponding applications and configuring the nginx server to serve as a proxy for the kibana and mysql applications.

First, you create a bash script `run.sh` that would contain the initialization script:

```bash

#!/bin/bash

sudo apt-get -y update
sudo apt install -y libssl-dev python3-dev sshpass apt-transport-https jq moreutils ca-certificates curl gnupg2 software-properties-common python3-pip rsync

sudo apt-get remove docker docker-engine docker.io containerd runc -y

sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update -y

sudo apt-get install docker-ce docker-ce-cli containerd.io -y
```

The script above installs all the necessary dependencies needed to run the applications.

Next, create a `docker-compose.yaml` file that would contain the applications to be built:

```yaml

version: '2.2'
services:

  # Elasticsearch
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.4.2
    restart: unless-stopped
    container_name: elasticsearch
    environment:
      - node.name=elasticsearch-master
      - cluster.name=es-cluster-7
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms128m -Xmx128m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es-data01:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - app-network
 
  # Kibana - v6.4.2
  kibana:
    image: docker.elastic.co/kibana/kibana:6.4.2
    restart: unless-stopped
    container_name: kibana
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    ports:
      - 5601:5601
    networks:
      - app-network
    depends_on:
      - elasticsearch
  
  # MySQL/MariaDB
  mysql:
    image: mariadb
    restart: unless-stopped
    container_name: mysql
    volumes: 
      - ./mariadb/conf:/etc/mysql
    environment:
      MYSQL_DATABASE: demo
      MYSQL_ROOT_PASSWORD: demo
      SERVICE_TAGS: dev
      SERVICE_NAME: mysql
    # env_file: 
    #   - database.env
    ports:
      - 3306:3306
    networks:
      - app-network
  
  # NGINX
  nginx:
    image: nginx:alpine
    container_name: nginx
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8081:8081"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/error.log:/etc/nginx/error_log.log
      - ./nginx/cache/:/etc/nginx/cache
      - /etc/letsencrypt/:/etc/letsencrypt/
    networks:
      - app-network

volumes:
  es-data01:
    driver: local
  es-db:
    driver: local
  mysql-db:
    driver: local
  

networks:
  app-network:
    driver: bridge
```


This docker compose file, when run, would create the respective applications.

* Elasticsearch: This application would act as the backend for the kibana application.
* Kibana: This is an open-source business management tool would be listening on port 5601
* MySql: The mysql server would be listening on port 3306
* Nginx: The webserver would be listening on port 8080 an 8081 as a reverse proxy for kibana and mysql respectively.

The proposed behaviour of the web server is not possible by default, as such you would need to configure the webserver to route traffic to the various applications.

To achieve this, create a `nginx.conf` file which will be used to override the default config setup for the nginx server:

```

worker_processes 1;
  
events { worker_connections 1024; 
}

http {

    sendfile on;

    # upstream kibana {
    #     server kibana:5601;

    # }

    # upstream mysql {
    #     server mysql:3306;
    # }
    
    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Host $server_name;
    
    server {
        listen 8080;
 
        location / {
            proxy_pass         http://kibana:5601;
            proxy_redirect     off;
        }
    }
 
    server {
        listen 8081;
 
        location / {
            proxy_pass         http://mysql:3306;
            proxy_redirect     off;
        }
    }
}
```
This configuration basically instructs the nginx server to listen on port 8080 and 8081, and serve all the traffic coming through to the kibana application listening on port 5601, and mysql application listening on port 3306 respectively.

Now, all we would need to is run the docker compose command to start the services:

```
docker-compose up -d
```

## Putting it all together

So you now have a `docker-compose.yaml` and `run.sh` script for both creating the applications and initializing a provisioned server/environment.
In order to better automate this process, we can merge both processes into `run.sh` file, which will call docker once all the dependencies have been installed:

```bash

#!/bin/bash

#start deployment
echo "Installing Dependencies..."
sudo apt-get -y update
sudo apt install -y libssl-dev python3-dev sshpass apt-transport-https jq moreutils ca-certificates curl gnupg2 software-properties-common python3-pip rsync

#install docker
echo "Removing legacy Docker Dependencies (if any)..."
sudo apt-get remove docker docker-engine docker.io containerd runc -y

echo "Update done. Preparing the environment..."
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
echo "Configuring..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
echo "Finalizing System Update.."
sudo apt-get update -y
echo "Installing recommended docker packages..."
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
echo "Install completed!"

#run docker compose
sudo docker-compose up > logfile
```

This script now ensures the applications are created once the environment has been successfully initialized.


## Running the project

Clone the repo into the provisioned server (Preferably Ubuntu CE 18.04):
```
git clone https://github.com/alnwoks/arca-test.git;
``

Once done, move into the `arca-test/` directory and run the initialization script:
```
cd arca-test
./run.sh
```
This will install the necessary dependencies and deploy the applications.

* Kibana can be reached via `<http://server-ip:8080>`
* MySQL can be reached via `<http://server-ip:8081>`

## Contact

You can reach me at <chalonnwokedike@gmail.com>.
