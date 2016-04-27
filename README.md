#####################################################################
#
# Deep Learning Setup
#
#####################################################################

**Maintainers**: 

  * Samuel Cozannet <samuel.cozannet@canonical.com> 
  * Andy Petrella <noootsab@data-fellas.guru>,
  * François Bayart <francois.bayart@data-fellas.guru>,
  * Adam Gibson <adam@skymind.io>,
  * Alex Black <alex@skymind.io>,
  * Melanie Warrick <melanie@skymind.io>

# Purpose of the project
## Introduction 

Data Science, a buzz word we've seen popping everywhere in 2015

Why? It turns out engineers explored the Big Data's value and the way to deal it, that is, digging the gold, Data Science, covering mathematics, statistics, machine learning, data preparation, software development and more.

Data science came to the front because data is accumulating and exploiting the value is a key to competitivity. Data Science and Machine Learning in particular had traditionally been the smart and helpful tool mostly designed and developed in academia, the enterprise could only grasp at high premium.

Now the game is changing drastically, methods have matured, libraries are available and more data scientists are entering the market.

Still, there are many friction points in the development process of services exploiting data. It's true that Data Scientists are developers, but usually they are not software developers and even less devops which leads to a disrupted organization and a lack of efficiency.

We present here some solutions providing a unifying environment, helping different people with different tasks and background to develop a data service pipeline with minimal friction and maximal agility.

## Deep Learning Stack
### Training 

This project is also about sharing an example of architecture providing: 

* A  data pipeline to push data into Hadoop HDFS
* An evolutive data computation stack, made of Spark, Hadoop, Kafka and other components from traditional big data stacks. 
* A Computing framework for the scheduling of Spark jobs
  * Based on YARN for traditional Hadoop users
  * Based on Mesos for cutting edge and green field projects
* An interactive notebook to create training pipelines and build NNs

So something like 

![this](https://github.com/SaMnCo/ods-dl/blob/master/docs/software-pieces.png)

The whole system is modelled via [Juju](https://jujucharms.com), Canonical's Application Modelling Framework. 
The deployment is run on GPU enabled machines, either on AWS or on Bare Metal, on clusters or, with Juju 2.0, on LXD containers. 
We've been ourselves using IBM Power architectures for our deployment: 

![power](https://github.com/SaMnCo/ods-dl/blob/master/docs/openpower-logo.jpg)

The Juju model for this looks like: 

![this](https://github.com/SaMnCo/ods-dl/blob/master/docs/dl-bundle.png)

This project will provide guidance about how you can deploy your own machine/deep learning stack at scale and do your own data analysis. We hope it will be useful for other universities and students to get their hands on classic big data infrastructure in just minutes. 

### Using

Once you have a model, you'd want to use it. While in development, you'd probably want to do that on your machine, systems in production are usually slightly different to say the least. So you'd also want to build something that allows you to see what happens for the end users. 

Here we'll take a simple example, and see how we can  deploy a Spark Application in a separate cluster (TBD)

## Use Cases

There are so many use cases for Deep Learning that it's hard to pick one only! However, Canonical has invested a lot into the OpenStack environment and made Ubuntu the "OS for the cloud". The management of very large scale clouds and the ability to provision services on top in an easy way, with enterprise-grade SLAs is therefore an area of interest. 

In that context, the excellent performance NeuroNets show in anomaly detection are an asset to create intelligent monitoring agents, that analyze the status of clusters in real time, and predict its remaining time to live. There is also a potential to look at the network traffic and estimate if the current conditions match some attacks for example. And of course, there are sentiment analysis, image recognition...

### OpenStack Logs

Canonical runs a private OpenStack Interoperability Lab (OIL), where 1000s of combinations of OpenStack clouds are tested every month, on different hardware setups, different combinations of network and software versions and so on. This allows to grow our expertise of what works and what doesn't work. 

This generates logs. Not huge amounts, but around 10GB a week or so. The idea is to use these results, which are already labelled with all sorts of bugs, if they passed or failed and so on, and train a model which will be able to predict when a cluster is going to fail. 

There are 2 main outcomes to that: 

* Of course at the beginning, this is an improvement over traditional monitoring systems, which only assess the status to the extend of how IS engineers have built the monitoring of the solution. Intelligent agents will be able to trigger alarms based on "feeling" the network, rather than on straight values and probabilities. A little bit like a spam robot, it will reduce the amount of work of support teams by notifying them of the threat level. 
* but over time and as clouds grow, losing a node will become less and less manageable. It will then be safe to turn to these agents to make completely automated decisions when we are comfortable they can take them. Like "migrate all containers off this node" or "restart these services asap"

The beauty of this is that it doesn't depend on OpenStack itself. The same network will be trainable on any form of applications, creating a new breed of monitoring and metrology systems, combining the power of logs with metrics. 

### Network Intrusion

Anomaly detection using NIDS (network intrustion detection) data is a classic problem for NeuroNets. Models are trained to monitor and identify unauthorized, illicit and anomalous network behavior, notify network administrators and/or take autonomous actions to save the network integrity. 

The models used are 

- MLP | Feedforward (currently used for streaming)
- RNN
- AutoEncoder
- MLP simulated AutoEncoder

and several datasets have been used for a first PoC to function, among which

- UNSW NB-15 = main dataset used in the project especially for streaming
  - Cyber Range Lab of the Australian Cyber Security 
  - Hybrid of normal activities and synthetic contemporary attack behaviors using the IXIA tool
  - 3 networks
  - 45 IP addresses
  - 16 hours data collection
  - 49 features
  - 2.5M records
  - Includes 9 core attack families with training dataset breakdown as follows:
    - Normal 56K 
    - Analysis 2K
    - Backdoor 1.7K
    - DoS 12K
    - Exploits 33K
    - Fuzzers 18K
    - Generic 40K
    - Reconnaissance 10K
    - Shellcode 1K
    - Worms 130
  - ISCX
  - NSL-KDD

### Sentiment Analysis

TBD

### Image Recognition

TBD

# Roadmap

This is very much a work in progress, and we have a lot of ideas to push it further. Some ideas for the future

## Ingest Pipeline
### Log Pipeline

In our example, we are using HDFS files for the training. That means there is an out of band data cleaning & ingest process. As far as Juju goes, because of the relations that are created between services, it is very easy to build intelligent charms for monitoring & logging agents. Suddenly, they auto-integrate with the underlying app they are supposed to monitor. 

The idea is to use fluentd, the open source tool used by Google in GCP and supported by Treasure Data, and wrap it in a charm that will auto-adapt to the unit it runs on. If the unit runs OpenStack Nova, it will collect and serialize Nova logs. If it's a RabbitMQ node, it will collect the proper information. And so on and so on. 

Standardizing logs outputed by applications powered by Juju will help us create generic, reusable, repeatable ingest pipelines not only for OpenStack, our primary use case, but also for any big software. 

### Metric Pipeline

For now we have only looked at logs, but we intend to add metrology to the mix as well. Fortunately, InfluxDB has recently announced a Spark API. They are also native in Mesos. 
The idea here is also to make intelligent charms, so the Telegraph agent adapts to the underlying workload. This way, we'll have also a generic pipeline for metrics on Juju, and will be able to train on this dataset as well. 

### Media Pipeline

This is a little trickier, but our vision is to create classic entry points for images, sound, video, other text... We are open to suggestions in that space. Current assumption is to base our work on Kafka, then offer http endpoints to offer scale out interfaces. 

## Training to production 

This project really focused on the training part for now. The output of the process is simply a file, that represents the pre-trained model, and more or less looks like a big CSV file. 

Our vision is to add another charm, that will push this pre-trained model to some endpoints like S3, NFS or just an HTTP server. 

Models evolve over time, as you continue training over time. So from time to time, they will be updated. 

Then agents running the models will be able to subscribe to this file, and update themselves a little bit like an antivirus would do. 

## DC/OS

So right now we've been using Mesos and Marathon 0.29 as the management layer for Spark workloads. But now that Mesosphere has open sourced the full DC/OS experience, we look forward to using that. Work in progress with our friends at Spicule and Mesosphere. 

## Additional Power Optimizations

The IBM Research & Development teams have developed a series of improvements in a layer called Ego





# Usage
## Installing Juju

First of all, refer to the [official documentation](https://jujucharms.com/get-started) to get your Juju started

## Cloud Credentials

The installation of the Juju client has a wizard to connect to your favorite cloud. For this project, we advise the use of GPU machines, which are currently available only on AWS or Azure (soon). 

Just run ```juju quickstart -i``` to create the controller. 

## Configuration 
### Sizing your cluster

By default, Juju charms will only set the replication level in HDFS to 1, and this project will spin 3 units of Hadoop slaves. So 1 byte will actually cost you 1 byte of storage (more or less)

Now this project deploys 3 data nodes of HDFS, each of them having ${LOG_STORAGE} gigabytes of storage available, hence you'll end up with 3x as much storage as you defined. 

You have 2 choices: 

* Change the replication to 3, and pick a log storage size 30 to 50% higher than the size of your files
* Or keep it to 1 for the sake of the experiment, and pick a log storage 40% lower than the size of your files. 

If you don't have any data, this setup will pick 64GB / node, so you'll end up with about 192GB of storage in HDFS. 

### GPU or No GPU

This is really about your money. GPU machines on AWS are typically 5x more expensive than the others. So you may want to reduce the cost, at the expense of the speed of computation, or not. It's really up to you. 

To give you an idea, a g2.2xlarge instance costs about $0.65/hr and we use 5 of them (eventualy 6), so that would put this in the range of $4/hr, or $100/day. 

### Setting up users

You may not be the only person who will have access to this. If you have a team of people, collect their SSH keys (.pub files) and put them all in ./var/ssh/

### Downloading the repository

First clone the repo 

    git clone --recursive https://github.com/SaMnCo/juju-dl-ods dl

### Building the configuration 

Create a configuration file from the template

    cd dl 
    cp ./etc/project.conf.template ./etc/project.conf

The configuration items you need to take care of: 

```
# Cloud: set to aws, azure or local for local laptop deployment. Defaults to AWS. 
#  - Local will attempt to deploy using the LXD provider, which required Xenial (16.04)
#  - AWS will use GPU instances whenever possible
#  - Azure will soon be able to use GPUs, but for now will go on CPU only
# Other clouds that don't have GPUs on their roadmap are not yet added to this. 
CLOUD_ID=aws

# Project Settings: Enter the name of your Juju cloud settings here
# This is the name of your Juju model (formerly environment)
PROJECT_ID=ENTER_PROJECT_NAME

# Logging Settings: these are the settings for the deployment scripts
# You can see the available levels in the file "syslog-levels". You can therefore
# reduce the verbosity by going higher in the stack. 
FACILITY="local0"
LOGTAG="deepstack"
MIN_LOG_LEVEL="debug"

# Temporary files list: in case temporary files are created, they will be created in this 
# folder. 
TMP_FILES="tmp/deepstack"

# Log Storage in GB: This will be used to size HDFS nodes. Defaults to 64. 
LOG_STORAGE=64

# Use GPU machines: 0 or 1, defaults to 0
# For now, Azure doesn't yet have the GPU instances so can't have ENABLE_GPU=1
ENABLE_GPU=0

# Scheduler type ("mesos" or "yarn", defaults to "mesos")
# Initially the solution used only YARN, but with time it appears Mesos is taking a good 
# marketshare in this space, so we also made it available. Kudos to DataArt's team for 
# bootstrapping Juju compliance. 
SCHEDULER="mesos"

# Dataset: path to dataset to upload to HDFS
# If you intend to push a dataset to HDFS, store it on your local FS as a tgz file and
# put the path here. 
DATASET="PATH_TO_DATASET_TGZ"

# Default Ubuntu Series: xenial or trusty. Other non-LTS types are not supported. 
DEFAULT_SERIES="trusty"
```

## Deploying the stack

This is architecture dependent. 

As a normal user, on Ubuntu, run: 

* If you are running this demo on a Power 8 machine, with local provider (LXD) do: 

    cd /path/to/dl/project
    ./bin/00-bootstrap-ppc64le.sh

* If you are running this demo on a x86 machine, regardless of where and how, do: 

    cd /path/to/dl/project
    ./bin/00-bootstrap-x86_64.sh

This will make sure your Juju environment is up & running

Then install with 

    ./bin/01-deploy.sh

Then... wait for a few minutes! 

## Adding users

If you are a team and you have copies the SSH keys in ./var/ssh, do 


    ./bin/10-add-users.sh

their keys will installed on the different machines so they can connect to them. Don't forget to share juju access details with them. 

## Adding data

If you have a dataset available that you want to push to HDFS, you can configure it in the project.conf file. Then

    ./bin/11-push-data.sh

will upload the .tgz, extract it and push to HDFS. 

## Using the stack
### Gathering IP addresses 

When you run ```juju status --format tabular``` you get a good overview of what's going on in your cluster: 

```
[Services]          
NAME                STATUS  EXPOSED CHARM                                  
apache-spark        waiting false   cs:trusty/apache-spark-7               
cuda                        false   local:trusty/cuda-2                    
datafellas-notebook         true    local:trusty/datafellas-notebook-0     
dl4j                        false   local:trusty/deeplearning4j-2          
juju-gui            unknown true    cs:trusty/juju-gui-54                  
mesos-master        active  true    local:trusty/mesos-master-0            
mesos-slave                 false   local:trusty/mesos-slave-0             
namenode            active  false   cs:trusty/apache-hadoop-namenode-1     
nids                        false   local:trusty/nids-2                    
plugin                      false   cs:trusty/apache-hadoop-plugin-13      
slave               active  false   cs:trusty/apache-hadoop-slave-1        
spark-standalone    active  false   cs:~bigdata-dev/trusty/apache-spark-73 

[Units]                 
ID                      WORKLOAD-STATE AGENT-STATE VERSION MACHINE PORTS                       PUBLIC-ADDRESS MESSAGE                              
apache-spark/0          waiting        idle        1.25.5  6                                   I.P.AD.RS    Waiting for Plugin to become ready   
  plugin/0              active         idle        1.25.5                                      I.P.AD.RS    Ready (HDFS)                         
juju-gui/0              unknown        idle        1.25.5  0       80/tcp,443/tcp              I.P.AD.RS                                       
mesos-master/0          active         idle        1.25.5  5       5050/tcp,8080/tcp           I.P.AD.RS                                       
  datafellas-notebook/0 active         idle        1.25.5          9000/tcp                    I.P.AD.RS                                       
  dl4j/0                active         idle        1.25.5                                      I.P.AD.RS  dl4j installed and ready             
namenode/0              active         idle        1.25.5  1       50070/tcp                   I.P.AD.RS  Ready (3 DataNodes)                  
slave/0                 active         idle        1.25.5  2       50075/tcp                   I.P.AD.RS  Ready (DataNode)                     
  cuda/1                active         idle        1.25.5                                      I.P.AD.RS  CUDA drivers installed and available 
  mesos-slave/2         active         idle        1.25.5                                      I.P.AD.RS                                       
slave/1                 active         idle        1.25.5  3       50075/tcp                   I.P.AD.RS    Ready (DataNode)                     
  cuda/0                active         idle        1.25.5                                      I.P.AD.RS    CUDA drivers installed and available 
  mesos-slave/0         active         idle        1.25.5                                      I.P.AD.RS                                         
slave/2                 active         idle        1.25.5  4       50075/tcp                   I.P.AD.RS   Ready (DataNode)                     
  cuda/2                active         idle        1.25.5                                      I.P.AD.RS   CUDA drivers installed and available 
  mesos-slave/1         active         idle        1.25.5                                      I.P.AD.RS                                        
spark-standalone/3      active         idle        1.25.5  10      8000/tcp,8080/tcp,18080/tcp I.P.AD.RS   Ready (standalone - master)          
  cuda/3                active         idle        1.25.5                                      I.P.AD.RS   CUDA drivers installed and available 
  dl4j/1                active         idle        1.25.5                                      I.P.AD.RS   dl4j installed and ready             
  nids/0                active         idle        1.25.5                                      I.P.AD.RS   NIDS demo installed and ready         
```

A good practice is actually to keep a watcher on this via ```watch juju status --format tabular```

**Note**: Starting from Juju 2.0, this view is the default of ```juju status```

### Main training setup

The interesting services for this are 

* Mesos Master: Serving on port 5050
* Marathon: Serving on port 8080
* Spark Notebook: Serving on port 9000

By default these are unprotected. If you want to protect them, you can do ```juju unexpose mesos-master```, ```juju unexpose datafellas-notebook```

### Production Application (pre trained model)

The interesting services for this are 

* Spark Standalone: Serving on port 8080 and 18080
* Spark Application: Serving on port 8000 and 8001

# Example output
## Bootstrapping 

	./bin/00-bootstrap.sh

Will set up the environment, which essentially means setting up the cloud environment and installing the first machine. 

An example of logs from that would be : 

    Sourcing ./ods/bin/../etc/project.conf
    Sourcing ./ods/bin/../lib/00_bashlib.sh
    Sourcing ./ods/bin/../lib/dockerlib.sh
    Sourcing ./ods/bin/../lib/gcelib.sh
    Sourcing ./ods/bin/../lib/jujulib.sh
    [mar abr 5 23:06:38 CEST 2016] [deepstack] [local0.debug] : Validating dependencies
    [mar abr 5 23:06:40 CEST 2016] [deepstack] [local0.debug] : Successfully switched to dl
    [mar abr 5 23:13:21 CEST 2016] [deepstack] [local0.debug] : Succesfully bootstrapped dl
    [mar abr 5 23:13:42 CEST 2016] [deepstack] [local0.debug] : Successfully deployed juju-gui to machine-0
    [mar abr 5 23:13:44 CEST 2016] [deepstack] [local0.info] : Juju GUI now available on https://X.X.X.X with user admin:password
    [mar abr 5 23:13:44 CEST 2016] [deepstack] [local0.debug] : Bootstrapping process finished for dl. You can safely move to deployment.


## Deploying  

	./bin/01-deploy.sh

Will deploy the charms required for the project: 

* Hadoop (Master, 3x Slave, YARN Master)
* Spark 

Example logs: 

    Sourcing ./ods/bin/../etc/project.conf
    Sourcing ./ods/bin/../lib/00_bashlib.sh
    Sourcing ./ods/bin/../lib/dockerlib.sh
    Sourcing ./ods/bin/../lib/gcelib.sh
    Sourcing ./ods/bin/../lib/jujulib.sh
    [mar abr 5 23:14:05 CEST 2016] [deepstack] [local0.debug] : Validating dependencies
    [mar abr 5 23:14:07 CEST 2016] [deepstack] [local0.debug] : Successfully switched to dl
    [mar abr 5 23:14:07 CEST 2016] [deepstack] [local0.info] : Using GPU for this deployment
    [mar abr 5 23:14:07 CEST 2016] [deepstack] [local0.info] : Using constraints instance-type=g2.2xlarge root-disk=64G for this deployment
    [mar abr 5 23:14:26 CEST 2016] [deepstack] [local0.debug] : Successfully deployed namenode
    [mar abr 5 23:14:31 CEST 2016] [deepstack] [local0.debug] : Successfully set constraints "mem=4G cpu-cores=2 root-disk=32G" for namenode
    [mar abr 5 23:14:59 CEST 2016] [deepstack] [local0.debug] : Successfully deployed resourcemanager
    [mar abr 5 23:15:04 CEST 2016] [deepstack] [local0.debug] : Successfully set constraints "mem=2G cpu-cores=2" for resourcemanager
    [mar abr 5 23:15:29 CEST 2016] [deepstack] [local0.debug] : Successfully deployed slave
    [mar abr 5 23:15:35 CEST 2016] [deepstack] [local0.debug] : Successfully set constraints "instance-type=g2.2xlarge root-disk=64G" for slave
    [mar abr 5 23:16:00 CEST 2016] [deepstack] [local0.debug] : Successfully added 2 units of slave
    [mar abr 5 23:16:10 CEST 2016] [deepstack] [local0.debug] : Successfully deployed plugin
    [mar abr 5 23:16:13 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between resourcemanager and namenode
    [mar abr 5 23:16:15 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between slave and resourcemanager
    [mar abr 5 23:16:19 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between slave and namenode
    [mar abr 5 23:16:22 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between plugin and resourcemanager
    [mar abr 5 23:16:24 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between plugin and namenode
    [mar abr 5 23:16:43 CEST 2016] [deepstack] [local0.debug] : Successfully deployed spark
    [mar abr 5 23:16:47 CEST 2016] [deepstack] [local0.debug] : Successfully set constraints "mem=2G cpu-cores=2" for spark
    [mar abr 5 23:16:49 CEST 2016] [deepstack] [local0.debug] : Successfully created relation between spark and plugin


## Resetting 

	./bin/50-reset.sh

Will reset the environment but keep it alive

## Clean

	./bin/99-cleanup.sh

Will completely rip of the environment and delete local files

