const {deployments, upgrades, ethers} = require("hardhat")
const fs = require("fs");
const path = require("path");

module.exports = async ({getNamedAccounts}) => {
    const {deployer} = await getNamedAccounts();

    //  1. 部署MyAuction代理合约
    console.log("Deploying NFT Auction...")
    const MyAuction = await ethers.getContractFactory('MyAuction');
    const beacon = await upgrades.deployBeacon(MyAuction);
    const beaconAddress = await beacon.getAddress();
    console.log("Deploying NFT Auction end..." + beaconAddress);

    //  2. 部署priceProvider合约
    console.log("Deploying PriceProvider ...")
    const PriceProvider = await ethers.getContractFactory('PriceProvider');
    const priceProvider = await PriceProvider.deploy(beacon);
    await priceProvider.waitForDeployment();
    const priceProviderAddress = await priceProvider.getAddress()
    console.log("Deploying PriceProvider End..." + priceProviderAddress);

    //  3. 部署MyAuctionFactory合约（利用1、2的合约地址创建）
    console.log("Deploying MyAuctionFactory start...")
    const MyAuctionFactory = await ethers.getContractFactory("MyAuctionFactory");
    const myAuctionFactoryProxy = await upgrades.deployProxy(MyAuctionFactory,
        [
            deployer,
            priceProviderAddress,
            beaconAddress,
        ],
        {
            kind: "uups"
        });
    await myAuctionFactoryProxy.waitForDeployment();
    console.log("Deploying MyAuctionFactory End..." + await myAuctionFactoryProxy.getAddress());
}


module.exports.tags = ['MyAuction'];
