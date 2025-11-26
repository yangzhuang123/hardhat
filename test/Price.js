const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("test price", function(){
    it("it should be get price", async function(){
        let TestAggreagatorV3 = await ethers.getContractFactory("TestAggreagatorV3");
        let mock = await TestAggreagatorV3.deploy(10, "ETH/USD", 4000);
        await mock.waitForDeployment();
        let data = await mock.latestRoundData();
        console.log("price:", data.answer);

        let baseRate = 600;
        let k = 100000;

        console.log("price when v=100000:", (baseRate * k) / (k + 100000) * 100000 / baseRate);
        console.log("price when v=100000:", (baseRate * k) / (k + 10000) * 10000 / baseRate);
        console.log("price when v=100000:", (baseRate * k) / (k + 1000000) * 1000000 / baseRate);
        console.log("price when v=100000:", (baseRate * k) / (k + 100000000) * 100000000 / baseRate);
    });
});