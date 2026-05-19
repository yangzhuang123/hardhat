const {deployments, upgrades, ethers} = require("hardhat")
const fs = require("fs");
const path = require("path");

module.exports = async ({getNamedAccounts}) => {
    console.log("开始升级uups代理合约...")

    // 获取部署账户信息
    const {deployer} = await getNamedAccounts();

    // 获取合约部署信息
    const deploymentInfoPath = path.join(__dirname, 'uups_proxy_deployment_info.json');
    if (!fs.existsSync(deploymentInfoPath)) {
        console.error("部署信息文件不存在，请先部署uups代理合约！");
        return;
    }
    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentInfoPath, 'utf-8'));
    const proxyAddress = deploymentInfo.proxyAddress;
    console.log("读取到的uups代理合约地址：" + proxyAddress);

    // 连接代理合约
    const Box = await ethers.getContractFactory('BoxUUPS');
    const boxProxy = await ethers.getContractAt('BoxUUPS', proxyAddress);

    // 测试升级前的状态
    console.log("测试升级前的状态...")
    const valueBeforeUpgrade = await boxProxy.retrieve();
    console.log("升级前通过uups代理合约获取的值为：" + valueBeforeUpgrade);

    // 升级实现合约
    console.log("升级实现合约...")
    const BoxV2 = await ethers.getContractFactory('BoxUUPSV2');
    const boxProxyUpgraded = await upgrades.upgradeProxy(proxyAddress, BoxV2, {kind: 'uups'});
    await boxProxyUpgraded.waitForDeployment();
    const implementationAddress = await upgrades.erc1967.getImplementationAddress(await boxProxy.getAddress());

    console.log("升级实现合约完成，代理合约地址为：" + await boxProxyUpgraded.getAddress());
    console.log("升级实现合约完成，实现合约地址为：" + implementationAddress);

    // 测试升级后的状态
    console.log("测试升级后的状态...")
    const boxProxyAsBoxV2 = await ethers.getContractAt('BoxV2', await boxProxyUpgraded.getAddress());
    await boxProxyAsBoxV2.increment();
    console.log("调用BoxV2的increment函数成功！");
    const valueAfterUpgrade = await boxProxyAsBoxV2.retrieve();
    console.log("升级后通过uups代理合约获取的值为：" + valueAfterUpgrade);

    // 更新部署信息 到新文件中
    const upgradedDeploymentInfo = {
        proxyAddress: await boxProxyUpgraded.getAddress(),
        implementationAddress: await upgrades.erc1967.getImplementationAddress(await boxProxyUpgraded.getAddress()),
        adminAddress: await upgrades.erc1967.getAdminAddress(await boxProxyUpgraded.getAddress()),
    };
    const upgradedDeploymentInfoPath = path.join(__dirname, 'uups_proxy_upgraded_deployment_info.json');
    fs.writeFileSync(upgradedDeploymentInfoPath, JSON.stringify(upgradedDeploymentInfo, null, 2));
    console.log("升级后的部署信息已保存到：" + upgradedDeploymentInfoPath);

}


module.exports.tags = ['UUPSProxyUpgrade'];
