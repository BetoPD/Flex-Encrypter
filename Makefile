encrypt: encrypter.l
	flex -o encrypter.cpp encrypter.l
	g++ -g -o bin/encrypter encrypter.cpp -ll

debug: encrypter.l
	flex -Ld -o encrypter.cpp encrypter.l
	g++ -g -o bin/encrypter encrypter.cpp -ll

clean:
	rm -f encrypter.cpp bin/encrypter

