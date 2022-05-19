# wp-backup

_Create database and userdata backups for staggered Wordpress releases._

---

## Installation

### Via GitHub

Check the "Assets" field [in the latest GitHub release](https://github.com/gebruederheitz/wp-backup/releases) to 
download the compiled binary for Linux x64.

### Via ghdev

For now, the built binary will also be hosted on ghdev.de. This is probably not permanent and is not guaranteed to 
be up to date.
 - https://cdn.ghdev.de/wp-backup/wp-backup

### Via NPM

Use NPM to install this package for direct usage:

```shell
$> npm i @gebruederheitz/wp-backup
# Then you can use
$> npx wp-backup
# or
$> ./node_modules/.bin/wp-backup
```

## Usage

This application is meant to be used with "staggered" Wordpress releases. It assumes the following project structure:

```
<project directory>
 |
 |-- backup/               # Where backups will be stored
 |-- configuration/        # Optional
 |   |-- .env              # Optional - DB config can be read from this
 |
 |-- (public/, releases/, ...)
 |-- userdata/             # This will be backed up when using -U or -a
 |   |-- uploads/
 |   |-- plugins/
 |   |-- languages/
 |   |-- ...
```

In this setup, the build releases are written to `releases/`, with the current release being symlinked from `public/`.
The `userdata/` directory's contents are them symlinked into each release, as these files are specific to the instance
and remain across releases.

`wp-backup` creates (and restores) two types of backup:
 - the database (using `mysqldump`, which must be present on the system)
 - the userdata directory (by zipping the entire directory content).

The `-h` flag will show you a list of available options and some usage information. You can however just execute the 
program without any options and have the wizard guide you through creating or restoring your Wodpress backups.

```shell
# Start the wizard
$> wp-backup

# Get help
$> wp-backup -h

# Provide some settings and have the wizard ask for the rest
$> wp-backup backup -d ~/projects/my-wp-site/htdocs

# Skip the wizard, don't ask questions: Run a backup of userdata & DB in the 
# current directory
$> wp-backup backup -na
```

### Dependencies

 - GNU coreutils (`readlink`, `whoami`, `realpath`)
 - mysqldump


### Configuration

#### Database config

There are three ways to configure the database connection used by mysql / mysqldump:
 - Using the dotenv file (default, file must be in `<project_dir>/configuration/.env`)
 - Using a custom YAML configuration (`.wp-backup.yaml`, either in the pwd when using `-c` or specified by 
   `-C /path/to/.wp-backup.yaml`)
 - Passing a "database URL" to `-x mysql://user:pass@host:port/database/prefix` (port, database name and table 
   prefix are optional and can be omitted – they will fall back to their defaults `3306 / wordpress / wp_`; 
   however in order to set a prefix the database name must be provided.)

##### Dotenv

The following fields are read from `configuration/.env`:

```dotenv
DB_NAME=database       # default "worpdress"
DB_USER=user
DB_PASSWORD=pass
DB_HOST=localhost      # default "127.0.0.1" so as not to accidentally use sockets
DB_TABLE_PREFIX=prefix # default "wp_"
DB_PORT=port           # default "3306"
```

Any value not set will fall back to its default; user and password are always required.


##### YAML

Pass the `-c` or `--config` flag to read the `.wp-backup.yaml` from the current working directory. With the option 
`-C <path>` or `--config-file=<path>` you can use a file in a different location.

```yaml
# .wp-backup.yaml
db:
  host: host
  user: user
  pass: pass
  port: port
  prefix: prefix
  database: database
```

Any value not set will fall back to its default (see above); user and password are always required.

You can also use the YAML config to provide a "database URL":

```yaml
db: mysql://user:pass@host:port/db/prefix
```


##### DB-URL

You can also provide a database URL string on the command line, overriding any settings read from dotenv or YAML:

```shell
# Create a database backup tagged "--testing-db-url-setup" without running the
# wizard for additional configuration on the database "db" on "host:port".
$> wp-backup backup -Dn -x mysql://user:pass@host:port/db/prefix -c "testing db url setup" 
```

Some parts of this URL-style string are optional:

```shell
# the mysql:// prefix is optional 
user:pass@host
# the username, password and hostname must always be provided
mysql://user:pass@host
# the port can be omitted
mysql://user:pass@host/db
# in order to supply a table prefix, the database name must be provided
mysql://user:pass@host/db/prefix
mysql://user:pass@host:port/db
```


## Development

### Dependencies

 - dart SDK >=2.10.0 <3.0.0
 - [dcli installed on the system](https://dcli.noojee.dev/getting-started)

#### Recommended
 - GNU Make or drop-in alternative
 - NodeJS 16.x (for publishing to NPM)

```shell
# Install dependencies
$> dart pub get
# Pack & Compile everything (recommended once)
$> make package
# Run through Dart runtime
$> dart dist/wp-backup.dart
```
