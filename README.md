#####################################################################
#
# Deep Learning Setup
#
#####################################################################

**Maintainer**: Samuel Cozannet <samuel.cozannet@canonical.com> 

# Purpose of the project
## Introduction 
TBD

## Deep Learning Stack

This project is also about sharing an example of architecture providing: 

* A  data pipeline sending to Hadoop from many machines
* An evolutive data computation stack, made of Spark, Hadoop, Kafka and other components from traditional big data stacks. 

The whole system is modelled via [Juju](https://jujucharms.com), Canonical's Application Modelling Framework. 
The deployment is run on GPU enabled machines, either on AWS or on Bare Metal. 

This project will provide guidance about how you can deploy your own machine/deep learning stack at scale and do your own data analysis. We hope it will be useful for other universities and students to get their hands on classic big data infrastructure in just minutes. 

# Usage

TBD

### Pre requisites 
#### Downloading the repository

First clone the repo 

    git clone --recursive https://github.com/SaMnCo/juju-dl-ods dl

Then create a configuration file from the template

    cd dl 
    cp ./etc/project.conf.template ./etc/project.conf

#### Juju Client 

In order to run the stack, you need to install the Juju client on your laptop. Instructions for Ubuntu, Windows and OS X are available [here](https://jujucharms.com/get-started)

#### Cloud Credentials

The installation of the Juju client has a wizard to connect to your favorite cloud. For this project, we advise the use of GPU machines, which are currently available only on AWS or Azure. 

* For AWS: TBC
* For Azure: TBC

Then use the cloud name you gave to configure the etc/project.conf file

#### Sizing your cluster

TBD

#### GPU or No GPU

This is really about your money. GPU machines on AWS are typically 5x more expensive than the others. So you may want to reduce the cost, at the expense of the speed of computation, or not. It's really up to you. 

### Deploying the stack

As a normal user, on Ubuntu, run: 

    cd /path/to/dl/project
    ./bin/00-bootstrap.sh

This will make sure your Juju environment is up & running

Then install with 

    ./bin/01-deploy.sh

Then... wait for a few minutes! 

#### Configuration

Edit ./etc/project.conf to change: 

* PROJECT_ID : This is the name of your environment
* FACILITY (default to local0): Log facility to use for logging demo activity
* LOGTAG (default to demo): A tag to add to log lines to ease recognition of demos
* MIN_LOG_LEVEL (default to debug): change verbosity. Only logs above this in ./etc/syslog-levels will show up

## Bootstrapping 

	./bin/00-bootstrap.sh

Will set up the environment, which essentially means setting up the cloud environment and installing the first machine. 

## Deploying  

	./bin/01-deploy.sh

Will deploy the charms required for the project: 

* Hadoop (Master, 3x Slave, YARN Master)
* Spark 
* Zeppelin & iPython Notebook

## Configure  

	./bin/10-add-users.sh

Will take public ssh keys hosted in the ./var/ssh/ folder, and add them to each machine of the cluster, for the ubuntu user. This can be run several times (especially after adding other services) to make sure administrators can log in. 

## Resetting 

	./bin/50-reset.sh

Will reset the environment but keep it alive

## Clean

	./bin/99-cleanup.sh

Will completely rip of the environment and delete local files

# Sample Outputs
## Bootstrapping

TBD
 

## Deployment

TBD

## Reset

TBD

## Status 
### Deploying

TBD

### Up & Running

TBD