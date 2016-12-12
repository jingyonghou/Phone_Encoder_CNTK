#!/home2/jyh705/anaconda2/bin/python
# Author: jyhou@nwpu-aslp.org
# Date: 17/10/2016
# Description: this script get encode phone labels accordding to phone label file

import sys
import numpy as np
PHONE_NUM=40
SIL_ID=0

def get_one_hot(class_ids, class_num=42): #zero based
    one_hot_label_all = []
    for class_id in class_ids:
        one_hot_label = [0]*class_num
        one_hot_label[int(class_id)] = 1
        one_hot_label_all += one_hot_label
    return one_hot_label_all

def get_phone_pairs(phones):
    previous_phone = phones[0]
    count_num = 0
    phone_pairs = []
    for phone in phones:
        if phone != previous_phone:
            phone_pairs.append([previous_phone, count_num])
            count_num = 0
            previous_phone = phone
        count_num += 1
        
    phone_pairs.append([previous_phone, count_num])
    return phone_pairs

def convert_to_pair(phone_labels):
    phone_pairs_all = []
    for phone_label in phone_labels:
        fields = phone_label.strip().split()
        utterance_id = fields[0]
        phone_pairs = get_phone_pairs(fields[1:])
        phone_pairs_all.append([utterance_id, phone_pairs])
    return phone_pairs_all

def get_encode_phone_pairs(phone_pairs_all, left_encode_num, right_encode_num):
    encode_phone_pairs_all = []
    for phone_pairs in phone_pairs_all:
        utt_id = phone_pairs[0]
        pairs_num = len(phone_pairs[1])
        phones = [ pairs[0] for pairs in phone_pairs[1] ]
        occur_nums = [ pairs[1] for pairs in phone_pairs[1] ]
        encode_phone_pairs = []
        for i in range(pairs_num):
            pair = phone_pairs[1][i]
            if (i+1 >= left_encode_num and (pairs_num - 1 - i) >= right_encode_num):
                encode_phone_pairs.append([phones[i+1-left_encode_num:i+1+right_encode_num], occur_nums[i]])
            elif (i+1 < left_encode_num and pairs_num - 1 - i < right_encode_num):
                encode_phone_pairs.append([[phones[0]]*(left_encode_num-i-1) + phones + [phones[-1]]*(right_encode_num-(pairs_num-1-i)), occur_nums[i]])
                print("WARNNING: the phoneme is to short!")
            elif (i+1 < left_encode_num):
                encode_phone_pairs.append([[phones[0]]*(left_encode_num-i-1)+phones[0:i+1+right_encode_num], occur_nums[i]])
            elif ((pairs_num-1 - i) < right_encode_num):
                encode_phone_pairs.append([phones[i+1-left_encode_num:]+[phones[-1]]*(right_encode_num-(pairs_num-1-i)), occur_nums[i]])
            else:
                print("ERROR: condition error!")
        encode_phone_pairs_all.append([utt_id, encode_phone_pairs])
    return encode_phone_pairs_all

def repeat_write_list(fid, vector, repeat_num):
    for i in range(repeat_num):
        fid.writelines("\n  ")
        for j in range(len(vector)):
            fid.writelines(str(vector[j]) + " ")

def write_one_hot_labels(fid, encode_phone_pairs_all, class_num):
    for encode_phone_pairs in encode_phone_pairs_all:
        utt_id = encode_phone_pairs[0]
        fid.writelines(utt_id + "  [")
        for pairs in encode_phone_pairs[1]:
            one_hot_labels = get_one_hot(pairs[0], class_num)
            occur_num = pairs[1]
            repeat_write_list(fid, one_hot_labels, occur_num)
        fid.writelines("]\n")

def write_weight_frame(fid, phone_pairs_all, left_encode_num, right_encode_num):
    for phone_pairs in phone_pairs_all:
        utt_id = phone_pairs[0]
        pairs = phone_pairs[1]
        phone_ids = [pair[0] for pair in pairs]
        occur_nums = [pair[1] for pair in pairs]
        start_num = sum(occur_nums[0:left_encode_num-1])
        fid.writelines(utt_id + "  [")
        repeat_write_list(fid, [0], start_num)
        end_num = sum(occur_nums[len(occur_nums)-right_encode_num:])
        repeat_write_list(fid, [1], sum(occur_nums)-start_num-end_num)
        repeat_write_list(fid, [0], end_num)
        fid.writelines("]\n")
         
def write_weight_boundary(fid, phone_pairs_all, left_encode_num, right_encode_num):
    for phone_pairs in phone_pairs_all:
        utt_id = phone_pairs[0]
        pairs = phone_pairs[1]
        phone_ids = [pair[0] for pair in pairs]
        occur_nums = [pair[1] for pair in pairs]
        fid.writelines(utt_id + "  [")
        start_num = sum(occur_nums[0:left_encode_num-1])
        repeat_write_list(fid, [0], start_num)
        if len(occur_nums) < (left_encode_num + right_encode_num):
            print("ERROR: the phone number less than encoder length\n")
        for i in range(left_encode_num-1, len(occur_nums)-right_encode_num):
            if int(phone_ids[i])!=SIL_ID or i != len(occur_nums)-right_encode_num-1:
                repeat_write_list(fid, [0], occur_nums[i]-1)
                repeat_write_list(fid, [1], 1)
            else:
                repeat_write_list(fid, [0], occur_nums[i])
        end_num = sum(occur_nums[len(occur_nums)-right_encode_num:])
        repeat_write_list(fid, [0], end_num)
        fid.writelines("]\n")
            
if __name__=='__main__':
    if len(sys.argv)<=4:
        print("USAGE: python " + sys.argv[0] + " phone_lable.ark.txt phone_encode_lable_post.ark.txt left_encode_num [right_encode_num] [weight_frame.ark.txt] [weight_boundary.ark.txt]")
        exit(1)
    phone_labels_all = open(sys.argv[1]).readlines()
    fid = open(sys.argv[2], "w")
    left_encode_num = int(sys.argv[3])
    if len(sys.argv) >= 5:
        right_encode_num = int(sys.argv[4])
    
    phone_pairs_all = convert_to_pair(phone_labels_all)
    encode_phone_pairs_all = get_encode_phone_pairs(phone_pairs_all, left_encode_num, right_encode_num)
    write_one_hot_labels(fid, encode_phone_pairs_all, class_num=PHONE_NUM)
    fid.close()

    if len(sys.argv) >= 6:
        fid = open(sys.argv[5], "w")
        write_weight_frame(fid, phone_pairs_all, left_encode_num, right_encode_num)
        fid.close()
    
    if len(sys.argv) >= 7:
        fid = open(sys.argv[6], "w")
        write_weight_boundary(fid, phone_pairs_all, left_encode_num, right_encode_num)
        fid.close()
