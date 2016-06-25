type proto
	a as integer
end type

dim prova(0 to 19) as proto

dim c as integer

for c = 0 to 19
	prova(c).a = c
	
next c

print c


function leggi(sorg() as proto) as integer
	sorg(0).a = 20
	return sorg(0).a
end function

print (leggi(prova()))
print prova(0).a



sleep
