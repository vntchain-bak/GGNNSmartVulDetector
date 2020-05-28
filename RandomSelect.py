from random import sample

raw_file_corenodes = "./tools/loops/results/Infinite_Loop_AutoExtract_fullnodes_all.json"
raw_data_corenodes = open(raw_file_corenodes, 'r')
lines_fullnodes = raw_data_corenodes.readlines()

# raw_file_fullnodes = "./tools/loops/results/Reentrancy_AutoExtract_fullnodes.json"
# raw_data_fullnodes = open(raw_file_fullnodes, 'r')
# lines_fullnodes = raw_data_fullnodes.readlines()

valid_idx = sample(range(1, len(lines_fullnodes) - 1), int(len(lines_fullnodes) * 0.2))

print("loading train/validation split")

train_out_fullnodes = "train_data/loops/train.json"
valid_out_fullnodes = "train_data/loops/valid.json"

# train_out_corenodes = "train_data/loops/train_corenodes.json"
# valid_out_corenodes = "train_data/loops/valid_corenodes.json"

train_fullnodes = open(train_out_fullnodes, 'a')
valid_fullnodes = open(valid_out_fullnodes, 'a')

# train_corenodes = open(train_out_corenodes, 'a')
# valid_corenodes = open(valid_out_corenodes, 'a')

for i in range(len(lines_fullnodes)):
    if i not in valid_idx:
        train_fullnodes.write(lines_fullnodes[i])
        # train_corenodes.write(lines_corenodes[i])
    else:
        valid_fullnodes.write(lines_fullnodes[i])
        # valid_corenodes.write(lines_corenodes[i])
print('split finished')
