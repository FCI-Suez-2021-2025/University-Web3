import os
import json

from utils import deployer_private_key
from utils.contract_type import ContractType
from utils.project_components import get_abi_dir, get_bin_dir, get_web3, get_config, update_config


def deploy_contract(contract_type: ContractType, constructor_args=()):
    w3 = get_web3()
    contract_name = contract_type.value
    deployer_account = get_config()["deployer_address"]

    abi_path = os.path.join(get_abi_dir(), f"{contract_name}.abi")
    bin_path = os.path.join(get_bin_dir(), f"{contract_name}.bin")

    with open(abi_path, "r") as abi_file:
        abi = json.load(abi_file)

    with open(bin_path, "r") as bin_file:
        bytecode = bin_file.read().strip()

    contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    construct_tx = contract.constructor(*constructor_args).build_transaction({
        'from': deployer_account,
        'nonce': w3.eth.get_transaction_count(deployer_account),
    })
    signed_tx = w3.eth.account.sign_transaction(construct_tx, deployer_private_key)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"{contract_name} deployed at: {tx_receipt.contractAddress}")
    get_config()["contracts"][contract_name] = tx_receipt.contractAddress
    update_config()
    return w3.eth.contract(address=tx_receipt.contractAddress, abi=abi)