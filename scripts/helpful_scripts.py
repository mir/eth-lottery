from brownie import (
    accounts, config, network, Contract,
    MockV3Aggregator,
    VRFCoordinatorV2Mock,
    LinkToken
    )
from web3 import Web3

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-forked", "mainnet-fork-dev"]
LOCAL_BLOCKHAIN_ENVIRONMENTS = ["development", "ganache-local"]


def get_account(index=None, id=None):
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)

    if (network.show_active() in LOCAL_BLOCKHAIN_ENVIRONMENTS
            or network.show_active() in FORKED_LOCAL_ENVIRONMENTS):
        return accounts[0]
    else:
        return accounts.add(config["wallets"]["from_key"])


contract_to_mock = {
    "eth_usd_price_feed": MockV3Aggregator,
    "vrf_coordinator": VRFCoordinatorV2Mock,
    "link_token": LinkToken
    }


def get_contract(contract_name):
    contract_type = contract_to_mock[contract_name]
    if (network.show_active() in LOCAL_BLOCKHAIN_ENVIRONMENTS):
        if len(contract_type) <= 0:
            deploy_mocks()
        contract=contract_type[-1]
    else:
        contract_address = config["networks"][network.show_active()][contract_name]
        contract = Contract.from_abi(
            contract_type._name,
            contract_address,
            contract_type.abi)
    return contract

DECIMALS = 8
INITIAL_VALUE = 2000e8


def deploy_mocks(decimals=DECIMALS, initial_value=INITIAL_VALUE):
    print(f"Active network is {network.show_active()}")
    print("Deploying mocks...")
    mock_aggregator = MockV3Aggregator.deploy(
        decimals,  # Decimals
        Web3.toWei(INITIAL_VALUE, "ether"),  # Cost (wei)
        {"from": get_account()})
    print("MockV3Aggregator is deployed")
