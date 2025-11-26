// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./util/PriceProvider.sol";

contract MyAuction is ERC721Holder,Initializable,UUPSUpgradeable, OwnableUpgradeable{

    event AuctionCreated(uint256 indexed auctionId,address indexed seller,uint256 startingPrice,uint256 duration,address collectionAddress,uint256 collectionId);
    event AuctionStarted(uint256 indexed auctionId,address indexed seller,address collectionAddress,uint256 collectionId);
    event BidPlaced(uint256 indexed auctionId,address indexed bidder,address bidToken, uint256 bidAmount);
    event AuctionEnded(uint256 indexed auctionId,address indexed highestBidder,uint256 highestBid, uint256 fee);

    // 结构体
    struct AuctionInfo {
        uint256 auctionId;
        // 拍卖人
        address seller;
        // 起拍价格
        uint256 startingPrice;
        // 最高价格
        uint256 highestBid;
        // 出价的ERC20地址
        address highestBidToken;
        // 最高出价者
        address highestBidder;
        // 是否结束
        bool isActive;
        // 拍卖持续时间
        uint256 duration;
        // 开始时间
        uint256 startTime;
        // 结束时间
        uint256 endTime;
        // nft藏品地址
        address collectionAddress;
        // nft 藏品Id
        uint256 collectionId;
    }

    //手续费收款账户
    address public feeAddress;
    //拍卖信息
    AuctionInfo public info;
    //价格预言机
    PriceProvider private priceProvider;
    //基础费率
    uint256 baseRate;
    //基础费率调整参数
    uint256 k;

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(
        address _feeAddress,
        address _priceProvider,
        uint256 auctionId,
        address seller,
        uint256 startingPrice,
        uint256 duration,
        address collectionAddress,
        uint256 collectionId
    ) public initializer{
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        require(duration >= 1 days, "Duration must be greater than 1 day");
        require(startingPrice > 0, "startingPrice must be greater than 0");
        feeAddress = _feeAddress;
        priceProvider = PriceProvider(_priceProvider);
        baseRate = 600;
        k = 100000;
        info = AuctionInfo({
            auctionId: auctionId,
            seller: seller,
            startingPrice: startingPrice,
            highestBid: startingPrice,
            highestBidToken: address(0),
            highestBidder: address(0),
            isActive: false,
            duration: duration,
            startTime: 0,
            endTime: 0,
            collectionAddress: collectionAddress,
            collectionId: collectionId
        });

        emit AuctionCreated(auctionId, msg.sender, startingPrice, duration, collectionAddress, collectionId);
    }

    function startAuction() external {
        IERC721(info.collectionAddress).safeTransferFrom(info.seller, address(this), info.collectionId);
        info.isActive = true;
        info.startTime = block.timestamp;
        info.endTime = block.timestamp + info.duration;

        emit AuctionStarted(info.auctionId, info.seller, info.collectionAddress, info.collectionId);
    }

    /**
     * 竞标
     * 接收ERC20token 和 ETH
     * 支付ETH时 token传0地址
     * @param token 支付的代币类型
     * @param amount 支付的代币数量
     */
    function bid(address token, uint256 amount) external payable {
        require(info.isActive, "Auction is not active");
        require(block.timestamp < info.endTime, "Auction has ended");
        require(msg.sender != info.seller, "Seller cannot bid on their own auction");
        require(comparePrice(token, amount), "Bid too low");

        //先收款
        if (token == address(0)) {
            require(msg.value == amount, "not receive Bid");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        // 退还之前的最高出价者
        if (info.highestBidder != address(0)) {
            if (info.highestBidToken == address(0)) {
                payable(info.highestBidder).transfer(info.highestBid);
            } else {
                IERC20(info.highestBidToken).transfer(info.highestBidder, info.highestBid);
            }
        }

        info.highestBid = amount;
        info.highestBidToken = token;
        info.highestBidder = msg.sender;

        emit BidPlaced(info.auctionId, msg.sender, token, amount);
    }
    /**
     * 出价比较
     */
    function comparePrice(address token, uint256 amount) private view returns(bool) {
        uint256 highestBidValue = priceProvider.getPrice(info.highestBidToken) * info.highestBid;
        uint256 bidValue = priceProvider.getPrice(token) * amount;
        return bidValue > highestBidValue;
    }


    /**
        * 结束拍卖
        *
        */
    function endAuction() external {
        require(info.isActive, "Auction is not active");
        require(block.timestamp >= info.endTime, "Auction has not ended yet");
        require(msg.sender == info.seller, "Only seller can end the auction");

        info.isActive = false;

        IERC721 nft = IERC721(info.collectionAddress);
        // 如果有人出价，把NFT转给最高出价者，把钱转给卖家
        if (info.highestBidder != address(0)) {
            uint256 fee = _fee(info.highestBidToken, info.highestBid);
            uint256 money = info.highestBid - fee;
            if (info.highestBidToken == address(0)) {
                payable(info.seller).transfer(money);
                payable(feeAddress).transfer(fee);
            } else {
                IERC20(info.highestBidToken).transfer(info.seller, money);
                IERC20(info.highestBidToken).transfer(feeAddress, fee);
            }
            nft.safeTransferFrom(address(this), info.highestBidder, info.collectionId);

            emit AuctionEnded(info.auctionId, info.highestBidder, info.highestBid, fee);
        } else {
            // 如果没人出价，把NFT退还给卖家
            nft.safeTransferFrom(address(this), info.seller, info.collectionId);

            emit AuctionEnded(info.auctionId, info.highestBidder, info.highestBid, 0);
        }
    }

    /**
     * 计算基于代币的手续费
     */
    function _fee(address token, uint256 amount) private view returns(uint256){
        uint256 price = priceProvider.getPrice(token);
        uint256 v = price * amount;
        uint256 usdFee = _usdFee(v);
        return usdFee / price;
    }

    /**
     * 计算手续费
     * @param v 成交金额 USD
     */
    function _usdFee(uint256 v) private view returns(uint256) {
        return (baseRate * k / (k + v)) * v / k ;
    }
}
