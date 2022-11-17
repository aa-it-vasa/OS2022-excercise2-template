sortwords: sortwords.c
	gcc sortwords.c -o sortwords

test: test-short test-filename test-long 

test-short: sortwords 
	bash test/test_short.sh 

test-filename: sortwords 
	bash test/test_filename.sh 

test-long: sortwords 
	bash test/test_long.sh 

clean:
	rm -f sortwords
	rm -f test/*.sort
	rm -f test/*.out