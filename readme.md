# PubSub MongoDB Streaming Datapipeline
This project is a pipeline that streams data from MongoDB to Google Cloud PubSub. It uses a custom Dataflow job to process and transform the data in real-time.

## Purpose 
The purpose of this project is to provide a simple and efficient way to stream data from a MongoDB database to Google Cloud PubSub, allowing for real-time processing and analysis of the data.

## Repo Content
This repository contains the following files:

* README.md: this file
* main.py: the main file that sets up and runs the custom Dataflow job
* main.tf: the Terraform configuration file for deploying the necessary infrastructure
* variables.tf: the Terraform variable file
* streaming_data_gen.py: a Python script for generating sample data to stream
* requirements.txt: a file containing the necessary Python dependencies
* streaming_test.charts: This file contains pre-created charts for MongoDB Charts that can be imported directly from the MongoDB Charts interface.

## .env File

Before running the project, you will need to create a .env file with the following variables:

```bash
export PROJECT_ID=<your_project_id>
export MONGODB_USERNAME=<mongodb database username>
export MONGODB_PASSWORD=<mongodb database password>
export PUBLIC_KEY=<atlas public key >
export PRIVATE_KEY=<atlas private key>
export TOPIC_NAME=<google cloud pubsub topic name>
```

## Activate Cloud Services

To use the necessary Cloud services, you will need to enable the following APIs:

* compute.googleapis.com
* containerregistry.googleapis.com
* pubsub.googleapis.com
* cloudbuild.googleapis.com
* dataflow.googleapis.com

You can enable these APIs by running the following command:
```bash
gcloud config set project <your-cloud-project-id>
gcloud services enable compute.googleapis.com containerregistry.googleapis.com pubsub.googleapis.com cloudbuild.googleapis.com dataflow.googleapis.com
```

## Deploy Infrastructure
To deploy the necessary infrastructure, you can use Terraform. First, run the following command to initialize Terraform:

```bash
terraform init
```
Then, run the following command to generate an execution plan:
```bash
terraform plan
```
If the plan looks correct, run the following command to apply the changes:
```bash
terraform apply
```
Finally, run the following command to output the Terraform state to a JSON file:
```bash
terraform output -json > terraform_output.json
```

## Export URIS
To export URIs, use the following commands in the terminal:
```bash
export MONGODB_URI_TEST=<from terraform output MONGODB_URI_FOR_TEST>
export MONGODB_URI_PRIVATE=<from terraform output MONGODB_URI_FOR_PRIVATE>
```
Replace <value from terraform output MONGODB_URI_FOR_TEST> and <value from terraform output MONGODB_URI_FOR_PRIVATE> with the corresponding values obtained from the Terraform output.

## Create Virtual Environment
Create a new virtual environment with the following command:
```bash
virtualenv mongo_dataflow
source mongo_dataflow/bin/activate
```
## Install Dependencies
To install the necessary Python dependencies, run the following command:
```bash
pip3 install -r requirements.txt
```

## Generate Streaming Events
To generate sample data to stream, run the following command:
```bash
python3 streamig_data_gen.py
```
## TEST Job or Peering Job
* For DirectRunner (TEST=True) jobs, you need to allow your IP address in the IP access list for your MongoDB database. Additionally, you must select the standard connection URI for your MongoDB database.
* For DataflowRunner jobs, you need to select the MongoDB URI for a private IP address for peering that can be used for peering with your Dataflow network. Make sure to whitelist this IP address in your MongoDB IP access list to allow connections from your Dataflow job region.
Note: We are using Terraform to manage infrastructure, it will automatically create the necessary permissions for project. Simply define TEST=True or TEST=False in main.py code.

## Start Custom Dataflow Job
Finally, start the custom Dataflow job with the following command:
```bash
python3 main.py
```

## Verifying Inserted Data
* To ensure that your MongoDB data has been written correctly, navigate to your database and collection, and check the inserted documents using the MongoDB console.

* If you want to visualize your MongoDB data using charts, you can import the streaming_test.charts file from the MongoDB console charts. This will allow you to easily create a dashboard for your MongoDB charts.

## Delete Infrastructure
To delete the infrastructure, you must first cancel the dataflow job and the treamig_data_gen.py process. Afterward, you can use the terraform destroy command. Please note that you will also need to manually delete your Google Cloud project.

To cancel the dataflow job and treamig_data_gen.py process, follow these steps:

* In the terminal window where treamig_data_gen.py is running, press Ctrl + C to stop the process.
* In the Dataflow console, locate the running job and click the 'Cancel' button to stop the job.
Once the dataflow job and treamig_data_gen.py process are cancelled, you can run the following command to delete the infrastructure:
```bash
terraform destroy
```
Please keep in mind that this will delete all resources that were created using the Terraform script. You will be prompted to confirm the destruction of the infrastructure.

After you have successfully run the terraform destroy command, you will need to manually delete your Google Cloud project. This can be done by going to the Google Cloud console and selecting the project you want to delete. Then, click on the 'Delete' button and follow the prompts to delete the project.

## Checks for problems 

* User permissions: readWriteAnyDatabase@admin
* Connection uris
* Ip cidr range for mongo ip access list
* Note: Top 3 arranged by Terraform, it will automatically create the necessary permissions for project.
* When terraform destroy  if have problem with atlas project deletion you can check charts if your project have
  - In project dashboard click on three dot icon which is left of delete icon.
  - Click on "Visit Project Settings"
  - Scroll down to the bottom
  - You will see an option "Delete Charts" click on red Delete button
  - Come back to project dashboard and now you can delete it without any error

## Here are some things to check for problems and deleting project with terraform destroy:

* Make sure you have the necessary user permissions (readWriteAnyDatabase@admin).
* Check the connection URIs to ensure they are correct.
* Verify that the IP CIDR range for Mongo IP access is properly configured.
* If you encounter any issues while trying to delete the Atlas project with Terraform, try the following steps:
  * In the project dashboard, click on the three-dot icon to the left of the delete icon.
  * Select "Visit Project Settings."
  * Scroll down to the bottom of the page.
  * Click on the "Delete Charts" option and then click on the red "Delete" button.
  * Return to the project dashboard and try to delete the project again. This time, it should work without any errors.

## Infrastructure and Terraform

* The main.tf file contains the Terraform configuration code that defines and manages the resources to be deployed to the infrastructure environment.
* The required_providers block in the main.tf file specifies the providers that Terraform needs to use in order to create the infrastructure. In this case, the Google Cloud Platform and MongoDB Atlas providers are required.
* The provider blocks in the main.tf file specify the configurations for each provider that is used in the Terraform configuration code. The google provider block specifies the Google Cloud Platform project, region and zone, and the mongodbatlas provider block specifies the MongoDB Atlas public and private keys.
* The data blocks in the main.tf file retrieve data from existing resources in the Google Cloud Platform infrastructure. In this case, the google_project and google_compute_network data blocks retrieve information about the current project and default network respectively.
* The resource blocks in the main.tf file create new resources in the Google Cloud Platform and MongoDB Atlas infrastructure. These resources include a firewall rule for the MongoDB port, a Google Cloud Storage bucket, a Pub/Sub topic and subscription, a MongoDB Atlas project, network container, network peering and a MongoDB Atlas cluster.
* The output block in the main.tf file defines the outputs of the Terraform configuration code, which can be used by other applications or scripts. In this case, it includes the GCP project ID, database name, collection name, database username and password.
* The variables.tf file contains the input variables that are used by the Terraform configuration code. These variables include the GCP project ID, region, zone, MongoDB public and private keys, MongoDB Atlas project name and organization ID, MongoDB Atlas cluster name, size and database user details.
* The resource "google_project_iam_member" block in the main.tf file grants the Cloud Build service account and the Compute Engine default service account permission to create objects in the Cloud Storage bucket.
* The resource "google_compute_firewall" "mongodb" block in the main.tf file creates a firewall rule to allow incoming traffic on port 27017 for the MongoDB cluster.
* The resource "mongodbatlas_network_peering" "test" block in the main.tf file creates the network peering connection between the Google Cloud Platform and MongoDB Atlas infrastructure, which allows secure communication between the two.
* The resource "google_compute_network_peering" "peering" block in the main.tf file creates the Google Cloud Platform network peering, which enables communication between the Google Cloud Platform and MongoDB Atlas resources.
* The resource "mongodbatlas_cluster" "mongodb_cluster" block in the main.tf file creates the MongoDB Atlas cluster with a specified size and region, and associates it with the project and network peering connection.
* The resource "mongodbatlas_database_user" "mongodb_cluster" block in the main.tf file creates a database user with read and write privileges for the specified database.
* The data "mongodbatlas_cluster" "mongodb_cluster" block in the main.tf file retrieves information about the MongoDB Atlas cluster created in a previous step.
* The resource "mongodbatlas_project_ip_access_list" "test" block in the main.tf file adds an IP address to the MongoDB Atlas project's IP access list to enable remote access to the database.

## Future Development Possibilities as Architecture Development
This project could be expanded in a number of ways, such as adding support for additional databases or adding more advanced processing and analysis capabilities. Additionally, the infrastructure could be further optimized for performance and scalability etc.