# wp-backup

_Create database and userdata backups for staggered Wordpress releases._

---

## Installation

### Via GitHub

Check the "Assets" field [in the latest GitHub release](https://github.com/gebruederheitz/wp-backup/releases) to 
download the binaries.

### Via ghdev

For now, the built binaries will also be hosted on ghdev.de. This is probably not permanent and is not guaranteed to 
be up to date.
 - https://cdn.ghdev.de/wp-backup/wp-backup
 - https://cdn.ghdev.de/wp-backup/wp-backup-bundle
 - https://cdn.ghdev.de/wp-backup/wp-backup-bundle.gz
 - https://cdn.ghdev.de/wp-backup/wp-backup-pack.tar.gz

### Via NPM

Use NPM to install this package for direct usage:

```shell
$> npm i @gebruederheitz/wp-backup
# Then you can use
$> npx wp-backup
$> npx wp-backup-bundle
# or
$> ./node_modules/.bin/wp-backup
$> ./node_modules/.bin/wp-backup-bundle
```

## Usage

The application comes in three variations:
 - "vanilla" `wp-backup`: The backup application only. Requires `wp-cli` on the target system.
 - "bundled" `wp-backup-bundle`: Contains `wp-cli` compiled into the binary and is thus easier to use, but a lot 
   larger in file size.
 - "packaged" `wp-backup-pack.tar.gz`: A gzipped tarball containing the vanilla script and the wp-cli PHAR archive.

In each case, the `-h` flag will show you a list of available options and
some usage information. You can however just execute the program without any
options and have the wizard guide you through creating or restoring your
Wodpress backups.

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

 - GNU coreutils
 - mysqldump
 - php (CLI binary) or php-wrapper

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
