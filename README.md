# GGNNSmartVulDetector![GitHub stars](https://img.shields.io/github/stars/Messi-Q/GGNNSmartVulDetector.svg?style=plastic) ![GitHub forks](https://img.shields.io/github/forks/Messi-Q/GGNNSmartVulDetector.svg?color=blue&style=plastic) ![License](https://img.shields.io/github/license/Messi-Q/GGNNSmartVulDetector.svg?color=blue&style=plastic)

This repo is a python implementation of smart contract vulnerability detection based on graph neural networks (GNNs). 
In this research work, we focus on detecting three kinds of smart contract vulnerabilities (i.e., reentrancy, timestamp dependence, and infinite loop), 
which are not only the most significant threat to contract security but also challenging to precisely identify. 
All of the infinite loop types we concerned are implemented by Class C/C++ of [VNT](https://github.com/vntchain/go-vnt), 
while the smart contracts of reentrancy and timestamp dependence are wirrten by Solidity, i.e., [Ethereum](https://etherscan.io/) smart contract. 
Ethereum is a decentralized blockchain platform that can build a broad scope of applications, while Ether is one kind of cryptocurrency used on this platform.
Vntchain, an open-source distributed value network that runs smart contracts represented by Class C/C++. 
Vntchain is a novel and evolutionary blockchain platform, which borrows the architecture mode from Ethereum and 
incorporates Delegate Proof of Stake (DPOS) and Byzantine Fault Tolerance (BFT) technologies for higher 
performance and security. 

The ESC dataset consists of 40,932 smart contracts from Ethereum. Among the functions, around 5,013 functions possess at least one invocation to call.value, making them potentially affected by the reentrancy vulnerability. Around 4,833 functions contain the block.timestamp statement, making them susceptible to the timestamp dependence vulnerability.
The VSC dataset contains all the available 4,170 smart contracts collected from the VNT Chain network, which overall contain 13,761 functions. VNT Chain is an experimental public blockchain platform proposed by companies and universities from Singapore, China, and Australia.

## Requirements

#### Required Packages
* **python**3
* **TensorFlow**1.14.0
* **keras**2.2.4 with TensorFlow backend
* **sklearn** for model evaluation
* **docopt** as a command-line interface parser 
* **go-vnt** as a vntchain platform support
* **go-ethereum** as a ethereum platform support

Run the following script to install the required packages.
```shell
pip install --upgrade pip
pip install --upgrade tensorflow
pip install keras
pip install scikit-learn
pip install docopt
```

### Required Dataset
For each dataset, we randomly pick 20% contracts as the training set while the remainings are utilized for the testing set. 
In the comparison, metrics accuracy, recall, precision, and F1 score are all involved. In consideration of the distinct features of different platforms, 
experiments on reentrancy vulnerability and timestamp dependence vulnerability are conducted on the ESC dataset, 
while experiments on infinite loop vulnerability detection are conducted on the VSC dataset.

#### source code
Original smart contract source code:

Ethereum smart contracts:  [Etherscan_contract](https://drive.google.com/open?id=1h9aFFSsL7mK4NmVJd4So7IJlFj9u0HRv)

Vntchain smart contacts: [Vntchain_contract](https://drive.google.com/open?id=1FTb__ERCOGNGM9dTeHLwAxBLw7X5Td4v)


#### Dataset structure in this project
All of the smart contract source code, graph data, and training data in these folders in the following structure respectively.
```shell
${GGNNSmartVulDetector}
├── data
│   ├── loops
│   │   └── contract
│   │   └── graph_data
│   ├── timestamp
│   │   └── contract
│   │   └── graph_data
│   └── reentrancy
│       └── contract
│       └── graph_data
├── train_data
    ├── loops
    │   └── train.json
    │   └── vaild.json
    ├── timestamp
    │   └── train.json
    │   └── vaild.json
    └── reentrancy
        └── train.json
        └── vaild.json

```

* `data/reentrancy/contract`:  This is the data of original smart contracts.
* `data/reentrancy/graph_data`: This is the graph data, consisting edges and nodes, which are extracted by our AutoExtractor.
* `graph_data/edge`: It includes all edges and edge of each smart contract.
* `graph_data/node`: It includes all nodes and node of each smart contract.
* `train_data/reentrancy/train.json`: This is the training data of all the smart contract.
* `train_data/reentrancy/valid.json`: This is the testing data of all the smart contract.


### Code Files
The tools and models are as follows:
```shell
${GGNNSmartVulDetector}
├── tools
│   ├── remove_comment.py
│   ├── construct_fragment.py
│   ├── reentrancy/AutoExtractGraph.py
│   └── reentrancy/graph2vec.py
├── GGNNChemModel.py
├── BasicChemModel.py
└── utils.py
```

`GGNNChemModel.py`
* Interface to project, uses functionality from other code files.
* Loads dataset, trains TMP model, passes to neural network, models evaluation.
* Specific implementation for TMP model 

`BasicChemModel.py`
* Basically model of TMP.
* Basicall hyper-parameters for TMP.

`utils.py`
* The general tools for adjusting the iteration of models, include make_network_params.

`AutoExtractGraph.py`
* All functions in the smart contract code are automatically split and stored.
* Find the relationships between functions.
* Extract all smart contracts source code into features of nodes and edges.
```shell
python AutoExtractGraph.py
```

`graph2vec.py`
* Feature ablation.
* Converts graph into vectors.
```shell
python graph2vec.py
```

**Note:** The graph structure automation extraction tool is being improved.


## Running project
* To run the program, use this command: python GGNNChemModel.py.
* Also, you can use specific hyper-parameters to train the model, which can be found in `GGNNChemModel.py` and `BasicChemModel.py`.

Examples:
```shell
python GGNNChemModel.py --random_seed 9930 --thresholds 0.45
```

Using script：
Repeating 10 times for different seeds with `reentrancy_seed.sh`.
```shell
for i in $(seq 1 10);
do seed=$(( (RANDOM % 10000) + 1 ));
python ./GGNNChemModel.py --random_seed $seed --thresholds 0.45 | tee logs/SVDetector_"$i".log;
done
```
Repeating for different thresholds with `*_threshold.sh`.
```shell
for i in 0.352 0.38 0.4 0.42 0.45 0.48 0.5 0.52 0.55;
do
python ./GGNNChemModel.py --random_seed 9930 --thresholds $i | tee logs/SVDetector_"$i".log;
done
```
Then, you can find the training results in the `logs`.


## References
1. VNT Document. [vnt-document](https://github.com/vntchain/vnt-documentation).
2. Smart contract vulnerability detection based on graph neural network (GCN). [GraphDeeSmartContract](https://github.com/Messi-Q/GraphDeeSmartContract).
3. Thomas N. Kipf, Max Welling, Semi-Supervised Classification with Graph Convolutional Networks, ICLR 2017. [GCN](https://arxiv.org/abs/1609.02907).
4. Li Y, Tarlow D, Brockschmidt M, et al. Gated graph sequence neural networks. ICLR, 2016. [GGNN](https://arxiv.org/abs/1511.05493)



