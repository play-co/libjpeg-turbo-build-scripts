# Get the gas-preprocessor
curl -O "http://sourceforge.net/p/libjpeg-turbo/code/HEAD/tree/gas-preprocessor/gas-preprocessor.pl?format=raw"
mv "gas-preprocessor.pl?format=raw" "gas-preprocessor.pl"
chmod +x gas-preprocessor.pl

# unzip the source
unzip libjpeg-turbo-code-1492-trunk.zip
mv libjpeg-turbo-code-1492-trunk src

echo "\n\tReady to build"
