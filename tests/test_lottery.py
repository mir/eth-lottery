from brownie import accounts, Lottery, config,network
from web3 import Web3

def test_entrance_fee():
    account = accounts[0]
    lottery = Lottery.deploy(
        config["networks"][network.show_active()]["eth_usd_price_feed"],
        {"from": account})
    fee = lottery.getEntranceFee() / 1e18
    assert fee > 0.014
    assert fee < 0.02