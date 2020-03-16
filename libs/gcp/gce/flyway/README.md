# Flyway

**Flyway** is an open-source database migration tool. It strongly favors simplicity and convention over configuration.

It is based around just 7 basic commands: Migrate, Clean, Info, Validate, Undo, Baseline and Repair.

Migrations can be written in SQL (database-specific syntax (such as PL/SQL, T-SQL, ...) is supported) or Java (for advanced data transformations or dealing with LOBs).

It has a Command-line client. If you are on the JVM, we recommend using the Java API (also works on Android) for migrating the database on application startup. Alternatively, you can also use the Maven plugin or Gradle plugin.

And if that not enough, there are plugins available for Spring Boot, Dropwizard, Grails, Play, SBT, Ant, Griffon, Grunt, Ninja and more!

Supported databases are Oracle, SQL Server (including Amazon RDS and Azure SQL Database), DB2, MySQL (including Amazon RDS, Azure Database & Google Cloud SQL), Aurora MySQL, MariaDB, Percona XtraDB Cluster, PostgreSQL (including Amazon RDS, Azure Database, Google Cloud SQL & Heroku), Aurora PostgreSQL, Redshift, CockroachDB, SAP HANA, Sybase ASE, Informix, H2, HSQLDB, Derby, Snowflake, SQLite and Firebird.

For further references, please visit https://flywaydb.org/

## How to use Flyway in your project  

1. Create the folder flywaydb in your project's root directory  
2. Within flywaydb folder, add two files:  

`flyway.template` (This file will contain the required parameters for flyway to connect into the database)  
`flyway-vm.template` (This file will contain the VM zone and service account info required to create the flyway VM)  

**flyway-vm.template** file sample:  
```
--zone ${TF_VAR_zone}  
--service-account ${TF_VAR_sa_mail}  
```

**flyway.template** file sample:  
```
# JDBC connection containing IP address and database name
flyway.url=jdbc:postgresql://${CLOUDSQL_PRIVATE_ADDRESS}/${TF_VAR_cloudsql_db_name}  
# Database user name
flyway.user=${TF_VAR_cloudsql_adminname}  
# Database password
flyway.password=${CLOUDSQL_PASSWORD}  
# Database schema
flyway.schemas=nextier_vip  
# SQL location to be processed
flyway.locations=filesystem:${FLYWAY_VM_HOME}/sql  
```

## Application side 

On the application side, a deploy script must be created containing the following steps:  

```
# Importing the main lib
source $(dirname ${BASH_SOURCE[0]})/../devops-libs.sh

# Declare the application's files
FLYWAY_VM_TEMPLATE="${ROOTDIR}/flywaydb/flyway-vm.template"
FLYWAY_TEMPLATE="${ROOTDIR}/flywaydb/flyway.template"

# Import required libs
do.import gcp.gce gcp.sql gcp.gce.flyway utils.tokens utils.configs

# Get the Flyway home stored in the metadata
assign FLYWAY_VM_HOME=do.gcp.gce.getMetadataFromFile ${ROOTDIR}/scripts/devops-libs/gcp/gce/flyway/flyway-vm-metadata.template FLYWAY_VM_HOME

validateVars GCLOUD_PROJECT_ID TF_VAR_zone TF_VAR_cloudsql_db_name TF_VAR_cloudsql_adminname TF_VAR_sa_mail CLOUDSQL_PASSWORD FLYWAY_VM_HOME
exitOnError "There are required environment variables that are not yet declared"

# Getting the database Private IP Address for Flyway connection driver
assign CLOUDSQL_PRIVATE_ADDRESS=do.gcp.sql.getValueFromInstance ${GCLOUD_PROJECT_ID} ${TF_VAR_cloudsql_db_name} "PRIVATE_ADDRESS"

# Delete the VM in case it has been left behind 
do.gcp.gce.flyway.deleteVM ${GCLOUD_PROJECT_ID}

# Get the flyway-vm.template file and replace variables by final values
do.utils.tokens.replaceFromFileToFile ${FLYWAY_VM_TEMPLATE} ${FLYWAY_VM_TEMPLATE}
exitOnError "Fail to replace variables in '${FLYWAY_VM_TEMPLATE}'"

# Extracting the additional/custom parameters for the new VM
assign FLYWAY_VM_FQDN_PARAMETERS=do.utils.configs.getAllArgsFromFile ${FLYWAY_VM_TEMPLATE}

# Creating the Flyway VM
do.gcp.gce.flyway.createVM ${GCLOUD_PROJECT_ID} ${FLYWAY_VM_FQDN_PARAMETERS[@]}

# Replacing custom variables in the flyway.template and generating the final file as flyway.conf
do.utils.tokens.replaceFromFileToFile ${FLYWAY_TEMPLATE} ${ROOTDIR}/flywaydb/flyway.conf
exitOnError "Failed to replace variables in '${FLYWAY_TEMPLATE}'"

# Verifies and wait for the VM initialization. Expiration wait limit is 10 min
do.gcp.gce.flyway.waitInitialization ${GCLOUD_PROJECT_ID}

# Copies all required files from local to the VM
do.gcp.gce.flyway.copyFilesToVM ${GCLOUD_PROJECT_ID} ${ROOTDIR}/sql ${ROOTDIR}/scripts ${ROOTDIR}/flywaydb

# Triggers the flyway shell script remotely to perform the database actions 
do.gcp.gce.flyway.runFlywayRemote ${GCLOUD_PROJECT_ID}

# Removes the VM at the end of execution
do.gcp.gce.flyway.deleteVM ${GCLOUD_PROJECT_ID}
```

# Flyway and SQL Format 

## Naming  
In order to be picked up by Flyway, SQL migrations must comply with the following naming patterns:  

## Versioned Migrations  

Versioned Migration files cannot be incremented or modified. Once the file is deployed into the database and its version tracked by FlywayDB, it cannot be modified and re-executed otherwise there will be a hash version conflict.  
`V1.1__Add_new_table.sql`  

The file name consists of the following parts:  

**Prefix**: V for versioned (configurable), U for undo (configurable) and R for repeatable migrations (configurable)  
**Version**: Version with dots or underscores separate as many parts as you like (Not for repeatable migrations)  
**Separator**: __ (two underscores) (configurable)  
**Description**: Underscores or spaces separate the words  
**Suffix**: .sql (configurable)  

If there is a need of incrementing the same file, please create a new sql having a new version to amend the change.  

## Repeatable Migrations  

Repeatable Migrations have a description and a checksum, but no version. Instead of being run just once, they are (re-)applied every time their **checksum changes**.   

`R__Add_new_table.sql`   

For further details, please visit https://flywaydb.org/documentation/migrations
