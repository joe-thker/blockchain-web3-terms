contract OrderBookMarket {
    struct Order {
        address trader;
        uint256 amount;
        uint256 price;
    }

    Order[] public buyOrders;
    Order[] public sellOrders;

    function placeBuy(uint256 amount, uint256 price) external {
        buyOrders.push(Order(msg.sender, amount, price));
    }

    function placeSell(uint256 amount, uint256 price) external {
        sellOrders.push(Order(msg.sender, amount, price));
    }

    function getBestBid() external view returns (uint256 price) {
        for (uint i = 0; i < buyOrders.length; i++) {
            if (buyOrders[i].amount > 0) {
                price = buyOrders[i].price;
                break;
            }
        }
    }
}
