#!/bin/bash

# Copyright 2015  Guoguo Chen
# Apache 2.0.

# Script for CNTK neural network training.

# Begin configuration section.
cmd=run.pl
cntk_command=train
learning_rate="0.2:1:1:1"
momentum="0:0.9"
max_epochs=50
num_utts_per_iter=20
minibatch_size=256
evaluate_period=100

cntk_config=cntk_config/CNTK2_lstmp.config
device=-1
parallel_opts=
num_threads=1
feature_transform=NO_FEATURE_TRANSFORM
feat_dim=
label_dim=
clipping_per_sample="1#INF"
l2_reg_weight=0
dropout_rate=0
feats_tr=
feats_cv=
labels_tr=
labels_cv=
weights_tr=
weights_cv=
counts_tr=
counts_cv=
encode_num=
# End configuration section

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# -ne 2 ]; then
  echo "Usage: steps/$0 <ali-dir> <exp-dir>"
  echo " e.g.: steps/$0 exp/tri4a exp/dnn_phone_encoder_6"
  echo ""
  echo "Main options (for others, see top of script file)"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."

  exit 1;
fi

#data=${1%/}
alidir=$1
dir=$2

for f in $alidir/final.mdl $alidir/tree; do
  [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done
if [ $feature_transform != "NO_FEATURE_TRANSFORM" ]; then
  [ ! -f $feature_transform ] &&\
    echo "$0: missing file $feature_transform" && exit 1;
fi

mkdir -p $dir/log
mkdir -p $dir/configs
mkdir -p $dir/cntk_model

cp -L $alidir/final.mdl $dir
cp -L $alidir/tree $dir

# Handles parallelization.
if [ $num_threads -gt 1 -a -z "$parallel_opts" ]; then
  parallel_opts="--num-threads $num_threads"
fi
cntk_train_opts="$cntk_train_opts numThreads=$num_threads"

cntk_tr_feats=$dir/cntk_train.feats
cntk_tr_labels=$dir/cntk_train.labels
cntk_tr_weights=$dir/cntk_train.weights
cntk_tr_counts=$counts_tr

cntk_cv_feats=$dir/cntk_valid.feats
cntk_cv_labels=$dir/cntk_valid.labels
cntk_cv_weights=$dir/cntk_valid.weights
cntk_cv_counts=$counts_cv

cntk_label_mapping=$dir/cntk_label.mapping

# Prepares training files.
echo "$feats_tr" > $cntk_tr_feats
echo "$labels_tr" > $cntk_tr_labels
echo "$weights_tr" > $cntk_tr_weights
if [ ! -f $cntk_tr_counts ]; then
    (feat-to-len "$feats_tr" ark,t:- > $cntk_tr_counts) || exit 1;
fi

echo "$feats_cv" > $cntk_cv_feats
echo "$labels_cv" > $cntk_cv_labels
echo "$weights_cv" > $cntk_cv_weights
if [ ! -f $cntk_cv_counts ]; then
    (feat-to-len "$feats_cv" ark,t:- > $cntk_cv_counts) || exit 1;
fi
for ((c = 0; c < label_dim; c++)); do
  echo $c
done > $cntk_label_mapping
if [ -z $feat_dim ]; then feat_dim=$(feat-to-dim "$feats_tr" -) || exit 1; fi

# Copies CNTK config files.
cp -f $cntk_config $dir/configs/Train.config

tee $dir/configs/Base.config <<EOF
DeviceId=$device
command=$cntk_command
ExpDir=$dir
modelName=cntk_model/cntk.nnet

momentum=$momentum
lratePerMB=$learning_rate
l2RegWeight=$l2_reg_weight
dropoutRate=$dropout_rate
maxEpochs=$max_epochs

encodeNum=$encode_num
labelDim=$label_dim
labelMapping=$cntk_label_mapping
featDim=$feat_dim
featureTransform=$feature_transform

inputCounts=$cntk_tr_counts
inputFeats=$cntk_tr_feats
inputLabels=$cntk_tr_labels
inputWeights=$cntk_tr_weights

cvInputCounts=$cntk_cv_counts
cvInputFeats=$cntk_cv_feats
cvInputLabels=$cntk_cv_labels
cvInputWeights=$cntk_cv_weights

numUttsPerMinibatch=$num_utts_per_iter
minibatchSize=$minibatch_size
evaluatePeriod=$evaluate_period
clippingThresholdPerSample=$clipping_per_sample
EOF

cn_command="cntk configFile=${dir}/configs/Base.config"
cn_command="$cn_command configFile=${dir}/configs/Train.config"
$cmd $parallel_opts JOB=1:1 $dir/log/cntk.train.JOB.log $cn_command || exit 1;

echo "$0 successfuly finished.. $dir"

sleep 3
exit 0
