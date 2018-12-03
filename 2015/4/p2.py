import hashlib

i = 1
while True:
    hsh = hashlib.md5('iwrupvqb{}'.format(i).encode()).hexdigest()
    if '000000' == hsh[:6]:
        print(i, hsh)
        break
    i+=1
