all: ecu1 ecu2

ecu1: ecu1.cpp
	g++ -o ecu1 ecu1.cpp

ecu2: ecu2.cpp
	g++ -o ecu2 ecu2.cpp

clean:
	rm -f ecu1 ecu2
