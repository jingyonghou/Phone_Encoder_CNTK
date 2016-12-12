#!/usr/bin/bash

stage=6;
model_config=LSTMP.cntk
raw_feat=fbank
cntk_command=
nj=20
cmd=run.pl
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
#prepare data and make mfcc feature
if [ $stage -le 1 ]; then
    corpus=/home2/jyh705/data/wsj
    local/cstr_wsj_data_prep.sh $corpus
fi

if [ $stage -le 2 ]; then 
    for x in test_dev93 train_si284; do
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
        labels=$dir/phone_post_${x}.ark.txt
        map="map.int"
        mkdir -p $dir
        if [ ! -f ${labels} ]; then
            ali-to-phones --per-frame=true $alidir/final.mdl "ark:gunzip -c $alidir/ali.*.gz |" \
                         ark:- | hmm-phone-to-mono-phone --hmm-phn-to-phn-map=${map} \
                         ark:- ark:- | ali-to-post ark:- ark,t:${labels}
        fi
    done
fi

#train cntk net

if [ $stage -le 6 ]; then
    x=train_si284
    feats_tr=scp:data/${x}/feats.scp
    labels_tr=ark:$dir/phone_post_${x}.ark.txt
    counts_tr=$dir/${x}_feats.count

    x=test_dev93
    feats_cv=scp:$scp_dir/${x}_feats.scp
    labels_cv=ark:$dir/phone_post_${x}.ark.txt
    counts_cv=$dir/${x}_feats.count

    feat_dim=$(feat-to-dim $feats_cv -)
    label_dim=42
    num_utts_per_iter=40
    myscript/train_nnet.sh --cmd $cmd --device 0 --cntk-command $cntk_command --learning-rate "0.005:0.01" \
        --momentum "0:0.9" --max-epochs 30 --num-utts-per-iter $num_utts_per_iter --minibatch-size 1024 \
        --evaluate-period 10 --cntk-config "cntk_config/${model_config}" --num-threads 1 \
        --encode-num $encode_num --feat-dim $feat_dim --label-dim $label_dim \
        --clipping-per-sample 0.05 --l2-reg-weight 0.00001 --dropout-rate 0 \
        --feats-tr $feats_tr --labels-tr $labels_tr --counts-tr $counts_tr \
        --feats-cv $feats_cv --labels-cv $labels_cv --counts-cv $counts_cv \
        exp/tri4a $dir
fi

