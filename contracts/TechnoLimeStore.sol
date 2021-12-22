//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Ownable.sol";

contract TechnoLimeStore is Ownable {
    mapping(bytes32 => Product) products; // bytes32 will be used for the product name (ID)
    mapping(address => mapping(bytes32 => uint)) public productsByCustomer; // keep every customer address and the id and the block number of each item

    struct Product {
        bytes32 productId;
        uint32 quantity;
        address[] customers;
    }

    event OrderResult(bytes32 productId, uint32 availableQty, address customerAddr);

    modifier productAvailable(string memory _productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        require(products[productId].quantity > 0, "Not enought quantity of this product");
        _;
    }

    modifier productNotPurchasedByUser(string memory _productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        require(productsByCustomer[msg.sender][productId] == 0, "A product can be purchased only once.");
        _;
    }

    modifier productOwnedByUser(string memory _productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        require(productsByCustomer[msg.sender][productId] > 0, "The product is not owned by the customer.");
        _;
    }

    modifier productReturn(string memory _productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        require(!returnPeriodExpired(productId, msg.sender), "The product cannot be returned - the period has expired.");
        _;
    }

    // "Iphone 13", 10
    // Method used to add the product only from the owner of the contract
    function addProduct(string memory _productName, uint32 _quantity) public onlyOwner {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        products[productId].productId = productId;
        products[productId].quantity += _quantity; // by default the quantity will be 0, so it is fine to increment always
    }

    // Method used to show the product given the product name
    function getProduct(string memory _productName) public view returns (Product memory) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        return products[productId];
    }

    // Method used to buy a product by its id
    function buyProduct(string memory _productName) public productAvailable(_productName) productNotPurchasedByUser(_productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        productsByCustomer[msg.sender][productId] = block.number;
        products[productId].customers.push(msg.sender);
        products[productId].quantity -= 1;

        emit OrderResult(productId, products[productId].quantity, msg.sender);
    }

    // Method used to return a product by its id
    function returnProduct(string memory _productName) public productOwnedByUser(_productName) productReturn(_productName) {
        bytes32 productId = keccak256(abi.encodePacked(_productName));
        productsByCustomer[msg.sender][productId] = 0;
        deleteCustomer(productId, msg.sender);
        products[productId].quantity += 1;

        emit OrderResult(productId, products[productId].quantity, msg.sender);
    }

    // Method that checks if the return period has expired - 100 blocks
    function returnPeriodExpired(bytes32 productId, address _custAddr) private view returns (bool) {
        uint blockDiff = block.number - productsByCustomer[_custAddr][productId];

        if (blockDiff <= 100) {
            return false;
        }

        return true;
    }

    // Method that will pop out the customer from the products collection
    function deleteCustomer(bytes32 productId, address custAddr) private {
        uint customerLen = products[productId].customers.length;
        if (customerLen != 0) {
            for (uint i = 0; i < customerLen; i++) {
                if (products[productId].customers[i] == custAddr) {
                    // copy the last customer address on the place of the one that is returning the item and delete the last address
                    products[productId].customers[i] = products[productId].customers[customerLen - 1]; 
                    products[productId].customers.pop();
                    break;
                }
            }
        }
    }
}