left_encode_num=4
right_encode_num=3
nj=20
for x in test_dev93 train_si284; 
do
    #python prepare_encoder_labels.py phone_label_test_dev93.ark.txt pone_encode_lable_post.ark.txt left_encode_num right_encode_num weight_frame.ark.txt weight_boundary.ark.txt
    echo "python prepare_encoder_labels.py phone_label_${x}.ark.txt phone_encode_lable_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt ${left_encode_num} ${right_encode_num} encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt"
    #python split.py phone_label_${x}.ark.txt $nj
    #python prepare_encoder_labels.py phone_label_${x}.ark.txt \
    #                pone_encode_lable_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt \
    #                ${left_encode_num} ${right_encode_num} \
    #                encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt \
    #                encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt
                    
done
