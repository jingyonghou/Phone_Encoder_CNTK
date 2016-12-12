#!/usr/bin/bash
exp=5
# exp 1
if [ $exp = 1 ]; then
    stage=6;
    left_encode_num=3
    right_encode_num=2
    model_config=BLSTMP_encoder.cntk
    raw_feat=fbank
    boundary_type=frame
    nj=20
    ali_dir="tri4a"
    cntk_command="TrainBLSTMEncoder"
    
    dir="exp/phone_encoder_${left_encode_num}_${right_encode_num}_${model_config}_${raw_feat}_${boundary_type}"
    myscript/run_encoder.sh --cmd run.pl --stage $stage --left-encode-num $left_encode_num \
                    --right-encode-num $right_encode_num --cntk-command $cntk_command \
                    --model-config $model_config --raw-feat $raw_feat \
                    --boundary-type $boundary_type --nj $nj \
                    $ali_dir $dir
fi

# exp 2
if [ $exp = 2 ]; then
    stage=6;
    left_encode_num=3
    right_encode_num=3
    model_config=BLSTMP_encoder.cntk
    raw_feat=fbank
    boundary_type=boundary
    nj=20
    ali_dir="tri4a"
    cntk_command="TrainBLSTMEncoder"
    dir="exp/phone_encoder_${left_encode_num}_${right_encode_num}_${model_config}_${raw_feat}_${boundary_type}"
    
    myscript/run_encoder.sh --cmd run.pl --stage $stage --left-encode-num $left_encode_num \
                    --right-encode-num $right_encode_num --cntk-command $cntk_command \
                    --model-config $model_config --raw-feat $raw_feat --boundary-type $boundary_type --nj $nj \
                    $ali_dir $dir
fi

# exp 3
if [ $exp = 3 ]; then
    stage=3;
    left_encode_num=9
    right_encode_num=0
    model_config=LSTMP_encoder.cntk
    raw_feat=fbank
    boundary_type=boundary
    nj=20
    ali_dir="tri4a"
    cntk_command="TrainLSTMEncoder"
    #tag= # | tmp1 | tmp2
    dir="exp/phone_encoder_${left_encode_num}_${right_encode_num}_${model_config}_${raw_feat}_${boundary_type}${tag}"
    myscript/run_encoder.sh --cmd run.pl --stage $stage --left-encode-num $left_encode_num \
                    --right-encode-num $right_encode_num --cntk-command $cntk_command \
                    --model-config $model_config --raw-feat $raw_feat \
                    --boundary-type $boundary_type --nj $nj \
                    $ali_dir $dir
fi

# exp 4
if [ $exp = 4 ]; then
    stage=6;
    left_encode_num=5
    right_encode_num=4
    model_config=BLSTMP_FF_encoder.cntk
    raw_feat=fbank
    boundary_type=frame
    nj=20
    ali_dir="tri4a"
    cntk_command="TrainBLSTMEncoder"
    tag="_3lstm_1dnn" # | tmp1 | tmp2
    dir="exp/phone_encoder_${left_encode_num}_${right_encode_num}_${model_config}_${raw_feat}_${boundary_type}${tag}"
    myscript/run_encoder.sh --cmd run.pl --stage $stage --left-encode-num $left_encode_num \
                    --right-encode-num $right_encode_num --cntk-command $cntk_command \
                    --model-config $model_config --raw-feat $raw_feat \
                    --boundary-type $boundary_type --nj $nj \
                    $ali_dir $dir
fi

# exp 5
if [ $exp = 5 ]; then
    stage=5;
    left_encode_num=4
    right_encode_num=3
    model_config=BLSTMP_FF_encoder_frame.cntk
    raw_feat=fbank
    boundary_type=frame
    nj=20
    ali_dir="tri4a"
    cntk_command="TrainBLSTMEncoder"
    tag="_3lstm_1dnn" # | tmp1 | tmp2
    dir="exp/phone_encoder_${left_encode_num}_${right_encode_num}_${model_config}_${raw_feat}_${boundary_type}${tag}"
    myscript/run_encoder_frame.sh --cmd run.pl --stage $stage --left-encode-num $left_encode_num \
                    --right-encode-num $right_encode_num --cntk-command $cntk_command \
                    --model-config $model_config --raw-feat $raw_feat \
                    --boundary-type $boundary_type --nj $nj \
                    $ali_dir $dir
fi

