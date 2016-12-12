
for x in test_dev93 train_si284; 
do

    python ./myscript/get_missed_utt.py scp/${x}_feats.scp scp/${x}_labels.scp scp/${x}_missed.utt

done
