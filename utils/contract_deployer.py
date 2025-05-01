import os
import json
from typing import Tuple

from web3.contract import Contract

from utils.contract_type import ContractType
from utils.project_components import get_abi_dir, get_bin_dir, get_web3, get_config, update_config


def _load_contract_artifacts(contract_type: ContractType) -> Tuple[dict, str]:
    """Load ABI and bytecode for a contract type"""
    abi_path = os.path.join(get_abi_dir(), contract_type.abi_filename)
    bin_path = os.path.join(get_bin_dir(), contract_type.bin_filename)

    if not os.path.exists(abi_path):
        raise FileNotFoundError(f"ABI not found at {abi_path}")
    if not os.path.exists(bin_path):
        raise FileNotFoundError(f"Bytecode not found at {bin_path}")

    with open(abi_path, "r") as abi_file:
        abi = json.load(abi_file)

    with open(bin_path, "r") as bin_file:
        bytecode = bin_file.read().strip()

    return abi, bytecode

def deploy_contract(contract_type: ContractType, constructor_args: tuple = ()):
    w3 = get_web3()
    contract_name = contract_type.value
    deployer_account = get_config()["deployer_address"]

    abi, bytecode = _load_contract_artifacts(contract_type)

    contract = w3.eth.contract(abi=abi, bytecode=bytecode)

    construct_tx = contract.constructor(*constructor_args).build_transaction({
        'from': deployer_account,
        'nonce': w3.eth.get_transaction_count(deployer_account),
    })

    signed_tx = w3.eth.account.sign_transaction(construct_tx, get_config()["deployer_private_key"])
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    print(f"{contract_name} deployed at: {tx_receipt.contractAddress}")
    get_config()["contracts"][contract_name] = tx_receipt.contractAddress
    update_config()
    return w3.eth.contract(address=tx_receipt.contractAddress, abi=abi)

def deploy_with_dependencies(contract_type: ContractType) -> Contract:
    """
    Deploy a contract with all its dependencies
    Returns the deployed contract instance
    """
    config = get_config()

    # Handle dependencies first
    if contract_type == ContractType.COURSE:
        if not config["contracts"].get(ContractType.PROFESSOR.value):
            deploy_with_dependencies(ContractType.PROFESSOR)
        professor_address = config["contracts"][ContractType.PROFESSOR.value]
        return deploy_contract(contract_type, (professor_address,))

    elif contract_type == ContractType.ENROLLMENT:
        for dep in [ContractType.STUDENT, ContractType.PROFESSOR, ContractType.COURSE]:
            if not config["contracts"].get(dep.value):
                deploy_with_dependencies(dep)

        return deploy_contract(
            contract_type,
            (
                config["contracts"][ContractType.STUDENT.value],
                config["contracts"][ContractType.PROFESSOR.value],
                config["contracts"][ContractType.COURSE.value],
            )
        )

    elif contract_type == ContractType.UNIVERSITY:
        for dep in [ContractType.STUDENT, ContractType.PROFESSOR, ContractType.COURSE, ContractType.ENROLLMENT]:
            if not config["contracts"].get(dep.value):
                deploy_with_dependencies(dep)

        return deploy_contract(
            contract_type,
            (
                config["contracts"][ContractType.STUDENT.value],
                config["contracts"][ContractType.PROFESSOR.value],
                config["contracts"][ContractType.COURSE.value],
                config["contracts"][ContractType.ENROLLMENT.value]
            )
        )

    else:  # Simple contracts without constructor args
        return deploy_contract(contract_type)