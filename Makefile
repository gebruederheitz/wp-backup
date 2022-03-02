compile:
	@mkdir -p build
	@dcli pack
	@dart compile exe -o build/wp-backup dist/wp-backup.dart
	@dart compile exe -o build/wp-backup-bundle dist/wp-backup-with-wp-cli.dart

get-latest-wp-cli:
	@mkdir -p resource
	@curl -o ./resource/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

package: compile get-latest-wp-cli
	@rm -f ./build/wp-backup-pack.tar*
	@mkdir -p ./build/wp-backup-pack
	@cp ./build/wp-backup ./build/wp-backup-pack/wp-backup
	@cp ./resource/wp ./build/wp-backup-pack/wp
	@tar --create --file ./build/wp-backup-pack.tar build/wp-backup-pack/*
	@gzip -9 ./build/wp-backup-pack.tar
	@gzip -9k ./build/wp-backup-bundle
	@rm -rf ./build/wp-backup-pack/

compile-only-bundle:
	@mkdir -p build
	@dart compile exe -o build/wp-backup-bundle dist/wp-backup-with-wp-cli.dart
