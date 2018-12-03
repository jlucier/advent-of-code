import hashlib

i = 1
while True:
    hsh = hashlib.md5('iwrupvqb{}'.format(i).encode()).hexdigest()
    if '00000' == hsh[:5]:
        print(i, hsh)
        break
    i+=1
