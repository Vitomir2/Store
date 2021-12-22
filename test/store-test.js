const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TechnoLimeStore", function() {
    let TechnoLimeStoreContract;
    let owner;
    let address1;
    const productName = "Iphone 13";
    const productHex = "0x791b821c9d69f4f937859cbe0d1a49d6f658d410bc1577a910d3405f36b6eaf2";
    const productQty = 10;

    beforeEach(async() => {
        const TechnoLimeStore = await ethers.getContractFactory("TechnoLimeStore");
        [owner, address1] = await ethers.getSigners();
        TechnoLimeStoreContract = await TechnoLimeStore.deploy();
        await TechnoLimeStoreContract.deployed();

        // add a product
        const addProductTx = await TechnoLimeStoreContract.addProduct(productName, productQty);

        // wait until the transaction is mined
        await addProductTx.wait();
    });

    it("Should set the right owner", async function() {
        expect(await TechnoLimeStoreContract.owner()).to.equal(await owner.address);
    });

    it("Should return the new product once it is added", async function() {
        // ensure that the product is added successfully
        let product = await TechnoLimeStoreContract.getProduct(productName);
        expect(product[0]).to.equal(productHex);
    });

    it('Should check the quantity of the prodcut that was added', async function() {
        // ensure that the quantity is correct
        let product = await TechnoLimeStoreContract.getProduct(productName);
        expect(product[1]).to.equal(productQty);
    });

    it('Should buy the product, reduce the available quantity and check for correctness', async function() {
        // ensure that the quantity is correct
        let product = await TechnoLimeStoreContract.getProduct(productName);
        expect(product[1]).to.equal(productQty);

        await TechnoLimeStoreContract.buyProduct(productName);
        product = await TechnoLimeStoreContract.getProduct(productName);
        expect(product[1]).to.equal(productQty - 1);
        expect(product[2][0]).to.equal(owner.address);
    });

    it('Should buy the product, reduce the available quantity and check for correctness', async function() {
        await TechnoLimeStoreContract.buyProduct(productName);
        await TechnoLimeStoreContract.returnProduct(productName);
        let product = await TechnoLimeStoreContract.getProduct(productName);
        expect(product[1]).to.equal(productQty);
    });
});