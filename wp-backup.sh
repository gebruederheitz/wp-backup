#! /bin/bash

VERSION="1.0.0-beta.1.1"
DATE_SLUG=$(date +%Y-%m-%d-%H-%M)

PROJECT_ROOT_DIR="$HOME"
OPERATION="all"
BACKUP_USER=""
VERBOSE=""
USE_PHP_WRAPPER=""
WP_BIN="wp"
PHP_BIN=""

backup_db() {
	verbose "Creating database backup..."

	local filename="$PROJECT_ROOT_DIR/backup/db-${DATE_SLUG}.mysql"
	local export_command="db export $filename"

	pushd "$PROJECT_ROOT_DIR/public" || exit 2

	if [ -n "$USE_PHP_WRAPPER" ]; then
		userdo $PHP_BIN $WP_BIN $export_command
	else
		userdo $WP_BIN export_command
	fi

	popd || exit 2

	verbose "Database exported. Compressing..."
	userdo gzip -9 "$filename"

	verbose "Done: Created database backup at $filename.gz."
	info "Database backup created."
}

backup_userdata() {
	verbose "Backing up userdata directory..."
	info "Creating ZIP archive of userdata. This might take a while."

	local filename="$PROJECT_ROOT_DIR/backup/userdata-${DATE_SLUG}.zip"
	local zip_options="-9 -r"

	if [ -z "$VERBOSE" ]; then
		# Quiet zip output, unless in verbose mode
		zip_options="$zip_options -q -dg"
	else
		zip_options="$zip_options -dc"
	fi

	userdo zip $zip_options "$filename" "$PROJECT_ROOT_DIR/userdata"

	verbose "Done: Created userdata backup at $filename."
	info "Userdata backup created."
}

test_directory() {
	if [ ! -d "$PROJECT_ROOT_DIR" ]; then
		error_and_exit "Invalid directory! Please check the parameter passed via the '-f' option.";
	fi

	if
		[ ! -d "$PROJECT_ROOT_DIR/userdata" ] ||
			[ ! -d "$PROJECT_ROOT_DIR/backup" ]
		[ ! -d "$PROJECT_ROOT_DIR/public" ]
	then
		error_and_exit "Not a project directory – make sure the target directory is a \"staggered release\" Wordpress installation containing \"userdata\", \"backup\" and \"release\" subdirectories."
	fi
}

# Execute the commands passed as the current $USER
userdo() {
	if [ -n "$BACKUP_USER" ]; then
		sudo -su "$BACKUP_USER" "$@"
	else
		"$@"
	fi
}

# Print an information message in yellow on blue
info() {
	local content="${1}"
	echo -e "\e[1;33;4;44m${content}\e[0m"
}

# Print an error message in red on black
error() {
	local content="${1}"
	echo -e "\e[31;40mFatal Error: ${content}\e[0m"
}

verbose() {
	if [ -n "$VERBOSE" ]; then
		local content="${1}"
		echo -e "\e[35m${content}\e[0m"
	fi
}

error_and_exit() {
	error "$1"
	exit 2
}

version() {
	echo
	info "/gebrüderheitz Wordpress deployments backup utility."
	info "Version v$VERSION"
	echo
}

Help() {
	version
	echo "Create backups for the database and userdata (plugins, languages, uploads) of a Wordpress instance."
	echo
	echo "Usage: backup [-a|d|u] [-h|v] [-V] [-p] [-w wp_cli_path] [-f directory] [-s user]"
	echo "Options:"
	echo "  -h    Show this help and exit."
	echo "  -v    Display version and exit."
	echo
	echo "  -a        All: back up both db and userdata (default)"
	echo "  -d        Database: Back up the database only"
	echo "  -u        Userdata: Back up the userdata directory only"
	echo -e "  -f \e[4mpath\e[0m   Project root directory: The directory containing releases/, backup/ and userdata/. Defaults to \$HOME."
	echo -e "  -s \e[4muser\e[0m   (sudo) User to execute commands under. Defaults to the current user."
	echo "  -p        Use php-wrapper for calls to WP-CLI during database backup."
	echo -e "  -p \e[4mpath\e[0m   Path to the PHP binary to use for calling WP-CLI during database backup."
	echo -e "  -w \e[4mpath\e[0m   Path to WP-CLI binary (phar). Defaults to \"which wp\"."
	echo "  -V        Enable verbose output."
	echo
	echo "Backups will target \$DIR/userdata and the WP instance at \$DIR/public. They will be zipped and written to \$DIR/backup/."
	echo
}

parse_options() {
	# Get the options
	while getopts ":hadvVp:w:f:s:u:" option; do
		case $option in
		h) # display Help
			Help
			exit
			;;
		a) # "all" - backup both db and userdata directory
			OPERATION="all" ;;
		d) # "database-only"
			OPERATION="db" ;;
		u) # "userdata-only"
			OPERATION="userdata" ;;
		f) # "file" / directory target
			PROJECT_ROOT_DIR="$OPTARG" ;;
		s) # "sudo" user to operate as
			BACKUP_USER="$OPTARG" ;;
		p) # "php-wrapper" / "php-binary"
			USE_PHP_WRAPPER="true"
			if [ -z "$OPTARG" ]; then
				PHP_BIN="php-wrapper"
				if [ ! -x "$(which php-wrapper)" ]; then
					error_and_exit "php-wrapper executable could not be found."
				fi
			else
				PHP_BIN="$OPTARG"
				if [ ! -x "$PHP_BIN" ]; then
					error_and_exit "php binary could not be found."
				fi
			fi
			;;
		w) # "wp-cli"
			if [ ! -x "$OPTARG" ]; then
				error_and_exit "Invalid wp-cli provided. Please make sure it exists and is executable."
			fi
			WP_BIN="$OPTARG" ;;
		V) # "verbose"
			VERBOSE="true" ;;
		v) # "version"
			version
			exit
			;;
		\?) # Invalid option
			error_and_exit "Invalid option. Try \"-h\" for help." ;;
		esac
	done
}

main() {
	parse_options "$@"

	PROJECT_ROOT_DIR=$(realpath "$PROJECT_ROOT_DIR")
	verbose "Testing directory $PROJECT_ROOT_DIR..."
	test_directory

	verbose "Starting Wordpress backup with user $BACKUP_USER in directory $PROJECT_ROOT_DIR."

	if [ $OPERATION = 'all' ] || [ $OPERATION = 'db' ]; then
		backup_db
	fi

	if [ $OPERATION = 'all' ] || [ $OPERATION = 'userdata' ]; then
		backup_userdata
	fi

	verbose "Done."
}

main "$@"
