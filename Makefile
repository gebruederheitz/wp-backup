compile:
	@mkdir -p build
	@dcli pack
	@dart compile exe -o build/wp-backup dist/wp-backup.dart

clear:
	@rm -rf ./build/*

package: clear compile

release:
	. $$NVM_DIR/nvm.sh && nvm use \
	&& npm i \
	&& npm run release
