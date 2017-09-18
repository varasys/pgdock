# pgdock

pgdock is a bash script to:  
- start docker containers running postgresql  
- proxy commands from the host the the containers  
- build and run a docker image to run pgadmin4

## Installation

To install pgdock, download it from github and run the install command with the installation directory as an argument.

```bash
git clone https://github.com/varasys/pgdock
./pgdock/bin/pgdock install /usr/local/bin
```

The installation command above will copy the pgdock script to the installation directory and create the following symlinks in the installation directory pointing to the pgdock script:

- pg_archivecleanup
- pg_basebackup
- pg_config
- pg_controldata
- pg_ctl
- pg_dump
- pg_dumpall
- pg_isready
- pg_receivexlog
- pg_recvlogical
- pg_resetxlog
- pg_restore
- pg_rewind
- pg_standby
- pg_test_fsync
- pg_test_timing
- pg_upgrade
- pg_xlogdump
- pgadmin4
- postgresql
- psql

## Usage

The `pgdock` script should only be run directly for installing (or uninstalling) the script and symlinks.

During normal operation the script should be called using one of the symlinks, and the behavior of the script will depend on which symlink was used to call it (the script inspects the $0 argument to see what name it was called as).

### postgres

To run a new postgresql container:

```bash
postgres [-d] [-a docker_args] [-s secret] [-u user] [-p host_port] [env | --] [pg_options]
postgres -c [-a docker_args] [env]
postgres ( -h | -v )
```

Where:

- env is an optional file, or directory containing a file called Environment, with environment variables to configure the cluster  
- -a ) arguments to pass through to docker (as a single string)  
- -c ) run debug console (load shell instead of postgres)  
- -d ) run in background (daemonize)  
- -h ) show this help  
- -p host_port) expose postgres on host port_no (ie. -p "0.0.0.0:5050")  
- -s secret) initial password for new database  
- -u user ) run database as user (must be in container password file)  
- -v ) print the version to stdout  

When run without an Environment file the container name will be
					    "${PGD_IMAGE}-${PGD_IMAGE_TAG//./_}", data will be persisted in a docker volume
					    called "${PGD_IMAGE}-${PGD_IMAGE_TAG//./_}", and no host ports will be exposed.

### pgadmin4

To run pgadmin4 (including building the docker image if it does not exist):

```bash
pgadmin4 [-a docker_args] [-bdr] [-p host_port] [env]
pgadmin4 ( -h | -v )
```

Where:  

- -a docker_args ) pass "docker_args" string to docker
- -b ) build docker image (even if it exists)
- -c ) run debug console (load shell instead of pgadmin4)
- -d ) run in background (daemonize)
- -h ) print this help to stdout
- -p host_port ) expose pgadmin4 on host port "host_port" (ie. -p "0.0.0.0:5050")
- -r ) reset pgadmin4 data (delete pgadmin4 docker volume)
- -v ) print the version (${version}) to stdout

The script automatically builds a docker image for pgadmin4 if it doesn't
already exist. Base images and packages are downloaded as needed.
On the first run the user will be prompted for an admin user
name and password. That information and other configuration
is persisted in a docker volume called ${PGA_CONTAINER}. Use the
-r flag to delete/reset this volume on start.

### Utilities

The other commands work from the host exactly the same way they work inside the container, except that when called from the host, the second argument is the container name as shown in the following examples:

```bash
# EXAMPLES FOR RUNNING POSTGRES UTILITIES

psql my_db                # run psql on my_db
psql my_db -l             # run spql on my_db and list databases
# copy database cluster from "my_db" container to "your_db" container
pg_dumpall my_db | psql your_db
```