# encrypt: encrypter.l
# 	# flex encrypter.l
# 	g++ -std=c++20 -Wall -g -o bin/encrypter encrypter.cpp 
encrypt: encrypter.l
	flex encrypter.l
	g++ -std=c++20 -Wall -fdiagnostics-color=always -I.\include -L.\lib -g -o bin/encrypter encrypter.cpp -lfl

debug: encrypter.l
	flex -Ld -o encrypter.l
	g++ -std=c++20 -g -o bin/encrypter encrypter.cpp -ll

clean:
	del bin\encrypter.exe

