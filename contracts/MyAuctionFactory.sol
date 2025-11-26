// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./MyAuction.sol";

contract MyAuctionFactory is ERC721Holder, Initializable, UUPSUpgradeable, OwnableUpgradeable {

    //拍卖数据
    address[] public auctions;
    //拍卖计数
    uint256 public auctionCount;
    //拍卖合约 beacon 地址
    address public auctionBeacon;
    //预言机价格提供者
    address public priceProvider;
    //手续费地址
    address public feeAddress;

    function initialize(address _feeAddress, address _priceProvider, address _auctionBeacon) public initializer{
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        feeAddress = _feeAddress;
        priceProvider = _priceProvider;
        auctionBeacon = _auctionBeacon;
        auctionCount = 0;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * 创建拍卖
     * @param startingPrice 起拍价格
     * @param duration 拍卖时长
     * @param collectionAddress 拍卖品地址
     * @param collectionId 拍卖品ID
     */
    function createAuction(
        uint256 startingPrice,
        uint256 duration,
        address collectionAddress,
        uint256 collectionId
    ) public returns (address) {
        auctionCount++;

        bytes memory data = abi.encodeWithSelector(
            MyAuction.initialize.selector,
            feeAddress,
            priceProvider,
            auctionCount,
            msg.sender,
            startingPrice,
            duration,
            collectionAddress,
            collectionId);
        BeaconProxy proxy = new BeaconProxy(auctionBeacon, data);
        address myAuctionAddress = address(proxy);

        auctions.push(myAuctionAddress);
        return myAuctionAddress;
    }

    /**
     * 获取所有拍卖信息
     */
    function getAuctions() public view returns (address[] memory) {
        return auctions;
    }

    /**
     * 获取单场拍卖信息
     */
    function getAuction(uint256 auctionId) public view returns (address) {
        require(auctionId > 0 && auctionId <= auctions.length, "Index out of bounds");
        return auctions[auctionId - 1];
    }

}
