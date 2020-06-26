# YODA-Project
Repository to hold all files related to VADER Yoda Project

The file structure is as follows:

VADER.v: Main module used to control the statement machine and drive the encryption module. Acts as the top module.
encrypter.v: Home of the encryption/decryption algorithm. All functions used b the algorithm are found here.
Debounce.v: Basic debounce module for start button
Delayed_Res.v: Baic delayed reset debouncer module for reset button.

LUT_cdcard.coe: LUT used to drive the BRAM. Simulated the storage of input hashed password as well as the passowrds available for the dictionary attack.

function_list.txt: List of all functions used for the AES algorithm.

vader_constraints.xdc: Constraints file

python folder: Holds the golden measure python code. We do not take credit for this code.
