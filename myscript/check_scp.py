#!/home2/jyh705/anaconda2/bin/python
# Author: jyhou@nwpu-aslp.org
# Date: 19/10/2016
# Description: this script check the utterance length and order of label, weight_frame and weight_boundary, and generate the feature scp file acordding to the label order.

import sys
def warnning(s):
    print("Warnning: " + str(s) + "\n")

def error(s):
    print("Error: " + str(s) + "\n")
    exit(1)

if __name__=='__main__':
    if len(sys.argv)<6:
        print("USAGE:python " + sys.argv[0] + " feats.scp labels.scp weights_frame.scp weights_boundary.scp sorted_feats.scp" )
        exit(1)
    
    feats = open(sys.argv[1]).readlines()
    labels = open(sys.argv[2]).readlines()
    weights_frame = open(sys.argv[3]).readlines()
    weights_boundary = open(sys.argv[4]).readlines()
    fid = open(sys.argv[5], "w")

    # check length
    length_right=False
    if len(labels) != len(weights_frame):
        warnning("labels lenght is not equal to weights_frame length")
    elif len(labels) != len(weights_boundary):
        warnning("labels lenght is not equal to weights_boundary length")
    elif len(weights_frame) != len(weights_boundary):
        warnning("weights_frame length is not equal to weights_boundary length")
    else:
        length_right=True
        print("labels lenght = weights_frame length = weights_boundary length\n")
    
    # check order
    utt_ids = []
    for i in range(len(labels)):
        utt_id_label = labels[i].strip().split()[0]
        utt_id_weight_frame = weights_frame[i].strip().split()[0]
        utt_id_weight_boundary = weights_boundary[i].strip().split()[0]
        if not ((utt_id_label==utt_id_weight_frame) and (utt_id_label==utt_id_weight_boundary)):
            error("order of label and weight_frame and weight_boundary is not same")
        utt_ids.append(utt_id_label)
    print("order of label and weight_frame and weight_boundary is same\n")
    # if length is right and order of label and weight_frame and weight_boundary is same then try to prepare feats.scp
    feats_dict = {}
    for i in range(len(feats)):
        fields = feats[i].strip().split()
        utt_id_feat = fields[0]
        feats_dict[utt_id_feat] = fields[1]

    for utt_id in utt_ids:
        if feats_dict.has_key(utt_id):
            fid.writelines(utt_id)
            fid.writelines(" ")
            fid.writelines(feats_dict[utt_id])
            fid.writelines("\n")
        else:
            # delete the utt_id in labels scp
            
            error("can not find features of utterance:" + utt_id)
        

    
        
