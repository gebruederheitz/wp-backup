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

# Use the local configuration file for a quick pre-configured backup
$> wp-backup -c
```

### Dependencies

 - GNU coreutils (`readlink`, `whoami`, `realpath`)
 - mysqldump


### Configuration

In essence you can use `wp-backup` in three ways: The easiest to get started is to simply run the application without 
any parameters and let the wizard guide you through the process. The only option you can not set through the wizard is
`-v`/ `--verbose`.

Taking a look at the command line options by running `wp-backup -h`, you can skip the wizard (in part or completely) by
providing any of these options. Let's say you know you want to _create_ a backup (not restore one), and you only want
a database backup (not a userdata one). But you can not be bothered to look through all the available options and
decide which ones you might also need: You can just run `wp-backup backup -D`. Now the wizard will skip the questions
about what mode to use and which operation to perform and only ask questions that might still be relevant.
But you might just as well know exactly that you want a full backup created under the user `wpuser` for the WP instance
at `/home/wpuser/website` with the tag `quick-fallback-before-v2.0` – in this case the `-n` or `--no-interaction` flag
is your friend, as it will skip the wizard completely (and apply sensible defaults to any settings you haven't 
provided). The result might look like this:

```shell
$> wp-backup backup-an -u wpuser -d /home/wpuser/website -t "quick fallback before v2.0"
```

This sort of setup is ideal for CI environments before deployments as well.

The third way, particularly useful for regularly reoccurring backups, is to create a configuration file. 

#### YAML configuration

This file has to be called `.wp-backup.yaml` and must contain a valid YAML document. Here's an example structure 
outlining all the valid settings:

```yaml
projectDir: /path/to/project   # Analogous to -d / --directory. Default current working directory.
operation: all                 # [all|database|userdata], analogous to -o / --operation. Default 'all' when 
                               # --no-interaction or "wizard: false" are set.
verbose: true                  # Whether to enable verbose output, analogous to -V / --verbose. Default false.
backupUser: whoami             # The user to perform system calls under. Analogous to -u / --user. Default current user.
wizard: false                  # A toggle that allows you to always skip the wizard with this file when set 
                               # to "false". Default true.
backupBeforeRestore: true      # Always create a backup before restoring one. Analogous to -b / --backup-before. 
                               # Default false.
askForTag: false               # Default true. Setting this to "false" will always skip the question about whether to
                               # set a tag / comment in the wizard, keeping the focus on fewer, possibly more important
                               # questions. Default true.
db: mysql://user:pass@host     # See "Database config" below. Defaults to reading dotenv. Accepts either a "database 
                               # URL" or a map of setting keys and values.
```

Passing the `-c` / `--config` flag will make the application look for `.wp-backup.yaml` in the current working 
directory. You can also pass the path to a specific file outside the cwd via the `-C` / `--config-file` option:

```shell
$> wp-backup restore -C ./conf/.wp-backup.weekly.yaml
$> wp-backup --config-file=/etc/backup/wp-backup/daily.yaml

# Parameters set in the configuration file can we overridden by command line options:
$> wp-back backup -c --verbose --user=different_user
```

To make full use of the configuration file, `wp-backup` has a special syntax that allows you to create quick backups
based on that configuration: When no mode / command (i.e. `backup` or `restore`) is given and on of 
`-c|-C|--config|--config-file` is present, the mode will automatically be set to `backup`. Thus, with a configuration
file like the following:

```yaml
projectDir: /home/wpuser/website
backupUser: wpuser
wizard: false
operation: database
db: mysql://wpdb_u:h4xx0rZ@127.0.0.1:3306/wpdb
```

you can call `wp-backup -c` and achieve the same result as with

```shell
$> wp-backup backup -Dn -u wpuser -d /home/wpuser/website -x mysql://wpdb_u:h4xx0rZ@127.0.0.1:3306/wpdb
```

You can still use the configuration file in order to, for example, restore a backup:

```shell
# Will give you list of backups you might restore and restore it using the above
# settings for project directory, shell user, operation and database.
$> wp-backup restore -c
```

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

You may also explicitly configure the database connection, either using a ["database URL"](#db-url) on the command
line, or by adding a section to your [YAML configuration file](#yaml-configuration) like this:

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

You can also use the YAML config to provide a "database URL" (details below):

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
