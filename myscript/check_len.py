#!/home2/jyh705/anaconda2/bin/python

import sys
def warnning(s):
    print("Warnning: " + str(s) + "\n")

def error(s):
    print("Error: " + str(s) + "\n")
    exit(1)

def equal(l):
    for i in range(1,len(l)):
        if l[i-1]!=l[i]:
            return False
    return True

if __name__=="__main__":
    if len(sys.argv)<6:
        print("USAGE: python " + sys.argv[0] + "feats.scp labels.scp weights_frame.scp weights_boundary.scp wrong_len.utt\n ")
        exit(1)

    feats = open(sys.argv[1]).readlines()
    labels = open(sys.argv[2]).readlines()
    weights_frame = open(sys.argv[3]).readlines()
    weights_boundary = open(sys.argv[4]).readlines()
    fid=open(sys.argv[5], "w")
    for i in range(len(feats)):
        feat_id, feat_num = feats[i].strip().split()
        label_id, label_num = labels[i].strip().split()
        weight_frame_id, weight_frame_num = weights_frame[i].strip().split()
        weight_boundary_id, weight_boundary_num = weights_boundary[i].strip().split()
        if not (equal([feat_id, label_id, weight_frame_id, weight_boundary_id]) and 
                equal([feat_num, label_num, weight_frame_num, weight_boundary_num])):
            warnning("the frame number or utterence id is not same: " + 
                    feat_id + " " + label_id + " " + weight_frame_id + " " + weight_boundary_id + " " +
                    feat_num + " " + label_num + " " + weight_frame_num + " " +  weight_boundary_num)
            fid.writelines(feat_id + "\n")
            continue
        if int(feat_num) > 1800:
            fid.writelines(feat_id + "\n")
            warnning("too lang setence: " + feat_id + ", " + feat_num)
    print("frame num check finished\n")
