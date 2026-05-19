const {deployments, upgrades, ethers} = require("hardhat")
const fs = require("fs");
const path = require("path");

module.exports = async ({getNamedAccounts}) => {
    console.log("开始部署uups代理合约...")

    // 获取部署账户信息
    const {deployer} = await getNamedAccounts();

    // 获取合约工厂
    const Box = await ethers.getContractFactory('BoxUUPS');

    // 部署uups代理合约
    console.log("部署uups代理合约...")
    const boxProxy = await upgrades.deployProxy(Box, [], {initializer: 'initialize', kind: 'uups'});
    await boxProxy.waitForDeployment();
    console.log("部署uups代理合约完成，地址为：" + await boxProxy.getAddress());

    // 获取实现合约地址
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(await boxProxy.getAddress());
    console.log("实现合约地址：" + implementationAddress);

    // 测试uups代理合约功能
    console.log("测试uups代理合约功能...")
    const boxProxyAsBox = await ethers.getContractAt('BoxUUPS', await boxProxy.getAddress());
    await boxProxyAsBox.store(42);
    const value = await boxProxyAsBox.retrieve();
    console.log("通过uups代理合约获取的值为：" + value);

    // 保存部署信息
    const deploymentInfo = {
        proxyAddress: await boxProxy.getAddress(),
        implementationAddress: implementationAddress,
    };
    const deploymentInfoPath = path.join(__dirname, 'uups_proxy_deployment_info.json');
    fs.writeFileSync(deploymentInfoPath, JSON.stringify(deploymentInfo, null, 2));
    console.log("部署信息已保存到：" + deploymentInfoPath);

}


module.exports.tags = ['UUPSProxy'];
