from typing import Dict

from utils.contract_type import ContractType
from utils.project_components import get_web3, get_config


def verify_contract(address: str) -> bool:
    """Verify if a contract exists at the given address"""
    w3 = get_web3()
    try:
        code = w3.eth.get_code(address)
        return len(code) > 0
    except Exception:
        return False


def verify_all_contracts() -> Dict[ContractType, bool]:
    """Verify all contracts in config"""
    config = get_config()
    results = {}

    for contract_type in ContractType:
        address = config['contracts'].get(contract_type.value)
        if address:
            results[contract_type] = verify_contract(address)

    return results