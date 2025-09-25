all: build/ecu1 build/ecu2

build/ecu1: ecu1.cpp
	mkdir -p build
	g++ -o build/ecu1 ecu1.cpp

build/ecu2: ecu2.cpp
	mkdir -p build
	g++ -o build/ecu2 ecu2.cpp

clean:
	rm -f build/ecu1 build/ecu2
