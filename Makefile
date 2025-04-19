# encrypt: encrypter.l
# 	# flex encrypter.l
# 	g++ -std=c++20 -Wall -g -o bin/encrypter encrypter.cpp 
encrypt: encrypter.l
	flex -o encrypter.cpp encrypter.l
	g++ -std=c++20 -Wall -g -o bin/encrypter encrypter.cpp 

debug: encrypter.l
	flex -Ld -o encrypter.l
	g++ -std=c++20 -g -o bin/encrypter encrypter.cpp -ll

clean:
	rm -rf bin/* encrypter.cpp


