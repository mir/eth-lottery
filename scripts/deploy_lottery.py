from rsa import verify
from scripts.helpful_scripts import (
    get_account,
    get_contract   
)
from brownie import (
    Lottery,
    accounts,
    config,
    network
)

def deploy():
    account = get_account()
    print(account.balance)
    lottery = Lottery.deploy(
        get_contract("vrf_coordinator").address,
        get_contract("eth_usd_price_feed").address,
        config["networks"][network.show_active()]["key_hash"],
        config["networks"][network.show_active()]["subscription_id"],
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify", False)
        )

def start_lotter():
    account = get_account()
    lottery = Lottery[-1]
    starting_tx = lottery.startLottery({"from": account})

def enter_lottery():
    account = get_account()
    lottery = Lottery[-1]
    gas_wei = 1e5
    value = lottery.getEntranceFee()
    enter_lotter = lottery.enter({"from": account, "value": value })

def main():
    deploy()
