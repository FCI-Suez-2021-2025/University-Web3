import json
import os

from web3.contract import Contract

from utils import web3
from utils.contract_deployer import deploy_contract, deploy_with_dependencies
from utils.contract_type import ContractType
from utils.contract_verifier import verify_contract
from utils.project_components import get_abi_dir, get_config, get_web3


def get_contract(contract_type: ContractType) -> Contract:
    """Get a contract instance, deploying if necessary"""
    config = get_config()
    address = config['contracts'].get(contract_type.value)

    if not address or not verify_contract(address):
        contract = deploy_with_dependencies(contract_type)
        return contract  # Already returns a Contract instance

        # Load contract ABI
    abi_path = os.path.join(get_abi_dir(), contract_type.abi_filename)
    with open(abi_path, "r") as abi_file:
        abi = json.load(abi_file)

    return web3.eth.contract(address=address, abi=abi)