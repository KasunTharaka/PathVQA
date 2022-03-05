imgv=1
baseUrl=drive/MyDrive/PathVQA
dir=scratch_imgv${imgv}
echo $dir

for seed in 9595 1 2 3 4 5
do

    # The name of experiment
  pre_name=lxmert_pvqa_pre_from_pretrained_${dir}_${seed}

  # Create dirs and make backup
  pre_output=snap/pretrain/$pre_name
  mkdir -p $pre_output

  # Pre-trainin
  PYTHONPATH=$PYTHONPATH:./src \
      python ${baseUrl}/baselines/method1/src/pretrain/lxmert_adv_pretrain.py \
      --taskQA_woi --taskMatched --taskVA2 \
      --visualLosses obj,attr,feat \
      --wordMaskRate 0.15 --objMaskRate 0.15 \
      --train train --valid val \
      --loadLXMERT ${baseUrl}/baselines/method1/snap/pretrained/model \
      --llayers 9 --xlayers 5 --rlayers 5 \
      --batchSize 32 --optim bert --lr 1e-4 --epochs 20 \
      --seed $seed --pvqaimgv $imgv \
      --tqdm --output $pre_output

  ft_name=pvqa_pre_from_pretrained_${dir}_${seed}_lxr955 # pvqa_pre

  # Save logs and models under snap/vqa; make backup.
  ft_output=snap/pvqa/$ft_name
  mkdir -p $ft_output

  # See Readme.md for option details.
  CUDA_VISIBLE_DEVICES=0 PYTHONPATH=$PYTHONPATH:./src \
      python ${baseUrl}/baselines/method1/src/pretrain/lxmert_adv_pretrain.py \
      --train train --valid val  \
      --llayers 9 --xlayers 5 --rlayers 5 \
      --loadLXMERT ${pre_output}/Epoch01 \
      --batchSize 32 --optim bert --lr 5e-5 --epochs 120 \
      --seed $seed --pvqaimgv $imgv \
      --tqdm --output $ft_output

    # The name of this experiment.
  res_name=pvqa_pre_from_pretrained_${dir}_${seed}_lxr955_results

  # Save logs and models under snap/vqa; make backup.
  res_output=snap/pvqa/$res_name
  mkdir -p $res_output

  # See Readme.md for option details.
  CUDA_VISIBLE_DEVICES=0 PYTHONPATH=$PYTHONPATH:./src \
      python src/tasks/pvqa.py \
      --test test  --train val --valid "" \
      --load ${ft_output}/BEST \
      --llayers 9 --xlayers 5 --rlayers 5 \
      --batchSize 32 --optim bert --lr 5e-5 --epochs 4 \
      --seed $seed --pvqaimgv $imgv \
      --tqdm --output $res_output

done
