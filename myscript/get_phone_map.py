import sys

if __name__ == '__main__':
    sets = open(sys.argv[1]).readlines()
    maps = open(sys.argv[2], "w")
    phone_p_num=1
    mono_phone_num=0
    for i in range(len(sets)):
        for phone_p in sets[i].strip().split():
            maps.write(str(phone_p_num) + " " + str(mono_phone_num))
            maps.write("\n")
            phone_p_num += 1
        mono_phone_num +=1
    

