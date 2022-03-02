# wp-backup

_Create database and userdata backups for staggered Wordpress releases._

---

## Installation

Use NPM to install this package:

```shell
$> npm i @gebruederheitz/wp-backup
```

## Usage

### Dependencies

 - GNU coreutils
 - zip
 - gzip
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
# Pack & Compile everything
$> make package
```
