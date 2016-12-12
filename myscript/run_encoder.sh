#!/usr/bin/bash

stage=6;
left_encode_num=5
right_encode_num=4
model_config=BLSTMP_encoder.cntk
raw_feat=fbank
boundary_type=frame
cntk_command=
nj=20
cmd=run.pl
PHONE_NUM=40
echo "$0 $@"
[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;
if [ $# -ne 2 ]; then
    echo "Usage: myscript/$0 <ali-dir> <exp-dir>"
    echo "e.g.: myscirpt/$0 exp/tri4a exp/phone_encoder_4_3_BLSTMP_encoder.cntk_fbank_frame"
    echo ""
    echo "Main options (for others, see top of scrip file)"
    echo "--left-encode-num (4|5|6) # left encode num include current phone"
    echo "--right-encode-num (3|4|5) # right encode num"
    echo "--raw-feat (fbank|mfcc) # raw feature used for nn training"

fi
alidir=$1
dir=$2
if [ ! -d $dir ]; then
    mkdir $dir
fi
#prepare data and make mfcc feature
if [ $stage -le 1 ]; then
    corpus=/home2/jyh705/data/wsj
    local/cstr_wsj_data_prep.sh $corpus
fi

if [ $stage -le 2 ]; then 
    for x in test_dev93 train_si284; do
      cut -d" " -f1 data/$x/wav.scp | sed 's:\(^.*$\):\1 \1:' > data/$x/utt2spk
      cp data/$x/utt2spk data/$x/spk2utt
      steps/make_fbank.sh --cmd "run.pl" --nj $nj data/$x || exit 1;
      steps/compute_cmvn_stats.sh data/$x || exit 1;
      myscript/add_delta.sh --source_name $raw_feat --delta-order 2 --nj $nj --cmvn true data/${x} data/${x}_add-delta data/${x}_add-delta/log
    done
fi

#get phone label file for dnn trainning
encode_num=$((left_encode_num+right_encode_num))
if [ $stage -le 3 ]; then
    for x in test_dev93 train_si284; do
        alidir="exp/tri4a/ali-${x}"
        labels=$dir/phone_label_${x}.ark.txt
        map="map.int"
        mkdir -p $dir
        if [ ! -f ${labels} ]; then
            ali-to-phones --per-frame=true $alidir/final.mdl "ark:gunzip -c $alidir/ali.*.gz |" \
                         ark:- | hmm-phone-to-mono-phone --hmm-phn-to-phn-map=${map} \
                         ark:- ark,t:${labels}
        fi
    done
fi


#prepare encode phone label and weight file
tmp_dir=$dir/tmp
mkdir -p $tmp_dir
if [ $stage -le 4 ]; then
    for x in test_dev93 train_si284;
    do
        echo "python prepare_encoder_labels.py phone_label_${x}.ark.txt phone_encode_lable_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt ${left_encode_num} ${right_encode_num} encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt"
        
        feats_dir=data/${x}_add-delta
        labels_dir=data/${x}_${left_encode_num}_${right_encode_num}_labels
        weights_frame_dir=data/${x}_${left_encode_num}_${right_encode_num}_weights_frame
        weights_boundary_dir=data/${x}_${left_encode_num}_${right_encode_num}_weights_boundary
        mkdir -p $labels_dir/data
        mkdir -p $weights_frame_dir/data
        mkdir -p $weights_boundary_dir/data

        python myscript/split.py ${dir}/phone_label_${x}.ark.txt $tmp_dir/ $nj
        for JOB in `seq ${nj}`; 
        do
        {
            python myscript/prepare_encoder_labels.py $tmp_dir/phone_label_${x}.ark.txt${JOB} \
                $tmp_dir/phone_encode_label_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt${JOB} \
                ${left_encode_num} ${right_encode_num} \
                $tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt${JOB} \
                $tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt${JOB}

            copy-feats --compress=true \
                    ark,t:$tmp_dir/phone_encode_label_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt${JOB} \
                    ark,scp:${labels_dir}/data/label.ark${JOB},${labels_dir}/data/labels.scp${JOB}
            copy-feats --compress=true \
                    ark,t:$tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt${JOB} \
                    ark,scp:${weights_frame_dir}/data/weights_frame.ark${JOB},${weights_frame_dir}/data/weights_frame.scp${JOB}
            copy-feats --compress=true \
                    ark,t:$tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt${JOB} \
                    ark,scp:${weights_boundary_dir}/data/weights_boundary.ark${JOB},${weights_boundary_dir}/data/weights_boundary.scp${JOB}
            rm $tmp_dir/phone_label_${x}.ark.txt${JOB}
            rm $tmp_dir/phone_encode_label_${left_encode_num}_${right_encode_num}_one_hot_${x}.ark.txt${JOB}
            rm $tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_frame_${x}.ark.txt${JOB}
            rm $tmp_dir/encode_weight_${left_encode_num}_${right_encode_num}_boundary_${x}.ark.txt${JOB}
        }&
        done
        
        wait
        
        for JOB in `seq ${nj}`; 
        do
            cat ${labels_dir}/data/labels.scp${JOB} || exit 1;
        done > ${labels_dir}/labels.scp
        
        for JOB in `seq ${nj}`; 
        do
            cat ${weights_frame_dir}/data/weights_frame.scp${JOB} || exit 1;
        done > ${weights_frame_dir}/weights_frame.scp
        
        for JOB in `seq ${nj}`; 
        do
            cat ${weights_boundary_dir}/data/weights_boundary.scp${JOB} || exit 1;
        done > ${weights_boundary_dir}/weights_boundary.scp

    done
fi

#check the phone label file and weight file
scp_tmp_dir=${dir}/scp_tmp
if [ $stage -le 5 ]; then
    mkdir -p $scp_tmp_dir
    for x in test_dev93 train_si284;
    do
        feats=data/${x}_add-delta/feats.scp
        labels=data/${x}_${left_encode_num}_${right_encode_num}_labels/labels.scp
        weights_frame=data/${x}_${left_encode_num}_${right_encode_num}_weights_frame/weights_frame.scp
        weights_boundary=data/${x}_${left_encode_num}_${right_encode_num}_weights_boundary/weights_boundary.scp        
        python ./myscript/get_missed_utt.py $feats $labels ${scp_tmp_dir}/${x}_missed.utt
        grep -v -f ${scp_tmp_dir}/${x}_missed.utt $labels > $scp_tmp_dir/${x}_labels.scp
        grep -v -f ${scp_tmp_dir}/${x}_missed.utt $weights_frame > $scp_tmp_dir/${x}_weights_frame.scp
        grep -v -f ${scp_tmp_dir}/${x}_missed.utt $weights_boundary > $scp_tmp_dir/${x}_weights_boundary.scp
    done
fi
scp_dir=${dir}/scp
if [ $stage -le 5 ]; then
    mkdir -p $scp_dir
    for x in test_dev93 train_si284;
    do
        feats=data/${x}_add-delta/feats.scp
        python myscript/check_scp.py $feats $scp_tmp_dir/${x}_labels.scp $scp_tmp_dir/${x}_weights_frame.scp \
            $scp_tmp_dir/${x}_weights_boundary.scp $scp_tmp_dir/${x}_feats.scp
        feat-to-len scp:$scp_tmp_dir/${x}_feats.scp ark,t:$scp_tmp_dir/${x}_feats.count
        feat-to-len scp:$scp_tmp_dir/${x}_labels.scp ark,t:$scp_tmp_dir/${x}_labels.count
        feat-to-len scp:$scp_tmp_dir/${x}_weights_frame.scp ark,t:$scp_tmp_dir/${x}_weights_frame.count
        feat-to-len scp:$scp_tmp_dir/${x}_weights_boundary.scp ark,t:$scp_tmp_dir/${x}_weights_boundary.count
        
        python myscript/check_len.py $scp_tmp_dir/${x}_feats.count $scp_tmp_dir/${x}_labels.count \
                                     $scp_tmp_dir/${x}_weights_frame.count $scp_tmp_dir/${x}_weights_boundary.count \
                                     $scp_tmp_dir/${x}_wrong_len.utt
        
        grep -v -f ${scp_tmp_dir}/${x}_wrong_len.utt \
                $scp_tmp_dir/${x}_feats.scp > $scp_dir/${x}_feats.scp
        grep -v -f ${scp_tmp_dir}/${x}_wrong_len.utt \
                $scp_tmp_dir/${x}_labels.scp > $scp_dir/${x}_labels.scp
        grep -v -f ${scp_tmp_dir}/${x}_wrong_len.utt \
                $scp_tmp_dir/${x}_weights_frame.scp > $scp_dir/${x}_weights_frame.scp
        grep -v -f ${scp_tmp_dir}/${x}_wrong_len.utt \
                $scp_tmp_dir/${x}_weights_boundary.scp > $scp_dir/${x}_weights_boundary.scp
        grep -v -f ${scp_tmp_dir}/${x}_wrong_len.utt \
                $scp_tmp_dir/${x}_feats.count > $scp_dir/${x}_feats.count
         
    done
    
fi
#train cntk net

if [ $stage -le 6 ]; then
    x=train_si284
    feats_tr=scp:$scp_dir/${x}_feats.scp
    labels_tr=scp:$scp_dir/${x}_labels.scp
    if [ $boundary_type = "frame" ]; then
        weights_tr=scp:$scp_dir/${x}_weights_frame.scp
    else
        weights_tr=scp:$scp_dir/${x}_weights_boundary.scp
    fi
    counts_tr=$scp_dir/${x}_feats.count

    x=test_dev93
    feats_cv=scp:$scp_dir/${x}_feats.scp
    labels_cv=scp:$scp_dir/${x}_labels.scp
    if [ $boundary_type = "frame" ]; then
        weights_cv=scp:$scp_dir/${x}_weights_frame.scp
    else
        weights_cv=scp:$scp_dir/${x}_weights_boundary.scp
    fi
    counts_cv=$scp_dir/${x}_feats.count

    feat_dim=$(feat-to-dim $feats_cv -)
    label_dim=$((encode_num*PHONE_NUM))
    num_utts_per_iter=11
    myscript/train_nnet.sh --cmd $cmd --device 0 --cntk-command $cntk_command --learning-rate "0.1" \
        --momentum "0:0.9" --max-epochs 50 --num-utts-per-iter $num_utts_per_iter --minibatch-size 1024 \
        --evaluate-period 10 --cntk-config "cntk_config/${model_config}" --num-threads 1 \
        --encode-num $encode_num --feat-dim $feat_dim --label-dim $label_dim \
        --clipping-per-sample 0.05 --l2-reg-weight 0.00001 --dropout-rate 0 \
        --feats-tr $feats_tr --labels-tr $labels_tr --weights-tr $weights_tr --counts-tr $counts_tr \
        --feats-cv $feats_cv --labels-cv $labels_cv --weights-cv $weights_cv --counts-cv $counts_cv \
        exp/tri4a $dir
fi

