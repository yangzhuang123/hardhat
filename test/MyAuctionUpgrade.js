const { expect } = require("chai");
const { ethers,upgrades } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const parseEther = ethers.parseEther ?? ethers.utils.parseEther;
const getAddr = (c) => (typeof c === 'string' ? c : (c?.address ?? c?.target));

describe("MyAuctionUpgrade", function () {
    let MyAuction, myAuction, myAuctionV2;
    let MyNFT, myNFT;
    let MyAuctionFactory, myAuctionFactory;
    let seller, bidder1, bidder2;
    let beacon;
    const ONE_DAY = 24 * 60 * 60; // 1 day in seconds
    const STARTING_PRICE = parseEther("0.001");
    const FIRST_BID = parseEther("0.002");
    const SECOND_BID = parseEther("0.003");
    const INITIAL_BALANCE = parseEther("10");

    beforeEach(async function () {
        [seller, bidder1, bidder2] = await ethers.getSigners();

        // Deploy MyNFT contract
        MyNFT = await ethers.getContractFactory("MyNFT");
        myNFT = await MyNFT.deploy();
        await myNFT.waitForDeployment();

        // Deploy MyAuction contract
        MyAuction = await ethers.getContractFactory("MyAuction");
        beacon = await upgrades.deployBeacon(MyAuction);
        await beacon.waitForDeployment();

        // Deploy MyAuctionFactory contract
        MyAuctionFactory = await ethers.getContractFactory("MyAuctionFactory");
        myAuctionFactory = await upgrades.deployProxy(MyAuctionFactory, [getAddr(seller), "0x0000000000000000000000000000000000000000", getAddr(beacon)], { initializer: 'initialize', kind: 'uups' });

        // Mint token to seller
        await myNFT.connect(seller).mint(seller.address);
    });

    describe("Auction Upgrade", function () {
        it("should create auction correctly", async function () {
            const tx1 = await myAuctionFactory.connect(seller).createAuction(STARTING_PRICE,ONE_DAY,getAddr(myNFT),1);
            await tx1.wait();  // Wait for the transaction to be mined
            const tx2 = await myAuctionFactory.connect(seller).createAuction(STARTING_PRICE,ONE_DAY,getAddr(myNFT),2);
            await tx2.wait();  // Wait for the transaction to be mined


            const MyAuctionV2 = await ethers.getContractFactory("MyAuctionV2");
            await upgrades.upgradeBeacon(getAddr(beacon), MyAuctionV2);

            const auctionAddress1 = await myAuctionFactory.getAuction(1);  // Get the auction address from the factory
            const myAuction1 = MyAuctionV2.attach(auctionAddress1);
            await myAuction1.reinitializeV2("poly auctioning");
            const name1 = await myAuction1.name();
            expect(name1).to.equal("poly auctioning");

            const auctionAddress2 = await myAuctionFactory.getAuction(2);  // Get the auction address from the factory
            const myAuction2 = MyAuctionV2.attach(auctionAddress2);
            await myAuction2.reinitializeV2("poly auctioning");
            const name2 = await myAuction2.name();
            expect(name2).to.equal("poly auctioning");

            const tx3 = await myAuctionFactory.connect(seller).createAuction(STARTING_PRICE,ONE_DAY,getAddr(myNFT),2);
            await tx3.wait();  // Wait for the transaction to be mined

            const auctionAddress3 = await myAuctionFactory.getAuction(3);  // Get the auction address from the factory
            const myAuction3 = MyAuctionV2.attach(auctionAddress3);
            await myAuction3.reinitializeV2("poly auctioning");
            const name3 = await myAuction3.name();
            expect(name3).to.equal("poly auctioning");
        });
    });


    describe("AuctionFactory Upgrade", function () {
        it("should create auction correctly", async function () {
            const MyAuctionFactoryV2 = await ethers.getContractFactory("MyAuctionFactoryV2");
            await upgrades.upgradeProxy(getAddr(myAuctionFactory), MyAuctionFactoryV2, { call: { fn: 'initializeV2', args:["poly auction"] } });
            console.log("address:", getAddr(myAuctionFactory));
            const myAuctionFactoryV2 = MyAuctionFactoryV2.attach(getAddr(myAuctionFactory));

            const name = await myAuctionFactoryV2.name();
            expect(name).to.equal("poly auction");
        });
    });

});