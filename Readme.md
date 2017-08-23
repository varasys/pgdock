# pgdock

pgdock is a bash script to start and stop docker containers running the official postgresql docker image, and a set of links that can be installed on the docker host machine to forward docker commands to the postgres servers running in the various containers. Its design is very much inspired by the way multi-cluster postgresql installations are handled on ubuntu.

Use git to download pgdock:

    git clone github.com/varasys/pgdock

pgdock was created to provide a streamlined command line interface to manage running multiple postgresql containers. The following examples show how to create a new database (my_db) and manipulate it.



	# EXAMPLES FOR CONTROLLING SERVER CONTAINER
	
	./pgdock install /usr/local/bin  # install pgdock
	pgdock start ./my_db             # initialize new db (daemon)
	pgdock debug ./my_db             # initialize new db (foreground)
	pgdock stop my_db                # stop server
	pgdock start ./my_db             # start server (daemon)
	pgdock attach my_db              # attach console to running server
	pgdock reload my_db              # reload server configuration
	pgdock restart by_db             # restart server container
	pgdock debug ./my_db             # start server (foreground)
	pgdock console ./my_db           # debug the server (foreground)

pgdock also allows piping the following postgres commands to/from the host terminal:

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
- psql

These commands work from the host exactly the same way they work inside the container, except that when called from the host, the second argument is the container name as shown in the following examples:

    # EXAMPLES FOR RUNNING POSTGRES UTILITIES
    
    psql my_db                # run psql on my_db
    psql my_db -l             # run spql on my_db and list databases
    # copy database cluster from "my_db" container to "your_db" container
    pg_dumpall my_db | psql your_db

pgdock was specifically written to promote standardization across all postgres uses, so it does not have any options other than the following which can be set as environment variables:

- HOSTPORT - change the host port that the server is exposed on (default=5432)
- PGIMAGE - change the postgresql docker image tag (default=postgresql:9.6.4-alpine)
- NAME - (optional) specify the container name (instead of using the root directory name)

## Directory Structure
pgdock requires a specific directory structure to run properly.

Each postgresql cluster should have a root directory `data_dir` with the following:

- Environment - an environment file that is sourced at the beginning of the pgdock script, and is used to set the host port and postgresql image, and optionally set the container name
- config - this directory will be mounted in the container at /etc/postgresql and should contain postgresql.conf, pg_hba.conf and pg_ident.conf files (see the config section)
- data - this is the postgresql data directory (including the pg_xlog directory)

The "data" directory will be created automatically if it does not exist. The "Environment" file and "config" directory are not automatically created, but can be created by cloning the pgdata git repository.

In this document `data_dir` means this top level directory (and not the `data` subdirectory with the postgresql data).

Where `data_dir` is required as an argument to `pgdock` it should be an absolute path starting with a slash, or a relative path starting with a dot, or a relative directory ending with a slash. pgdock looks for the presence of either a dot or a slash to determine whether a `data_dir` was provided or a container name.

Where `container` is required as an argument to `pgdock` it can either be the name of the running container, or a path to the `data_dir`. If a path is provide (ie. it starts with a dot or includes a slash), and the path is to a directory containing a file called "Environment" that file will be sourced and the "NAME" environment variable is used as the container name. If no "Environment" file is found, or the "Environment" file does not define the "NAME" variable, the name of the `data_dir` is used as the container name.

## Configuration
pgdock uses the "Environment" file in the "data_dir" to determine which host port to expose the database through, which postgresql image to use, and optionally set the docker container name used to run the server.

pgdock passes the `--config_file=/etc/postgresql/postgresql.conf` command line option when starting postgres. The path to this config file on the host is "data_dir/config/postgresql.conf" and the default config in the git repository includes "include_dir = 'conf.d'", so all files in the "config/conf.d" that end in ".conf" will also be included in the configuration.


## How it Works
Each time a bash script is executed, the command used to execute the script is set as environment variable `$0` within the script. If a symlink (ie. `ls -s pg_dump pgdata`) is created to the pgdock script with a different name (ie. `pg_dump`), the name passed in the `$0` variable will be the name of the symlink (ie. `pg_dump` instead of `pgdock`).

When called as `pgdock install target_dir` the script will copy itself to the `target_dir` directory and creates a symlink in `target_dir` to the `pgdock` script for each postgresql utility program (ie. `pg_dump`, `psql`, etc.).

When run, the pgdock script inspects variable `$0` and if it is called as `pgdock` it operates on the container, but if it is called as something else it executes the command (whatever is in the `$0` variable) within the container with any additional arguments supplied on the command line. It attaches to the container as a terminal so data can be piped into or out of the container (ie. `pg_dumpall my_db | psql your_db` to pipe a backup from my_db to restore in your_db using `psql`).

Before each command is run, the full docker command is echoed to the terminal for information.

## Starting a Container
pgdock uses the official postgres docker images with no modifications (so there is no Docker file). The entrypoint in the container runs a script called "docker-entrypoint.sh" which runs `initdb` to initialize a new database cluster if the `data_dir/data` directory is empty, or runs postgres if the data directory is not empty.

Running pgdock with the `console` sub-command starts a container with the port exposed and volumes mounted, but runs `bash --login` instead of the "docker-entrypoint.sh" script. This can be useful for troubleshooting.

## About Volumes
pgdock does not use docker volumes, and bind mounts directories directly instead (ie. the "data" and "config" directories). This so that the postgresql data is not obfuscated behind dockers volume storage drivers and can be backed-up directly.