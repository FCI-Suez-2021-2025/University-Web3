import json
import os

from utils.contract_type import ContractType
from utils.project_components import get_abi_dir, get_config, get_web3


def get_contract(contract_type: ContractType):
    abi_path = os.path.join(get_abi_dir(), f"{contract_type.value}.abi")
    if not os.path.exists(abi_path):
        raise FileNotFoundError(f"ABI file not found: {abi_path}")

    with open(abi_path, "r") as abi_file:
        contract_abi = json.load(abi_file)

    contract_address = get_config()["contracts"].get(contract_type.value)
    if not contract_address:
        raise ValueError(f"Contract address for '{contract_type.value}' not found in config.")

    return get_web3().eth.contract(address=contract_address, abi=contract_abi)