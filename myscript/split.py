#usr/bin/env python
#-*- coding:utf-8 -*-

#author: jyhou@nwpu-aslp.org 
#data: 23/1/2015 update:17/10/2016

#this program split a file averagely by line 
#input filename(string) splitfilenumber(int)
#output splitedfile(for 1 to n)
#example: split.py all.prompts 12
import sys
import numpy as np
import os
import shutil

def split_file_by_row(filepath, targetdir, newfilenum):
    file_object=open(filepath,'r')
    s=filepath.rfind('/')
    fileID=filepath.strip()[s+1:]
    try:
        i=0
        all_the_text=[]
        for line in file_object:
            i=i+1
            all_the_text.append(line)
            #print line
        n=i
        print n
        index=n//newfilenum
        print index
        for i in range(1,newfilenum):
            file_object_write=open(targetdir + fileID+'%d' % i,'w')
            for line in all_the_text[int((i-1)*index):int(i*index)]:
                file_object_write.write(line)
            file_object_write.close()
        file_object_write=open(targetdir + fileID+'%d' % newfilenum,'w')
        for line in all_the_text[int((newfilenum-1)*index):]:
            file_object_write.write(line)
        file_object_write.close()		
    finally:
        file_object.close()
	
if __name__ == '__main__':
    if len(sys.argv)<4:
        print("USAGE: fileList targetdir splitNum")
        exit(1)
    fileList=sys.argv[1]
    targetdir=sys.argv[2]
    splitNum=int(sys.argv[3])
    split_file_by_row(fileList, targetdir, splitNum)
