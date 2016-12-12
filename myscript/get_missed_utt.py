#!/home2/jyh705/anaconda2/bin/python
import sys

if __name__=="__main__":
    if len(sys.argv) < 4:
        print("USAGE: python " + sys.argv[0] + " feats.scp labels.scp missed.utt")
        exit(1)
    feats = open(sys.argv[1]).readlines()
    labels = open(sys.argv[2]).readlines()
    fid = open(sys.argv[3], "w")
    print("feats_num:" + str(len(feats)) + ", labels_num:" + str(len(labels)) + "\n")    
    utt_ids = []
    for i in range(len(feats)):
        utt_id_feat = feats[i].strip().split()[0]
        utt_ids.append(utt_id_feat)

    for i in range(len(labels)):
        utt_id_label = labels[i].strip().split()[0]
        if not utt_id_label in utt_ids:
            fid.writelines(utt_id_label + "\n")

